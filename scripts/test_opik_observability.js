/**
 * Opik Observability Test Script
 * 
 * This script generates AI traces using Opik to demonstrate observability features.
 * Run this to populate your Opik dashboard with traces for evaluation and analysis.
 * 
 * Usage:
 *   cd scripts
 *   node test_opik_observability.js
 */

const { Opik } = require('opik');
const { trackOpenAI } = require('opik-openai');
const OpenAI = require('openai').default;
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../functions/.env') });

// Configuration
const OPIK_API_KEY = process.env.OPIK_API_KEY;
const OPIK_WORKSPACE = process.env.OPIK_WORKSPACE || 'default';
const OPIK_PROJECT = process.env.OPIK_PROJECT || 'easy-mode';
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

if (!OPIK_API_KEY || !OPENAI_API_KEY) {
  console.error('Missing required environment variables. Check functions/.env');
  console.error('Required: OPIK_API_KEY, OPENAI_API_KEY');
  process.exit(1);
}

console.log('=== Opik Observability Test ===\n');
console.log(`Opik Workspace: ${OPIK_WORKSPACE}`);
console.log(`Opik Project: ${OPIK_PROJECT}`);
console.log('');

// Initialize Opik client
const opikClient = new Opik({
  apiKey: OPIK_API_KEY,
  workspaceName: OPIK_WORKSPACE,
  projectName: OPIK_PROJECT,
});

// Get tracked OpenAI client
const rawOpenai = new OpenAI({ apiKey: OPENAI_API_KEY });
const openai = trackOpenAI(rawOpenai, {
  client: opikClient,
  traceMetadata: { test: true, source: 'observability-test-script' },
});

// Test scenarios to generate diverse traces
const TEST_SCENARIOS = [
  {
    name: 'personalize_task',
    description: 'Task personalization for user',
    systemPrompt: `You are Easy Mode, an AI life coach focused on building confidence through Action, Audacity, and Enjoyment.`,
    userPrompt: `Personalize this task for the user:
TASK: Practice saying "no" to one small request
USER CONTEXT:
- Name: Alex
- Current streak: 5 days
- Level: 3
- Goal: Build assertiveness
- Pain point: Can't say no to people
Respond in JSON format with: personalizedDescription, coachTip, motivationalNote`,
    tags: ['task-personalization', 'action'],
  },
  {
    name: 'daily_insight',
    description: 'Daily insight generation',
    systemPrompt: `You are Easy Mode, an AI life coach. Generate a personalized daily insight.`,
    userPrompt: `Generate a daily insight for this user:
USER STATS:
- Name: Sam
- Level: 7
- XP Total: 3500
- Current streak: 12 days
- Goal: Speak up in meetings
RECENT ACTIVITY:
- Tasks completed: 8 in last 7 days
- Task types: action, action, audacity, action
Today is Saturday, February 8.
Respond in JSON format with: greeting, insight, todayFocus, encouragement`,
    tags: ['daily-insight'],
  },
  {
    name: 'coach_decides',
    description: 'Coach decides task selection',
    systemPrompt: `You are the Easy Mode AI Coach. The user has asked you to DECIDE what they should do right now.`,
    userPrompt: `Make a decision for this user about what they should do RIGHT NOW.
USER CONTEXT:
- Name: Jordan
- Level: 5 (2500 XP)
- Current streak: 7 days
- Goal: Build social confidence
- Pain point: Anxiety in new situations
BEHAVIOR ANALYSIS (Last 30 days):
- Total tasks completed: 28
- Success rate: Action 85%, Audacity 60%, Enjoy 90%
- Peak activity hour: 9:00
CURRENT MOMENT:
- Day: Saturday
- Time: morning (9:00)
- Tasks completed today: 0
TOP TASK CANDIDATES:
1. [Score: 85] Start a conversation with a stranger (audacity, 5min)
2. [Score: 78] Journal for 5 minutes (action, 5min)
3. [Score: 75] Take a mindful walk (enjoy, 10min)
Respond in JSON format with: decision (taskId, taskTitle, taskType), reasoning (headline, whyNow, expectedOutcome, confidenceLevel), coachMessage`,
    tags: ['coach-decides', 'decision-making'],
  },
  {
    name: 'smart_recommendation',
    description: 'Smart task recommendation based on behavior',
    systemPrompt: `You are Easy Mode, an AI life coach. Select the most impactful task for the user RIGHT NOW.`,
    userPrompt: `Select the best task for this user:
USER PROFILE:
- Name: Riley
- Level: 10
- Streak: 21 days
- Goal: Overcome procrastination
- Challenge: Starting tasks feels overwhelming
BEHAVIOR PATTERNS:
- Total tasks completed: 65
- Preferred types: {"action": 40, "audacity": 15, "enjoy": 10}
- Success rates: {"action": 0.88, "audacity": 0.73, "enjoy": 0.95}
- Peak activity hour: 14:00
CANDIDATE TASKS:
1. [Score: 92] 2-minute rule: Do one tiny task immediately (action, 2min)
2. [Score: 85] Set a timer and work for 10 minutes (action, 10min)
3. [Score: 80] Reward yourself before starting (enjoy, 5min)
4. [Score: 75] Tell someone your goal today (audacity, 3min)
Respond in JSON format with: selectedTaskId, whyThisTask, expectedImpact, personalizedTip`,
    tags: ['smart-recommendation'],
  },
  {
    name: 'weekly_plan_reasoning',
    description: 'Weekly plan generation reasoning',
    systemPrompt: `You are the Easy Mode Planner Agent. Your role is to create a personalized weekly plan for building confidence.`,
    userPrompt: `Create a plan for this user:
USER CONTEXT:
- Goal: Build confidence in public speaking
- Pain point: Voice shakes when presenting
- Daily time available: 15 minutes
- Current week: 2 of 4
- Past completion rate: 75%
What are your 4 weekly milestones, and what should the user do each day of week 2?
Respond in JSON format with: milestones (array of 4), dailyTasks (array of 7 for week 2), adjustmentRecommendation`,
    tags: ['weekly-plan', 'multi-step-reasoning'],
  },
];

// LLM-as-Judge evaluation prompts
const EVALUATION_PROMPTS = {
  taskRelevance: {
    name: 'task_relevance',
    prompt: `Evaluate the relevance of this AI coaching response to the user's goal.
Score from 1-5 where:
1 = Completely irrelevant
2 = Slightly related
3 = Somewhat relevant
4 = Good relevance
5 = Highly relevant

Response: {{response}}
User Goal: {{goal}}

Respond with only a number 1-5.`,
  },
  specificity: {
    name: 'specificity',
    prompt: `Evaluate how specific and actionable this AI coaching response is.
Score from 1-5 where:
1 = Very vague
2 = Somewhat generic
3 = Moderately specific
4 = Specific with clear actions
5 = Highly specific and immediately actionable

Response: {{response}}

Respond with only a number 1-5.`,
  },
  engagementPotential: {
    name: 'engagement_potential',
    prompt: `Evaluate how engaging and motivating this response is likely to be.
Score from 1-5 where:
1 = Boring, unlikely to motivate
2 = Mildly interesting
3 = Moderately engaging
4 = Engaging and likely to prompt action
5 = Highly engaging and inspiring

Response: {{response}}

Respond with only a number 1-5.`,
  },
};

/**
 * Run LLM-as-Judge evaluation
 */
async function evaluateResponse(response, evaluationConfig, variables) {
  let prompt = evaluationConfig.prompt;
  for (const [key, value] of Object.entries(variables)) {
    prompt = prompt.replace(new RegExp(`{{${key}}}`, 'g'), value);
  }

  try {
    const evalResponse = await rawOpenai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You are an evaluation assistant. Respond only with a numeric score.' },
        { role: 'user', content: prompt },
      ],
      temperature: 0,
      max_tokens: 10,
    });

    const raw = evalResponse.choices[0]?.message?.content || '';
    const score = parseInt(raw.trim(), 10);
    return { score: isNaN(score) ? 3 : Math.max(1, Math.min(5, score)), raw };
  } catch (error) {
    console.error('Evaluation error:', error.message);
    return { score: 3, raw: 'error' };
  }
}

/**
 * Run a single test scenario with Opik tracing
 */
async function runTestScenario(scenario, index) {
  console.log(`\n[${index + 1}/${TEST_SCENARIOS.length}] Running: ${scenario.name}`);
  console.log(`   Description: ${scenario.description}`);

  // Create trace
  const trace = opikClient.trace({
    name: scenario.name,
    input: { scenario: scenario.description, userPrompt: scenario.userPrompt.substring(0, 200) + '...' },
    metadata: {
      source: 'test-script',
      testRun: true,
      promptVersion: 'v1',
      timestamp: new Date().toISOString(),
    },
    tags: ['easy-mode', 'test', ...scenario.tags],
  });

  try {
    // Make AI call with tracked OpenAI client
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: scenario.systemPrompt },
        { role: 'user', content: scenario.userPrompt },
      ],
      temperature: 0.7,
      max_tokens: 500,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0]?.message?.content;
    console.log(`   Response received (${response.usage?.total_tokens} tokens)`);

    // Run evaluations
    const evaluations = [];
    
    const relevanceScore = await evaluateResponse(content, EVALUATION_PROMPTS.taskRelevance, {
      response: content,
      goal: 'Build confidence and overcome challenges',
    });
    evaluations.push({ name: 'task_relevance', value: relevanceScore.score, reason: `LLM eval: ${relevanceScore.raw}` });

    const specificityScore = await evaluateResponse(content, EVALUATION_PROMPTS.specificity, {
      response: content,
    });
    evaluations.push({ name: 'specificity', value: specificityScore.score, reason: `LLM eval: ${specificityScore.raw}` });

    const engagementScore = await evaluateResponse(content, EVALUATION_PROMPTS.engagementPotential, {
      response: content,
    });
    evaluations.push({ name: 'engagement_potential', value: engagementScore.score, reason: `LLM eval: ${engagementScore.raw}` });

    console.log(`   Evaluations: relevance=${relevanceScore.score}, specificity=${specificityScore.score}, engagement=${engagementScore.score}`);

    // Update trace with output and scores
    trace.update({
      output: {
        response: JSON.parse(content),
        tokensUsed: response.usage?.total_tokens,
        model: 'gpt-4o-mini',
      },
      metadata: {
        promptVersion: 'v1',
        experimentName: `${scenario.name}_experiment`,
      },
    });

    // Add feedback scores
    for (const evaluation of evaluations) {
      trace.score(evaluation);
    }

    trace.end();
    console.log(`   Trace completed with ${evaluations.length} feedback scores`);

    return { success: true, response: content, evaluations };

  } catch (error) {
    console.error(`   Error: ${error.message}`);
    
    trace.update({
      output: { error: error.message, success: false },
    });
    trace.end();

    return { success: false, error: error.message };
  }
}

/**
 * Main test runner
 */
async function runAllTests() {
  console.log('\nStarting Opik observability tests...');
  console.log(`Running ${TEST_SCENARIOS.length} test scenarios\n`);
  console.log('-------------------------------------------');

  const results = [];

  for (let i = 0; i < TEST_SCENARIOS.length; i++) {
    const result = await runTestScenario(TEST_SCENARIOS[i], i);
    results.push({ scenario: TEST_SCENARIOS[i].name, ...result });
    
    // Small delay between requests
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  // Flush all Opik data
  console.log('\n-------------------------------------------');
  console.log('\nFlushing Opik data...');
  
  try {
    await Promise.race([
      Promise.all([
        opikClient.traceBatchQueue.flush(),
        opikClient.spanBatchQueue.flush(),
        opikClient.traceFeedbackScoresBatchQueue.flush(),
        opikClient.spanFeedbackScoresBatchQueue.flush(),
      ]),
      new Promise((_, reject) => setTimeout(() => reject(new Error('Flush timeout')), 10000)),
    ]);
    console.log('Opik data flushed successfully!');
  } catch (error) {
    console.error('Warning: Opik flush failed:', error.message);
  }

  // Also flush the tracked OpenAI client
  try {
    await openai.flush();
    console.log('OpenAI tracker flushed successfully!');
  } catch (error) {
    console.error('Warning: OpenAI tracker flush failed:', error.message);
  }

  // Summary
  console.log('\n===========================================');
  console.log('TEST SUMMARY');
  console.log('===========================================\n');

  const successful = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;

  console.log(`Total scenarios: ${results.length}`);
  console.log(`Successful: ${successful}`);
  console.log(`Failed: ${failed}`);

  console.log('\nDetailed Results:');
  for (const result of results) {
    const status = result.success ? '[OK]' : '[FAIL]';
    console.log(`  ${status} ${result.scenario}`);
    if (result.evaluations) {
      const scores = result.evaluations.map(e => `${e.name}=${e.value}`).join(', ');
      console.log(`        Scores: ${scores}`);
    }
    if (result.error) {
      console.log(`        Error: ${result.error}`);
    }
  }

  console.log('\n===========================================');
  console.log('OPIK DASHBOARD');
  console.log('===========================================\n');
  console.log(`View your traces at:`);
  console.log(`  https://www.comet.com/opik/${OPIK_WORKSPACE}/${OPIK_PROJECT}/traces`);
  console.log(`\nOr search for traces in the Opik dashboard with:`);
  console.log(`  Project: ${OPIK_PROJECT}`);
  console.log(`  Tags: test, easy-mode`);
  console.log('\nThe following data is now available in Opik:');
  console.log('  - Full traces for each AI operation');
  console.log('  - Input/output for each LLM call');
  console.log('  - LLM-as-Judge evaluation scores');
  console.log('  - Prompt versions for experiment tracking');
  console.log('  - Token usage and latency metrics');
  console.log('\n===========================================\n');
}

// Run tests
runAllTests()
  .then(() => {
    console.log('Test script completed!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Test script failed:', error);
    process.exit(1);
  });
