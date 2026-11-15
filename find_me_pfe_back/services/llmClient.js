/**
 * FINDME — Provider-agnostic LLM client (no extra npm dependency, uses global fetch, Node >= 18).
 *
 * .env
 *   LLM_PROVIDER = openai | anthropic        (openai = any OpenAI-compatible API)
 *   LLM_API_KEY  = ...                        (not needed for a local Ollama)
 *   LLM_MODEL    = gpt-4o-mini | llama-3.3-70b-versatile | gemini-2.0-flash | claude-haiku-4-5 | ...
 *   LLM_BASE_URL = https://api.openai.com/v1 (default)
 *                  https://api.groq.com/openai/v1
 *                  https://generativelanguage.googleapis.com/v1beta/openai
 *                  http://localhost:11434/v1  (Ollama)
 *   LLM_VISION_MODEL = optional, model used for image search (defaults to LLM_MODEL)
 *   LLM_TIMEOUT_MS   = 20000
 *
 * The LLM never decides which products exist: it only understands the request and
 * phrases the answer. Products, prices and stock always come from MongoDB.
 */

function config() {
  const provider = (process.env.LLM_PROVIDER || 'openai').toLowerCase();
  const baseUrl = (process.env.LLM_BASE_URL || (provider === 'anthropic' ? 'https://api.anthropic.com/v1' : 'https://api.openai.com/v1')).replace(/\/+$/, '');
  return {
    provider,
    apiKey: process.env.LLM_API_KEY || '',
    model: process.env.LLM_MODEL || '',
    visionModel: process.env.LLM_VISION_MODEL || process.env.LLM_MODEL || '',
    baseUrl,
    timeoutMs: Number(process.env.LLM_TIMEOUT_MS || 20000),
  };
}

function isEnabled() {
  const c = config();
  if (!c.model) return false;
  if (process.env.LLM_DISABLED === 'true') return false;
  const isLocal = /localhost|127\.0\.0\.1|0\.0\.0\.0/.test(c.baseUrl);
  return Boolean(c.apiKey) || isLocal;
}

/** Extract the first JSON object from a model answer (handles ```json fences and chatter). */
function extractJson(text) {
  if (!text) throw new Error('Empty LLM answer');
  const cleaned = String(text).replace(/```(?:json)?/gi, '').trim();
  try {
    return JSON.parse(cleaned);
  } catch (_) {
    const start = cleaned.indexOf('{');
    const end = cleaned.lastIndexOf('}');
    if (start >= 0 && end > start) return JSON.parse(cleaned.slice(start, end + 1));
    throw new Error('LLM answer is not JSON');
  }
}

async function httpPost(url, headers, body, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...headers },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
    const text = await res.text();
    if (!res.ok) throw new Error(`LLM HTTP ${res.status}: ${text.slice(0, 300)}`);
    return JSON.parse(text);
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Low level call.
 * @param {object} opts { system, messages:[{role:'user'|'assistant', content:string|parts}], json, temperature, maxTokens, model }
 *   parts (for vision): [{type:'text', text}, {type:'image', mimeType, base64}]
 * @returns {Promise<string>} the assistant text
 */
async function complete({ system, messages, json = false, temperature = 0.3, maxTokens = 700, model }) {
  const c = config();
  const useModel = model || c.model;

  if (c.provider === 'anthropic') {
    const toAnthropic = (content) => {
      if (typeof content === 'string') return content;
      return content.map((part) => (part.type === 'image'
        ? { type: 'image', source: { type: 'base64', media_type: part.mimeType, data: part.base64 } }
        : { type: 'text', text: part.text }));
    };
    const data = await httpPost(`${c.baseUrl}/messages`, {
      'x-api-key': c.apiKey,
      'anthropic-version': '2023-06-01',
    }, {
      model: useModel,
      max_tokens: maxTokens,
      temperature,
      system: json ? `${system}\n\nAnswer with a single valid JSON object and nothing else.` : system,
      messages: messages.map((m) => ({ role: m.role, content: toAnthropic(m.content) })),
    }, c.timeoutMs);
    return (data.content || []).filter((b) => b.type === 'text').map((b) => b.text).join('');
  }

  // OpenAI-compatible
  const toOpenAI = (content) => {
    if (typeof content === 'string') return content;
    return content.map((part) => (part.type === 'image'
      ? { type: 'image_url', image_url: { url: `data:${part.mimeType};base64,${part.base64}` } }
      : { type: 'text', text: part.text }));
  };
  const body = {
    model: useModel,
    temperature,
    max_tokens: maxTokens,
    messages: [
      { role: 'system', content: json ? `${system}\n\nAnswer with a single valid JSON object and nothing else.` : system },
      ...messages.map((m) => ({ role: m.role, content: toOpenAI(m.content) })),
    ],
  };
  if (json) body.response_format = { type: 'json_object' };
  const headers = c.apiKey ? { Authorization: `Bearer ${c.apiKey}` } : {};
  let data;
  try {
    data = await httpPost(`${c.baseUrl}/chat/completions`, headers, body, c.timeoutMs);
  } catch (err) {
    // some compatible providers reject response_format: retry once without it
    if (json && /response_format|json_object/i.test(err.message)) {
      delete body.response_format;
      data = await httpPost(`${c.baseUrl}/chat/completions`, headers, body, c.timeoutMs);
    } else {
      throw err;
    }
  }
  return (((data.choices || [])[0] || {}).message || {}).content || '';
}

async function completeJson(opts) {
  const text = await complete({ ...opts, json: true });
  return extractJson(text);
}

/** Vision helper: returns parsed JSON describing an image. */
async function describeImageJson({ system, prompt, base64, mimeType = 'image/jpeg' }) {
  const c = config();
  return completeJson({
    system,
    model: c.visionModel,
    temperature: 0.1,
    maxTokens: 500,
    messages: [{ role: 'user', content: [{ type: 'image', mimeType, base64 }, { type: 'text', text: prompt }] }],
  });
}

module.exports = { isEnabled, complete, completeJson, describeImageJson, extractJson, config };
