# Analytics Dashboard Guide

This document explains the analytics events tracked in Easy Mode and how to query them for insights.

## Event Structure

All events are stored in the Firestore `analytics` collection with this structure:

```json
{
  "event": "event_name",
  "category": "category_name",
  "data": { /* event-specific data */ },
  "userId": "user_uid",
  "sessionId": "timestamp_string",
  "timestamp": "ISO8601_datetime",
  "platform": "ios|android|web"
}
```

## Event Categories

| Category | Description |
|----------|-------------|
| `session` | App session start/end |
| `navigation` | Screen views and navigation |
| `auth` | Authentication events |
| `onboarding` | Onboarding flow steps |
| `engagement` | Feature usage (tasks, actions, scripts, rituals) |
| `progress` | Level ups, streaks, badges |
| `ai` | AI feature interactions |
| `error` | Error tracking |

## Events Reference

### Session Events
- `session_start` - App opened
- `session_end` - App closed (includes `duration_seconds`)

### Navigation Events
- `screen_view` - Screen viewed (`screen_name`, `previous_screen`)

### Auth Events
- `sign_in_attempt` - Sign in started (`method`: email|google)
- `sign_in_success` - Sign in completed
- `sign_in_failure` - Sign in failed (`error`)
- `sign_up_attempt` - Sign up started
- `sign_up_success` - Sign up completed
- `sign_up_failure` - Sign up failed (`error`)
- `sign_out` - User signed out

### Onboarding Events
- `onboarding_step_view` - Step viewed (`step`, `step_name`)
- `onboarding_step_complete` - Step completed (`step`, `step_name`, `selection`)
- `onboarding_skip` - Onboarding skipped (`at_step`)
- `onboarding_complete` - Onboarding finished (`pain`, `goal`, `dailyTime`)

### Engagement Events
- `task_view` - Daily task viewed (`task_id`, `task_type`)
- `task_start` - Task timer started
- `task_complete` - Task finished (`xp_earned`, `duration_seconds`)
- `task_abandon` - Task abandoned before completion

- `action_view` - Action library item viewed (`action_id`, `action_category`)
- `action_start` - Action started
- `action_complete` - Action completed (`xp_earned`)

- `script_view` - Audacity script viewed (`script_id`, `risk_level`)
- `script_start` - Script practice started
- `script_attempt` - Script attempted (`outcome`, `xp_earned`)

- `ritual_view` - Joy ritual viewed (`ritual_id`)
- `ritual_start` - Ritual started
- `ritual_complete` - Ritual finished (`xp_earned`)

### Progress Events
- `level_up` - User leveled up (`new_level`, `total_xp`)
- `streak_update` - Streak changed (`streak`)
- `badge_earned` - Badge earned (`badge_id`, `badge_name`)

### AI Events
- `ai_insight_viewed` - Daily insight viewed
- `ai_recommendation_interaction` - User interacted with AI recommendation

---

## Firestore Queries for Key Metrics

### 1. Daily Active Users (DAU)
```javascript
// Firebase Console or Admin SDK
const today = new Date();
today.setHours(0, 0, 0, 0);

db.collection('analytics')
  .where('event', '==', 'session_start')
  .where('timestamp', '>=', today.toISOString())
  .get()
  .then(snap => {
    const uniqueUsers = new Set(snap.docs.map(d => d.data().userId));
    console.log('DAU:', uniqueUsers.size);
  });
```

### 2. Onboarding Funnel / Drop-off Analysis
```javascript
// Count users at each onboarding step
const steps = ['Welcome', 'Challenge', 'Goal', 'Time'];

for (const step of steps) {
  const count = await db.collection('analytics')
    .where('event', '==', 'onboarding_step_view')
    .where('data.step_name', '==', step)
    .get()
    .then(snap => snap.size);
  console.log(`${step}: ${count} users`);
}

// Completion rate
const started = await db.collection('analytics')
  .where('event', '==', 'onboarding_step_view')
  .where('data.step', '==', 0)
  .get().then(s => s.size);

const completed = await db.collection('analytics')
  .where('event', '==', 'onboarding_complete')
  .get().then(s => s.size);

console.log(`Completion rate: ${(completed/started*100).toFixed(1)}%`);
```

### 3. Task Completion Rate
```javascript
const views = await db.collection('analytics')
  .where('event', '==', 'task_view')
  .get().then(s => s.size);

const completions = await db.collection('analytics')
  .where('event', '==', 'task_complete')
  .get().then(s => s.size);

console.log(`Task completion rate: ${(completions/views*100).toFixed(1)}%`);
```

### 4. Feature Usage by Category
```javascript
const features = ['task_complete', 'action_complete', 'script_attempt', 'ritual_complete'];

for (const event of features) {
  const count = await db.collection('analytics')
    .where('event', '==', event)
    .get().then(s => s.size);
  console.log(`${event}: ${count}`);
}
```

### 5. Auth Conversion Rate
```javascript
const signUpAttempts = await db.collection('analytics')
  .where('event', '==', 'sign_up_attempt')
  .get().then(s => s.size);

const signUpSuccess = await db.collection('analytics')
  .where('event', '==', 'sign_up_success')
  .get().then(s => s.size);

console.log(`Sign-up success rate: ${(signUpSuccess/signUpAttempts*100).toFixed(1)}%`);
```

### 6. Average Session Duration
```javascript
const sessions = await db.collection('analytics')
  .where('event', '==', 'session_end')
  .get();

const durations = sessions.docs.map(d => d.data().data?.duration_seconds || 0);
const avgDuration = durations.reduce((a,b) => a+b, 0) / durations.length;
console.log(`Avg session: ${(avgDuration/60).toFixed(1)} minutes`);
```

---

## Building a Dashboard

### Option 1: Firebase Extensions + BigQuery + Looker Studio (Recommended)

1. **Export to BigQuery**: Use the "Export Collections to BigQuery" Firebase Extension
   - Install from Firebase Console > Extensions
   - Configure to export `analytics` collection
   
2. **Create Looker Studio Dashboard**:
   - Connect BigQuery as data source
   - Create charts for:
     - DAU/WAU/MAU trends
     - Onboarding funnel
     - Feature engagement pie chart
     - Session duration histogram
     - Retention cohorts

### Option 2: Custom Admin Dashboard

Build a simple web dashboard using:
- React/Next.js + Firebase Admin SDK
- Chart.js or Recharts for visualizations
- Query analytics collection and aggregate data

### Option 3: Third-Party Analytics (Alternative)

For more advanced analytics, consider integrating:
- **Mixpanel**: Event-based analytics with funnels
- **Amplitude**: Product analytics with cohorts
- **PostHog**: Open-source product analytics

To integrate, add SDK and log events alongside Firestore:
```dart
// In analytics_service.dart
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

// In logEvent method:
await _mixpanel?.track(event, properties: data);
```

---

## Key Metrics to Track

| Metric | Query | Target |
|--------|-------|--------|
| DAU | `session_start` unique users/day | Track growth |
| Onboarding Completion | `onboarding_complete` / step 0 views | >70% |
| Task Completion Rate | `task_complete` / `task_view` | >60% |
| Audacity Attempt Rate | `script_attempt` / `script_view` | >30% |
| Session Duration | avg `session_end.duration_seconds` | >5 min |
| 7-Day Retention | Users active on day 7 / day 0 | >40% |
| Sign-up Conversion | `sign_up_success` / `sign_up_attempt` | >80% |

---

## Debugging Tips

1. **View raw events** in Firebase Console:
   - Go to Firestore Database
   - Browse `analytics` collection
   - Filter by userId or event name

2. **Test events locally**:
   - Use Firebase Emulator Suite
   - Events appear in emulator UI

3. **Verify tracking**:
   - Add debug prints in `analytics_service.dart`
   - Check Firestore writes in real-time
