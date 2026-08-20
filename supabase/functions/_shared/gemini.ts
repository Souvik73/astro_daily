/**
 * Thin REST wrapper for Google Gemini 2.5 Flash.
 * No SDK required — one endpoint, simple JSON contract.
 */

const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta/models";
const MODEL = "gemini-2.5-flash";

export interface GeminiMessage {
  role: "user" | "model";
  parts: Array<{ text: string }>;
}

export interface GeminiRequest {
  systemInstruction?: { parts: Array<{ text: string }> };
  contents: GeminiMessage[];
  generationConfig?: {
    temperature?: number;
    maxOutputTokens?: number;
    /// thinkingBudget: 0 disables thinking on Gemini 2.5 Flash so the entire
    /// maxOutputTokens budget is spent on visible reply tokens.
    thinkingConfig?: { thinkingBudget: number };
    /// Structured JSON output — set responseMimeType to "application/json"
    /// and supply a responseSchema so Gemini returns well-formed JSON every time.
    responseMimeType?: string;
    responseSchema?: Record<string, unknown>;
  };
}

export interface GeminiResponse {
  candidates: Array<{
    content: { parts?: Array<{ text?: string; thought?: boolean }> };
    finishReason: string;
  }>;
  usageMetadata?: {
    promptTokenCount: number;
    candidatesTokenCount: number;
    cachedContentTokenCount?: number;
  };
}

/**
 * Calls Gemini 2.5 Flash and returns the generated text.
 * Throws on non-2xx responses.
 */
export async function callGemini(payload: GeminiRequest): Promise<{ text: string; usage: GeminiResponse["usageMetadata"] }> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) throw new Error("GEMINI_API_KEY environment variable not set");

  const url = `${GEMINI_BASE}/${MODEL}:generateContent?key=${apiKey}`;

  const resp = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!resp.ok) {
    const err = await resp.text();
    throw new Error(`Gemini API error ${resp.status}: ${err}`);
  }

  const data: GeminiResponse = await resp.json();

  // Defensive parser: when thinking is enabled, parts can include thought
  // entries marked { thought: true }. Skip those and only collect visible text.
  const parts = data.candidates?.[0]?.content?.parts ?? [];
  const text = parts
    .filter((p: { thought?: boolean }) => p.thought !== true)
    .map((p: { text?: string }) => p.text ?? "")
    .join("");

  return { text, usage: data.usageMetadata };
}
