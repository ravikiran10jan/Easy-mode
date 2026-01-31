# Test Plan - Easy Mode

## Overview

This document outlines the testing strategy for the Easy Mode app.

## Test Categories

### 1. Unit Tests

Location: `test/unit/`

| Test File | Coverage |
|-----------|----------|
| `models_test.dart` | Data models (UserModel, TaskModel, ScriptModel, RitualModel) |
| `xp_calculation_test.dart` | XP calculation logic, streak bonuses, level calculation |

**Run:**
```bash
flutter test test/unit/
```

### 2. Widget Tests

Location: `test/widget/`

| Test File | Coverage |
|-----------|----------|
| `onboarding_test.dart` | Onboarding flow, navigation, state persistence |
| `daily_task_card_test.dart` | Task card rendering, timer, completion flow |

**Run:**
```bash
flutter test test/widget/
```

### 3. Cloud Functions Tests

Location: `functions/test/`

| Test File | Coverage |
|-----------|----------|
| `xp.test.ts` | XP calculation, streak bonus, badge eligibility |

**Run:**
```bash
cd functions && npm test
```

### 4. Integration Tests (Manual)

| Scenario | Steps | Expected Result |
|----------|-------|-----------------|
| New User Flow | Sign up → Onboard → Complete task | XP awarded, streak = 1 |
| Returning User | Sign in → See streak | Streak maintained or incremented |
| Audacity Flow | Select script → Practice → Log outcome | XP awarded based on outcome |
| Resilience Flow | Start task → Tap "I couldn't" | See alternative suggestions |
| Streak Break | Skip a day | Streak resets to 1 |

## Test Data

### Seed Data
The app includes seed data for testing:
- 8 Audacity Scripts (various risk levels)
- 8 Daily Tasks (action, audacity, enjoy types)
- 10 Joy Rituals
- 10 Badges

**Seed Command:**
```bash
node scripts/seed_firestore.js
```

### Test User
Create a test user or use emulator auth:
- Email: `test@easymode.app`
- Password: `test123!`

## CI/CD Testing

GitHub Actions runs on every PR:
1. `flutter analyze` - Static analysis
2. `flutter test` - Unit and widget tests
3. `flutter build apk` - Android build verification
4. `flutter build ios` - iOS build verification
5. `npm test` (functions) - Cloud Functions tests

## Manual Testing Checklist

### Authentication
- [ ] Email sign up creates user in Firestore
- [ ] Email sign in works with existing user
- [ ] Google sign in creates/links user
- [ ] Sign out clears local state
- [ ] Password reset sends email

### Onboarding
- [ ] Progress indicators update correctly
- [ ] Can navigate back to previous steps
- [ ] Selections are preserved on back navigation
- [ ] "Get Started" saves profile to Firestore
- [ ] Skip onboarding redirects correctly

### Home / Daily Task
- [ ] Task card displays correct type badge
- [ ] Timer starts and updates
- [ ] "I did it!" awards XP
- [ ] Confetti animation plays on completion
- [ ] "I couldn't" shows resilience dialog
- [ ] XP header updates after completion

### Audacity Scripts
- [ ] Scripts load from Firestore
- [ ] Search filters scripts correctly
- [ ] Category chips filter correctly
- [ ] Script detail shows all fields
- [ ] Template is editable
- [ ] Outcome logging awards correct XP
- [ ] Success shows celebration dialog

### Joy Rituals
- [ ] Rituals load from Firestore
- [ ] Selection highlights correctly
- [ ] Steps display for selected ritual
- [ ] "Complete" awards XP

### Progress
- [ ] XP bar shows correct progress
- [ ] Level displays correctly
- [ ] Streak counter is accurate
- [ ] Stats match user activity
- [ ] Badges show earned vs locked

### Profile
- [ ] User info displays correctly
- [ ] Settings options work
- [ ] Sign out returns to auth screen
- [ ] Delete account removes data

### Notifications (Emulator)
- [ ] FCM token is saved to user doc
- [ ] Daily nudge is scheduled

## Performance Benchmarks

| Metric | Target |
|--------|--------|
| Cold start | < 3s |
| Hot reload | < 1s |
| Firestore query | < 500ms |
| Screen transition | < 300ms |

## Known Limitations (MVP)

1. Offline mode has limited functionality
2. LLM features are behind feature flag (not implemented)
3. Push notifications require FCM setup per platform
4. No deep linking support yet
