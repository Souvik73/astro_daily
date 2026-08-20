/**
 * compute-chart edge function
 *
 * Called once per user immediately after profile completion (or when DOB/place changes).
 * 1. Geocodes their place of birth → lat/lon/timezone
 * 2. Converts local birth time to UT
 * 3. Runs the ephemeris engine to produce the full natal chart
 * 4. Upserts the result into the birth_charts table
 *
 * POST body:
 *   { dob: "YYYY-MM-DD", tob: "HH:MM", place: "City, Country" }
 *
 * Response:
 *   { chart: NatalChart, tz: string, lat: number, lon: number }
 */

import { DateTime } from "luxon";
import { handleCors, corsHeaders } from "../_shared/cors.ts";
import { requireAuth } from "../_shared/auth.ts";
import { adminClient } from "../_shared/db.ts";
import { geocodePlace } from "../_shared/geocode.ts";
import { toJD, computeNatalChart, computeTransits, lahiriAyanamsa } from "../_shared/ephemeris.ts";

Deno.serve(async (req) => {
  const corsResp = handleCors(req);
  if (corsResp) return corsResp;

  try {
    // ── Auth ──
    const { userId } = await requireAuth(req);

    // ── Parse body ──
    const { dob, tob, place } = await req.json() as {
      dob: string;   // "YYYY-MM-DD"
      tob: string;   // "HH:MM"  or "HH:MM:SS"
      place: string; // "Mumbai, India"
    };

    if (!dob || !tob || !place) {
      return new Response(
        JSON.stringify({ error: "dob, tob, and place are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Geocode ──
    const geo = await geocodePlace(place);

    // ── Local → UT conversion ──
    const localDT = DateTime.fromISO(`${dob}T${tob}:00`, { zone: geo.tz });
    if (!localDT.isValid) {
      return new Response(
        JSON.stringify({ error: "Invalid date/time format" }),
        { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    const utDT = localDT.toUTC();

    // ── Julian Day ──
    const jd = toJD(
      utDT.year, utDT.month, utDT.day,
      utDT.hour + utDT.minute / 60 + utDT.second / 3600
    );

    // ── Birth date for Dasha calculation ──
    const birthDate = new Date(`${dob}T${tob}:00`);

    // ── Compute chart ──
    const chart = computeNatalChart(jd, geo.lat, geo.lon, birthDate);

    // ── Compute today's transits (for immediate use) ──
    const nowJD = toJD(
      new Date().getUTCFullYear(),
      new Date().getUTCMonth() + 1,
      new Date().getUTCDate(),
      new Date().getUTCHours() + new Date().getUTCMinutes() / 60
    );
    const transits = computeTransits(nowJD);

    // ── Build dob_hash (change detection) ──
    const dobHash = `${dob}|${tob}|${place.toLowerCase().trim()}`;

    // ── Upsert into birth_charts ──
    const db = adminClient();
    const { error: upsertError } = await db
      .from("birth_charts")
      .upsert(
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
        { onConflict: "user_id" }
      );

    if (upsertError) {
      console.error("birth_charts upsert error:", upsertError);
      return new Response(
        JSON.stringify({ error: "Failed to save chart", detail: upsertError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ chart, transits, tz: geo.tz, lat: geo.lat, lon: geo.lon }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    if (err instanceof Response) return err; // Auth throws a Response directly

    console.error("compute-chart error:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
