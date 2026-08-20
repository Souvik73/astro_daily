/**
 * astro edge function
 *
 * Reads the user's cached birth_charts row and returns formatted data
 * for each app feature. Replaces MockAstroProvider everywhere.
 *
 * kind=kundli         → KundliData (planets, houses, dasha, gemstone)
 * kind=horoscope      → DailyHoroscope with AI-generated summary
 * kind=numerology     → NumerologyResult (from DOB)
 * kind=compatibility  → CompatibilityResult  body: { partnerDob, partnerTob, partnerPlace }
 * kind=dosddonts      → AI-generated dos/don'ts list  body: { locale }
 * kind=transits       → refresh + return today's transits
 *
 * kind can be in URL query params (?kind=kundli) OR in the POST body ({ kind: "kundli" }).
 */

import { DateTime } from "luxon";
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { adminClient } from "../_shared/db.ts";
import {
  toJD, computeNatalChart, computeTransits,
  nakshatraOf, computeDasha,
} from "../_shared/ephemeris.ts";
import { geocodePlace } from "../_shared/geocode.ts";
import { callGemini } from "../_shared/gemini.ts";

// ─── Gemstone mapping by ascendant sign ────────────────────────────────────────
const SIGN_GEMSTONE: Record<string, { primary: string; secondary: string }> = {
  Aries:       { primary: "Red Coral",    secondary: "Bloodstone" },
  Taurus:      { primary: "Diamond",      secondary: "White Sapphire" },
  Gemini:      { primary: "Emerald",      secondary: "Jade" },
  Cancer:      { primary: "Pearl",        secondary: "Moonstone" },
  Leo:         { primary: "Ruby",         secondary: "Garnet" },
  Virgo:       { primary: "Emerald",      secondary: "Peridot" },
  Libra:       { primary: "Diamond",      secondary: "Opal" },
  Scorpio:     { primary: "Red Coral",    secondary: "Aquamarine" },
  Sagittarius: { primary: "Yellow Sapphire", secondary: "Citrine" },
  Capricorn:   { primary: "Blue Sapphire",   secondary: "Amethyst" },
  Aquarius:    { primary: "Blue Sapphire",   secondary: "Lapis Lazuli" },
  Pisces:      { primary: "Yellow Sapphire", secondary: "Amethyst" },
};

const PLANET_GEMSTONE: Record<string, string> = {
  Sun:     "Ruby",
  Moon:    "Pearl",
  Mars:    "Red Coral",
  Mercury: "Emerald",
  Jupiter: "Yellow Sapphire",
  Venus:   "Diamond",
  Saturn:  "Blue Sapphire",
  Rahu:    "Hessonite (Gomed)",
  Ketu:    "Cat's Eye",
};

// ─── Numerology (Pythagorean reduction from DOB) ───────────────────────────────
function reduceToSingleDigit(n: number): number {
  while (n > 9 && n !== 11 && n !== 22 && n !== 33) {
    n = n.toString().split("").reduce((s, d) => s + parseInt(d), 0);
  }
  return n;
}

function lifePathNumber(dob: string): number {
  const parts = dob.replace(/-/g, "").split("").map(Number);
  return reduceToSingleDigit(parts.reduce((a, b) => a + b, 0));
}

function destinyNumber(dob: string): number {
  // Sum of all date digits
  return lifePathNumber(dob);
}

function luckyNumber(lifePath: number): number {
  return ((lifePath - 1) % 9) + 1;
}

const LIFE_PATH_MEANINGS: Record<number, string> = {
  1: "The Leader — Independent, ambitious, original thinker.",
  2: "The Mediator — Cooperative, diplomatic, sensitive.",
  3: "The Creative — Expressive, social, optimistic.",
  4: "The Builder — Practical, disciplined, hardworking.",
  5: "The Adventurer — Freedom-loving, versatile, curious.",
  6: "The Nurturer — Caring, responsible, family-oriented.",
  7: "The Seeker — Analytical, spiritual, introspective.",
  8: "The Achiever — Ambitious, authoritative, business-minded.",
  9: "The Humanitarian — Compassionate, generous, idealistic.",
  11: "The Visionary — Intuitive, inspirational, idealistic master number.",
  22: "The Master Builder — Visionary with practical execution.",
  33: "The Master Teacher — Nurturing, compassionate on a grand scale.",
};

// ─── Today's JD ───────────────────────────────────────────────────────────────
function todayJD(): number {
  const n = new Date();
  return toJD(n.getUTCFullYear(), n.getUTCMonth() + 1, n.getUTCDate(),
    n.getUTCHours() + n.getUTCMinutes() / 60);
}

// ─── Compatibility score ───────────────────────────────────────────────────────
// Degree-precision synastry: weighted planetary aspects (not just whole-sign
// matches) plus nakshatra affinity, so two pairs with different exact
// placements get different scores instead of collapsing onto the same
// whole-sign bucket. Previously this only compared 4 booleans (same
// sign / same trine, for ascendant + moon), which put >50% of all random
// pairs at exactly the 50-point floor.
const TRINE_GROUPS = [
  ["Aries", "Leo", "Sagittarius"],
  ["Taurus", "Virgo", "Capricorn"],
  ["Gemini", "Libra", "Aquarius"],
  ["Cancer", "Scorpio", "Pisces"],
];
const inSameTrine = (a: string, b: string) =>
  TRINE_GROUPS.some((g) => g.includes(a) && g.includes(b));

function angularSeparation(deg1: number, deg2: number): number {
  const diff = Math.abs(deg1 - deg2) % 360;
  return diff > 180 ? 360 - diff : diff;
}

// Classical synastry aspects with orb tolerance. Conjunction/trine read as
// harmonious, square/opposition as friction; anything else is neutral.
function aspectScore(separation: number): number {
  const aspects: { angle: number; orb: number; points: number }[] = [
    { angle: 0, orb: 8, points: 12 },
    { angle: 60, orb: 6, points: 6 },
    { angle: 120, orb: 8, points: 10 },
    { angle: 90, orb: 6, points: -6 },
    { angle: 180, orb: 8, points: -4 },
  ];
  for (const a of aspects) {
    if (Math.abs(separation - a.angle) <= a.orb) return a.points;
  }
  return 0;
}

interface CompatChart {
  ascendant: { sign: string };
  planets: Record<string, { siderealDeg: number }>;
  nakshatra: { name: string; lord: string };
}

function compatibilityScore(
  chart1: CompatChart,
  chart2: CompatChart
): { score: number; rating: string; description: string } {
  let score = 50;

  // Moon carries the most weight in Vedic synastry (emotional compatibility),
  // then Venus (romance), Sun (identity), Mars (drive/friction).
  const weights: Record<string, number> = { moon: 1.4, venus: 1.2, sun: 1.0, mars: 0.9 };
  for (const [planet, weight] of Object.entries(weights)) {
    const p1 = chart1.planets[planet];
    const p2 = chart2.planets[planet];
    if (p1 && p2) {
      const separation = angularSeparation(p1.siderealDeg, p2.siderealDeg);
      score += aspectScore(separation) * weight;
    }
  }

  if (chart1.ascendant.sign === chart2.ascendant.sign) score += 6;
  else if (inSameTrine(chart1.ascendant.sign, chart2.ascendant.sign)) score += 8;

  if (chart1.nakshatra.name === chart2.nakshatra.name) score += 6;
  else if (chart1.nakshatra.lord === chart2.nakshatra.lord) score += 3;

  score = Math.max(20, Math.min(Math.round(score), 98));

  const rating =
    score >= 80 ? "Excellent" : score >= 65 ? "Good" : score >= 50 ? "Average" : "Challenging";

  const description =
    score >= 80
      ? "Strong cosmic alignment between your birth charts."
      : score >= 65
      ? "Positive compatibility with room to grow together."
      : score >= 50
      ? "Moderate compatibility — awareness and communication are key."
      : "Significant karmic differences; growth requires effort from both sides.";

  return { score, rating, description };
}

// ─── Handler ──────────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  const corsResp = handleCors(req);
  if (corsResp) return corsResp;

  try {
    const { userId } = await requireAuth(req);
    const url = new URL(req.url);

    // Accept kind from URL query params OR from POST body (Flutter compat)
    let body: Record<string, unknown> = {};
    try { body = await req.clone().json(); } catch { /* body optional */ }
    const kind = url.searchParams.get("kind") ?? (body.kind as string) ?? "kundli";
    const locale = url.searchParams.get("locale") ?? (body.locale as string) ?? "en";

    const db = adminClient();

    // Load user's cached chart row
    const { data: row, error: fetchErr } = await db
      .from("birth_charts")
      .select("*")
      .eq("user_id", userId)
      .single();

    if (fetchErr || !row) {
      return new Response(
        JSON.stringify({ error: "chart_missing", message: "Please complete your birth profile first." }),
        { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const chart = row.chart;
    const ascSign: string = chart.ascendant.sign;
    const moonSign: string = chart.planets.moon.sign;
    const sunSign: string  = chart.planets.sun.sign;

    // ── kundli ───────────────────────────────────────────────────────────────
    if (kind === "kundli") {
      const gems = SIGN_GEMSTONE[ascSign] ?? { primary: "Pearl", secondary: "Moonstone" };
      const dashaLordGem = PLANET_GEMSTONE[chart.dasha.mahadasha.planet] ?? "Pearl";

      const response = {
        ascendant: ascSign,
        sunSign,
        moonSign,
        nakshatra: chart.nakshatra,
        dasha: chart.dasha,
        planets: chart.planets,
        houses: chart.houses,
        ayanamsa: chart.ayanamsa,
        recommendedGemstone: gems.primary,
        alternateGemstone: gems.secondary,
        dashaGemstone: dashaLordGem,
        focusArea: deriveFocusArea(chart),
      };
      return json(response);
    }

    // ── horoscope ─────────────────────────────────────────────────────────────
    if (kind === "horoscope") {
      // Refresh transits if stale (>4 hours)
      const lastRefresh = row.transits_refreshed_at
        ? new Date(row.transits_refreshed_at)
        : new Date(0);
      const staleMs = Date.now() - lastRefresh.getTime();

      let transits = row.transits;
      if (staleMs > 4 * 60 * 60 * 1000) {
        transits = computeTransits(todayJD());
        await db.from("birth_charts").update({
          transits,
          transits_refreshed_at: new Date().toISOString(),
        }).eq("user_id", userId);
      }

      // ── AI-generated daily summary ──
      const dashaLord = chart.dasha?.mahadasha?.planet ?? "Sun";
      const moonTransit = transits?.moon?.sign ?? moonSign;
      const summaryPrompt = `Generate a concise, personalized daily horoscope in 2-3 sentences for someone with these birth chart details:
- Ascendant (Lagna): ${ascSign}
- Sun sign: ${sunSign}, Moon sign: ${moonSign}
- Current Mahadasha lord: ${dashaLord}
- Moon transiting through: ${moonTransit} today
- Birth nakshatra: ${chart.nakshatra?.name} (lord: ${chart.nakshatra?.lord})
Language: ${locale}. Be warm, practical and encouraging. No generic statements.`;

      let summary = `Today, ${sunSign}, your ${dashaLord} Mahadasha brings focused energy. Moon in ${moonTransit} enhances intuition and emotional clarity.`;
      try {
        const aiResult = await callGemini({
          contents: [{ role: "user", parts: [{ text: summaryPrompt }] }],
          generationConfig: { temperature: 0.8, maxOutputTokens: 150 },
        });
        if (aiResult.text) summary = aiResult.text.trim();
      } catch { /* fallback to template summary above */ }

      // Lucky color and number from current dasha lord
      const LUCKY_COLORS: Record<string, string> = {
        Sun: "Gold", Moon: "White", Mars: "Red", Mercury: "Green",
        Jupiter: "Yellow", Venus: "Cream", Saturn: "Blue", Rahu: "Brown", Ketu: "Grey",
      };
      const LUCKY_NUMBERS: Record<string, number> = {
        Sun: 1, Moon: 2, Mars: 9, Mercury: 5,
        Jupiter: 3, Venus: 6, Saturn: 8, Rahu: 4, Ketu: 7,
      };

      const response = {
        sunSign, moonSign,
        ascendant: ascSign,
        summary,
        luckyColor: LUCKY_COLORS[dashaLord] ?? "Gold",
        luckyNumber: LUCKY_NUMBERS[dashaLord] ?? 1,
        todayTransits: transits,
        natalPlanets: chart.planets,
        dasha: chart.dasha,
        nakshatra: chart.nakshatra,
        date: new Date().toISOString().split("T")[0],
      };
      return json(response);
    }

    // ── dosddonts ─────────────────────────────────────────────────────────────
    if (kind === "dosddonts") {
      let transits = row.transits ?? {};
      const dashaLord = chart.dasha?.mahadasha?.planet ?? "Sun";
      const moonTransit = transits?.moon?.sign ?? moonSign;

      const prompt = `Generate exactly 4 personalized astrological dos and don'ts for today for:
- Ascendant: ${ascSign}, Sun: ${sunSign}, Moon: ${moonSign}
- Mahadasha: ${dashaLord}, Moon today in: ${moonTransit}
Language: ${locale}.
Format: 4 bullet points alternating Do/Don't. Each under 12 words. Practical and specific.`;

      let items: string[] = [
        `Do: Focus on tasks aligned with your ${dashaLord} energy today.`,
        "Do: Reach out to someone you've been meaning to connect with.",
        "Don't: Make major financial decisions without careful reflection.",
        "Don't: Overcommit your schedule — protect your energy.",
      ];

      try {
        const aiResult = await callGemini({
          contents: [{ role: "user", parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.7, maxOutputTokens: 200 },
        });
        if (aiResult.text) {
          const lines = aiResult.text.split("\n").map((l: string) => l.replace(/^[-•*]\s*/, "").trim()).filter(Boolean);
          if (lines.length >= 4) items = lines.slice(0, 4);
        }
      } catch { /* use default items */ }

      return json({ items });
    }

    // ── numerology ────────────────────────────────────────────────────────────
    if (kind === "numerology") {
      // Extract DOB from dob_hash (format: "YYYY-MM-DD|HH:MM|place")
      const dob = row.dob_hash.split("|")[0];
      const lp = lifePathNumber(dob);
      const response = {
        lifePathNumber: lp,
        destinyNumber: lp, // same digit reduction from DOB
        luckyNumber: luckyNumber(lp),
        meaning: LIFE_PATH_MEANINGS[lp] ?? "A unique life path.",
        sunSign,
        moonSign,
      };
      return json(response);
    }

    // ── compatibility ─────────────────────────────────────────────────────────
    if (kind === "compatibility") {
      if (req.method !== "POST") {
        return new Response(
          JSON.stringify({ error: "POST required for compatibility" }),
          { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { partnerDob, partnerTob, partnerPlace } = body as Record<string, string>;
      if (!partnerDob || !partnerTob || !partnerPlace) {
        return new Response(
          JSON.stringify({ error: "partnerDob, partnerTob, partnerPlace are required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Geocode partner's place
      const partnerGeo = await geocodePlace(partnerPlace);
      const partnerDT = DateTime.fromISO(`${partnerDob}T${partnerTob}:00`, { zone: partnerGeo.tz }).toUTC();
      const partnerJD = toJD(partnerDT.year, partnerDT.month, partnerDT.day,
        partnerDT.hour + partnerDT.minute / 60);
      const partnerChart = computeNatalChart(partnerJD, partnerGeo.lat, partnerGeo.lon, new Date(partnerDob));

      const result = compatibilityScore(chart, partnerChart);

      return json({
        user: { ascendant: ascSign, moon: moonSign, sun: sunSign, nakshatra: chart.nakshatra.name },
        partner: {
          ascendant: partnerChart.ascendant.sign,
          moon: partnerChart.planets.moon.sign,
          sun: partnerChart.planets.sun.sign,
          nakshatra: partnerChart.nakshatra.name,
        },
        ...result,
      });
    }

    // ── transits (manual refresh) ─────────────────────────────────────────────
    if (kind === "transits") {
      const transits = computeTransits(todayJD());
      await db.from("birth_charts").update({
        transits,
        transits_refreshed_at: new Date().toISOString(),
      }).eq("user_id", userId);
      return json({ transits });
    }

    return new Response(
      JSON.stringify({ error: `Unknown kind: ${kind}` }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    if (err instanceof Response) return err;
    console.error("astro error:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function deriveFocusArea(chart: { planets: Record<string, { house: number; sign: string }> }): string {
  // Return the life area of the 10th house sign (career/public life)
  const tenth = Object.values(chart.planets).find((p) => p.house === 10);
  const HOUSE_MEANINGS: Record<number, string> = {
    1: "Self & Health", 2: "Wealth & Values", 3: "Communication",
    4: "Home & Family", 5: "Creativity & Children", 6: "Service & Health",
    7: "Relationships", 8: "Transformation", 9: "Philosophy & Travel",
    10: "Career & Status", 11: "Social Network", 12: "Spirituality & Loss",
  };
  // Focus on the house with the most planets
  const houseCounts: Record<number, number> = {};
  for (const p of Object.values(chart.planets)) {
    houseCounts[p.house] = (houseCounts[p.house] ?? 0) + 1;
  }
  const focusHouse = parseInt(
    Object.entries(houseCounts).sort((a, b) => b[1] - a[1])[0]?.[0] ?? "10"
  );
  return HOUSE_MEANINGS[focusHouse] ?? "Career & Status";
}
