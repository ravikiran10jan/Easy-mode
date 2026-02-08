import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import OpenAI from 'openai';
import {
  getTrackedOpenAI,
  createTrace,
  endTrace,
  runEvaluations,
  trackPromptExperiment,
  flushOpik,
  EVALUATION_PROMPTS,
  PROMPT_VERSIONS,
} from './opik';

admin.initializeApp();

const db = admin.firestore();

// ============ MEMORY SYSTEM FOR RAG ============

interface MemoryEntry {
  id: string;
  userId: string;
  type: 'conversation' | 'achievement' | 'setback' | 'insight' | 'preference';
  content: string;
  embedding?: number[];
  metadata: Record<string, unknown>;
  importance: number; // 1-5, for retrieval ranking
  createdAt: admin.firestore.Timestamp;
}

/**
 * Store a memory entry for a user
 * Used for RAG - retrieval augmented generation
 */
async function storeMemory(
  userId: string,
  type: MemoryEntry['type'],
  content: string,
  metadata: Record<string, unknown> = {},
  importance: number = 3
): Promise<string> {
  const memoryRef = db.collection('users').doc(userId).collection('memories').doc();
  
  await memoryRef.set({
    userId,
    type,
    content,
    metadata,
    importance,
    createdAt: admin.firestore.Timestamp.now(),
  });

  return memoryRef.id;
}

/**
 * Retrieve relevant memories for context (simple keyword-based for MVP)
 * In production, use vector embeddings for semantic search
 */
async function retrieveRelevantMemories(
  userId: string,
  query: string,
  limit: number = 5
): Promise<MemoryEntry[]> {
  // Get recent memories
  const recentSnapshot = await db
    .collection('users')
    .doc(userId)
    .collection('memories')
    .orderBy('createdAt', 'desc')
    .limit(20)
    .get();

  if (recentSnapshot.empty) {
    return [];
  }

  // Simple relevance scoring based on keyword overlap
  const queryWords = query.toLowerCase().split(/\s+/);
  const scoredMemories = recentSnapshot.docs.map((doc) => {
    const data = doc.data() as MemoryEntry;
    const contentWords = data.content.toLowerCase().split(/\s+/);
    
    // Calculate overlap score
    const overlap = queryWords.filter((w) => contentWords.includes(w)).length;
    const recencyBonus = (Date.now() - data.createdAt.toMillis()) < 86400000 ? 2 : 0; // 24hr recency boost
    const score = overlap + (data.importance * 0.5) + recencyBonus;
    
    return { ...data, id: doc.id, score };
  });

  // Sort by score and return top results
  return scoredMemories
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(({ score: _score, ...memory }) => memory);
}

// Constants
const XP_TASK_COMPLETE = 100;
const XP_AUDACITY_ATTEMPT = 200;
const XP_AUDACITY_SUCCESS = 100;
const XP_PER_LEVEL = 500;
const STREAK_BONUS_START_DAY = 3;
const STREAK_MULTIPLIER = 0.10;

/**
 * Calculate XP with streak multiplier
 */
export function calculateXpWithStreak(baseXp: number, streak: number): number {
  if (streak < STREAK_BONUS_START_DAY) {
    return baseXp;
  }
  
  const bonusDays = streak - STREAK_BONUS_START_DAY + 1;
  const multiplier = Math.min(bonusDays * STREAK_MULTIPLIER, 0.5); // Cap at 50%
  return Math.round(baseXp * (1 + multiplier));
}

/**
 * Calculate level from total XP
 */
export function calculateLevel(xpTotal: number): number {
  return Math.floor(xpTotal / XP_PER_LEVEL) + 1;
}

/**
 * Award XP for completing a task
 * Triggered when a new document is created in userTasks subcollection
 */
export const onTaskComplete = functions.firestore
  .document('users/{userId}/userTasks/{taskId}')
  .onCreate(async (snapshot, context) => {
    const { userId } = context.params;
    const taskData = snapshot.data();
    
    if (!taskData.completed) {
      return null;
    }
    
    try {
      const userRef = db.collection('users').doc(userId);
      const userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        console.error(`User ${userId} not found`);
        return null;
      }
      
      const userData = userDoc.data()!;
      const currentStreak = userData.streak || 0;
      
      // Calculate base XP based on task type
      let baseXp = XP_TASK_COMPLETE;
      if (taskData.type === 'audacity') {
        baseXp = XP_AUDACITY_ATTEMPT;
        if (taskData.outcome === 'success') {
          baseXp += XP_AUDACITY_SUCCESS;
        }
      }
      
      // Apply streak multiplier
      const finalXp = calculateXpWithStreak(baseXp, currentStreak);
      
      // Update the task document with final XP
      await snapshot.ref.update({ xpEarned: finalXp });
      
      // Update user's total XP and level
      const newXpTotal = (userData.xpTotal || 0) + finalXp;
      const newLevel = calculateLevel(newXpTotal);
      
      await userRef.update({
        xpTotal: newXpTotal,
        level: newLevel,
        lastActivity: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      // Check for badge awards
      await checkAndAwardBadges(userId, {
        xpTotal: newXpTotal,
        level: newLevel,
        taskType: taskData.type,
      });
      
      console.log(`Awarded ${finalXp} XP to user ${userId}. New total: ${newXpTotal}`);
      return { xpAwarded: finalXp, newTotal: newXpTotal };
    } catch (error) {
      console.error('Error awarding XP:', error);
      throw error;
    }
  });

/**
 * Update streak when user completes a task
 */
export const updateStreak = functions.firestore
  .document('users/{userId}/userTasks/{taskId}')
  .onCreate(async (snapshot, context) => {
    const { userId } = context.params;
    const taskData = snapshot.data();
    
    if (!taskData.completed) {
      return null;
    }
    
    try {
      const userRef = db.collection('users').doc(userId);
      const userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        return null;
      }
      
      const userData = userDoc.data()!;
      const lastActivity = userData.lastActivity?.toDate() || new Date(0);
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      const lastActivityDate = new Date(lastActivity);
      lastActivityDate.setHours(0, 0, 0, 0);
      
      const daysDiff = Math.floor(
        (today.getTime() - lastActivityDate.getTime()) / (1000 * 60 * 60 * 24)
      );
      
      let newStreak = userData.streak || 0;
      
      if (daysDiff === 0) {
        // Same day, streak unchanged
      } else if (daysDiff === 1) {
        // Consecutive day, increment streak
        newStreak += 1;
      } else {
        // Streak broken, reset to 1
        newStreak = 1;
      }
      
      if (newStreak !== userData.streak) {
        await userRef.update({ streak: newStreak });
        
        // Log analytics event
        await db.collection('analytics').add({
          event: 'streak_increase',
          userId: userId,
          newStreak: newStreak,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      
      return { newStreak };
    } catch (error) {
      console.error('Error updating streak:', error);
      throw error;
    }
  });

/**
 * Check and award badges based on user progress
 */
async function checkAndAwardBadges(
  userId: string,
  progress: { xpTotal: number; level: number; taskType?: string }
): Promise<void> {
  const userRef = db.collection('users').doc(userId);
  const userDoc = await userRef.get();
  const userData = userDoc.data();
  const earnedBadges: string[] = userData?.badges?.map((b: any) => b.badgeId) || [];
  
  const badgesToAward: string[] = [];
  
  // First Step badge - complete first task
  if (!earnedBadges.includes('first_step')) {
    badgesToAward.push('first_step');
  }
  
  // Level badges
  const levelBadges: { [key: number]: string } = {
    5: 'level_5',
    10: 'level_10',
    25: 'level_25',
    50: 'level_50',
  };
  
  for (const [level, badgeId] of Object.entries(levelBadges)) {
    if (progress.level >= Number(level) && !earnedBadges.includes(badgeId)) {
      badgesToAward.push(badgeId);
    }
  }
  
  // Bold Beginner - first audacity attempt
  if (progress.taskType === 'audacity' && !earnedBadges.includes('bold_beginner')) {
    badgesToAward.push('bold_beginner');
  }
  
  // Award badges
  for (const badgeId of badgesToAward) {
    await userRef.update({
      badges: admin.firestore.FieldValue.arrayUnion({
        badgeId: badgeId,
        earnedAt: new Date().toISOString(),
      }),
    });
    
    // Log analytics
    await db.collection('analytics').add({
      event: 'badge_earned',
      userId: userId,
      badgeId: badgeId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

/**
 * AI-powered task personalization
 * Takes a task and user context, returns personalized description and tips
 * Includes Opik tracing and LLM-as-judge evaluations
 */
export const personalizeTask = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to use this feature.'
    );
  }

  const { task, userContext } = data;
  const userId = context.auth.uid;
  
  if (!task || !task.title) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Task data is required.'
    );
  }

  // Create Opik trace for this AI operation
  const trace = createTrace({
    name: 'personalize_task',
    userId,
    functionName: 'personalizeTask',
    input: { task, userContext },
    tags: ['task-personalization', task.type || 'action'],
  });

  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'OpenAI API key not configured. Add OPENAI_API_KEY to functions/.env file.'
      );
    }

    // Use tracked OpenAI client for automatic span creation
    const openai = getTrackedOpenAI(apiKey, {
      userId,
      feature: 'task_personalization',
    });

    const systemPrompt = `You are Easy Mode, an AI life coach focused on building confidence through Action, Audacity, and Enjoyment. Your tone is warm, encouraging, and direct—like a supportive friend who believes in the user.

Core principles:
- Action: Small steps create momentum. Progress over perfection.
- Audacity: Bold asks expand comfort zones. The outcome matters less than the attempt.
- Enjoyment: Romanticize everyday moments. Find joy in the ordinary.

Keep responses concise and actionable. No fluff.`;

    const userPrompt = `Personalize this task for the user:

TASK:
- Title: ${task.title}
- Description: ${task.description}
- Type: ${task.type}
- Estimated time: ${task.estimatedMinutes} minutes

USER CONTEXT:
- Name: ${userContext?.name || 'Friend'}
- Current streak: ${userContext?.streak || 0} days
- Level: ${userContext?.level || 1}
- Goal: ${userContext?.goal || 'Build confidence'}
- Pain point: ${userContext?.pain || 'Feeling stuck'}
- Time available: ${userContext?.dailyTimeMinutes || 10} minutes

Respond in JSON format:
{
  "personalizedDescription": "A personalized version of the task description (2-3 sentences)",
  "coachTip": "One specific, actionable tip for this task (1-2 sentences)",
  "motivationalNote": "A brief encouraging message based on their progress (1 sentence)"
}`;

    // Track prompt experiment version
    trackPromptExperiment(trace, {
      ...PROMPT_VERSIONS.personalizeTask.v1,
      systemPrompt,
      userPromptTemplate: userPrompt,
    });

    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      temperature: 0.7,
      max_tokens: 300,
      response_format: { type: 'json_object' }
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error('Empty response from AI');
    }

    const personalized = JSON.parse(content);

    // Run LLM-as-judge evaluations
    const rawOpenai = new OpenAI({ apiKey });
    const evaluationScores = await runEvaluations(rawOpenai, [
      {
        config: EVALUATION_PROMPTS.taskRelevance,
        variables: {
          goal: userContext?.goal || 'Build confidence',
          pain: userContext?.pain || 'Feeling stuck',
          task: JSON.stringify(personalized),
        },
      },
      {
        config: EVALUATION_PROMPTS.specificityScore,
        variables: { response: JSON.stringify(personalized) },
      },
      {
        config: EVALUATION_PROMPTS.safetyScore,
        variables: { response: JSON.stringify(personalized) },
      },
    ]);

    // End trace with output and evaluation scores
    await endTrace(trace, {
      personalized,
      model: 'gpt-4o-mini',
      tokensUsed: response.usage?.total_tokens,
    }, evaluationScores);

    // Flush Opik data
    await openai.flush();
    await flushOpik();
    
    return {
      success: true,
      personalizedDescription: personalized.personalizedDescription,
      coachTip: personalized.coachTip,
      motivationalNote: personalized.motivationalNote,
    };
  } catch (error) {
    console.error('Error personalizing task:', error);

    // End trace with error
    await endTrace(trace, {
      error: error instanceof Error ? error.message : 'Unknown error',
      success: false,
    });
    await flushOpik();
    
    // Return fallback personalization
    return {
      success: false,
      personalizedDescription: task.description,
      coachTip: 'Take it one step at a time. You\'ve got this.',
      motivationalNote: 'Every small action builds momentum.',
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
});

/**
 * Generate daily AI insight based on user progress
 * Includes Opik tracing and LLM-as-judge evaluations
 */
export const generateDailyInsight = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to use this feature.'
    );
  }

  const userId = context.auth.uid;
  const { userStats, recentActivity } = data;
  
  // Declare outside try block for catch fallback access
  let stats = userStats;
  let activity = recentActivity;

  // Create Opik trace for this AI operation
  const trace = createTrace({
    name: 'generate_daily_insight',
    userId,
    functionName: 'generateDailyInsight',
    input: { userStats, recentActivity },
    tags: ['daily-insight'],
  });

  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'OpenAI API key not configured.'
      );
    }

    // Use tracked OpenAI client
    const openai = getTrackedOpenAI(apiKey, {
      userId,
      feature: 'daily_insight',
    });
    
    // Get additional user data if not provided
    if (!stats) {
      const userDoc = await db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        const userData = userDoc.data()!;
        stats = {
          name: userData.name,
          xpTotal: userData.xpTotal || 0,
          level: userData.level || 1,
          streak: userData.streak || 0,
          goal: userData.profile?.goal,
          pain: userData.profile?.pain,
        };
      }
    }
    
    if (!activity) {
      // Get last 7 days of activity
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
      
      const tasksSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('userTasks')
        .where('date', '>=', sevenDaysAgo.toISOString())
        .get();
      
      activity = {
        tasksCompleted: tasksSnapshot.size,
        taskTypes: tasksSnapshot.docs.map(d => d.data().type),
      };
    }

    const systemPrompt = `You are Easy Mode, an AI life coach. Generate a personalized daily insight that feels like a message from a supportive mentor.

Your insights should:
- Acknowledge specific progress or patterns
- Provide one actionable suggestion for today
- Be warm but not cheesy
- Keep it under 100 words total`;

    const userPrompt = `Generate a daily insight for this user:

USER STATS:
- Name: ${stats?.name || 'Friend'}
- Level: ${stats?.level || 1}
- XP Total: ${stats?.xpTotal || 0}
- Current streak: ${stats?.streak || 0} days
- Goal: ${stats?.goal || 'Build confidence'}
- Challenge: ${stats?.pain || 'Getting started'}

RECENT ACTIVITY (Last 7 days):
- Tasks completed: ${activity?.tasksCompleted || 0}
- Task types: ${activity?.taskTypes?.join(', ') || 'None yet'}

Today is ${new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}.

Respond in JSON format:
{
  "greeting": "A personalized greeting (e.g., 'Good morning, [name]!' or 'Hey [name],')",
  "insight": "Main insight about their progress or a pattern you notice (2-3 sentences)",
  "todayFocus": "One specific thing to focus on today (1 sentence)",
  "encouragement": "Brief closing encouragement (1 sentence)"
}`;

    // Track prompt experiment version
    trackPromptExperiment(trace, {
      ...PROMPT_VERSIONS.dailyInsight.v1,
      systemPrompt,
      userPromptTemplate: userPrompt,
    });

    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      temperature: 0.8,
      max_tokens: 250,
      response_format: { type: 'json_object' }
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error('Empty response from AI');
    }

    const insight = JSON.parse(content);

    // Run LLM-as-judge evaluations
    const rawOpenai = new OpenAI({ apiKey });
    const evaluationScores = await runEvaluations(rawOpenai, [
      {
        config: EVALUATION_PROMPTS.specificityScore,
        variables: { response: JSON.stringify(insight) },
      },
      {
        config: EVALUATION_PROMPTS.engagementPotential,
        variables: {
          response: JSON.stringify(insight),
          context: JSON.stringify({ stats, activity }),
        },
      },
      {
        config: EVALUATION_PROMPTS.safetyScore,
        variables: { response: JSON.stringify(insight) },
      },
    ]);

    // End trace with output and scores
    await endTrace(trace, {
      insight,
      model: 'gpt-4o-mini',
      tokensUsed: response.usage?.total_tokens,
    }, evaluationScores);
    
    // Log analytics
    await db.collection('analytics').add({
      event: 'daily_insight_generated',
      userId: userId,
      evaluationScores: evaluationScores.reduce((acc, s) => ({ ...acc, [s.name]: s.value }), {}),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Flush Opik data
    await openai.flush();
    await flushOpik();
    
    return {
      success: true,
      greeting: insight.greeting,
      insight: insight.insight,
      todayFocus: insight.todayFocus,
      encouragement: insight.encouragement,
      generatedAt: new Date().toISOString(),
    };
  } catch (error) {
    console.error('Error generating daily insight:', error);

    // End trace with error
    await endTrace(trace, {
      error: error instanceof Error ? error.message : 'Unknown error',
      success: false,
    });
    await flushOpik();
    
    // Return fallback insight
    const fallbackGreetings = [
      `Good morning${stats?.name ? `, ${stats.name}` : ''}!`,
      `Hey there${stats?.name ? `, ${stats.name}` : ''}!`,
    ];
    
    return {
      success: false,
      greeting: fallbackGreetings[Math.floor(Math.random() * fallbackGreetings.length)],
      insight: 'Every day is a fresh opportunity to take action toward your goals.',
      todayFocus: 'Pick one small task and give it your full attention.',
      encouragement: 'You\'re building something great, one step at a time.',
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
});

/**
 * Scheduled function to send daily nudge notifications
 * Runs every day at 9:00 AM UTC
 */
export const sendDailyNudge = functions.pubsub
  .schedule('0 9 * * *')
  .timeZone('UTC')
  .onRun(async (_context) => {
    try {
      // Get users who have notifications enabled
      const usersSnapshot = await db.collection('users')
        .where('notificationsEnabled', '==', true)
        .get();
      
      const messaging = admin.messaging();
      const messages: admin.messaging.Message[] = [];
      
      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        if (userData.fcmToken) {
          messages.push({
            notification: {
              title: 'Easy Mode Moment',
              body: "Your daily task is ready! Let's make today count.",
            },
            token: userData.fcmToken,
          });
        }
      });
      
      if (messages.length > 0) {
        await messaging.sendEach(messages);
        console.log(`Sent ${messages.length} daily nudge notifications`);
      }
      
      return null;
    } catch (error) {
      console.error('Error sending daily nudge:', error);
      throw error;
    }
  });

// ============ AGENTIC PLANNING SYSTEM ============

/**
 * Tool definitions for the Planner Agent
 * These enable multi-step reasoning with function calling
 */
const PLANNER_TOOLS: OpenAI.Chat.Completions.ChatCompletionTool[] = [
  {
    type: 'function',
    function: {
      name: 'create_milestone',
      description: 'Create a weekly milestone that breaks down the user goal into achievable steps',
      parameters: {
        type: 'object',
        properties: {
          week_number: { type: 'number', description: 'Week number (1-4)' },
          milestone_title: { type: 'string', description: 'Short title for this milestone' },
          milestone_description: { type: 'string', description: 'What success looks like for this milestone' },
          focus_area: { type: 'string', enum: ['action', 'audacity', 'enjoyment'], description: 'Primary focus area' },
          difficulty_level: { type: 'number', description: 'Difficulty 1-5 (1=easy, 5=challenging)' },
        },
        required: ['week_number', 'milestone_title', 'milestone_description', 'focus_area', 'difficulty_level'],
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'create_daily_task',
      description: 'Create a specific daily micro-task for a milestone',
      parameters: {
        type: 'object',
        properties: {
          day_of_week: { type: 'string', enum: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'] },
          task_title: { type: 'string', description: 'Specific actionable task title' },
          task_type: { type: 'string', enum: ['action', 'audacity', 'enjoy'], description: 'Task category' },
          estimated_minutes: { type: 'number', description: 'Time required in minutes' },
          difficulty: { type: 'number', description: 'Difficulty 1-5' },
          why_today: { type: 'string', description: 'Why this task fits this day' },
        },
        required: ['day_of_week', 'task_title', 'task_type', 'estimated_minutes', 'difficulty', 'why_today'],
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'adjust_difficulty',
      description: 'Adjust the plan difficulty based on user performance',
      parameters: {
        type: 'object',
        properties: {
          adjustment_type: { type: 'string', enum: ['simplify', 'maintain', 'increase'] },
          reason: { type: 'string', description: 'Why this adjustment is being made' },
          new_difficulty_target: { type: 'number', description: 'Target difficulty level 1-5' },
        },
        required: ['adjustment_type', 'reason', 'new_difficulty_target'],
      },
    },
  },
];

interface WeeklyMilestone {
  weekNumber: number;
  title: string;
  description: string;
  focusArea: 'action' | 'audacity' | 'enjoyment';
  difficultyLevel: number;
  dailyTasks: DailyPlanTask[];
}

interface DailyPlanTask {
  dayOfWeek: string;
  title: string;
  type: 'action' | 'audacity' | 'enjoy';
  estimatedMinutes: number;
  difficulty: number;
  whyToday: string;
  completed?: boolean;
}

interface WeeklyPlan {
  id: string;
  userId: string;
  weekNumber: number;
  startDate: string;
  endDate: string;
  userGoal: string;
  milestones: WeeklyMilestone[];
  currentMilestone: number;
  difficultyLevel: number;
  completionRate: number;
  adjustmentHistory: Array<{
    date: string;
    type: string;
    reason: string;
  }>;
  agentReasoning: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

/**
 * PLANNER AGENT - Generates weekly plans with multi-step reasoning
 * Uses OpenAI function calling for tool use pattern
 * 
 * Multi-step reasoning chain:
 * 1. Analyze user goal and context
 * 2. Break goal into 4 weekly milestones (tool: create_milestone)
 * 3. For current week, generate daily micro-tasks (tool: create_daily_task)
 * 4. Adjust based on past completion rate (tool: adjust_difficulty)
 */
export const generateWeeklyPlan = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to generate a weekly plan.'
    );
  }

  const userId = context.auth.uid;
  const { userGoal, weekNumber = 1, forceRegenerate = false } = data;

  try {
    // Step 1: Gather user context
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.exists ? userDoc.data()! : {};
    
    const goal = userGoal || userData.profile?.goal || 'Build confidence through small daily actions';
    const timeAvailable = userData.profile?.dailyTimeMinutes || 10;
    const painPoint = userData.profile?.pain || 'Feeling stuck';

    // Get user's past completion data for adaptive difficulty
    const behaviorPattern = await analyzeUserBehavior(userId);
    
    // Check for existing plan this week
    const existingPlan = await db
      .collection('users')
      .doc(userId)
      .collection('weeklyPlans')
      .where('weekNumber', '==', weekNumber)
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    if (!existingPlan.empty && !forceRegenerate) {
      const plan = existingPlan.docs[0].data() as WeeklyPlan;
      return {
        success: true,
        plan,
        source: 'cached',
        message: 'Retrieved existing plan for this week',
      };
    }

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'OpenAI API key not configured.'
      );
    }
    const openai = new OpenAI({ apiKey });

    // Step 2: Multi-step reasoning - Generate milestones
    console.log(`[Planner Agent] Starting multi-step reasoning for user ${userId}`);
    
    const milestonePrompt = `You are the Easy Mode Planner Agent. Your role is to create a personalized 4-week plan for building confidence.

USER CONTEXT:
- Goal: ${goal}
- Pain point: ${painPoint}
- Daily time available: ${timeAvailable} minutes
- Current week: ${weekNumber} of 4
- Past completion rate: ${behaviorPattern.totalTasksCompleted > 0 ? Math.round((behaviorPattern.successRateByType.action || 0.5) * 100) : 50}%
- Strongest area: ${Object.entries(behaviorPattern.preferredTaskTypes).sort(([,a], [,b]) => b - a)[0]?.[0] || 'action'}
- Tasks completed (30 days): ${behaviorPattern.totalTasksCompleted}

REASONING STEPS:
1. First, analyze what specific outcomes would indicate progress toward the user's goal
2. Break the overall goal into 4 progressive weekly milestones
3. For week ${weekNumber}, create daily micro-tasks that build momentum
4. Consider the user's completion history to set appropriate difficulty

Use the create_milestone tool to define each of the 4 weekly milestones.
After milestones, use create_daily_task to plan each day of week ${weekNumber}.
If completion rate < 60%, use adjust_difficulty to simplify the plan.
If completion rate > 80%, use adjust_difficulty to increase challenge.`;

    const milestones: WeeklyMilestone[] = [];
    const dailyTasks: DailyPlanTask[] = [];
    let difficultyAdjustment: { type: string; reason: string; newLevel: number } | null = null;
    let agentReasoning = '';

    // First call - get milestones
    const response1 = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You are a planning agent that creates personalized weekly plans. Use the provided tools to structure your response.' },
        { role: 'user', content: milestonePrompt }
      ],
      tools: PLANNER_TOOLS,
      tool_choice: 'auto',
      temperature: 0.7,
    });

    // Process tool calls in a loop (agentic loop)
    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
      { role: 'system', content: 'You are a planning agent that creates personalized weekly plans. Use the provided tools to structure your response.' },
      { role: 'user', content: milestonePrompt },
      response1.choices[0].message,
    ];

    let currentResponse = response1;
    let iterationCount = 0;
    const MAX_ITERATIONS = 10;

    // Agentic loop - process tool calls until complete
    while (currentResponse.choices[0].message.tool_calls && iterationCount < MAX_ITERATIONS) {
      const toolCalls = currentResponse.choices[0].message.tool_calls;
      
      for (const toolCall of toolCalls) {
        // Type guard for function tool calls
        if (toolCall.type !== 'function') continue;
        
        // Access function properties (runtime structure matches this)
        const fnCall = toolCall as { id: string; type: string; function: { name: string; arguments: string } };
        const args = JSON.parse(fnCall.function.arguments);
        let toolResult = '';

        switch (fnCall.function.name) {
          case 'create_milestone': {
            const milestone: WeeklyMilestone = {
              weekNumber: args.week_number,
              title: args.milestone_title,
              description: args.milestone_description,
              focusArea: args.focus_area,
              difficultyLevel: args.difficulty_level,
              dailyTasks: [],
            };
            milestones.push(milestone);
            toolResult = `Milestone ${args.week_number} created: "${args.milestone_title}"`;
            console.log(`[Planner Agent] Created milestone: ${args.milestone_title}`);
            break;
          }

          case 'create_daily_task': {
            const task: DailyPlanTask = {
              dayOfWeek: args.day_of_week,
              title: args.task_title,
              type: args.task_type,
              estimatedMinutes: args.estimated_minutes,
              difficulty: args.difficulty,
              whyToday: args.why_today,
            };
            dailyTasks.push(task);
            toolResult = `Daily task created for ${args.day_of_week}: "${args.task_title}"`;
            console.log(`[Planner Agent] Created daily task: ${args.task_title}`);
            break;
          }

          case 'adjust_difficulty':
            difficultyAdjustment = {
              type: args.adjustment_type,
              reason: args.reason,
              newLevel: args.new_difficulty_target,
            };
            toolResult = `Difficulty adjusted: ${args.adjustment_type} to level ${args.new_difficulty_target}. Reason: ${args.reason}`;
            console.log(`[Planner Agent] Adjusted difficulty: ${args.adjustment_type}`);
            break;

          default:
            toolResult = 'Unknown tool';
        }

        messages.push({
          role: 'tool',
          tool_call_id: fnCall.id,
          content: toolResult,
        });
      }

      // Continue the conversation
      const nextResponse = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages,
        tools: PLANNER_TOOLS,
        tool_choice: 'auto',
        temperature: 0.7,
      });

      messages.push(nextResponse.choices[0].message);
      currentResponse = nextResponse;
      iterationCount++;
    }

    // Get final reasoning from the agent
    if (currentResponse.choices[0].message.content) {
      agentReasoning = currentResponse.choices[0].message.content;
    }

    // Assign daily tasks to current milestone
    const currentMilestone = milestones.find(m => m.weekNumber === weekNumber);
    if (currentMilestone) {
      currentMilestone.dailyTasks = dailyTasks;
    }

    // Calculate week dates
    const now = new Date();
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay() + 1); // Monday
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 6); // Sunday

    // Create the weekly plan document
    const planRef = db.collection('users').doc(userId).collection('weeklyPlans').doc();
    const weeklyPlan: Omit<WeeklyPlan, 'id'> = {
      userId,
      weekNumber,
      startDate: startOfWeek.toISOString(),
      endDate: endOfWeek.toISOString(),
      userGoal: goal,
      milestones,
      currentMilestone: weekNumber,
      difficultyLevel: difficultyAdjustment?.newLevel || 3,
      completionRate: 0,
      adjustmentHistory: difficultyAdjustment ? [{
        date: new Date().toISOString(),
        type: difficultyAdjustment.type,
        reason: difficultyAdjustment.reason,
      }] : [],
      agentReasoning,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    };

    await planRef.set({ ...weeklyPlan, id: planRef.id });

    // Log analytics
    await db.collection('analytics').add({
      event: 'weekly_plan_generated',
      userId,
      weekNumber,
      milestonesCount: milestones.length,
      dailyTasksCount: dailyTasks.length,
      difficultyLevel: weeklyPlan.difficultyLevel,
      wasAdjusted: !!difficultyAdjustment,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`[Planner Agent] Successfully generated plan for user ${userId}, week ${weekNumber}`);

    return {
      success: true,
      plan: { ...weeklyPlan, id: planRef.id },
      source: 'generated',
      agentSteps: {
        milestonesCreated: milestones.length,
        dailyTasksPlanned: dailyTasks.length,
        difficultyAdjusted: !!difficultyAdjustment,
        iterations: iterationCount,
      },
      message: `Created ${milestones.length} milestones with ${dailyTasks.length} daily tasks for week ${weekNumber}`,
    };

  } catch (error) {
    console.error('[Planner Agent] Error generating weekly plan:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to generate weekly plan: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
});

/**
 * ADAPTIVE REPLANNING - Runs every Sunday at 8 PM UTC
 * Analyzes user's weekly completion rate and adjusts next week's plan
 * 
 * This is the "agent decides for the user" component:
 * - If < 60% completion: Simplifies next week's tasks
 * - If > 80% completion: Increases difficulty
 * - Stores adjustment reasoning in Firestore
 */
export const weeklyReplanningCheck = functions.pubsub
  .schedule('0 20 * * 0') // Every Sunday at 8 PM UTC
  .timeZone('UTC')
  .onRun(async (_context) => {
    console.log('[Adaptive Replanning] Starting weekly check...');

    try {
      // Get all users with active plans
      const usersSnapshot = await db.collection('users').get();
      let processedCount = 0;
      let adjustedCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        
        // Get this week's plan
        const now = new Date();
        const weekStart = new Date(now);
        weekStart.setDate(now.getDate() - now.getDay() + 1);
        
        const plansSnapshot = await db
          .collection('users')
          .doc(userId)
          .collection('weeklyPlans')
          .where('startDate', '>=', weekStart.toISOString())
          .orderBy('startDate', 'desc')
          .limit(1)
          .get();

        if (plansSnapshot.empty) continue;

        const currentPlan = plansSnapshot.docs[0].data() as WeeklyPlan;
        
        // Calculate actual completion rate for this week
        const tasksThisWeek = await db
          .collection('users')
          .doc(userId)
          .collection('userTasks')
          .where('date', '>=', currentPlan.startDate)
          .where('date', '<=', currentPlan.endDate)
          .get();

        const completedTasks = tasksThisWeek.docs.filter(d => d.data().completed).length;
        const totalPlannedTasks = currentPlan.milestones
          .find(m => m.weekNumber === currentPlan.currentMilestone)
          ?.dailyTasks.length || 7;
        
        const completionRate = totalPlannedTasks > 0 
          ? Math.round((completedTasks / totalPlannedTasks) * 100)
          : 50;

        // Determine adjustment
        let adjustmentType: 'simplify' | 'maintain' | 'increase' = 'maintain';
        let adjustmentReason = '';
        let newDifficulty = currentPlan.difficultyLevel;

        if (completionRate < 60) {
          adjustmentType = 'simplify';
          adjustmentReason = `Completion rate of ${completionRate}% indicates tasks may be too challenging. Reducing difficulty to build momentum.`;
          newDifficulty = Math.max(1, currentPlan.difficultyLevel - 1);
          adjustedCount++;
        } else if (completionRate > 80) {
          adjustmentType = 'increase';
          adjustmentReason = `Excellent completion rate of ${completionRate}%! Increasing challenge to accelerate growth.`;
          newDifficulty = Math.min(5, currentPlan.difficultyLevel + 1);
          adjustedCount++;
        } else {
          adjustmentReason = `Completion rate of ${completionRate}% is on track. Maintaining current difficulty.`;
        }

        // Update plan with completion rate and adjustment
        await plansSnapshot.docs[0].ref.update({
          completionRate,
          adjustmentHistory: admin.firestore.FieldValue.arrayUnion({
            date: new Date().toISOString(),
            type: adjustmentType,
            reason: adjustmentReason,
            previousDifficulty: currentPlan.difficultyLevel,
            newDifficulty,
          }),
          updatedAt: admin.firestore.Timestamp.now(),
        });

        // Store the adjustment for next plan generation
        await db.collection('users').doc(userId).update({
          'nextPlanSettings.difficultyLevel': newDifficulty,
          'nextPlanSettings.lastAdjustment': adjustmentType,
          'nextPlanSettings.adjustmentReason': adjustmentReason,
        });

        // Log analytics
        await db.collection('analytics').add({
          event: 'adaptive_replanning',
          userId,
          weekNumber: currentPlan.weekNumber,
          completionRate,
          adjustmentType,
          previousDifficulty: currentPlan.difficultyLevel,
          newDifficulty,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        processedCount++;
      }

      console.log(`[Adaptive Replanning] Processed ${processedCount} users, adjusted ${adjustedCount} plans`);
      return { processed: processedCount, adjusted: adjustedCount };

    } catch (error) {
      console.error('[Adaptive Replanning] Error:', error);
      throw error;
    }
  });

/**
 * COACH DECIDES - Full context smart recommendation
 * Called when user taps "Let Coach Decide" button
 * Returns detailed reasoning visible to user
 * Includes Opik tracing and LLM-as-judge evaluations
 */
export const coachDecides = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to use Coach Decides.'
    );
  }

  const userId = context.auth.uid;

  // Create Opik trace for this AI operation
  const trace = createTrace({
    name: 'coach_decides',
    userId,
    functionName: 'coachDecides',
    input: { userId, timestamp: new Date().toISOString() },
    tags: ['coach-decides', 'decision-making'],
  });

  try {
    // Gather comprehensive context
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.exists ? userDoc.data()! : {};

    // Get behavior patterns
    const behaviorPattern = await analyzeUserBehavior(userId);

    // Get current weekly plan
    const plansSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('weeklyPlans')
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    const currentPlan = !plansSnapshot.empty ? plansSnapshot.docs[0].data() as WeeklyPlan : null;

    // Get today's context
    const now = new Date();
    const dayOfWeek = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'][now.getDay()];
    const hourOfDay = now.getHours();
    const timeOfDay = hourOfDay < 12 ? 'morning' : hourOfDay < 17 ? 'afternoon' : 'evening';

    // Check what tasks were done today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tasksToday = await db
      .collection('users')
      .doc(userId)
      .collection('userTasks')
      .where('date', '>=', today.toISOString())
      .get();

    const completedToday = tasksToday.docs.filter(d => d.data().completed).length;

    // Get available tasks
    const tasksSnapshot = await db.collection('tasks').get();
    const scoredTasks = scoreTasksForUser(tasksSnapshot.docs, behaviorPattern, hourOfDay);
    const topCandidates = scoredTasks.slice(0, 5);

    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'OpenAI API key not configured.'
      );
    }

    // Use tracked OpenAI client for automatic span creation
    const openai = getTrackedOpenAI(apiKey, {
      userId,
      feature: 'coach_decides',
    });

    const systemPrompt = `You are the Easy Mode AI Coach. The user has asked you to DECIDE what they should do right now.
This is NOT a suggestion - you are MAKING THE DECISION for them based on their complete context.

Your response should be confident and decisive, explaining your reasoning clearly.`;

    const contextPrompt = `Make a decision for this user about what they should do RIGHT NOW.

FULL USER CONTEXT:
- Name: ${userData.name || 'Friend'}
- Level: ${userData.level || 1} (${userData.xpTotal || 0} XP)
- Current streak: ${userData.streak || 0} days
- Goal: ${userData.profile?.goal || 'Build confidence'}
- Pain point: ${userData.profile?.pain || 'Feeling stuck'}
- Daily time budget: ${userData.profile?.dailyTimeMinutes || 10} minutes

BEHAVIOR ANALYSIS (Last 30 days):
- Total tasks completed: ${behaviorPattern.totalTasksCompleted}
- Success rate by type: Action ${Math.round((behaviorPattern.successRateByType.action || 0) * 100)}%, Audacity ${Math.round((behaviorPattern.successRateByType.audacity || 0) * 100)}%, Enjoy ${Math.round((behaviorPattern.successRateByType.enjoy || 0) * 100)}%
- Peak activity hour: ${behaviorPattern.peakActivityHour}:00
- Preferred task types: ${JSON.stringify(behaviorPattern.preferredTaskTypes)}

CURRENT MOMENT:
- Day: ${dayOfWeek}
- Time: ${timeOfDay} (${hourOfDay}:00)
- Tasks completed today: ${completedToday}
- Energy alignment: ${Math.abs(hourOfDay - behaviorPattern.peakActivityHour) <= 2 ? 'HIGH (near peak hours)' : 'NORMAL'}

${currentPlan ? `
CURRENT WEEKLY PLAN:
- Week ${currentPlan.weekNumber} of 4
- Current milestone: "${currentPlan.milestones.find(m => m.weekNumber === currentPlan.currentMilestone)?.title || 'Building momentum'}"
- Difficulty level: ${currentPlan.difficultyLevel}/5
- Completion rate: ${currentPlan.completionRate}%
` : 'No weekly plan yet - recommending based on behavior patterns.'}

TOP TASK CANDIDATES (Pre-scored):
${topCandidates.map((t, i) => `${i + 1}. [Score: ${t.score}] ${t.title} (${t.type}, ${t.estimatedMinutes}min)
   ${t.scoreReasons.join(', ')}`).join('\n')}

DECIDE: What should this user do RIGHT NOW?

Respond in JSON:
{
  "decision": {
    "taskId": "selected_task_id",
    "taskTitle": "The task title",
    "taskType": "action|audacity|enjoy"
  },
  "reasoning": {
    "headline": "A bold, confident 1-line decision statement",
    "whyNow": "Why this specific moment is right for this task (2-3 sentences)",
    "expectedOutcome": "What completing this will do for them today",
    "confidenceLevel": "HIGH|MEDIUM",
    "alternativeConsidered": "What you considered but decided against and why"
  },
  "coachMessage": "A personalized encouraging message (1-2 sentences) that feels like a coach speaking directly to them"
}`;

    // Track prompt experiment version
    trackPromptExperiment(trace, {
      ...PROMPT_VERSIONS.coachDecides.v1,
      systemPrompt,
      userPromptTemplate: contextPrompt,
    });

    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: contextPrompt }
      ],
      temperature: 0.7,
      max_tokens: 500,
      response_format: { type: 'json_object' }
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error('Empty response from AI');
    }

    const coachDecision = JSON.parse(content);
    
    // Find the selected task
    const selectedTask = topCandidates.find(t => t.id === coachDecision.decision.taskId) || topCandidates[0];

    // Run LLM-as-judge evaluations
    const rawOpenai = new OpenAI({ apiKey });
    const evaluationScores = await runEvaluations(rawOpenai, [
      {
        config: EVALUATION_PROMPTS.taskRelevance,
        variables: {
          goal: userData.profile?.goal || 'Build confidence',
          pain: userData.profile?.pain || 'Feeling stuck',
          task: JSON.stringify(selectedTask),
        },
      },
      {
        config: EVALUATION_PROMPTS.decisionConfidence,
        variables: {
          task: JSON.stringify(selectedTask),
          reasoning: JSON.stringify(coachDecision.reasoning),
          context: JSON.stringify({
            streak: userData.streak,
            completedToday,
            timeOfDay,
            behaviorPattern: {
              totalTasksCompleted: behaviorPattern.totalTasksCompleted,
              successRateByType: behaviorPattern.successRateByType,
            },
          }),
        },
      },
      {
        config: EVALUATION_PROMPTS.engagementPotential,
        variables: {
          response: coachDecision.coachMessage,
          context: JSON.stringify({ userData, behaviorPattern }),
        },
      },
    ]);

    // End trace with output and evaluation scores
    await endTrace(trace, {
      selectedTask,
      coachDecision,
      model: 'gpt-4o-mini',
      tokensUsed: response.usage?.total_tokens,
      candidateCount: topCandidates.length,
    }, evaluationScores);

    // Log analytics
    await db.collection('analytics').add({
      event: 'coach_decides',
      userId,
      selectedTaskId: selectedTask.id,
      taskType: selectedTask.type,
      confidenceLevel: coachDecision.reasoning.confidenceLevel,
      evaluationScores: evaluationScores.reduce((acc, s) => ({ ...acc, [s.name]: s.value }), {}),
      dayOfWeek,
      timeOfDay,
      completedToday,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Flush Opik data
    await openai.flush();
    await flushOpik();

    return {
      success: true,
      decision: {
        task: {
          id: selectedTask.id,
          title: selectedTask.title,
          description: selectedTask.description,
          type: selectedTask.type,
          category: selectedTask.category,
          estimatedMinutes: selectedTask.estimatedMinutes,
        },
        reasoning: coachDecision.reasoning,
        coachMessage: coachDecision.coachMessage,
      },
      context: {
        streak: userData.streak || 0,
        completedToday,
        timeOfDay,
        energyAlignment: Math.abs(hourOfDay - behaviorPattern.peakActivityHour) <= 2 ? 'peak' : 'normal',
      },
    };

  } catch (error) {
    console.error('[Coach Decides] Error:', error);

    // End trace with error
    await endTrace(trace, {
      error: error instanceof Error ? error.message : 'Unknown error',
      success: false,
    });
    await flushOpik();
    
    // Fallback response
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      decision: {
        task: null,
        reasoning: {
          headline: 'Let\'s keep building momentum.',
          whyNow: 'Every small action counts.',
          expectedOutcome: 'Progress toward your goals.',
        },
        coachMessage: 'Take any small step forward - that\'s what matters most.',
      },
    };
  }
});

// ============ SMART RECOMMENDATIONS ============

interface UserBehaviorPattern {
  preferredTaskTypes: { [type: string]: number };
  preferredCategories: { [category: string]: number };
  successRateByType: { [type: string]: number };
  avgCompletionTime: number;
  totalTasksCompleted: number;
  recentTaskIds: string[];
  peakActivityHour: number;
}

interface TaskCandidate {
  id: string;
  title: string;
  description: string;
  type: string;
  category?: string;
  estimatedMinutes: number;
  score: number;
  scoreReasons: string[];
}

/**
 * Analyze user behavior patterns from their history
 */
async function analyzeUserBehavior(userId: string): Promise<UserBehaviorPattern> {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  // Get user's completed tasks
  const tasksSnapshot = await db
    .collection('users')
    .doc(userId)
    .collection('userTasks')
    .where('completed', '==', true)
    .where('date', '>=', thirtyDaysAgo.toISOString())
    .get();

  // Get user's script attempts
  const scriptsSnapshot = await db
    .collection('users')
    .doc(userId)
    .collection('userScripts')
    .where('attemptDate', '>=', thirtyDaysAgo.toISOString())
    .get();

  const pattern: UserBehaviorPattern = {
    preferredTaskTypes: { action: 0, audacity: 0, enjoy: 0 },
    preferredCategories: {},
    successRateByType: { action: 0, audacity: 0, enjoy: 0 },
    avgCompletionTime: 0,
    totalTasksCompleted: 0,
    recentTaskIds: [],
    peakActivityHour: 9, // default
  };

  const typeAttempts: { [type: string]: number } = { action: 0, audacity: 0, enjoy: 0 };
  const typeSuccesses: { [type: string]: number } = { action: 0, audacity: 0, enjoy: 0 };
  const hourCounts: { [hour: number]: number } = {};
  let totalTime = 0;

  // Analyze tasks
  tasksSnapshot.forEach((doc) => {
    const task = doc.data();
    const taskType = task.type || 'action';
    
    pattern.preferredTaskTypes[taskType] = (pattern.preferredTaskTypes[taskType] || 0) + 1;
    typeAttempts[taskType] = (typeAttempts[taskType] || 0) + 1;
    typeSuccesses[taskType] = (typeSuccesses[taskType] || 0) + 1;
    
    if (task.category) {
      pattern.preferredCategories[task.category] = (pattern.preferredCategories[task.category] || 0) + 1;
    }
    
    if (task.duration) {
      totalTime += task.duration;
    }
    
    if (task.completedAt) {
      const hour = new Date(task.completedAt).getHours();
      hourCounts[hour] = (hourCounts[hour] || 0) + 1;
    }
    
    pattern.recentTaskIds.push(task.taskId);
    pattern.totalTasksCompleted++;
  });

  // Analyze scripts (audacity attempts)
  scriptsSnapshot.forEach((doc) => {
    const script = doc.data();
    typeAttempts.audacity++;
    
    if (script.outcome === 'success' || script.outcome === 'partial') {
      typeSuccesses.audacity++;
    }
    
    if (script.attemptDate) {
      const hour = new Date(script.attemptDate).getHours();
      hourCounts[hour] = (hourCounts[hour] || 0) + 1;
    }
  });

  // Calculate success rates
  for (const type of Object.keys(typeAttempts)) {
    if (typeAttempts[type] > 0) {
      pattern.successRateByType[type] = typeSuccesses[type] / typeAttempts[type];
    }
  }

  // Find peak activity hour
  let maxHour = 9;
  let maxCount = 0;
  for (const [hour, count] of Object.entries(hourCounts)) {
    if (count > maxCount) {
      maxCount = count;
      maxHour = parseInt(hour);
    }
  }
  pattern.peakActivityHour = maxHour;

  // Average completion time
  if (pattern.totalTasksCompleted > 0) {
    pattern.avgCompletionTime = totalTime / pattern.totalTasksCompleted;
  }

  return pattern;
}

/**
 * Score candidate tasks based on user behavior patterns
 */
function scoreTasksForUser(
  tasks: admin.firestore.QueryDocumentSnapshot[],
  pattern: UserBehaviorPattern,
  currentHour: number
): TaskCandidate[] {
  return tasks.map((doc) => {
    const task = doc.data();
    const candidate: TaskCandidate = {
      id: doc.id,
      title: task.title,
      description: task.description,
      type: task.type || 'action',
      category: task.category,
      estimatedMinutes: task.estimatedMinutes || 5,
      score: 50, // base score
      scoreReasons: [],
    };

    // Don't recommend recently completed tasks
    if (pattern.recentTaskIds.includes(doc.id)) {
      candidate.score -= 30;
      candidate.scoreReasons.push('Recently completed');
    }

    // Boost preferred task types
    const typePreference = pattern.preferredTaskTypes[candidate.type] || 0;
    if (typePreference > 3) {
      candidate.score += 15;
      candidate.scoreReasons.push(`User prefers ${candidate.type} tasks`);
    }

    // Boost high success rate types
    const successRate = pattern.successRateByType[candidate.type] || 0;
    if (successRate > 0.7) {
      candidate.score += 10;
      candidate.scoreReasons.push(`High success rate with ${candidate.type}`);
    } else if (successRate < 0.3 && pattern.totalTasksCompleted > 5) {
      // If struggling with a type, occasionally suggest it but with lower priority
      candidate.score -= 5;
      candidate.scoreReasons.push(`Building skills in ${candidate.type}`);
    }

    // Boost preferred categories
    if (candidate.category && pattern.preferredCategories[candidate.category] > 2) {
      candidate.score += 10;
      candidate.scoreReasons.push(`Enjoys ${candidate.category} category`);
    }

    // Time-appropriate tasks
    const hourDiff = Math.abs(currentHour - pattern.peakActivityHour);
    if (hourDiff <= 2) {
      candidate.score += 5;
      candidate.scoreReasons.push('Peak activity time');
    }

    // Duration matching
    if (pattern.avgCompletionTime > 0) {
      const durationDiff = Math.abs(candidate.estimatedMinutes * 60 - pattern.avgCompletionTime);
      if (durationDiff < 120) { // within 2 minutes
        candidate.score += 5;
        candidate.scoreReasons.push('Matches typical task duration');
      }
    }

    // Variety boost - suggest underused types occasionally
    const totalByType = Object.values(pattern.preferredTaskTypes).reduce((a, b) => a + b, 0);
    if (totalByType > 10) {
      const typeRatio = (pattern.preferredTaskTypes[candidate.type] || 0) / totalByType;
      if (typeRatio < 0.2) {
        candidate.score += 8;
        candidate.scoreReasons.push(`Encourages variety with ${candidate.type}`);
      }
    }

    return candidate;
  }).sort((a, b) => b.score - a.score);
}

/**
 * AI-powered smart task recommendation
 * Combines rule-based scoring with AI selection
 * Includes Opik tracing and LLM-as-judge evaluations
 */
export const getSmartRecommendation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to use this feature.'
    );
  }

  const userId = context.auth.uid;
  const { preferredType } = data; // optional type filter

  // Create Opik trace for this AI operation
  const trace = createTrace({
    name: 'smart_recommendation',
    userId,
    functionName: 'getSmartRecommendation',
    input: { preferredType },
    tags: ['smart-recommendation', preferredType || 'all'],
  });

  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'OpenAI API key not configured.'
      );
    }

    // Get user data
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.exists ? userDoc.data()! : {};

    // Analyze user behavior
    const behaviorPattern = await analyzeUserBehavior(userId);

    // Get all available tasks
    let tasksQuery = db.collection('tasks') as admin.firestore.Query;
    if (preferredType) {
      tasksQuery = tasksQuery.where('type', '==', preferredType);
    }
    const tasksSnapshot = await tasksQuery.get();

    if (tasksSnapshot.empty) {
      await endTrace(trace, { error: 'No tasks available', success: false });
      await flushOpik();
      return {
        success: false,
        error: 'No tasks available',
        recommendation: null,
      };
    }

    // Score tasks based on behavior patterns
    const currentHour = new Date().getHours();
    const scoredTasks = scoreTasksForUser(tasksSnapshot.docs, behaviorPattern, currentHour);

    // Take top 5 candidates for AI selection
    const topCandidates = scoredTasks.slice(0, 5);

    // Use tracked OpenAI client
    const openai = getTrackedOpenAI(apiKey, {
      userId,
      feature: 'smart_recommendation',
      candidateCount: topCandidates.length,
    });

    const systemPrompt = `You are Easy Mode, an AI life coach. Your job is to select the most impactful task for the user RIGHT NOW based on their profile and behavioral patterns.

Consider:
- Their current streak and momentum
- What types of tasks they've been successful with
- Areas where they could grow
- The time of day and their typical patterns
- Balance between comfort zone and growth`;

    const userPrompt = `Select the best task for this user:

USER PROFILE:
- Name: ${userData.name || 'User'}
- Level: ${userData.level || 1}
- Streak: ${userData.streak || 0} days
- Goal: ${userData.profile?.goal || 'Build confidence'}
- Challenge: ${userData.profile?.pain || 'Getting started'}

BEHAVIOR PATTERNS:
- Total tasks completed (30 days): ${behaviorPattern.totalTasksCompleted}
- Preferred types: ${JSON.stringify(behaviorPattern.preferredTaskTypes)}
- Success rates: ${JSON.stringify(behaviorPattern.successRateByType)}
- Peak activity hour: ${behaviorPattern.peakActivityHour}:00

CANDIDATE TASKS (pre-scored by rules):
${topCandidates.map((t, i) => `
${i + 1}. [Score: ${t.score}] ${t.title}
   Type: ${t.type} | Duration: ${t.estimatedMinutes}min
   Description: ${t.description}
   Scoring reasons: ${t.scoreReasons.join(', ')}
`).join('')}

Current time: ${new Date().toLocaleTimeString()}

Select ONE task and explain why it's the best choice right now.

Respond in JSON:
{
  "selectedTaskId": "task_id_here",
  "whyThisTask": "Brief explanation of why this task is perfect for them right now (1-2 sentences)",
  "expectedImpact": "What completing this will do for them (1 sentence)",
  "personalizedTip": "A specific tip for this user on this task (1 sentence)"
}`;

    // Track prompt experiment version
    trackPromptExperiment(trace, {
      ...PROMPT_VERSIONS.smartRecommendation.v1,
      systemPrompt,
      userPromptTemplate: userPrompt,
    });

    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      temperature: 0.7,
      max_tokens: 300,
      response_format: { type: 'json_object' }
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error('Empty response from AI');
    }

    const aiSelection = JSON.parse(content);
    
    // Find the selected task
    const selectedTask = topCandidates.find(t => t.id === aiSelection.selectedTaskId) || topCandidates[0];

    // Run LLM-as-judge evaluations
    const rawOpenai = new OpenAI({ apiKey });
    const evaluationScores = await runEvaluations(rawOpenai, [
      {
        config: EVALUATION_PROMPTS.taskRelevance,
        variables: {
          goal: userData.profile?.goal || 'Build confidence',
          pain: userData.profile?.pain || 'Getting started',
          task: JSON.stringify({ title: selectedTask.title, description: selectedTask.description, reasoning: aiSelection }),
        },
      },
      {
        config: EVALUATION_PROMPTS.specificityScore,
        variables: { response: JSON.stringify(aiSelection) },
      },
      {
        config: EVALUATION_PROMPTS.engagementPotential,
        variables: {
          response: JSON.stringify(aiSelection),
          context: JSON.stringify({ userData, behaviorPattern }),
        },
      },
    ]);

    // End trace with output and scores
    await endTrace(trace, {
      selectedTask,
      aiSelection,
      model: 'gpt-4o-mini',
      tokensUsed: response.usage?.total_tokens,
      candidateCount: topCandidates.length,
    }, evaluationScores);

    // Log recommendation for analytics with evaluation scores
    await db.collection('analytics').add({
      event: 'smart_recommendation',
      userId: userId,
      selectedTaskId: selectedTask.id,
      candidateCount: topCandidates.length,
      evaluationScores: evaluationScores.reduce((acc, s) => ({ ...acc, [s.name]: s.value }), {}),
      behaviorPatternSummary: {
        totalTasks: behaviorPattern.totalTasksCompleted,
        preferredType: Object.entries(behaviorPattern.preferredTaskTypes)
          .sort(([,a], [,b]) => b - a)[0]?.[0] || 'action',
      },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Flush Opik data
    await openai.flush();
    await flushOpik();

    return {
      success: true,
      recommendation: {
        task: {
          id: selectedTask.id,
          title: selectedTask.title,
          description: selectedTask.description,
          type: selectedTask.type,
          category: selectedTask.category,
          estimatedMinutes: selectedTask.estimatedMinutes,
        },
        reasoning: {
          whyThisTask: aiSelection.whyThisTask,
          expectedImpact: aiSelection.expectedImpact,
          personalizedTip: aiSelection.personalizedTip,
        },
        behaviorInsights: {
          totalTasksCompleted: behaviorPattern.totalTasksCompleted,
          strongestType: Object.entries(behaviorPattern.preferredTaskTypes)
            .sort(([,a], [,b]) => b - a)[0]?.[0] || 'action',
          peakHour: behaviorPattern.peakActivityHour,
        },
      },
    };
  } catch (error) {
    console.error('Error getting smart recommendation:', error);

    // End trace with error
    await endTrace(trace, {
      error: error instanceof Error ? error.message : 'Unknown error',
      success: false,
    });
    await flushOpik();

    // Fallback to random task
    const tasksSnapshot = await db.collection('tasks').limit(5).get();
    const randomDoc = tasksSnapshot.docs[Math.floor(Math.random() * tasksSnapshot.docs.length)];
    const fallbackTask = randomDoc?.data();

    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      recommendation: fallbackTask ? {
        task: {
          id: randomDoc.id,
          title: fallbackTask.title,
          description: fallbackTask.description,
          type: fallbackTask.type,
          estimatedMinutes: fallbackTask.estimatedMinutes,
        },
        reasoning: {
          whyThisTask: 'A great way to build momentum today.',
          expectedImpact: 'Every small action moves you forward.',
          personalizedTip: 'Focus on starting, not perfecting.',
        },
      } : null,
    };
  }
});

// ============ EXPERIMENT COMPARISON ============

interface ExperimentMetrics {
  promptVersion: string;
  eventType: string;
  avgScores: { [metric: string]: number };
  sampleCount: number;
  scoreDistribution: { [metric: string]: { min: number; max: number; stdDev: number } };
}

interface ExperimentReport {
  generatedAt: string;
  dateRange: { start: string; end: string };
  experiments: ExperimentMetrics[];
  recommendations: string[];
  bestPerformers: { [eventType: string]: string };
}

/**
 * Generate Experiment Comparison Report
 * Analyzes evaluation scores by prompt version to enable systematic improvement
 * This demonstrates data-driven prompt iteration using Opik metrics
 */
export const generateExperimentReport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to generate experiment reports.'
    );
  }

  const { daysBack = 7, eventTypes } = data;

  try {
    // Calculate date range
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - daysBack);

    // Query analytics events with evaluation scores
    const analyticsEvents = [
      'smart_recommendation',
      'daily_insight_generated',
      'coach_decides',
    ];
    const targetEvents = eventTypes || analyticsEvents;

    const experimentData: Map<string, ExperimentMetrics> = new Map();

    for (const eventType of targetEvents) {
      const analyticsSnapshot = await db
        .collection('analytics')
        .where('event', '==', eventType)
        .where('timestamp', '>=', startDate)
        .where('timestamp', '<=', endDate)
        .get();

      if (analyticsSnapshot.empty) continue;

      // Group by prompt version (extracted from metadata or default to v1)
      const versionScores: Map<string, Array<{ [metric: string]: number }>> = new Map();

      analyticsSnapshot.forEach((doc) => {
        const data = doc.data();
        const scores = data.evaluationScores;
        
        if (!scores || typeof scores !== 'object') return;

        // Use prompt version from data or default
        const version = data.promptVersion || 'v1';
        const key = `${eventType}:${version}`;

        if (!versionScores.has(key)) {
          versionScores.set(key, []);
        }
        versionScores.get(key)!.push(scores);
      });

      // Calculate metrics for each version
      for (const [key, scores] of versionScores) {
        const [event, version] = key.split(':');
        const metrics: ExperimentMetrics = {
          promptVersion: version,
          eventType: event,
          avgScores: {},
          sampleCount: scores.length,
          scoreDistribution: {},
        };

        // Get all unique score metrics
        const allMetrics = new Set<string>();
        scores.forEach((s) => Object.keys(s).forEach((m) => allMetrics.add(m)));

        // Calculate average and distribution for each metric
        for (const metric of allMetrics) {
          const values = scores
            .map((s) => s[metric])
            .filter((v) => typeof v === 'number' && !isNaN(v));

          if (values.length === 0) continue;

          const sum = values.reduce((a, b) => a + b, 0);
          const avg = sum / values.length;
          const min = Math.min(...values);
          const max = Math.max(...values);
          
          // Calculate standard deviation
          const squaredDiffs = values.map((v) => Math.pow(v - avg, 2));
          const avgSquaredDiff = squaredDiffs.reduce((a, b) => a + b, 0) / values.length;
          const stdDev = Math.sqrt(avgSquaredDiff);

          metrics.avgScores[metric] = Math.round(avg * 100) / 100;
          metrics.scoreDistribution[metric] = {
            min,
            max,
            stdDev: Math.round(stdDev * 100) / 100,
          };
        }

        experimentData.set(key, metrics);
      }
    }

    // Generate recommendations based on metrics
    const recommendations: string[] = [];
    const bestPerformers: { [eventType: string]: string } = {};

    // Group by event type to find best performers
    const byEventType: Map<string, ExperimentMetrics[]> = new Map();
    for (const metrics of experimentData.values()) {
      if (!byEventType.has(metrics.eventType)) {
        byEventType.set(metrics.eventType, []);
      }
      byEventType.get(metrics.eventType)!.push(metrics);
    }

    for (const [eventType, versions] of byEventType) {
      if (versions.length === 0) continue;

      // Calculate composite score (average of all metrics)
      const versionComposites = versions.map((v) => {
        const avgValues = Object.values(v.avgScores);
        const composite = avgValues.length > 0
          ? avgValues.reduce((a, b) => a + b, 0) / avgValues.length
          : 0;
        return { version: v.promptVersion, composite, metrics: v };
      });

      // Sort by composite score
      versionComposites.sort((a, b) => b.composite - a.composite);
      
      if (versionComposites.length > 0) {
        bestPerformers[eventType] = versionComposites[0].version;
        
        // Generate specific recommendations
        const best = versionComposites[0];
        if (best.composite < 3.5) {
          recommendations.push(
            `${eventType}: Consider revising prompts - average score ${best.composite.toFixed(2)}/5 indicates room for improvement`
          );
        }

        // Check for high variance metrics
        for (const [metric, dist] of Object.entries(best.metrics.scoreDistribution)) {
          if (dist.stdDev > 1.0) {
            recommendations.push(
              `${eventType}: High variance in ${metric} (stdDev: ${dist.stdDev}) - consider making prompt more consistent`
            );
          }
        }

        // Compare versions if multiple exist
        if (versionComposites.length > 1) {
          const diff = versionComposites[0].composite - versionComposites[1].composite;
          if (diff > 0.5) {
            recommendations.push(
              `${eventType}: Version ${versionComposites[0].version} significantly outperforms ${versionComposites[1].version} (+${diff.toFixed(2)} avg score)`
            );
          }
        }
      }
    }

    // Add general recommendations if no specific ones
    if (recommendations.length === 0) {
      recommendations.push('All prompt versions performing within acceptable ranges');
      recommendations.push('Consider A/B testing new prompt variations to find improvements');
    }

    const report: ExperimentReport = {
      generatedAt: new Date().toISOString(),
      dateRange: {
        start: startDate.toISOString(),
        end: endDate.toISOString(),
      },
      experiments: Array.from(experimentData.values()),
      recommendations,
      bestPerformers,
    };

    // Store report for historical tracking
    await db.collection('experimentReports').add({
      ...report,
      generatedBy: context.auth.uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Log analytics event
    await db.collection('analytics').add({
      event: 'experiment_report_generated',
      userId: context.auth.uid,
      daysBack,
      experimentCount: experimentData.size,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      report,
      summary: {
        totalExperiments: experimentData.size,
        dateRange: `${daysBack} days`,
        recommendationCount: recommendations.length,
      },
    };

  } catch (error) {
    console.error('[Experiment Report] Error:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Failed to generate experiment report: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
});

// ============ CONVERSATIONAL AI CHAT COACH ============

interface ChatMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp?: string;
}

interface SelfReflectionResult {
  originalResponse: string;
  critique: string;
  improvedResponse: string;
  improvementsMade: string[];
  confidenceScore: number;
}

/**
 * Self-reflection loop - Agent critiques and improves its own response
 * Implements Chain-of-Thought reasoning with self-evaluation
 */
async function selfReflect(
  openai: OpenAI,
  originalPrompt: string,
  originalResponse: string,
  userContext: Record<string, unknown>
): Promise<SelfReflectionResult> {
  const critiquePrompt = `You are an AI quality evaluator for a life coaching app called Easy Mode.

ORIGINAL USER MESSAGE:
${originalPrompt}

AI COACH'S RESPONSE:
${originalResponse}

USER CONTEXT:
${JSON.stringify(userContext, null, 2)}

Critically evaluate this response:
1. Is it specific enough to be actionable?
2. Does it acknowledge the user's current state/feelings?
3. Is the tone warm but not patronizing?
4. Does it align with Easy Mode's principles (Action, Audacity, Enjoyment)?
5. Could anything be misinterpreted negatively?

Respond in JSON:
{
  "issues": ["List of specific issues found, or empty array if none"],
  "score": 1-5,
  "shouldImprove": true/false
}`;

  const critiqueResponse = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: 'You are a critical evaluator. Be honest and specific.' },
      { role: 'user', content: critiquePrompt }
    ],
    temperature: 0.3,
    max_tokens: 300,
    response_format: { type: 'json_object' }
  });

  const critique = JSON.parse(critiqueResponse.choices[0]?.message?.content || '{}');

  // If response is good enough, return original
  if (!critique.shouldImprove || critique.score >= 4) {
    return {
      originalResponse,
      critique: 'Response meets quality standards',
      improvedResponse: originalResponse,
      improvementsMade: [],
      confidenceScore: critique.score || 4,
    };
  }

  // Generate improved response
  const improvePrompt = `You are Easy Mode, an AI life coach. Your previous response had these issues:
${critique.issues.join('\n- ')}

ORIGINAL USER MESSAGE:
${originalPrompt}

YOUR PREVIOUS RESPONSE:
${originalResponse}

USER CONTEXT:
${JSON.stringify(userContext, null, 2)}

Write an IMPROVED response that:
- Fixes all identified issues
- Maintains warmth and encouragement
- Is specific and actionable
- Stays concise (2-4 sentences max)

Respond with ONLY the improved message, no explanations.`;

  const improvedResponse = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: 'You are Easy Mode, a warm and direct AI life coach.' },
      { role: 'user', content: improvePrompt }
    ],
    temperature: 0.7,
    max_tokens: 200,
  });

  return {
    originalResponse,
    critique: critique.issues.join('; '),
    improvedResponse: improvedResponse.choices[0]?.message?.content || originalResponse,
    improvementsMade: critique.issues,
    confidenceScore: Math.min(critique.score + 1, 5),
  };
}

/**
 * AI CHAT COACH - Conversational interface with memory (RAG)
 * 
 * Features:
 * - Retrieves relevant past conversations for context
 * - Self-reflection loop for quality improvement
 * - Stores important interactions as memories
 * - Multi-turn conversation support
 */
export const chatWithCoach = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to chat with coach.'
    );
  }

  const userId = context.auth.uid;
  const { message, conversationHistory = [], enableSelfReflection = true } = data;

  if (!message || typeof message !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Message is required.'
    );
  }

  // Create Opik trace
  const trace = createTrace({
    name: 'chat_with_coach',
    userId,
    functionName: 'chatWithCoach',
    input: { message, historyLength: conversationHistory.length },
    tags: ['chat', 'conversational'],
  });

  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'OpenAI API key not configured.'
      );
    }

    // Get user data
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.exists ? userDoc.data()! : {};

    // RETRIEVAL: Get relevant memories for context (RAG)
    const relevantMemories = await retrieveRelevantMemories(userId, message, 5);
    const memoryContext = relevantMemories.length > 0
      ? `\n\nRELEVANT PAST CONTEXT:\n${relevantMemories.map((m) => `- [${m.type}] ${m.content}`).join('\n')}`
      : '';

    // Build conversation context
    const recentHistory = conversationHistory.slice(-6) as ChatMessage[]; // Last 3 exchanges

    const openai = getTrackedOpenAI(apiKey, {
      userId,
      feature: 'chat_coach',
    });

    const systemPrompt = `You are Easy Mode, an AI life coach focused on building confidence through Action, Audacity, and Enjoyment.

ABOUT THE USER:
- Name: ${userData.name || 'Friend'}
- Level: ${userData.level || 1}
- Current streak: ${userData.streak || 0} days
- Goal: ${userData.profile?.goal || 'Build confidence'}
- Challenge: ${userData.profile?.pain || 'Getting started'}
${memoryContext}

YOUR PERSONALITY:
- Warm and encouraging, like a supportive friend
- Direct and practical - no fluff
- You celebrate small wins genuinely
- You gently challenge comfort zones when appropriate
- You remember past conversations (shown in RELEVANT PAST CONTEXT)

GUIDELINES:
- Keep responses concise (2-4 sentences unless asked for more)
- Be specific and actionable when giving advice
- Reference past context when relevant to show you remember them
- If they share something significant, acknowledge it
- End with a question or gentle nudge when appropriate`;

    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
      { role: 'system', content: systemPrompt },
      ...recentHistory.map((m) => ({
        role: m.role as 'user' | 'assistant',
        content: m.content,
      })),
      { role: 'user', content: message },
    ];

    // Generate initial response
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages,
      temperature: 0.8,
      max_tokens: 300,
    });

    let assistantMessage = response.choices[0]?.message?.content || '';
    let selfReflectionResult: SelfReflectionResult | null = null;

    // SELF-REFLECTION: Evaluate and improve response if needed
    if (enableSelfReflection && assistantMessage) {
      const rawOpenai = new OpenAI({ apiKey });
      selfReflectionResult = await selfReflect(
        rawOpenai,
        message,
        assistantMessage,
        {
          name: userData.name,
          level: userData.level,
          streak: userData.streak,
          goal: userData.profile?.goal,
          pain: userData.profile?.pain,
        }
      );
      assistantMessage = selfReflectionResult.improvedResponse;
    }

    // MEMORY: Store significant interactions
    const shouldStore = await shouldStoreAsMemory(message, assistantMessage);
    if (shouldStore.store) {
      await storeMemory(
        userId,
        shouldStore.type as MemoryEntry['type'],
        `User: "${message.substring(0, 200)}..." Coach response about: ${shouldStore.summary}`,
        { originalMessage: message },
        shouldStore.importance
      );
    }

    // Run evaluations
    const rawOpenai = new OpenAI({ apiKey });
    const evaluationScores = await runEvaluations(rawOpenai, [
      {
        config: EVALUATION_PROMPTS.engagementPotential,
        variables: {
          response: assistantMessage,
          context: JSON.stringify({ message, userData }),
        },
      },
      {
        config: EVALUATION_PROMPTS.specificityScore,
        variables: { response: assistantMessage },
      },
      {
        config: EVALUATION_PROMPTS.safetyScore,
        variables: { response: assistantMessage },
      },
    ]);

    // End trace
    await endTrace(trace, {
      response: assistantMessage,
      selfReflection: selfReflectionResult ? {
        wasImproved: (selfReflectionResult.improvementsMade?.length ?? 0) > 0,
        improvements: selfReflectionResult.improvementsMade,
      } : null,
      memoriesRetrieved: relevantMemories.length,
      memoryStored: shouldStore.store,
    }, evaluationScores);

    // Log analytics
    await db.collection('analytics').add({
      event: 'chat_with_coach',
      userId,
      messageLength: message.length,
      responseLength: assistantMessage.length,
      memoriesRetrieved: relevantMemories.length,
      selfReflectionUsed: enableSelfReflection,
      wasImproved: (selfReflectionResult?.improvementsMade?.length ?? 0) > 0,
      evaluationScores: evaluationScores.reduce((acc, s) => ({ ...acc, [s.name]: s.value }), {}),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Flush Opik data
    await openai.flush();
    await flushOpik();

    return {
      success: true,
      message: assistantMessage,
      metadata: {
        memoriesUsed: relevantMemories.length,
        selfReflection: selfReflectionResult ? {
          wasImproved: (selfReflectionResult.improvementsMade?.length ?? 0) > 0,
          confidenceScore: selfReflectionResult.confidenceScore,
        } : null,
      },
    };

  } catch (error) {
    console.error('[Chat Coach] Error:', error);

    await endTrace(trace, {
      error: error instanceof Error ? error.message : 'Unknown error',
      success: false,
    });
    await flushOpik();

    return {
      success: false,
      message: "I'm having trouble right now. Take a breath, and remember: small steps forward are still progress.",
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
});

/**
 * Determine if a conversation should be stored as a memory
 */
async function shouldStoreAsMemory(
  userMessage: string,
  _assistantResponse: string
): Promise<{ store: boolean; type: string; summary: string; importance: number }> {
  // Keywords that indicate memorable content
  const achievementKeywords = ['did it', 'completed', 'finished', 'achieved', 'won', 'succeeded', 'proud'];
  const setbackKeywords = ['failed', 'couldn\'t', 'struggled', 'hard time', 'difficult', 'anxious', 'scared'];
  const insightKeywords = ['realized', 'learned', 'understand now', 'figured out', 'noticed'];
  const preferenceKeywords = ['i like', 'i prefer', 'i hate', 'i love', 'works for me', 'doesn\'t work'];

  const lowerMessage = userMessage.toLowerCase();

  if (achievementKeywords.some((k) => lowerMessage.includes(k))) {
    return { store: true, type: 'achievement', summary: 'User shared an accomplishment', importance: 4 };
  }
  if (setbackKeywords.some((k) => lowerMessage.includes(k))) {
    return { store: true, type: 'setback', summary: 'User shared a challenge', importance: 4 };
  }
  if (insightKeywords.some((k) => lowerMessage.includes(k))) {
    return { store: true, type: 'insight', summary: 'User had a realization', importance: 3 };
  }
  if (preferenceKeywords.some((k) => lowerMessage.includes(k))) {
    return { store: true, type: 'preference', summary: 'User expressed a preference', importance: 3 };
  }

  // Store longer messages more often (likely meaningful)
  if (userMessage.length > 150) {
    return { store: true, type: 'conversation', summary: 'Detailed conversation', importance: 2 };
  }

  return { store: false, type: '', summary: '', importance: 0 };
}

// ============ PROACTIVE AI NOTIFICATIONS ============

/**
 * Generate AI-powered personalized push notification content
 * Called by scheduled function or triggered by user inactivity
 */
export const generateProactiveNudge = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated.'
    );
  }

  const userId = context.auth.uid;
  const { nudgeType = 'daily' } = data; // daily, streak_at_risk, comeback, celebration

  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'OpenAI API key not configured.'
      );
    }

    // Get user data
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.exists ? userDoc.data()! : {};

    // Get recent activity
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const recentTasks = await db
      .collection('users')
      .doc(userId)
      .collection('userTasks')
      .where('date', '>=', sevenDaysAgo.toISOString())
      .get();

    const completedCount = recentTasks.docs.filter((d) => d.data().completed).length;
    
    // Calculate days since last activity
    const lastActivity = userData.lastActivity?.toDate() || new Date(0);
    const daysSinceActivity = Math.floor((Date.now() - lastActivity.getTime()) / 86400000);

    const openai = new OpenAI({ apiKey });

    const contextPrompt = `Generate a personalized push notification for this user:

USER:
- Name: ${userData.name || 'Friend'}
- Level: ${userData.level || 1}
- Current streak: ${userData.streak || 0} days
- Tasks completed this week: ${completedCount}
- Days since last activity: ${daysSinceActivity}
- Goal: ${userData.profile?.goal || 'Build confidence'}

NUDGE TYPE: ${nudgeType}
- daily: Morning motivation to start the day
- streak_at_risk: User hasn't logged in today, streak might break
- comeback: User hasn't been active for 2+ days
- celebration: User hit a milestone or achievement

TIME: ${new Date().toLocaleTimeString()} on ${new Date().toLocaleDateString('en-US', { weekday: 'long' })}

Generate a notification that:
- Is personal and uses their name if available
- Is brief (title: 5-8 words, body: 1-2 short sentences)
- Creates gentle urgency without guilt-tripping
- Feels like a supportive friend, not a nagging app
- Aligns with Easy Mode's warm, encouraging tone

Respond in JSON:
{
  "title": "Notification title",
  "body": "Notification body text",
  "actionText": "Button text like 'Start' or 'Let's go'"
}`;

    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You are generating push notifications for a life coaching app. Be warm, brief, and motivating.' },
        { role: 'user', content: contextPrompt }
      ],
      temperature: 0.8,
      max_tokens: 150,
      response_format: { type: 'json_object' }
    });

    const notification = JSON.parse(response.choices[0]?.message?.content || '{}');

    // Log analytics
    await db.collection('analytics').add({
      event: 'proactive_nudge_generated',
      userId,
      nudgeType,
      daysSinceActivity,
      streak: userData.streak || 0,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      notification: {
        title: notification.title || 'Easy Mode Moment',
        body: notification.body || 'A small step forward is waiting for you.',
        actionText: notification.actionText || 'Start',
      },
      context: {
        nudgeType,
        daysSinceActivity,
        streak: userData.streak || 0,
      },
    };

  } catch (error) {
    console.error('[Proactive Nudge] Error:', error);
    
    // Return fallback notification
    return {
      success: false,
      notification: {
        title: 'Your Easy Mode moment',
        body: 'A small step forward is all it takes.',
        actionText: 'Start',
      },
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
});

/**
 * Scheduled function to send AI-personalized notifications
 * Runs multiple times per day to catch different timezones and contexts
 */
export const sendAINotifications = functions.pubsub
  .schedule('0 9,14,19 * * *') // 9 AM, 2 PM, 7 PM UTC
  .timeZone('UTC')
  .onRun(async (_context) => {
    console.log('[AI Notifications] Starting scheduled run...');

    try {
      const apiKey = process.env.OPENAI_API_KEY;
      if (!apiKey) {
        console.error('[AI Notifications] OpenAI API key not configured');
        return null;
      }

      // Get users who have notifications enabled
      const usersSnapshot = await db.collection('users')
        .where('notificationsEnabled', '==', true)
        .get();

      const openai = new OpenAI({ apiKey });
      const messaging = admin.messaging();
      let sentCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        if (!userData.fcmToken) continue;

        // Determine nudge type based on user state
        const lastActivity = userData.lastActivity?.toDate() || new Date(0);
        const daysSinceActivity = Math.floor((Date.now() - lastActivity.getTime()) / 86400000);
        const streak = userData.streak || 0;

        let nudgeType = 'daily';
        if (daysSinceActivity >= 2) {
          nudgeType = 'comeback';
        } else if (daysSinceActivity === 1 && streak > 0) {
          nudgeType = 'streak_at_risk';
        }

        // Generate personalized notification
        try {
          const prompt = `Generate a brief, warm push notification:
User: ${userData.name || 'Friend'}, Level ${userData.level || 1}, ${streak} day streak
Last active: ${daysSinceActivity} days ago
Nudge type: ${nudgeType}

JSON format: {"title": "...", "body": "..."}`;

          const response = await openai.chat.completions.create({
            model: 'gpt-4o-mini',
            messages: [
              { role: 'system', content: 'Generate brief, warm push notifications. Title: 5-8 words. Body: 1 short sentence.' },
              { role: 'user', content: prompt }
            ],
            temperature: 0.8,
            max_tokens: 80,
            response_format: { type: 'json_object' }
          });

          const notification = JSON.parse(response.choices[0]?.message?.content || '{}');

          await messaging.send({
            notification: {
              title: notification.title || 'Easy Mode',
              body: notification.body || 'Your daily moment awaits.',
            },
            token: userData.fcmToken,
          });

          sentCount++;
        } catch (err) {
          console.error(`[AI Notifications] Failed for user ${userDoc.id}:`, err);
        }
      }

      console.log(`[AI Notifications] Sent ${sentCount} personalized notifications`);
      return { sentCount };

    } catch (error) {
      console.error('[AI Notifications] Error:', error);
      throw error;
    }
  });

// ============ RESILIENCE AGENT ============

/**
 * Resilience Agent - Detects when user is struggling and provides support
 * Triggered when user reports a setback or shows signs of disengagement
 */
export const triggerResilienceSupport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated.'
    );
  }

  const userId = context.auth.uid;
  const { triggerType, setbackDetails } = data;
  // triggerType: 'task_failed', 'streak_broken', 'user_reported', 'inactivity'

  const trace = createTrace({
    name: 'resilience_support',
    userId,
    functionName: 'triggerResilienceSupport',
    input: { triggerType, setbackDetails },
    tags: ['resilience', 'support', triggerType],
  });

  try {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'OpenAI API key not configured.'
      );
    }

    // Get user data and history
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.exists ? userDoc.data()! : {};

    // Get recent memories for context
    const relevantMemories = await retrieveRelevantMemories(
      userId,
      setbackDetails || 'struggling feeling stuck difficult',
      3
    );

    // Get past successes to remind user
    const pastSuccesses = await db
      .collection('users')
      .doc(userId)
      .collection('userTasks')
      .where('completed', '==', true)
      .orderBy('completedAt', 'desc')
      .limit(5)
      .get();

    const successCount = pastSuccesses.size;

    const openai = getTrackedOpenAI(apiKey, {
      userId,
      feature: 'resilience_support',
    });

    const systemPrompt = `You are the Easy Mode Resilience Coach. A user is experiencing a setback or struggling. Your role is to:
1. Validate their feelings without minimizing
2. Reframe the setback as part of the growth process
3. Remind them of past successes
4. Offer ONE small, immediate action they can take
5. Express genuine belief in their ability to bounce back

Be warm, brief, and focus on building them back up without toxic positivity.`;

    const contextPrompt = `USER CONTEXT:
- Name: ${userData.name || 'Friend'}
- Level: ${userData.level || 1}
- Previous streak: ${userData.streak || 0} days
- Total tasks completed: ${successCount}
- Goal: ${userData.profile?.goal || 'Build confidence'}
- Their challenge: ${userData.profile?.pain || 'Getting started'}

TRIGGER: ${triggerType}
${setbackDetails ? `WHAT THEY SHARED: "${setbackDetails}"` : ''}

${relevantMemories.length > 0 ? `RELEVANT PAST CONTEXT:\n${relevantMemories.map((m) => `- ${m.content}`).join('\n')}` : ''}

Provide resilience support. Respond in JSON:
{
  "validation": "1-2 sentences acknowledging their experience",
  "reframe": "1-2 sentences reframing this as part of growth",
  "reminder": "Brief reminder of their progress (reference ${successCount} completed tasks)",
  "microAction": {
    "title": "One tiny action they can do RIGHT NOW",
    "description": "Why this helps (1 sentence)",
    "timeMinutes": 2-5
  },
  "closingMessage": "Brief encouraging close (1 sentence)"
}`;

    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: contextPrompt }
      ],
      temperature: 0.7,
      max_tokens: 400,
      response_format: { type: 'json_object' }
    });

    const support = JSON.parse(response.choices[0]?.message?.content || '{}');

    // Store this as a memory for future reference
    await storeMemory(
      userId,
      'setback',
      `User experienced ${triggerType}${setbackDetails ? `: "${setbackDetails.substring(0, 100)}"` : ''}. Provided resilience support.`,
      { triggerType, supportProvided: true },
      4
    );

    // End trace
    await endTrace(trace, {
      support,
      successCount,
      memoriesRetrieved: relevantMemories.length,
    });

    // Log analytics
    await db.collection('analytics').add({
      event: 'resilience_support_triggered',
      userId,
      triggerType,
      pastSuccessCount: successCount,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Flush Opik data
    await openai.flush();
    await flushOpik();

    return {
      success: true,
      support: {
        validation: support.validation,
        reframe: support.reframe,
        reminder: support.reminder,
        microAction: support.microAction,
        closingMessage: support.closingMessage,
      },
      context: {
        totalSuccesses: successCount,
        streak: userData.streak || 0,
      },
    };

  } catch (error) {
    console.error('[Resilience Support] Error:', error);

    await endTrace(trace, {
      error: error instanceof Error ? error.message : 'Unknown error',
      success: false,
    });
    await flushOpik();

    // Return fallback support
    return {
      success: false,
      support: {
        validation: 'It\'s okay to have hard moments. This is part of the journey.',
        reframe: 'Every setback is actually data about what works for you and what doesn\'t.',
        reminder: 'You\'ve shown up before, and that counts for something.',
        microAction: {
          title: 'Take 3 deep breaths',
          description: 'This helps reset your nervous system.',
          timeMinutes: 1,
        },
        closingMessage: 'You\'re still here. That matters.',
      },
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
});

