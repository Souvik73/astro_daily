/**
 * chat edge function
 *
 * Handles every chat turn in the Astro Daily chatbot.
 *
 * POST body:
 *   {
 *     question: string,
 *     history:  Array<{ role: "user"|"assistant", content: string }>,  // last 6 turns
 *     locale:   string   // e.g. "en", "hi"
 *   }
 *
 * Response:
 *   { reply: string, remaining: number }
 *
 * Errors:
 *   402 { error: "quota_exceeded", remaining: 0 }
 *   422 { error: "chart_missing" }
 *   503 { error: "ai_unavailable" }
 */

import { DateTime } from "luxon";
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { adminClient } from "../_shared/db.ts";
import { callGemini } from "../_shared/gemini.ts";
import { computeNatalChart, computeTransits, toJD } from "../_shared/ephemeris.ts";
import { geocodePlace } from "../_shared/geocode.ts";
import { buildSystemInstruction, buildHistory } from "./prompt.ts";

// ─── Quota configuration ──────────────────────────────────────────────────────
const FREE_DAILY_LIMIT = 3;
const PREMIUM_DAILY_LIMIT = 30;

type DbClient = ReturnType<typeof adminClient>;

async function checkAndIncrementQuota(
  userId: string,
  isPremium: boolean,
): Promise<{ allowed: boolean; remaining: number }> {
  const db = adminClient();
  const today = new Date().toISOString().split("T")[0]; // "YYYY-MM-DD"
  const limit = isPremium ? PREMIUM_DAILY_LIMIT : FREE_DAILY_LIMIT;

  const { data, error } = await db.rpc("increment_chat_quota", {
    p_user_id: userId,
    p_day: today,
    p_limit: limit,
  });

  if (error) {
    console.error("quota rpc error:", error);
    // Fail open — don't block users on quota errors
    return { allowed: true, remaining: limit };
  }

  // db.rpc() returns an array when the SQL function returns a table;
  // handle both array and scalar forms to be safe.
  const row = Array.isArray(data) ? data[0] : data;
  const count = (row?.count as number) ?? 1;
  const allowed = count <= limit;
  const remaining = Math.max(0, limit - count);
  return { allowed, remaining };
}

// ─── Current Julian Day ───────────────────────────────────────────────────────
function nowJD(): number {
  const n = new Date();
  return toJD(
    n.getUTCFullYear(), n.getUTCMonth() + 1, n.getUTCDate(),
    n.getUTCHours() + n.getUTCMinutes() / 60,
  );
}

// ─── Auto-compute chart from birth_details (for existing users) ───────────────
//
// Users who completed their profile before the compute-chart function existed
// won't have a birth_charts row. This function backfills it on the first chat
// request, so they never see a "chart_missing" error.
async function autoComputeChart(
  db: DbClient,
  userId: string,
): Promise<{ chart: unknown; transits: unknown } | null> {
  const { data: bd, error: bdErr } = await db
    .from("birth_details")
    .select("date_of_birth,time_of_birth,place_of_birth")
    .eq("user_id", userId)
    .single();

  if (bdErr || !bd?.date_of_birth || !bd?.place_of_birth) {
    console.warn(`No birth_details for ${userId}:`, bdErr?.message ?? "row missing");
    return null;
  }

  // date_of_birth is stored as an ISO string, e.g. "2000-01-15T00:00:00.000000"
  const dob = (bd.date_of_birth as string).split("T")[0]; // → "YYYY-MM-DD"
  const tob = (bd.time_of_birth as string | null) ?? "06:00";
  const place = bd.place_of_birth as string;

  const geo = await geocodePlace(place);

  const localDT = DateTime.fromISO(`${dob}T${tob}:00`, { zone: geo.tz });
  if (!localDT.isValid) {
    console.error("Invalid date/time from birth_details:", dob, tob, geo.tz);
    return null;
  }

  const utDT = localDT.toUTC();
  const jd = toJD(
    utDT.year, utDT.month, utDT.day,
    utDT.hour + utDT.minute / 60 + (utDT.second ?? 0) / 3600,
  );

  const birthDate = new Date(`${dob}T${tob}:00`);
  const chart = computeNatalChart(jd, geo.lat, geo.lon, birthDate);
  const transits = computeTransits(nowJD());
  const dobHash = `${dob}|${tob}|${place.toLowerCase().trim()}`;

  // Persist the computed chart (fire-and-forget — don't block the chat response)
  db.from("birth_charts").upsert(
    {
      user_id: userId,
      dob_hash: dobHash,
      lat: geo.lat,
      lon: geo.lon,
      tz: geo.tz,
      chart,
      transits,
      transits_refreshed_at: new Date().toISOString(),
      computed_at: new Date().toISOString(),
    },
    { onConflict: "user_id" },
  ).then();

  return { chart, transits };
}

// ─── Handler ──────────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  const corsResp = handleCors(req);
  if (corsResp) return corsResp;

  try {
    const { userId, user } = await requireAuth(req);

    const { question, history = [], locale = "en" } = await req.json() as {
      question: string;
      history: Array<{ role: string; content: string }>;
      locale: string;
    };

    if (!question?.trim()) {
      return new Response(
        JSON.stringify({ error: "question is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const db = adminClient();

    // ── Premium check — tier is stored in Supabase Auth user_metadata ──
    const isPremium = user.user_metadata?.subscription_tier === "premium";

    // ── Check and increment quota ──
    const { allowed, remaining } = await checkAndIncrementQuota(userId, isPremium);
    if (!allowed) {
      return new Response(
        JSON.stringify({ error: "quota_exceeded", remaining: 0 }),
        { status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── Load birth chart ──
    let { data: row, error: chartErr } = await db
      .from("birth_charts")
      .select("chart, transits, transits_refreshed_at")
      .eq("user_id", userId)
      .single();

    // ── If chart is missing, auto-compute it from birth_details ──
    if (chartErr || !row) {
      console.log(`birth_charts missing for ${userId}; auto-computing from birth_details`);
      try {
        const computed = await autoComputeChart(db, userId);
        if (!computed) {
          return new Response(
            JSON.stringify({
              error: "chart_missing",
              message: "Please complete your birth profile to use the chatbot.",
            }),
            { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } },
          );
        }
        // Synthesise a row that matches the DB shape the code below expects
        row = {
          chart: computed.chart,
          transits: computed.transits,
          transits_refreshed_at: new Date().toISOString(),
        };
      } catch (autoErr) {
        console.error("Auto-compute chart failed:", autoErr);
        return new Response(
          JSON.stringify({
            error: "chart_missing",
            message: "Please complete your birth profile to use the chatbot.",
          }),
          { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
    }

    // ── Refresh transits if stale (> 4 hours) ──
    const lastRefresh = row.transits_refreshed_at
      ? new Date(row.transits_refreshed_at)
      : new Date(0);
    let transits = row.transits ?? {};
    if (Date.now() - lastRefresh.getTime() > 4 * 60 * 60 * 1000) {
      transits = computeTransits(nowJD());
      // Fire-and-forget — don't block the chat response
      db.from("birth_charts").update({
        transits,
        transits_refreshed_at: new Date().toISOString(),
      }).eq("user_id", userId).then();
    }

    // ── Build Gemini prompt ──
    const systemText = buildSystemInstruction(row.chart, transits);
    const geminiHistory = buildHistory(history.slice(-6)); // last 6 turns max

    const localeNote = locale !== "en"
      ? `\n\n[The user's app locale is "${locale}". Respond in the same language as their question.]`
      : "";

    const payload = {
      systemInstruction: {
        parts: [{ text: systemText + localeNote }],
      },
      contents: [
        ...geminiHistory,
        { role: "user" as const, parts: [{ text: question }] },
      ],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 1500,
        // Disable thinking on gemini-2.5-flash so the entire output budget
        // is spent on the visible reply (no "thought tokens" eating headroom).
        thinkingConfig: { thinkingBudget: 0 },
        // Structured JSON output: Gemini returns { reply, suggestions[] } every time.
        responseMimeType: "application/json",
        responseSchema: {
          type: "object",
          properties: {
            reply: { type: "string" },
            suggestions: {
              type: "array",
              items: { type: "string" },
              minItems: 3,
              maxItems: 3,
            },
          },
          required: ["reply", "suggestions"],
        },
      },
    };

    // ── Call Gemini ──
    let reply: string;
    let suggestions: string[] = [];
    try {
      const result = await callGemini(payload);

      // Parse structured JSON output { reply, suggestions[] }.
      // Fallback: if Gemini ever emits non-JSON, treat the whole text as the reply
      // and return empty suggestions so the chat still works.
      try {
        const parsed = JSON.parse(result.text);
        reply = typeof parsed.reply === "string" ? parsed.reply : result.text;
        suggestions = Array.isArray(parsed.suggestions)
          ? (parsed.suggestions as unknown[])
              .filter((s): s is string => typeof s === "string")
              .slice(0, 3)
          : [];
      } catch {
        reply = result.text;
        suggestions = [];
      }

      // Log token usage for cost monitoring
      if (result.usage) {
        console.log("gemini_usage", JSON.stringify({
          user: userId,
          promptTokens: result.usage.promptTokenCount,
          outputTokens: result.usage.candidatesTokenCount,
          cachedTokens: result.usage.cachedContentTokenCount ?? 0,
        }));
      }
    } catch (aiErr) {
      console.error("Gemini call failed:", aiErr);
      return new Response(
        JSON.stringify({
          error: "ai_unavailable",
          message: "The AI service is temporarily unavailable. Please try again shortly.",
        }),
        { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ reply, suggestions, remaining: Math.max(0, remaining - 1) }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    if (err instanceof Response) return err;
    console.error("chat error:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
