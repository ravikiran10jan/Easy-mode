import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import OpenAI from 'openai';

admin.initializeApp();

// Initialize OpenAI client - API key from Firebase config
const getOpenAIClient = () => {
  const apiKey = functions.config().openai?.key;
  if (!apiKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'OpenAI API key not configured. Run: firebase functions:config:set openai.key="YOUR_KEY"'
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
  .onRun(async (context) => {
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
