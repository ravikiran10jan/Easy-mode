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
    let messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
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
          case 'create_milestone':
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

          case 'create_daily_task':
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
 */
export const coachDecides = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to use Coach Decides.'
    );
  }

  const userId = context.auth.uid;

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
    const openai = new OpenAI({ apiKey });

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

    // Log analytics
    await db.collection('analytics').add({
      event: 'coach_decides',
      userId,
      selectedTaskId: selectedTask.id,
      taskType: selectedTask.type,
      confidenceLevel: coachDecision.reasoning.confidenceLevel,
      dayOfWeek,
      timeOfDay,
      completedToday,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

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

