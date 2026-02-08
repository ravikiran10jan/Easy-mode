# Easy Mode - Hackathon Submission

> **Commit to Change: An AI Agents Hackathon**  
> Categories: **Productivity & Work Habits** | **Personal Growth & Learning** | **Best Use of Opik**

---

## Project Overview

**Easy Mode** is an AI-powered life coaching app that transforms New Year's resolutions into lasting habits through:

- **Action**: 5-10 minute micro-tasks that create momentum
- **Audacity**: Bold asks with word-for-word scripts
- **Enjoyment**: Rituals that romanticize everyday moments

---

## Problem Statement

**90% of New Year's resolutions fail.** Why?

- Goals are too big and overwhelming
- No clear daily action steps
- Setbacks feel like failure
- No accountability or feedback

**Easy Mode solves this by:**
- Breaking goals into 5-10 minute daily micro-tasks
- Using AI to personalize recommendations based on behavior patterns
- Rewarding attempts, not just success (XP for trying)
- Providing an AI coach that adapts difficulty based on completion rates

---

## Core AI Features

### 1. Smart Task Recommendations
AI analyzes 30 days of user behavior to recommend the perfect task:
- Preferred task types and categories
- Success rates by task type
- Peak activity hours
- Recent completions (variety boost)

### 2. Coach Decides (Autonomous AI)
When users feel overwhelmed, they tap "Let Coach Decide" and the AI:
- Analyzes full user context (streak, time, energy, weekly plan)
- Makes a decision FOR the user
- Explains reasoning with full transparency

### 3. Planner Agent (Multi-Step Reasoning)
Uses OpenAI function calling with tools:
- `create_milestone` - Break goal into weekly milestones
- `create_daily_task` - Plan specific daily tasks
- `adjust_difficulty` - Adapt based on completion rate

### 4. Adaptive Replanning
Scheduled agent runs weekly to:
- Analyze completion rates
- Simplify if < 60% completion
- Increase challenge if > 80% completion
- Store reasoning for transparency

---

## Personal Growth & Learning

Easy Mode is fundamentally a **personal development tool**:

### Emotional Growth
- **Overcoming Self-Doubt**: Daily micro-wins build confidence over time
- **Building Assertiveness**: Audacity Scripts teach users to ask for what they want
- **Resilience Training**: "I couldn't do it" flows teach constructive setback handling

### Skill Development
- **Word-for-Word Templates**: Audacity Scripts for negotiations, boundaries, requests
- **Risk-Graduated Learning**: Low/Medium/High risk levels let users progress at their pace
- **Outcome Tracking**: Learn from successes AND rejections (both earn XP)

### Self-Awareness
- **Aspiration-Based Onboarding**: Users define their growth identity
  - "I speak up for what I want"
  - "I take action without overthinking"
  - "I find joy in ordinary moments"
- **Weekly AI Reflections**: Summaries encourage learning from experience
- **Progress Visualization**: XP/levels make growth tangible and rewarding

---

## Opik Integration (Best Use of Opik)

### Full Tracing
Every AI call is traced with:
- User context (goals, pain points, streak)
- Behavior patterns (30-day analysis)
- Task candidates and selection reasoning

### LLM-as-Judge Evaluations
5 evaluation metrics scored on every AI response:

| Metric | What It Measures |
|--------|------------------|
| `task_relevance` | How well task matches user's stated goal |
| `specificity` | How actionable and specific the response is |
| `safety` | Whether advice is safe and appropriate |
| `engagement_potential` | How motivating the response is likely to be |
| `decision_confidence` | Quality of reasoning in Coach Decides |

### Experiment Tracking
- Prompt versions tracked with content hashes
- Experiment comparison reports generated on demand
- Recommendations for prompt improvement

### Data-Driven Improvement
```typescript
// Example: Experiment Report Output
{
  "experiments": [
    {
      "eventType": "coach_decides",
      "promptVersion": "v1",
      "avgScores": { "task_relevance": 4.2, "decision_confidence": 3.9 },
      "sampleCount": 150
    }
  ],
  "recommendations": [
    "coach_decides: High variance in decision_confidence - consider more consistent prompt"
  ]
}
```

---

## Technical Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Flutter Mobile App                           │
│  - Riverpod state management                                        │
│  - 40+ screens with animations                                      │
│  - Gamification (XP, levels, badges, streaks)                       │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Firebase Cloud Functions                         │
│  - personalizeTask()         → Traced + Evaluated                   │
│  - generateDailyInsight()    → Traced + Evaluated                   │
│  - getSmartRecommendation()  → Traced + Evaluated                   │
│  - coachDecides()            → Traced + Evaluated                   │
│  - generateWeeklyPlan()      → Agentic (tool use)                   │
│  - weeklyReplanningCheck()   → Scheduled (adaptive)                 │
│  - generateExperimentReport()→ Opik metrics analysis                │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Opik Platform                               │
│  - Traces with full context                                         │
│  - Feedback scores (LLM-as-Judge)                                   │
│  - Experiment tracking                                              │
└─────────────────────────────────────────────────────────────────────┘
```

### Tech Stack
- **Frontend**: Flutter 3.16+, Riverpod, flutter_animate
- **Backend**: Firebase (Auth, Firestore, Functions, FCM)
- **AI**: OpenAI GPT-4o-mini
- **Observability**: Opik (tracing, evaluation, experiments)

---

## Key Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Task Completion Rate | >70% | completed / shown |
| Opik Evaluation Avg | >4.0/5 | LLM-as-Judge scores |
| Coach Decides Usage | >20% | decisions / sessions |
| Adaptive Adjustments | Tracked | simplify/increase ratio |

---

## Demo Flow (90 seconds)

| Scene | Duration | Focus |
|-------|----------|-------|
| Hook | 5s | "90% of resolutions fail" |
| Onboarding | 15s | Aspiration-based personalization |
| Daily Task | 20s | AI-recommended micro-task + XP |
| Coach Decides | 20s | Autonomous AI decision with reasoning |
| Audacity Scripts | 10s | Bold asks with templates |
| Opik Dashboard | 15s | Traces + evaluation scores |
| Wrap-up | 5s | Progress screen |

---

## What Makes Us Different

| Traditional Habit Apps | Easy Mode |
|------------------------|-----------|
| Track habits | AI picks habits for you |
| Static difficulty | Adaptive difficulty |
| No reasoning | Full transparency ("Why this task?") |
| No observability | LLM-as-Judge on every response |
| Hope prompts work | Data-driven prompt improvement |

---

## Links

| Resource | URL |
|----------|-----|
| Demo Video | [YouTube](#) |
| Live App | [easymode.app](#) |
| Opik Dashboard | [Comet](#) |
| GitHub | [Repository](#) |

---

## Team

- **[Your Name]** - Solo Developer

---

## Cost Estimate

| Operation | Cost |
|-----------|------|
| Per user per day | ~$0.005 |
| Per 1,000 users/month | ~$150 |

Using GPT-4o-mini for cost-effectiveness while maintaining quality.

---

*Easy Mode - Because confidence is built one small action at a time.*
