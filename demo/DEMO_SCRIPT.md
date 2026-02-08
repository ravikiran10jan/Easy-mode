# Easy Mode - Demo Script (90 seconds)

> **Commit to Change: An AI Agents Hackathon**  
> Categories: Productivity & Work Habits | Personal Growth & Learning | Best Use of Opik

---

## Video Recording Checklist

Before recording:
- [ ] Fresh app install or cleared data
- [ ] Good lighting and stable device
- [ ] Notifications enabled
- [ ] Sound on for completion celebrations
- [ ] Opik dashboard open in browser (for observability demo)

---

## Demo Flow

### Scene 1: Hook (5 seconds)

**Screen:** Logo/splash with tagline

**Script:**
> "90% of New Year's resolutions fail. Easy Mode makes them stick."

---

### Scene 2: Onboarding (15 seconds)

**Show:** Quick onboarding flow

**Script:**
> "Easy Mode personalizes your experience from day one. What does 'Easy Mode' look like for you?"

**Action:**
1. Select 2-3 aspirations (e.g., "I speak up for what I want", "I take action without overthinking")
2. Choose intent: "I want to be bolder in my asks"
3. Set time: "10 minutes per day"
4. Tap "Let's Go"

---

### Scene 3: Home - Daily Task (20 seconds)

**Show:** Home screen with AI-recommended task

**Script:**
> "Every day, you get one 'Easy Mode Moment' - a micro-task tailored to YOUR behavior patterns. The AI analyzes your history to pick the perfect challenge."

**Action:**
1. Point to XP bar and streak counter
2. Show task card with personalized description
3. Tap "Start Now" 
4. Quick timer view
5. Tap "Done!"
6. Show confetti celebration + XP earned

> "100 XP earned. Small wins, big confidence."

---

### Scene 4: Coach Decides - Agentic AI (20 seconds)

**Show:** "Let Coach Decide" button → Decision sheet

**Script:**
> "Feeling overwhelmed? Let the AI coach decide FOR you. It analyzes your streak, time of day, energy levels, and 30 days of behavior data."

**Action:**
1. Tap "Let Coach Decide" button
2. Show loading state
3. Reveal decision sheet:
   - Headline decision
   - "Why this task, right now?" reasoning
   - Confidence level badge
   - Context pills (streak, time of day, peak energy)
4. Show coach message

> "Full transparency. You see exactly WHY the AI made this choice."

---

### Scene 5: Audacity Scripts (10 seconds)

**Show:** Scripts library

**Script:**
> "Ready to be bolder? Audacity Scripts give you word-for-word templates for asking what you want. Even a 'no' earns XP - because trying is what matters."

**Action:**
1. Show script categories with risk levels
2. Quick tap on one script

---

### Scene 6: Opik Observability (15 seconds)

**Show:** Opik dashboard (split screen or browser)

**Script:**
> "Under the hood, every AI decision is traced and evaluated. We use Opik with LLM-as-Judge to score every response on relevance, specificity, engagement, and safety."

**Action:**
1. Show trace list in Opik
2. Click on one trace
3. Point out:
   - Input/output
   - Evaluation scores (4.2/5 relevance, etc.)
   - Prompt version tracking
4. Show experiment comparison (if time)

> "This lets us systematically improve our prompts with real data."

---

### Scene 7: Wrap-up (5 seconds)

**Show:** Progress screen with badges

**Script:**
> "Easy Mode - because confidence is built one small action at a time."

**Action:** Show XP bar, level, and badge collection

---

## Key Talking Points (for Q&A)

### Productivity & Work Habits
1. **Micro-habits**: 5-10 minute daily tasks, not overwhelming goals
2. **Three Principles**: Action, Audacity, Enjoyment
3. **XP System**: Gamified with streak bonuses (up to 50% extra XP)
4. **Adaptive Difficulty**: System simplifies or increases based on completion rate

### Personal Growth & Learning
1. **Emotional Growth**: Overcoming self-doubt through daily micro-wins
2. **Skill Development**: Audacity Scripts teach assertiveness with word-for-word templates
3. **Aspiration-Based Identity**: Users define who they want to become, not just what they want to do
4. **Resilience Training**: "I couldn't do it" flows teach constructive setback handling
5. **Tangible Progress**: XP/levels make personal development feel rewarding

### Best Use of Opik
1. **Full Tracing**: Every AI call traced with user context
2. **LLM-as-Judge**: 5 evaluation metrics (task_relevance, specificity, safety, engagement_potential, decision_confidence)
3. **Experiment Tracking**: Prompt versions tracked with content hashes
4. **Data-Driven Improvement**: Experiment reports compare prompt versions
5. **Production-Ready**: Proper flushing with timeout protection in Cloud Functions

### Technical Stack
- Flutter 3.16+ (cross-platform mobile)
- Firebase (Auth, Firestore, Cloud Functions, FCM)
- OpenAI GPT-4o-mini (cost-effective, ~$0.005/user/day)
- Opik (observability, evaluation)
- 6 AI-powered Cloud Functions with multi-step reasoning

---

## Screenshots to Capture

1. Welcome screen
2. Onboarding - aspiration selection
3. Home with AI-recommended task
4. Task completion celebration
5. **Coach Decides** decision sheet (KEY SHOT)
6. Audacity scripts library
7. Progress screen with badges
8. **Opik trace view** with evaluation scores (KEY SHOT)
9. Opik experiment comparison (optional)

---

## B-Roll Suggestions

- Typing on phone
- Celebrating small win
- Opik dashboard scrolling
- Code scrolling (opik.ts, index.ts)

---

## Backup Plans

**If AI is slow:**
> "The AI is thinking... In production, we have intelligent fallbacks that provide a great experience even if the AI takes a moment."

**If Opik dashboard won't load:**
> "Every trace is stored and evaluated. Here's an example of what we track..." (show code)

---

## Demo Credentials

- Email: `demo@easymode.app`
- Password: `demo123!`

---

## Time Breakdown

| Scene | Time | Cumulative |
|-------|------|------------|
| Hook | 5s | 5s |
| Onboarding | 15s | 20s |
| Daily Task | 20s | 40s |
| Coach Decides | 20s | 60s |
| Audacity | 10s | 70s |
| Opik Demo | 15s | 85s |
| Wrap-up | 5s | 90s |
