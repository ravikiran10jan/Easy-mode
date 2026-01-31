# Easy Mode - Hackathon Submission

## Project Overview

**Easy Mode** is an AI-powered life coaching app that helps users build confidence through three core principles:

- **Action**: Clear, simple tasks that create momentum
- **Audacity**: Bold asks that expand comfort zones
- **Enjoyment**: Rituals that romanticize everyday moments

## Problem Statement

Many people struggle with:
- Taking action on goals due to overwhelm
- Asking for what they want (negotiations, requests, boundaries)
- Bouncing back from setbacks
- Finding joy in daily routines

Easy Mode addresses these by providing:
- One manageable daily task
- Pre-written scripts for bold asks
- Resilience flows when things don't go as planned
- Joy rituals to appreciate everyday moments

## Core Features

### 1. Daily Easy Mode Moment
- Personalized daily task based on user's goals
- Built-in timer for accountability
- "I couldn't" flow for supportive resilience

### 2. Audacity Scripts
- Word-for-word templates for bold asks
- Risk levels (Low/Medium/High)
- Outcome tracking (Success/Partial/Declined)
- All attempts earn XP - trying matters!

### 3. Joy Rituals
- Curated micro-rituals for daily enjoyment
- Quick 3-10 minute activities
- Mood tracking capabilities

### 4. Gamification
- XP for every action
- Levels with meaningful titles
- Streak bonuses (up to 50% XP boost)
- Achievement badges

## Technical Architecture

```
┌─────────────────┐     ┌──────────────────┐
│   Flutter App   │────▶│  Firebase Auth   │
│   (iOS/Android) │     └──────────────────┘
└────────┬────────┘              │
         │                       ▼
         │              ┌──────────────────┐
         ├─────────────▶│    Firestore     │
         │              │  (Real-time DB)  │
         │              └──────────────────┘
         │                       │
         │              ┌──────────────────┐
         └─────────────▶│ Cloud Functions  │
                        │ (XP/Badges/Push) │
                        └──────────────────┘
```

### Tech Stack
- **Frontend**: Flutter 3.16, Riverpod, Google Fonts
- **Backend**: Firebase (Auth, Firestore, Functions, FCM)
- **CI/CD**: GitHub Actions
- **Testing**: Flutter Test, Jest

## Key Metrics

| Metric | Target | How Measured |
|--------|--------|--------------|
| Daily Active Users | Track | Analytics events |
| Task Completion Rate | >70% | completed / shown |
| Audacity Attempt Rate | >30% | attempts / views |
| Streak Retention | 7+ days | User streaks |
| XP Velocity | Increasing | XP per user per week |

## Demo Flow (60s)

1. **Sign Up & Onboard** (10s) - Quick personalization
2. **Daily Task** (20s) - Complete task, earn XP, see celebration
3. **Audacity Script** (15s) - Show script, template, outcomes
4. **Joy Ritual** (10s) - Select and view ritual
5. **Progress** (5s) - XP, level, badges

## What Makes Us Different

1. **Not just tracking, but teaching** - We provide the words and actions
2. **Failure is rewarded** - XP for trying, not just succeeding
3. **Micro-commitment** - 5-10 minutes daily is enough
4. **Gamified resilience** - Setbacks have a supportive flow

## Future Roadmap

1. **LLM Personalization** - AI-tailored scripts based on context
2. **Community Challenges** - Social accountability features
3. **Voice Recording** - Practice audacity scripts with audio
4. **Progress Insights** - Weekly reports and patterns
5. **Coach Mode** - Premium 1:1 AI coaching sessions

## Team

Built with passion for helping people live more boldly.

## Try It

- **Demo Video**: [Link to video]
- **APK Download**: [Link to APK]
- **GitHub**: [Link to repo]

---

*Easy Mode - Because confidence is built one small action at a time.*
