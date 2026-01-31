import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

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
 * HTTP endpoint for LLM-powered task personalization (optional feature)
 * Enable this only if LLM_ENABLED feature flag is true
 */
export const personalizeTask = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to use this feature.'
    );
  }
  
  const { taskId, userContext } = data;
  
  // This is a placeholder for LLM integration
  // In production, you would call OpenAI/Claude API here
  // For MVP, return the original task with a personalized message
  
  return {
    success: true,
    message: 'Task personalization is a premium feature.',
    personalizedTask: null,
  };
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
