/**
 * Opik Advanced Observability Test Script
 * 
 * This script generates more advanced AI traces demonstrating edge cases,
 * error handling, and diverse scenarios for Opik observability.
 * 
 * Usage:
 *   cd scripts
 *   node test_opik_advanced.js
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

console.log('=== Opik Advanced Observability Test ===\n');

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
  traceMetadata: { test: true, source: 'advanced-test-script' },
});

// Advanced test scenarios - testing prompt variations for A/B testing
const PROMPT_VARIATIONS = [
  {
    name: 'coach_message_v1_formal',
    promptVersion: 'v1-formal',
    systemPrompt: `You are Easy Mode, a professional life coach. Maintain a formal, supportive tone.`,
    userPrompt: `Write a motivational message for a user who just completed their 7-day streak.
User: Alex, Level 5
Goal: Improve public speaking
Respond in JSON with: message, celebration, nextChallenge`,
    tags: ['prompt-experiment', 'formal-tone'],
  },
  {
    name: 'coach_message_v2_casual',
    promptVersion: 'v2-casual',
    systemPrompt: `You are Easy Mode, a fun and energetic life coach. Use casual, friendly language with occasional humor.`,
    userPrompt: `Write a motivational message for a user who just completed their 7-day streak.
User: Alex, Level 5
Goal: Improve public speaking
Respond in JSON with: message, celebration, nextChallenge`,
    tags: ['prompt-experiment', 'casual-tone'],
  },
  {
    name: 'coach_message_v3_encouraging',
    promptVersion: 'v3-encouraging',
    systemPrompt: `You are Easy Mode, an empathetic and deeply encouraging life coach. Focus on emotional support and validation.`,
    userPrompt: `Write a motivational message for a user who just completed their 7-day streak.
User: Alex, Level 5
Goal: Improve public speaking
Respond in JSON with: message, celebration, nextChallenge`,
    tags: ['prompt-experiment', 'encouraging-tone'],
  },
];

// Scenarios with different user contexts for testing adaptability
const USER_CONTEXT_TESTS = [
  {
    name: 'new_user_recommendation',
    description: 'Recommendation for new user (no history)',
    context: {
      userName: 'NewUser',
      level: 1,
      streak: 0,
      tasksCompleted: 0,
      goal: 'Get started with healthy habits',
    },
    tags: ['user-segment', 'new-user'],
  },
  {
    name: 'struggling_user_recommendation',
    description: 'Recommendation for struggling user (broken streak)',
    context: {
      userName: 'StrugglingUser',
      level: 3,
      streak: 0,
      previousStreak: 14,
      tasksCompleted: 25,
      completionRate: 45,
      goal: 'Build consistency',
    },
    tags: ['user-segment', 'struggling-user'],
  },
  {
    name: 'power_user_recommendation',
    description: 'Recommendation for power user (high engagement)',
    context: {
      userName: 'PowerUser',
      level: 25,
      streak: 45,
      tasksCompleted: 180,
      completionRate: 95,
      goal: 'Push beyond comfort zone',
    },
    tags: ['user-segment', 'power-user'],
  },
];

// Edge case tests
const EDGE_CASE_TESTS = [
  {
    name: 'minimal_input_handling',
    description: 'Testing with minimal input',
    systemPrompt: `You are Easy Mode. Help the user.`,
    userPrompt: `Task: Help
User: Someone
Respond in JSON with: suggestion`,
    tags: ['edge-case', 'minimal-input'],
  },
  {
    name: 'complex_goal_handling',
    description: 'Testing with complex multi-part goal',
    systemPrompt: `You are Easy Mode, an AI life coach.`,
    userPrompt: `Generate a task for this user:
Goal: I want to improve my work-life balance while also learning to code, getting in better shape, improving my relationships, and finding more meaning in my daily life. I struggle with time management and often feel overwhelmed.
Respond in JSON with: focusArea, prioritizedTask, reasoning`,
    tags: ['edge-case', 'complex-goal'],
  },
];

/**
 * Run LLM-as-Judge evaluation
 */
async function evaluateResponse(response, metric) {
  const prompts = {
    task_relevance: `Score 1-5 how relevant this response is to user goals. Response: ${response}. Reply with just a number.`,
    specificity: `Score 1-5 how specific and actionable this response is. Response: ${response}. Reply with just a number.`,
    engagement: `Score 1-5 how engaging and motivating this response is. Response: ${response}. Reply with just a number.`,
    tone_appropriateness: `Score 1-5 how appropriate the tone is for a coaching app. Response: ${response}. Reply with just a number.`,
    safety: `Score 1-5 how safe and appropriate this coaching advice is. Response: ${response}. Reply with just a number.`,
  };

  try {
    const evalResponse = await rawOpenai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You are an evaluation assistant. Respond only with a numeric score 1-5.' },
        { role: 'user', content: prompts[metric] },
      ],
      temperature: 0,
      max_tokens: 5,
    });
    const score = parseInt(evalResponse.choices[0]?.message?.content?.trim(), 10);
    return isNaN(score) ? 3 : Math.max(1, Math.min(5, score));
  } catch (error) {
    return 3;
  }
}

/**
 * Run prompt variation test
 */
async function runPromptVariationTest(variation, index, total) {
  console.log(`\n[${index + 1}/${total}] Prompt Experiment: ${variation.name}`);
  console.log(`   Version: ${variation.promptVersion}`);

  const trace = opikClient.trace({
    name: variation.name,
    input: { userPrompt: variation.userPrompt },
    metadata: {
      source: 'advanced-test-script',
      experimentType: 'prompt-variation',
      promptVersion: variation.promptVersion,
      timestamp: new Date().toISOString(),
    },
    tags: ['easy-mode', 'experiment', ...variation.tags],
  });

  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: variation.systemPrompt },
        { role: 'user', content: variation.userPrompt },
      ],
      temperature: 0.7,
      max_tokens: 300,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0]?.message?.content;
    console.log(`   Response received (${response.usage?.total_tokens} tokens)`);

    // Run evaluations
    const evaluations = [
      { name: 'task_relevance', value: await evaluateResponse(content, 'task_relevance') },
      { name: 'specificity', value: await evaluateResponse(content, 'specificity') },
      { name: 'engagement_potential', value: await evaluateResponse(content, 'engagement') },
      { name: 'tone_appropriateness', value: await evaluateResponse(content, 'tone_appropriateness') },
    ];

    console.log(`   Scores: ${evaluations.map(e => `${e.name}=${e.value}`).join(', ')}`);

    trace.update({
      output: { response: JSON.parse(content), tokensUsed: response.usage?.total_tokens },
      metadata: { promptVersion: variation.promptVersion },
    });

    for (const evaluation of evaluations) {
      trace.score(evaluation);
    }

    trace.end();
    return { success: true, evaluations };
  } catch (error) {
    console.error(`   Error: ${error.message}`);
    trace.update({ output: { error: error.message } });
    trace.end();
    return { success: false, error: error.message };
  }
}

/**
 * Run user context test
 */
async function runUserContextTest(test, index, total) {
  console.log(`\n[${index + 1}/${total}] User Context: ${test.name}`);
  console.log(`   Description: ${test.description}`);

  const trace = opikClient.trace({
    name: test.name,
    input: { context: test.context },
    metadata: {
      source: 'advanced-test-script',
      experimentType: 'user-context',
      userLevel: test.context.level,
      userStreak: test.context.streak,
      timestamp: new Date().toISOString(),
    },
    tags: ['easy-mode', 'user-context', ...test.tags],
  });

  const userPrompt = `Generate a personalized task recommendation for this user:
User: ${test.context.userName}
Level: ${test.context.level}
Streak: ${test.context.streak} days
${test.context.previousStreak ? `Previous streak: ${test.context.previousStreak} days` : ''}
Tasks completed: ${test.context.tasksCompleted}
${test.context.completionRate ? `Completion rate: ${test.context.completionRate}%` : ''}
Goal: ${test.context.goal}

Respond in JSON with: recommendedTask, reasoning, difficultyLevel, encouragement`;

  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You are Easy Mode, an AI life coach. Adapt your recommendations to the user\'s experience level and current situation.' },
        { role: 'user', content: userPrompt },
      ],
      temperature: 0.7,
      max_tokens: 400,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0]?.message?.content;
    console.log(`   Response received (${response.usage?.total_tokens} tokens)`);

    const evaluations = [
      { name: 'task_relevance', value: await evaluateResponse(content, 'task_relevance') },
      { name: 'specificity', value: await evaluateResponse(content, 'specificity') },
      { name: 'engagement_potential', value: await evaluateResponse(content, 'engagement') },
    ];

    console.log(`   Scores: ${evaluations.map(e => `${e.name}=${e.value}`).join(', ')}`);

    trace.update({
      output: { response: JSON.parse(content), tokensUsed: response.usage?.total_tokens },
    });

    for (const evaluation of evaluations) {
      trace.score(evaluation);
    }

    trace.end();
    return { success: true, evaluations };
  } catch (error) {
    console.error(`   Error: ${error.message}`);
    trace.update({ output: { error: error.message } });
    trace.end();
    return { success: false, error: error.message };
  }
}

/**
 * Run edge case test
 */
async function runEdgeCaseTest(test, index, total) {
  console.log(`\n[${index + 1}/${total}] Edge Case: ${test.name}`);
  console.log(`   Description: ${test.description}`);

  const trace = opikClient.trace({
    name: test.name,
    input: { userPrompt: test.userPrompt },
    metadata: {
      source: 'advanced-test-script',
      experimentType: 'edge-case',
      timestamp: new Date().toISOString(),
    },
    tags: ['easy-mode', 'edge-case', ...test.tags],
  });

  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: test.systemPrompt },
        { role: 'user', content: test.userPrompt },
      ],
      temperature: 0.7,
      max_tokens: 400,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0]?.message?.content;
    console.log(`   Response received (${response.usage?.total_tokens} tokens)`);

    const evaluations = [
      { name: 'task_relevance', value: await evaluateResponse(content, 'task_relevance') },
      { name: 'safety', value: await evaluateResponse(content, 'safety') },
    ];

    console.log(`   Scores: ${evaluations.map(e => `${e.name}=${e.value}`).join(', ')}`);

    trace.update({
      output: { response: JSON.parse(content), tokensUsed: response.usage?.total_tokens },
    });

    for (const evaluation of evaluations) {
      trace.score(evaluation);
    }

    trace.end();
    return { success: true, evaluations };
  } catch (error) {
    console.error(`   Error: ${error.message}`);
    trace.update({ output: { error: error.message } });
    trace.end();
    return { success: false, error: error.message };
  }
}

/**
 * Main test runner
 */
async function runAllTests() {
  console.log('\nRunning advanced observability tests...\n');
  console.log('===========================================');
  console.log('PART 1: PROMPT VARIATION EXPERIMENTS (A/B Testing)');
  console.log('===========================================');

  for (let i = 0; i < PROMPT_VARIATIONS.length; i++) {
    await runPromptVariationTest(PROMPT_VARIATIONS[i], i, PROMPT_VARIATIONS.length);
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  console.log('\n===========================================');
  console.log('PART 2: USER CONTEXT ADAPTATION');
  console.log('===========================================');

  for (let i = 0; i < USER_CONTEXT_TESTS.length; i++) {
    await runUserContextTest(USER_CONTEXT_TESTS[i], i, USER_CONTEXT_TESTS.length);
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  console.log('\n===========================================');
  console.log('PART 3: EDGE CASE HANDLING');
  console.log('===========================================');

  for (let i = 0; i < EDGE_CASE_TESTS.length; i++) {
    await runEdgeCaseTest(EDGE_CASE_TESTS[i], i, EDGE_CASE_TESTS.length);
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  // Flush all Opik data
  console.log('\n===========================================');
  console.log('Flushing all data to Opik...');

  try {
    await Promise.all([
      opikClient.traceBatchQueue.flush(),
      opikClient.spanBatchQueue.flush(),
      opikClient.traceFeedbackScoresBatchQueue.flush(),
      opikClient.spanFeedbackScoresBatchQueue.flush(),
    ]);
    await openai.flush();
    console.log('All data flushed successfully!');
  } catch (error) {
    console.error('Warning: Flush failed:', error.message);
  }

  console.log('\n===========================================');
  console.log('ADVANCED TEST COMPLETE');
  console.log('===========================================\n');

  const totalTests = PROMPT_VARIATIONS.length + USER_CONTEXT_TESTS.length + EDGE_CASE_TESTS.length;
  console.log(`Total advanced tests run: ${totalTests}`);
  console.log(`  - Prompt Variations: ${PROMPT_VARIATIONS.length}`);
  console.log(`  - User Context Tests: ${USER_CONTEXT_TESTS.length}`);
  console.log(`  - Edge Case Tests: ${EDGE_CASE_TESTS.length}`);

  console.log('\n===========================================');
  console.log('OPIK INSIGHTS NOW AVAILABLE');
  console.log('===========================================\n');
  console.log('In your Opik dashboard, you can now analyze:');
  console.log('');
  console.log('1. PROMPT EXPERIMENT COMPARISON:');
  console.log('   Filter by tag: "prompt-experiment"');
  console.log('   Compare tone_appropriateness scores across v1-formal, v2-casual, v3-encouraging');
  console.log('');
  console.log('2. USER SEGMENT ANALYSIS:');
  console.log('   Filter by tag: "user-segment"');
  console.log('   See how AI adapts to new-user vs struggling-user vs power-user');
  console.log('');
  console.log('3. EDGE CASE ROBUSTNESS:');
  console.log('   Filter by tag: "edge-case"');
  console.log('   Verify safety scores on minimal-input and complex-goal cases');
  console.log('');
  console.log(`Dashboard: https://www.comet.com/opik/${OPIK_WORKSPACE}/${OPIK_PROJECT}/traces`);
  console.log('\n===========================================\n');
}

// Run tests
runAllTests()
  .then(() => {
    console.log('Advanced test script completed!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Advanced test script failed:', error);
    process.exit(1);
  });
