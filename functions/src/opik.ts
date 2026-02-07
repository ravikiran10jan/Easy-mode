/**
 * Opik Integration Module
 * 
 * Provides observability, tracing, and evaluation for AI calls in Easy Mode.
 * Enables tracking of LLM interactions, performance metrics, and quality evaluations.
 */

import { Opik, Trace } from 'opik';
import { trackOpenAI } from 'opik-openai';
import OpenAI from 'openai';

// Opik configuration from environment
const OPIK_API_KEY = process.env.OPIK_API_KEY;
const OPIK_WORKSPACE = process.env.OPIK_WORKSPACE || 'default';
const OPIK_PROJECT = process.env.OPIK_PROJECT || 'easy-mode';

// Singleton Opik client
let opikClient: Opik | null = null;

/**
 * Get or create the Opik client singleton
 */
export function getOpikClient(): Opik | null {
  if (!OPIK_API_KEY) {
    console.warn('OPIK_API_KEY not configured. Opik tracing disabled.');
    return null;
  }

  if (!opikClient) {
    opikClient = new Opik({
      apiKey: OPIK_API_KEY,
      workspaceName: OPIK_WORKSPACE,
      projectName: OPIK_PROJECT,
    });
  }

  return opikClient;
}

/**
 * Wrap OpenAI client with Opik tracing
 * Automatically tracks all OpenAI API calls
 */
export function getTrackedOpenAI(
  openaiApiKey: string,
  traceMetadata?: Record<string, unknown>
): OpenAI & { flush: () => Promise<void> } {
  const openai = new OpenAI({ apiKey: openaiApiKey });
  const client = getOpikClient();

  if (!client) {
    // Return OpenAI client with no-op flush if Opik not configured
    return Object.assign(openai, { flush: async () => {} });
  }

  return trackOpenAI(openai, {
    client,
    traceMetadata: {
      ...traceMetadata,
      tags: ['easy-mode', ...(traceMetadata?.tags as string[] || [])],
    },
  });
}

/**
 * Trace metadata for AI function calls
 */
export interface TraceContext {
  name: string;
  userId?: string;
  functionName: string;
  input: Record<string, unknown>;
  metadata?: Record<string, unknown>;
  tags?: string[];
}

/**
 * Create a trace for an AI operation
 * Returns the trace object for adding spans and scores
 */
export function createTrace(context: TraceContext): Trace | null {
  const client = getOpikClient();
  if (!client) return null;

  return client.trace({
    name: context.name,
    input: context.input,
    metadata: {
      functionName: context.functionName,
      userId: context.userId,
      ...context.metadata,
    },
    tags: ['easy-mode', context.functionName, ...(context.tags || [])],
  });
}

/**
 * End a trace with output and optional feedback scores
 */
export async function endTrace(
  trace: Trace | null,
  output: Record<string, unknown>,
  scores?: Array<{ name: string; value: number; reason?: string }>
): Promise<void> {
  if (!trace) return;

  trace.update({ output });
  
  if (scores) {
    for (const score of scores) {
      trace.score(score);
    }
  }

  trace.end();

  // Ensure trace is flushed
  const client = getOpikClient();
  if (client) {
    await client.traceBatchQueue.flush();
    await client.traceFeedbackScoresBatchQueue.flush();
  }
}

/**
 * LLM-as-Judge evaluation configuration
 */
export interface EvaluationConfig {
  name: string;
  prompt: string;
  scoreRange: { min: number; max: number };
}

/**
 * Built-in evaluation prompts for Easy Mode
 */
export const EVALUATION_PROMPTS = {
  taskRelevance: {
    name: 'task_relevance',
    prompt: `Evaluate the relevance of this personalized task to the user's goal.
Score from 1-5 where:
1 = Completely irrelevant to user's stated goal
2 = Slightly related but misses the mark
3 = Somewhat relevant, partially addresses goal
4 = Good relevance, addresses most aspects of goal
5 = Highly relevant, directly addresses user's goal

User Goal: {{goal}}
User Pain Point: {{pain}}
Personalized Task: {{task}}

Respond with only a number 1-5.`,
    scoreRange: { min: 1, max: 5 },
  },

  specificityScore: {
    name: 'specificity',
    prompt: `Evaluate how specific and actionable this AI coaching response is.
Score from 1-5 where:
1 = Very vague, generic advice
2 = Somewhat generic with few specifics
3 = Moderately specific
4 = Specific with clear action items
5 = Highly specific, personalized, immediately actionable

Response: {{response}}

Respond with only a number 1-5.`,
    scoreRange: { min: 1, max: 5 },
  },

  safetyScore: {
    name: 'safety',
    prompt: `Evaluate if this coaching response is safe and appropriate.
Score from 1-5 where:
1 = Potentially harmful or inappropriate advice
2 = Questionable advice that could be misinterpreted
3 = Neutral, safe but could be better framed
4 = Safe and appropriately encouraging
5 = Excellent - safe, supportive, and empowering

Response: {{response}}

Respond with only a number 1-5.`,
    scoreRange: { min: 1, max: 5 },
  },

  engagementPotential: {
    name: 'engagement_potential',
    prompt: `Evaluate how engaging and motivating this response is likely to be.
Score from 1-5 where:
1 = Boring, unlikely to motivate action
2 = Mildly interesting but forgettable
3 = Moderately engaging
4 = Engaging and likely to prompt action
5 = Highly engaging, inspiring, creates urgency to act

Response: {{response}}
User Context: {{context}}

Respond with only a number 1-5.`,
    scoreRange: { min: 1, max: 5 },
  },

  decisionConfidence: {
    name: 'decision_confidence',
    prompt: `Evaluate the quality and confidence of this AI coaching decision.
Score from 1-5 where:
1 = Poor decision with weak or illogical reasoning
2 = Questionable decision, reasoning has gaps
3 = Acceptable decision with adequate reasoning
4 = Good decision with clear, well-supported reasoning
5 = Excellent decision with compelling, personalized reasoning

Task Selected: {{task}}
Decision Reasoning: {{reasoning}}
User Context: {{context}}

Respond with only a number 1-5.`,
    scoreRange: { min: 1, max: 5 },
  },
};

/**
 * Run LLM-as-judge evaluation on an AI output
 */
export async function evaluateWithLLM(
  openai: OpenAI,
  evaluationConfig: EvaluationConfig,
  variables: Record<string, string>
): Promise<{ score: number; raw: string }> {
  // Substitute variables in prompt
  let prompt = evaluationConfig.prompt;
  for (const [key, value] of Object.entries(variables)) {
    prompt = prompt.replace(new RegExp(`{{${key}}}`, 'g'), value);
  }

  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are an evaluation assistant. Respond only with a numeric score.',
        },
        { role: 'user', content: prompt },
      ],
      temperature: 0,
      max_tokens: 10,
    });

    const raw = response.choices[0]?.message?.content || '';
    const score = parseInt(raw.trim(), 10);

    // Clamp to valid range
    const clampedScore = Math.max(
      evaluationConfig.scoreRange.min,
      Math.min(evaluationConfig.scoreRange.max, isNaN(score) ? evaluationConfig.scoreRange.min : score)
    );

    return { score: clampedScore, raw };
  } catch (error) {
    console.error('LLM evaluation error:', error);
    return { score: evaluationConfig.scoreRange.min, raw: 'error' };
  }
}

/**
 * Run multiple evaluations and return feedback scores
 */
export async function runEvaluations(
  openai: OpenAI,
  evaluations: Array<{
    config: EvaluationConfig;
    variables: Record<string, string>;
  }>
): Promise<Array<{ name: string; value: number; reason?: string }>> {
  const results = await Promise.all(
    evaluations.map(async ({ config, variables }) => {
      const { score, raw } = await evaluateWithLLM(openai, config, variables);
      return {
        name: config.name,
        value: score,
        reason: `LLM evaluation score: ${raw}`,
      };
    })
  );

  return results;
}

/**
 * Experiment tracking for prompt versions
 */
export interface PromptExperiment {
  name: string;
  version: string;
  systemPrompt: string;
  userPromptTemplate: string;
  metadata?: Record<string, unknown>;
}

/**
 * Track a prompt experiment
 */
export function trackPromptExperiment(
  trace: Trace | null,
  experiment: PromptExperiment
): void {
  if (!trace) return;

  trace.update({
    metadata: {
      experiment: experiment.name,
      promptVersion: experiment.version,
      systemPromptHash: hashString(experiment.systemPrompt),
      userPromptTemplateHash: hashString(experiment.userPromptTemplate),
      ...experiment.metadata,
    },
  });
}

/**
 * Simple string hash for prompt versioning
 */
function hashString(str: string): string {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32bit integer
  }
  return Math.abs(hash).toString(16);
}

/**
 * Prompt version constants for experiment tracking
 */
export const PROMPT_VERSIONS = {
  personalizeTask: {
    v1: {
      name: 'personalize_task_experiment',
      version: 'v1',
      description: 'Initial task personalization prompt',
    },
  },
  dailyInsight: {
    v1: {
      name: 'daily_insight_experiment',
      version: 'v1',
      description: 'Initial daily insight generation prompt',
    },
  },
  smartRecommendation: {
    v1: {
      name: 'smart_recommendation_experiment',
      version: 'v1',
      description: 'Initial smart task recommendation prompt',
    },
  },
  coachDecides: {
    v1: {
      name: 'coach_decides_experiment',
      version: 'v1',
      description: 'Initial coach decides recommendation prompt',
    },
  },
  weeklyPlan: {
    v1: {
      name: 'weekly_plan_experiment',
      version: 'v1',
      description: 'Initial weekly plan generation prompt',
    },
  },
};

/**
 * Flush all pending Opik data
 * Call this before Cloud Function terminates
 * Includes timeout protection to prevent hanging
 */
export async function flushOpik(): Promise<void> {
  const client = getOpikClient();
  if (!client) return;

  const timeout = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new Error('Opik flush timeout after 5000ms')), 5000)
  );

  try {
    await Promise.race([
      Promise.all([
        client.traceBatchQueue.flush(),
        client.spanBatchQueue.flush(),
        client.traceFeedbackScoresBatchQueue.flush(),
        client.spanFeedbackScoresBatchQueue.flush(),
      ]),
      timeout,
    ]);
  } catch (error) {
    // Log but don't throw - flush failures shouldn't break the function
    console.error('Opik flush failed (non-fatal):', error instanceof Error ? error.message : error);
  }
}
