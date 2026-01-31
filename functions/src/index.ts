import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import OpenAI from 'openai';

admin.initializeApp();

// Initialize OpenAI client - API key from environment variable
const getOpenAIClient = () => {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'OpenAI API key not configured. Add OPENAI_API_KEY to functions/.env file.'
    );
  }
  return new OpenAI({ apiKey });
};

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
 */
export const personalizeTask = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to use this feature.'
    );
  }

  const { task, userContext } = data;
  
  if (!task || !task.title) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Task data is required.'
    );
  }

  try {
    const openai = getOpenAIClient();
    
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
    
    return {
      success: true,
      personalizedDescription: personalized.personalizedDescription,
      coachTip: personalized.coachTip,
      motivationalNote: personalized.motivationalNote,
    };
  } catch (error) {
    console.error('Error personalizing task:', error);
    
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

  try {
    const openai = getOpenAIClient();
    
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
    
    // Log analytics
    await db.collection('analytics').add({
      event: 'daily_insight_generated',
      userId: userId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    
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

  try {
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

    // Use AI to make final selection with reasoning
    const openai = getOpenAIClient();

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

    // Log recommendation for analytics
    await db.collection('analytics').add({
      event: 'smart_recommendation',
      userId: userId,
      selectedTaskId: selectedTask.id,
      candidateCount: topCandidates.length,
      behaviorPatternSummary: {
        totalTasks: behaviorPattern.totalTasksCompleted,
        preferredType: Object.entries(behaviorPattern.preferredTaskTypes)
          .sort(([,a], [,b]) => b - a)[0]?.[0] || 'action',
      },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

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

