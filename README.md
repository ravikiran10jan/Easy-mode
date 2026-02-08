# Easy Mode - AI Life Coach

> **Commit to Change: An AI Agents Hackathon**  
> Categories: **Productivity & Work Habits** | **Personal Growth & Learning** | **Best Use of Opik**

Your AI life coach for building confidence through **Action**, **Audacity**, and **Enjoyment**. Easy Mode transforms New Year's resolutions into daily micro-habits using AI-powered coaching, adaptive planning, and comprehensive observability.

## What is Easy Mode?

Easy Mode is a mobile app that helps users build sustainable productivity habits by:

- **Breaking down big goals** into 5-10 minute daily micro-tasks
- **Using AI agents** to personalize recommendations based on user behavior
- **Adapting difficulty** based on completion rates (the coach learns from you)
- **Tracking everything** with Opik for continuous improvement

### Core Principles

| Principle | Description | In-App Feature |
|-----------|-------------|----------------|
| **Action** | Small steps create momentum | Daily micro-tasks (5-10 min) |
| **Audacity** | Bold asks expand comfort zones | Audacity Scripts with risk levels |
| **Enjoyment** | Romanticize everyday moments | Joy Rituals for mindfulness |

---

## Live Demo

**Video Demo:** [YouTube Link - Coming Soon]

**Test Account:**
- Email: `demo@easymode.app`
- Password: `demo123!`

---

## Hackathon Categories

### Productivity & Work Habits

Easy Mode directly addresses the challenge of turning New Year's resolutions into lasting habits:

| Judging Criteria | How Easy Mode Delivers |
|------------------|----------------------|
| **Functionality** | Fully working Flutter app with Firebase backend, AI personalization, gamified progress |
| **Real-world relevance** | Addresses the #1 problem with resolutions: they're too big. We break them into 5-min daily actions |
| **Use of LLMs/Agents** | 14 AI Cloud Functions with reasoning chains, RAG, tool use, self-reflection, and autonomous scheduling |
| **Evaluation & observability** | Full Opik integration with LLM-as-Judge, experiment tracking, and adaptive learning |
| **Goal Alignment** | XP system, streaks, badges, and weekly plans keep users engaged and progressing |

### Personal Growth & Learning

Easy Mode is fundamentally a **personal development tool** that helps users grow emotionally and build new skills:

| Judging Criteria | How Easy Mode Delivers |
|------------------|----------------------|
| **Functionality** | Complete coaching system with lessons, practice scripts, and reflection prompts |
| **Real-world relevance** | Teaches confidence-building skills applicable to work, relationships, and life |
| **Use of LLMs/Agents** | AI personalizes growth journey based on aspirations and progress |
| **Evaluation & observability** | Tracks learning progress with XP, evaluates AI coaching quality with Opik |
| **Goal Alignment** | Core mission is emotional growth - overcoming self-doubt, building assertiveness, finding joy |

**Key Personal Growth Features:**
- **Audacity Scripts**: Learn to ask for what you want with word-for-word templates
- **Resilience Flows**: "I couldn't do it" paths teach users to handle setbacks constructively
- **Aspiration-Based Onboarding**: Users define their growth identity ("I speak up for what I want")
- **Reflection Prompts**: Weekly summaries encourage self-awareness and learning from experience
- **Skill Progression**: XP and levels make personal development feel rewarding and tangible

### Best Use of Opik

Easy Mode showcases exceptional Opik integration for AI evaluation and observability:

| Opik Feature | Implementation |
|--------------|----------------|
| **Tracing** | All 14 AI functions traced with full context (user, task, behavior patterns) |
| **Auto-Tracking** | `trackOpenAI()` wrapper automatically captures all LLM calls |
| **LLM-as-Judge** | 5 evaluation metrics scored automatically on every AI response |
| **Experiment Tracking** | Prompt versions tracked with hashes for A/B testing |
| **Feedback Scores** | Evaluation scores attached to traces for performance analysis |
| **Batch Queues** | Proper flushing with timeout protection in Cloud Functions |
| **Experiment Reports** | Cloud Function generates comparative analysis across prompt versions |

---

## Tech Stack

```
Frontend                 Backend                    AI/ML
------------------------+------------------------+------------------------
Flutter 3.16+           Firebase Auth             OpenAI GPT-4o-mini
Riverpod (State)        Cloud Firestore           Opik (Observability)
flutter_animate         Cloud Functions (Node 20) LLM-as-Judge Evals
confetti (Celebrations) Firebase Messaging (FCM)  RAG (Memory System)
                                                  Self-Reflection Loop
                                                  Multi-step Agents
```

### Architecture

```
easy_mode/
├── lib/                          # Flutter app
│   ├── core/
│   │   ├── services/
│   │   │   ├── ai_service.dart   # Cloud Function calls (supports all 14 functions)
│   │   │   ├── firestore_service.dart
│   │   │   └── analytics_service.dart
│   │   ├── models/               # Data models
│   │   └── providers/            # Riverpod state
│   └── features/
│       ├── home/                 # Daily task + Coach Decides
│       ├── actions/              # Action library
│       ├── scripts/              # Audacity scripts
│       ├── rituals/              # Joy rituals
│       ├── progress/             # XP, badges, momentum tracker
│       └── onboarding/           # Aspiration-based onboarding
│
├── functions/                    # Firebase Cloud Functions
│   └── src/
│       ├── index.ts              # 14 Cloud Functions (AI + Triggers)
│       └── opik.ts               # Opik integration module
│
└── scripts/                      # Utilities
    └── seed_firestore.js         # Seed data
```

---

## AI Features & Agentic System

Easy Mode implements a comprehensive AI architecture with **14 Cloud Functions**, featuring reasoning chains, autonomous decision-making, retrieval-augmented generation (RAG), and self-reflection loops.

### AI Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         EASY MODE AI ARCHITECTURE                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│   │   MEMORY    │    │  REASONING  │    │   TOOLS     │    │ REFLECTION  │ │
│   │    (RAG)    │    │   CHAINS    │    │  (Actions)  │    │   LOOP      │ │
│   └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘ │
│          │                  │                  │                  │        │
│          └──────────────────┴──────────────────┴──────────────────┘        │
│                                     │                                       │
│                            ┌────────▼────────┐                              │
│                            │   GPT-4o-mini   │                              │
│                            └────────┬────────┘                              │
│                                     │                                       │
│                            ┌────────▼────────┐                              │
│                            │      OPIK       │                              │
│                            │  (Observability)│                              │
│                            └────────┬────────┘                              │
│                                     │                                       │
│          ┌──────────────────────────┼──────────────────────────┐           │
│          │                          │                          │           │
│   ┌──────▼──────┐           ┌───────▼───────┐          ┌───────▼───────┐   │
│   │   Tracing   │           │ LLM-as-Judge  │          │  Experiments  │   │
│   │   & Spans   │           │  Evaluations  │          │   Tracking    │   │
│   └─────────────┘           └───────────────┘          └───────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Cloud Functions (14 Total)

| Function | Category | Description |
|----------|----------|-------------|
| `chatWithCoach` | **Conversational AI** | RAG-powered chat with memory + self-reflection |
| `triggerResilienceSupport` | **Resilience Agent** | Detects struggles, provides structured support |
| `generateProactiveNudge` | **Proactive AI** | Generates personalized push notification content |
| `sendAINotifications` | **Autonomous** | Scheduled AI-personalized push notifications |
| `coachDecides` | **Decision Agent** | Full-context autonomous task selection |
| `generateWeeklyPlan` | **Planner Agent** | Multi-step planning with tool use |
| `weeklyReplanningCheck` | **Adaptive Agent** | Scheduled difficulty adjustment |
| `getSmartRecommendation` | **Hybrid AI** | Rules + AI task recommendation |
| `personalizeTask` | **Personalization** | Context-aware task customization |
| `generateDailyInsight` | **Insight Gen** | Daily AI coaching messages |
| `generateExperimentReport` | **Analytics** | Prompt experiment comparison |
| `onTaskComplete` | **Triggers** | XP award on completion |
| `updateStreak` | **Triggers** | Streak tracking |
| `sendDailyNudge` | **Scheduled** | Basic daily reminders |

---

### 1. Conversational AI with Memory (RAG)

**Function:** `chatWithCoach`

Full conversational interface with retrieval-augmented generation:

```
User Message → Retrieve Relevant Memories → Generate Response → Self-Reflect → Store Important Info
```

**Memory System:**
- Stores: achievements, setbacks, insights, preferences
- Retrieves: keyword-matched + recency-boosted memories
- Location: `users/{uid}/memories` collection

```typescript
// Memory entry structure
interface MemoryEntry {
  type: 'conversation' | 'achievement' | 'setback' | 'insight' | 'preference';
  content: string;
  importance: 1-5;  // Affects retrieval ranking
  createdAt: Timestamp;
}

// Retrieval for RAG
const memories = await retrieveRelevantMemories(userId, userMessage, 5);
// → Returns top 5 relevant memories for context injection
```

**Key Features:**
- Remembers past conversations and achievements
- Self-reflection loop improves response quality
- Automatic importance-based memory storage

---

### 2. Self-Reflection Loop

**Integrated in:** `chatWithCoach`

The AI critiques and improves its own responses before returning them:

```
Generate Response → Critique (1-5 score) → If score < 4: Improve → Return best version
```

```typescript
async function selfReflect(openai, originalPrompt, originalResponse, userContext) {
  // Step 1: Critique the response
  const critique = await openai.chat.completions.create({
    messages: [{ role: 'user', content: critiquePrompt }],
    response_format: { type: 'json_object' }
  });
  // → Returns: { issues: [...], score: 1-5, shouldImprove: bool }

  // Step 2: If needed, generate improved version
  if (critique.shouldImprove && critique.score < 4) {
    const improved = await openai.chat.completions.create({...});
    return { improvedResponse, confidenceScore: score + 1 };
  }
  
  return { originalResponse, confidenceScore: score };
}
```

**Evaluation Criteria:**
- Is it specific enough to be actionable?
- Does it acknowledge user's current state?
- Is the tone warm but not patronizing?
- Does it align with Action, Audacity, Enjoyment?

---

### 3. Resilience Agent

**Function:** `triggerResilienceSupport`

Specialized agent that activates when users are struggling:

```
Trigger (setback/streak broken) → Gather Context + Past Successes → Structured Support Response
```

**Trigger Types:**
- `task_failed` - User couldn't complete a task
- `streak_broken` - User lost their streak
- `user_reported` - User explicitly shared difficulty
- `inactivity` - User hasn't engaged for days

**Response Structure:**
```json
{
  "validation": "Acknowledges their experience without minimizing",
  "reframe": "Reframes setback as part of growth",
  "reminder": "References their past successes",
  "microAction": {
    "title": "Take 3 deep breaths",
    "description": "Resets nervous system",
    "timeMinutes": 1
  },
  "closingMessage": "Brief encouragement"
}
```

---

### 4. Proactive AI Notifications

**Functions:** `generateProactiveNudge`, `sendAINotifications`

AI generates personalized push notification content based on user state:

**Nudge Types:**
| Type | Trigger | Example |
|------|---------|---------|
| `daily` | Morning check-in | "Good morning, Sarah! Your 5-day streak is glowing." |
| `streak_at_risk` | No activity today, streak > 0 | "Your streak is counting on you today!" |
| `comeback` | 2+ days inactive | "We missed you! One small step?" |
| `celebration` | Hit milestone | "Level 5! You're building something real." |

**Schedule:** Runs at 9 AM, 2 PM, 7 PM UTC

```typescript
// Each notification is uniquely generated
const notification = await openai.chat.completions.create({
  messages: [{
    content: `Generate notification for: ${userName}, ${streak} day streak, ${daysSinceActivity} days inactive...`
  }],
  response_format: { type: 'json_object' }
});
// → { title: "...", body: "...", actionText: "Start" }
```

---

### 5. Smart Task Recommendations

**Function:** `getSmartRecommendation`

Combines rule-based scoring with AI selection:

```
User Behavior Analysis     Rule-Based Scoring        AI Selection
------------------------->------------------------->------------------------->
- 30-day task history     - Recency penalty         - GPT-4o-mini picks best
- Success rates by type   - Type preference boost   - Explains reasoning
- Peak activity hours     - Time-of-day matching    - Personalized tip
- Category preferences    - Variety encouragement   
```

**Opik Integration:**
- Traces include full behavior pattern context
- LLM-as-Judge evaluates: `task_relevance`, `specificity`, `engagement_potential`

---

### 6. Coach Decides (Autonomous Decision-Making)

**Function:** `coachDecides`

When users tap "Let Coach Decide," the AI makes a decision FOR them:

```dart
// User taps button -> AI analyzes context -> AI picks task -> Shows reasoning
```

**Key Features:**
- Full context analysis (streak, time of day, energy alignment, weekly plan)
- Confident decision with detailed reasoning shown to user
- High/Medium confidence indicator
- "Why this task, right now?" explanation

**Opik Integration:**
- Traces include decision context and selected task
- Evaluates: `task_relevance`, `decision_confidence`, `engagement_potential`
- Evaluation scores stored in analytics for performance tracking

---

### 7. Planner Agent (Multi-Step Reasoning with Tool Use)

**Function:** `generateWeeklyPlan`

Uses OpenAI function calling for tool-use pattern:

```typescript
const PLANNER_TOOLS = [
  { name: 'create_milestone', ... },    // Break goal into weekly milestones
  { name: 'create_daily_task', ... },   // Plan specific daily micro-tasks
  { name: 'adjust_difficulty', ... },   // Adapt based on completion rate
];
```

**Agentic Loop:**
1. Analyze user goal and 30-day behavior patterns
2. Create 4 weekly milestones (tool calls)
3. Generate daily tasks for current week (tool calls)
4. Adjust difficulty based on completion rate (tool call)
5. Store reasoning for transparency

---

### 8. Adaptive Replanning (Scheduled Agent)

**Function:** `weeklyReplanningCheck` (Runs every Sunday 8 PM UTC)

```
Completion Rate     Action               Next Week
----------------+------------------+-------------------
< 60%           | Simplify         | Difficulty - 1
60-80%          | Maintain         | Same difficulty
> 80%           | Increase         | Difficulty + 1
```

The system automatically adjusts without user intervention, storing adjustment reasoning in Firestore.

---

## Opik Integration Deep Dive

### Module: `functions/src/opik.ts`

```typescript
// Core integration
import { Opik, Trace } from 'opik';
import { trackOpenAI } from 'opik-openai';

// Singleton client with workspace/project configuration
const opikClient = new Opik({
  apiKey: OPIK_API_KEY,
  workspaceName: OPIK_WORKSPACE,
  projectName: 'easy-mode',
});

// Auto-traced OpenAI client
const openai = trackOpenAI(openai, {
  client: opikClient,
  traceMetadata: { userId, feature: 'coach_decides' },
});
```

### LLM-as-Judge Evaluation Metrics

| Metric | What It Measures | Score Range |
|--------|------------------|-------------|
| `task_relevance` | How well task matches user's stated goal | 1-5 |
| `specificity` | How actionable and specific the response is | 1-5 |
| `safety` | Whether advice is safe and appropriate | 1-5 |
| `engagement_potential` | How motivating the response is likely to be | 1-5 |
| `decision_confidence` | Quality of reasoning in Coach Decides | 1-5 |

### Evaluation Flow

```typescript
// 1. Create trace for AI operation
const trace = createTrace({
  name: 'coach_decides',
  userId,
  functionName: 'coachDecides',
  input: { userId, timestamp },
  tags: ['coach-decides', 'decision-making'],
});

// 2. Track prompt experiment version
trackPromptExperiment(trace, {
  name: 'coach_decides_experiment',
  version: 'v1',
  systemPrompt,
  userPromptTemplate,
});

// 3. Run LLM-as-Judge evaluations
const evaluationScores = await runEvaluations(openai, [
  { config: EVALUATION_PROMPTS.taskRelevance, variables: {...} },
  { config: EVALUATION_PROMPTS.decisionConfidence, variables: {...} },
  { config: EVALUATION_PROMPTS.engagementPotential, variables: {...} },
]);

// 4. End trace with output and scores
await endTrace(trace, { selectedTask, coachDecision }, evaluationScores);

// 5. Flush before Cloud Function terminates
await flushOpik();
```

### Experiment Comparison Reports

**Function:** `generateExperimentReport`

Generates data-driven insights:
- Average scores by prompt version
- Score distribution (min, max, stdDev)
- Best performing versions by event type
- Actionable recommendations

```json
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
    "coach_decides: High variance in decision_confidence (stdDev: 1.2) - consider making prompt more consistent"
  ],
  "bestPerformers": { "coach_decides": "v1", "daily_insight": "v1" }
}
```

---

## XP & Gamification System

### XP Economy

| Action | Base XP | Streak Bonus |
|--------|---------|--------------|
| Complete daily task | 100 | +10% per day (day 3+, max 50%) |
| Attempt audacity script | 200 | +10% per day |
| Audacity success bonus | +100 | +10% per day |
| Complete joy ritual | 100 | +10% per day |

**Leveling:** 500 XP per level

### Badges

| Badge | Trigger |
|-------|---------|
| First Step | Complete first task |
| Bold Beginner | First audacity attempt |
| Level 5/10/25/50 | Reach level milestone |
| Streak badges | 3/7/14/30 day streaks |

---

## Getting Started

### Prerequisites

- Flutter 3.16+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Node.js 20+ (for Cloud Functions)
- Firebase CLI (`npm install -g firebase-tools`)
- Opik account ([Get API Key](https://www.comet.com/site/products/opik/))

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/easy-mode.git
   cd easy-mode
   ```

2. **Configure Firebase**
   ```bash
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   cd functions && npm install && cd ..
   ```

4. **Set up environment variables**
   ```bash
   cd functions
   cp .env.example .env
   # Edit .env with your keys:
   # OPENAI_API_KEY=sk-...
   # OPIK_API_KEY=...
   # OPIK_WORKSPACE=your-workspace
   # OPIK_PROJECT=easy-mode
   ```

5. **Seed Firestore**
   ```bash
   cd scripts
   node seed_firestore.js
   ```

6. **Deploy Cloud Functions**
   ```bash
   cd functions
   npm run build
   firebase deploy --only functions
   ```

7. **Run the app**
   ```bash
   flutter run
   ```

---

## Running Tests

### Flutter Tests
```bash
flutter test
flutter test --coverage
```

### Cloud Functions Tests
```bash
cd functions
npm test
```

### Opik Observability Tests
Generate real AI traces with LLM-as-Judge evaluations:
```bash
cd scripts
npm install dotenv opik opik-openai openai
node test_opik_observability.js  # Basic test (5 scenarios)
node test_opik_advanced.js       # Advanced test (8 scenarios)
```

**Test Results Summary:**
| Test Suite | Scenarios | Pass Rate | Avg Relevance | Avg Specificity |
|------------|-----------|-----------|---------------|-----------------|
| Basic | 5 | 100% | 5.0/5 | 4.2/5 |
| Advanced | 8 | 100% | 5.0/5 | 4.4/5 |

View traces at: https://www.comet.com/opik/ravikiran/easy-mode/traces

See [docs/OPIK_INTEGRATION.md](docs/OPIK_INTEGRATION.md) for detailed test results.

---

## Opik Dashboard Screenshots

### Trace View
![Opik Trace View](docs/screenshots/opik-trace.png)
*Full trace with input, output, and evaluation scores*

### Experiment Comparison
![Experiment Comparison](docs/screenshots/opik-experiments.png)
*Prompt version comparison with metrics*

### LLM-as-Judge Scores
![Evaluation Scores](docs/screenshots/opik-scores.png)
*Feedback scores attached to each trace*

---

## Data Model

### Firestore Collections

| Collection | Description |
|------------|-------------|
| `users/{uid}` | User profile, XP, level, streak |
| `users/{uid}/userTasks` | Completed task records |
| `users/{uid}/userScripts` | Audacity script attempts |
| `users/{uid}/userRituals` | Ritual completions |
| `users/{uid}/weeklyPlans` | AI-generated weekly plans |
| `users/{uid}/memories` | **RAG memory store** (achievements, setbacks, insights, preferences) |
| `tasks` | Task templates |
| `scripts` | Audacity scripts |
| `rituals` | Joy rituals |
| `badges` | Badge definitions |
| `analytics` | Event logs with evaluation scores |
| `experimentReports` | Generated experiment comparison reports |

---

## Key Differentiators

### vs. Generic Habit Trackers
- **AI Personalization**: Tasks adapt to your behavior patterns
- **Agentic Planning**: The coach creates your weekly plan autonomously
- **Coach Decides**: Let AI pick for you when you're overwhelmed
- **Conversational Memory**: The AI remembers your past achievements and struggles

### vs. Other AI Apps
- **Full Observability**: Every AI decision is traced and evaluated with Opik
- **LLM-as-Judge**: Automatic quality scoring on all 14 AI functions
- **Self-Reflection**: AI critiques and improves its own outputs before responding
- **RAG Memory System**: Retrieval-augmented generation for personalized context
- **Experiment Tracking**: Prompt versions compared with data-driven insights
- **Adaptive Learning**: System autonomously adjusts difficulty without user input
- **Resilience Agent**: Specialized support when users are struggling

---

## Cost Estimates

| Operation | Model | Est. Cost |
|-----------|-------|-----------|
| Task Personalization | gpt-4o-mini | ~$0.0005 |
| Daily Insight | gpt-4o-mini | ~$0.0004 |
| Smart Recommendation | gpt-4o-mini | ~$0.0008 |
| Coach Decides | gpt-4o-mini | ~$0.001 |
| Chat with Coach (RAG + Reflection) | gpt-4o-mini | ~$0.002 |
| Resilience Support | gpt-4o-mini | ~$0.001 |
| Proactive Nudge | gpt-4o-mini | ~$0.0003 |
| Weekly Plan (with tools) | gpt-4o-mini | ~$0.003 |
| LLM-as-Judge (per eval) | gpt-4o-mini | ~$0.0002 |
| **Per user per day** | | **~$0.008** |

---

## Team

- **[Your Name]** - Full Stack Developer

---

## License

MIT License - see [LICENSE](LICENSE)

---

## Acknowledgments

- Built for **Commit to Change: An AI Agents Hackathon** by Encode Club
- Powered by [Opik](https://www.comet.com/site/products/opik/) for AI observability
- Inspired by principles of habit formation and positive psychology

---

## Links

- [Demo Video](https://youtube.com/...)
- [Live App](https://easymode.app)
- [Opik Dashboard](https://www.comet.com/opik/ravikiran/easy-mode/traces)
- [GitHub Repository](https://github.com/...)
