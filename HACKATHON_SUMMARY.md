# Hackathon Submission Summary

> **Easy Mode - AI Life Coach**  
> Commit to Change: An AI Agents Hackathon

---

## Quick Links

| Resource | Link |
|----------|------|
| Demo Video | [YouTube](#) |
| Live App | [easymode.app](#) |
| Opik Dashboard | [Comet](#) |
| GitHub | [Repository](#) |

---

## Categories

### 1. Productivity & Work Habits ($5,000)

| Criteria | Score | Evidence |
|----------|-------|----------|
| **Functionality** | Strong | 8 Cloud Functions, 40+ screens, full CRUD, gamification |
| **Real-world relevance** | Strong | Addresses #1 reason resolutions fail: too big → micro-tasks |
| **Use of LLMs/Agents** | Strong | 6 AI functions, multi-step reasoning, tool use, autonomous decisions |
| **Evaluation & observability** | Strong | Full Opik integration, LLM-as-Judge, experiment tracking |
| **Goal Alignment** | Strong | XP system, streaks, badges, weekly plans, adaptive difficulty |

**Key Features:**
- Break big goals into 5-10 minute daily micro-tasks
- AI analyzes 30 days of behavior to personalize recommendations
- "Coach Decides" - AI makes decisions FOR the user when overwhelmed
- Weekly plans with automatic difficulty adjustment

### 2. Personal Growth & Learning ($5,000)

| Criteria | Score | Evidence |
|----------|-------|----------|
| **Functionality** | Strong | Audacity scripts, resilience flows, reflection prompts |
| **Real-world relevance** | Strong | Teaches practical confidence skills for work, relationships, life |
| **Use of LLMs/Agents** | Strong | AI personalizes growth journey based on aspirations |
| **Evaluation & observability** | Strong | Progress tracking with XP, AI quality evaluated via Opik |
| **Goal Alignment** | Strong | Core mission is emotional growth and skill development |

**Key Features:**
- **Audacity Scripts**: Word-for-word templates for bold asks (negotiations, boundaries, requests)
- **Aspiration-Based Onboarding**: "I speak up for what I want", "I take action without overthinking"
- **Resilience Flows**: Supportive paths when users say "I couldn't do it"
- **Skill Progression**: XP/levels make personal development feel rewarding
- **Weekly Reflections**: AI-generated summaries encourage self-awareness

### 3. Best Use of Opik ($5,000)

| Criteria | Score | Evidence |
|----------|-------|----------|
| **Functionality** | Strong | Tracing, feedback scores, experiment tracking all working |
| **Real-world relevance** | Strong | Shows how to build production AI with proper observability |
| **Evaluation & observability** | Strong | 5 LLM-as-Judge metrics, experiment reports, data-driven improvement |
| **Goal Alignment** | Strong | Full Opik SDK integration, proper Cloud Function flushing |

**Key Features:**
- 100% of AI calls traced with full context
- 5 evaluation metrics: task_relevance, specificity, safety, engagement_potential, decision_confidence
- Prompt version tracking with content hashes
- Experiment comparison reports for systematic prompt improvement
- Evaluation scores stored in Firestore for trend analysis

---

## Tech Stack

```
Frontend          Backend               AI/ML
-----------------+--------------------+-------------------
Flutter 3.16+    Firebase Auth        OpenAI GPT-4o-mini
Riverpod         Cloud Firestore      Opik SDK
flutter_animate  Cloud Functions      LLM-as-Judge Evals
                 FCM Notifications    Multi-step Agents
```

---

## AI Features Matrix

| Feature | Type | Opik Traced | Evaluations |
|---------|------|-------------|-------------|
| `personalizeTask` | Generation | Yes | task_relevance, specificity, safety |
| `generateDailyInsight` | Generation | Yes | specificity, engagement, safety |
| `getSmartRecommendation` | Decision | Yes | task_relevance, specificity, engagement |
| `coachDecides` | Autonomous | Yes | task_relevance, decision_confidence, engagement |
| `generateWeeklyPlan` | Agentic | Partial | N/A (multi-step tool use) |
| `weeklyReplanningCheck` | Scheduled | No | N/A (adaptive adjustment) |
| `generateExperimentReport` | Analysis | No | N/A (generates reports) |

---

## Agentic Capabilities

### Multi-Step Reasoning
```typescript
const PLANNER_TOOLS = [
  { name: 'create_milestone', ... },
  { name: 'create_daily_task', ... },
  { name: 'adjust_difficulty', ... },
];
// Agent loops until plan is complete (up to 10 iterations)
```

### Autonomous Decision-Making
- **Coach Decides**: AI picks task without user input
- **Adaptive Replanning**: Weekly cron job adjusts difficulty automatically
- **Smart Recommendations**: Combines rule-based scoring + AI selection

### Tool Use Pattern
- OpenAI function calling for structured output
- Tools: create_milestone, create_daily_task, adjust_difficulty
- Full reasoning chain stored and visible to user

---

## Opik Integration Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    OPIK INTEGRATION                              │
├─────────────────────────────────────────────────────────────────┤
│ Tracing                                                          │
│ ├── Auto-traced OpenAI client (trackOpenAI)                     │
│ ├── Manual traces with full context                             │
│ └── Tags: easy-mode, function-name, feature-type                │
├─────────────────────────────────────────────────────────────────┤
│ Evaluation (LLM-as-Judge)                                        │
│ ├── task_relevance (1-5)                                        │
│ ├── specificity (1-5)                                           │
│ ├── safety (1-5)                                                │
│ ├── engagement_potential (1-5)                                  │
│ └── decision_confidence (1-5)                                   │
├─────────────────────────────────────────────────────────────────┤
│ Experiment Tracking                                              │
│ ├── Prompt versions (v1, v2, etc.)                              │
│ ├── Content hashes for change detection                         │
│ └── Experiment comparison reports                               │
├─────────────────────────────────────────────────────────────────┤
│ Production Considerations                                        │
│ ├── Singleton client pattern                                    │
│ ├── Graceful fallback when disabled                             │
│ └── Timeout-protected flushing (5s max)                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Cost Analysis

| Component | Per User/Day | Notes |
|-----------|--------------|-------|
| Task Personalization | $0.0005 | ~300 tokens |
| Daily Insight | $0.0004 | ~250 tokens |
| Smart Recommendation | $0.0008 | ~400 tokens |
| Coach Decides | $0.001 | ~500 tokens |
| LLM-as-Judge (3 evals) | $0.0006 | ~100 tokens each |
| **Total** | **~$0.005** | Very cost-effective |

---

## Files to Review

For **Productivity & Work Habits** reviewers:
- `lib/features/home/screens/home_screen.dart` - Main UX
- `lib/core/services/ai_service.dart` - AI integration
- `functions/src/index.ts` - Cloud Functions

For **Best Use of Opik** reviewers:
- `functions/src/opik.ts` - Opik integration module
- `functions/src/index.ts` - See `personalizeTask`, `coachDecides`, `getSmartRecommendation`
- `docs/OPIK_INTEGRATION.md` - Detailed documentation

---

## Team

- **[Your Name]** - Solo Developer

---

## Contact

- Email: [your@email.com]
- GitHub: [@yourusername]
- Discord: [username#0000]
