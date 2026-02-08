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

---

## 5. Opik Observability Tests

Location: `scripts/`

These tests demonstrate the Opik integration for AI observability, generating real traces with LLM-as-Judge evaluations.

### Test Scripts

| Script | Purpose |
|--------|---------|
| `test_opik_observability.js` | Basic AI function traces (5 scenarios) |
| `test_opik_advanced.js` | A/B testing, user segments, edge cases (8 scenarios) |

### Setup

```bash
cd scripts
npm install dotenv opik opik-openai openai
```

### Run Tests

```bash
# Basic test - 5 AI function scenarios
node test_opik_observability.js

# Advanced test - A/B testing, user segments, edge cases
node test_opik_advanced.js
```

### Basic Test Scenarios

| Scenario | Description | Evaluations |
|----------|-------------|-------------|
| `personalize_task` | Personalizes a task for user context | task_relevance, specificity, engagement_potential |
| `daily_insight` | Generates daily coaching insight | task_relevance, specificity, engagement_potential |
| `coach_decides` | AI decides best task for user | task_relevance, specificity, engagement_potential |
| `smart_recommendation` | Behavior-based recommendation | task_relevance, specificity, engagement_potential |
| `weekly_plan_reasoning` | Multi-step weekly plan generation | task_relevance, specificity, engagement_potential |

### Advanced Test Scenarios

**Prompt A/B Testing:**
| Version | Tone | Purpose |
|---------|------|---------|
| v1-formal | Professional | Compare formal coaching tone |
| v2-casual | Friendly/Fun | Compare casual coaching tone |
| v3-encouraging | Empathetic | Compare encouraging coaching tone |

**User Segment Tests:**
| Segment | Purpose |
|---------|---------|
| new_user | Test recommendations for users with no history |
| struggling_user | Test support for users with broken streaks |
| power_user | Test challenges for highly engaged users |

**Edge Case Tests:**
| Case | Purpose |
|------|---------|
| minimal_input | Verify handling of sparse user data |
| complex_goal | Verify handling of overwhelming multi-part goals |

### Test Results (Latest Run)

#### Basic Test Results

| Scenario | Tokens | Relevance | Specificity | Engagement | Status |
|----------|--------|-----------|-------------|------------|--------|
| personalize_task | 279 | 5 | 4 | 4 | PASS |
| daily_insight | 278 | 5 | 4 | 5 | PASS |
| coach_decides | 450 | 5 | 4 | 4 | PASS |
| smart_recommendation | 412 | 5 | 4 | 4 | PASS |
| weekly_plan_reasoning | 480 | 5 | 5 | 4 | PASS |

**Total: 5/5 passed**

#### Advanced Test Results

| Category | Tests | Passed | Avg Relevance | Avg Safety |
|----------|-------|--------|---------------|------------|
| Prompt A/B Testing | 3 | 3 | 5.0 | N/A |
| User Segment Tests | 3 | 3 | 5.0 | N/A |
| Edge Case Tests | 2 | 2 | 5.0 | 5.0 |

**Total: 8/8 passed**

### Viewing Results in Opik Dashboard

**Dashboard URL:**
```
https://www.comet.com/opik/ravikiran/easy-mode/traces
```

**Useful Filters:**
- Tag: `test` - All test traces
- Tag: `prompt-experiment` - A/B testing results
- Tag: `user-segment` - User adaptation tests
- Tag: `edge-case` - Edge case robustness

### What Each Test Generates

Each test creates an Opik trace with:
- Full input/output payload
- Auto-created spans for OpenAI calls
- LLM-as-Judge evaluation scores
- Prompt version metadata
- Token usage and latency metrics

### Expected Output

```
=== Opik Observability Test ===

Opik Workspace: ravikiran
Opik Project: easy-mode

Starting Opik observability tests...
Running 5 test scenarios

[1/5] Running: personalize_task
   Description: Task personalization for user
   Response received (279 tokens)
   Evaluations: relevance=5, specificity=4, engagement=4
   Trace completed with 3 feedback scores
...

===========================================
TEST SUMMARY
===========================================

Total scenarios: 5
Successful: 5
Failed: 0
```
