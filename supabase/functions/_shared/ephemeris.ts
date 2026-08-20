/**
 * Vedic Astrology Ephemeris
 *
 * Computes natal chart data from date/time/location.
 * Planetary positions use Jean Meeus + Schlyter orbital elements (~1-2° accuracy).
 * Sidereal conversion uses Lahiri ayanamsa (standard for Vedic astrology).
 * Houses use the Whole Sign system (most common in Jyotish).
 *
 * References:
 *   - Jean Meeus, "Astronomical Algorithms" 2nd ed.
 *   - Paul Schlyter, "How to compute planetary positions" (stjarnhimlen.se)
 */

// ─── Type Definitions ─────────────────────────────────────────────────────────

export interface PlanetPosition {
  tropicalDeg: number;   // 0-360 tropical longitude
  siderealDeg: number;   // 0-360 sidereal longitude (after ayanamsa)
  sign: string;          // e.g. "Scorpio"
  signIndex: number;     // 0=Aries ... 11=Pisces
  signDegree: number;    // degree within sign (0-30)
  house: number;         // 1-12 (whole sign, relative to ascendant)
  retrograde: boolean;
}

export interface NakshatraInfo {
  name: string;
  pada: number;          // 1-4
  lord: string;          // ruling planet
  index: number;         // 0-26
}

export interface DashaEntry {
  planet: string;
  startDate: string;     // ISO date
  endDate: string;       // ISO date
  yearsRemaining?: number;
}

export interface DashaInfo {
  mahadasha: DashaEntry;
  antardasha: DashaEntry;
  pratyantardasha: DashaEntry;
}

export interface NatalChart {
  ascendant: PlanetPosition;
  planets: Record<string, PlanetPosition>;
  houses: Record<number, string>;   // house number → sign name
  nakshatra: NakshatraInfo;
  dasha: DashaInfo;
  ayanamsa: number;
}

// ─── Constants ────────────────────────────────────────────────────────────────

const RAD = Math.PI / 180;
const DEG = 180 / Math.PI;

const SIGNS = [
  "Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
  "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces",
];

const NAKSHATRAS = [
  "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra",
  "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni", "Uttara Phalguni",
  "Hasta", "Chitra", "Swati", "Vishakha", "Anuradha", "Jyeshtha",
  "Mula", "Purva Ashadha", "Uttara Ashadha", "Shravana", "Dhanishtha",
  "Shatabhisha", "Purva Bhadrapada", "Uttara Bhadrapada", "Revati",
];

// Vimshottari dasha: lord + period in years (120-year total cycle)
const VIMSHOTTARI = [
  { planet: "Ketu",    years: 7  },
  { planet: "Venus",   years: 20 },
  { planet: "Sun",     years: 6  },
  { planet: "Moon",    years: 10 },
  { planet: "Mars",    years: 7  },
  { planet: "Rahu",    years: 18 },
  { planet: "Jupiter", years: 16 },
  { planet: "Saturn",  years: 19 },
  { planet: "Mercury", years: 17 },
];
// Nakshatra[i % 9] → VIMSHOTTARI dasha lord
const NAKSHATRA_TO_DASHA_LORD: number[] = [
  0,1,2,3,4,5,6,7,8, 0,1,2,3,4,5,6,7,8, 0,1,2,3,4,5,6,7,8,
];

const NAKSHATRA_LORDS = NAKSHATRAS.map((_, i) => VIMSHOTTARI[NAKSHATRA_TO_DASHA_LORD[i]].planet);
const NAKSHATRA_SPAN = 360 / 27; // 13.333...°

const DAYS_PER_YEAR = 365.25;

// ─── Utility ──────────────────────────────────────────────────────────────────

function norm360(x: number): number {
  return ((x % 360) + 360) % 360;
}

function sin(deg: number): number { return Math.sin(deg * RAD); }
function cos(deg: number): number { return Math.cos(deg * RAD); }
function tan(deg: number): number { return Math.tan(deg * RAD); }
function atan2d(y: number, x: number): number { return Math.atan2(y, x) * DEG; }
function asin(x: number): number { return Math.asin(x) * DEG; }

// ─── Julian Day ───────────────────────────────────────────────────────────────

/**
 * Converts a calendar date + UT hour to Julian Day Number.
 * Uses the standard Meeus algorithm (Ch.7).
 */
export function toJD(year: number, month: number, day: number, utHour: number): number {
  if (month <= 2) { year -= 1; month += 12; }
  const A = Math.floor(year / 100);
  const B = 2 - A + Math.floor(A / 4);
  return Math.floor(365.25 * (year + 4716))
    + Math.floor(30.6001 * (month + 1))
    + day + B - 1524.5
    + utHour / 24;
}

// Days from J2000.0 (2000 Jan 1.5 = JD 2451545.0)
function dJ2000(jd: number): number { return jd - 2451545.0; }
// Julian centuries from J2000.0
function T(jd: number): number { return dJ2000(jd) / 36525; }

// ─── Kepler's Equation ────────────────────────────────────────────────────────

function solveKepler(M_deg: number, e: number): number {
  // Returns eccentric anomaly E in degrees
  let E = M_deg;
  for (let i = 0; i < 5; i++) {
    E = E - (E - e * DEG * sin(E) - M_deg) / (1 - e * cos(E));
  }
  return E;
}

function trueAnomaly(M_deg: number, e: number): number {
  const E = solveKepler(norm360(M_deg), e);
  const v = atan2d(
    Math.sqrt(1 - e * e) * sin(E),
    cos(E) - e
  );
  return norm360(v);
}

function radius(E_deg: number, e: number, a: number): number {
  return a * (1 - e * cos(E_deg));
}

// ─── Obliquity of the Ecliptic ────────────────────────────────────────────────

function obliquity(jd: number): number {
  const t = T(jd);
  // Meeus Ch.22 (low accuracy, sufficient for our purposes)
  return 23.4392911
    - 0.0130042 * t
    - 0.0000164 * t * t
    + 0.0000504 * t * t * t;
}

// ─── Lahiri Ayanamsa ──────────────────────────────────────────────────────────

/**
 * Lahiri (Chitrapaksha) ayanamsa — standard for Vedic astrology.
 * Returns degrees to subtract from tropical longitude to get sidereal.
 */
export function lahiriAyanamsa(jd: number): number {
  const t = T(jd);
  // Straight-line approximation from Lahiri definition, good to ~0.01°
  return 23.85 + 0.013608 * t;
}

function toSidereal(tropDeg: number, ayanamsa: number): number {
  return norm360(tropDeg - ayanamsa);
}

// ─── Sidereal Time ────────────────────────────────────────────────────────────

function greenwichSiderealTime(jd: number): number {
  // Greenwich Mean Sidereal Time in degrees (Meeus Ch.12)
  const t = T(jd);
  const GMST = 280.46061837
    + 360.98564736629 * dJ2000(jd)
    + 0.000387933 * t * t
    - t * t * t / 38710000;
  return norm360(GMST);
}

function localSiderealTime(jd: number, lonDeg: number): number {
  return norm360(greenwichSiderealTime(jd) + lonDeg);
}

// ─── Sun ──────────────────────────────────────────────────────────────────────

function sunLongitude(jd: number): { lon: number; lat: number } {
  const t = T(jd);
  const L0 = norm360(280.46646 + 36000.76983 * t);
  const M  = norm360(357.52911 + 35999.05029 * t - 0.0001537 * t * t);
  const C  = (1.914602 - 0.004817 * t - 0.000014 * t * t) * sin(M)
           + (0.019993 - 0.000101 * t) * sin(2 * M)
           + 0.000289 * sin(3 * M);
  return { lon: norm360(L0 + C), lat: 0 };
}

/** Heliocentric X/Y for Earth (Schlyter Sun/Earth orbital elements) */
function earthXY(d: number): { x: number; y: number } {
  const w = norm360(282.9404 + 4.70935e-5 * d);
  const e = 0.016709 - 1.151e-9 * d;
  const M = norm360(356.0470 + 0.9856002585 * d);
  const v = trueAnomaly(M, e);
  const r = radius(solveKepler(norm360(M), e), e, 1.0);
  const lon = norm360(v + w);
  return { x: r * cos(lon), y: r * sin(lon) };
}

// ─── Moon ─────────────────────────────────────────────────────────────────────

function moonLongitude(jd: number): { lon: number; lat: number } {
  // Simplified ELP2000 — accurate to ~0.3° (sufficient for nakshatra determination)
  const t = T(jd);
  const d = dJ2000(jd);

  // Fundamental arguments (degrees)
  const Lp = norm360(218.3165 + 481267.8813 * t);    // mean longitude
  const D  = norm360(297.8502 + 445267.1115 * t);    // mean elongation
  const Ms = norm360(357.5291 + 35999.0503 * t);     // Sun's mean anomaly
  const M  = norm360(134.9634 + 477198.8676 * t);    // Moon's mean anomaly
  const F  = norm360(93.2721  + 483202.0175 * t);    // arg of latitude

  const sumL =
    6.2888 * sin(M)
    + 1.2740 * sin(2 * D - M)
    + 0.6583 * sin(2 * D)
    + 0.2136 * sin(2 * M)
    - 0.1851 * sin(Ms)
    - 0.1143 * sin(2 * F)
    + 0.0588 * sin(2 * D - 2 * M)
    + 0.0572 * sin(2 * D - Ms - M)
    + 0.0533 * sin(2 * D + M)
    + 0.0458 * sin(2 * D - Ms)
    + 0.0409 * sin(M - Ms)
    - 0.0357 * sin(D)
    - 0.0302 * sin(Ms + M)
    - 0.0150 * sin(2 * F - 2 * D)
    + 0.0113 * sin(2 * D - 2 * Ms);

  const sumB =
    5.1282 * sin(F)
    + 0.2806 * sin(M + F)
    + 0.2777 * sin(M - F)
    + 0.1732 * sin(2 * D - F)
    + 0.0554 * sin(2 * D + F - M)
    + 0.0463 * sin(2 * D - F - M)
    + 0.0326 * sin(2 * D + F)
    - 0.0172 * sin(Ms - F)
    - 0.0093 * sin(2 * D - Ms - F);

  return { lon: norm360(Lp + sumL), lat: sumB };
}

// ─── Planetary Heliocentric Positions (Schlyter) ──────────────────────────────

interface OrbElems { N: number; i: number; w: number; a: number; e: number; M: number }

function orbitalElems(d: number): Record<string, OrbElems> {
  return {
    mercury: {
      N: norm360(48.3313 + 3.24587e-5 * d),
      i: 7.0047 + 5.00e-8 * d,
      w: norm360(29.1241 + 1.01444e-5 * d),
      a: 0.387098,
      e: 0.205635 + 5.59e-10 * d,
      M: norm360(168.6562 + 4.0923344368 * d),
    },
    venus: {
      N: norm360(76.6799 + 2.46590e-5 * d),
      i: 3.3946 + 2.75e-8 * d,
      w: norm360(54.8910 + 1.38374e-5 * d),
      a: 0.723330,
      e: 0.006773 - 1.302e-9 * d,
      M: norm360(48.0052 + 1.6021302244 * d),
    },
    mars: {
      N: norm360(49.5574 + 2.11081e-5 * d),
      i: 1.8497 - 1.78e-8 * d,
      w: norm360(286.5016 + 2.92961e-5 * d),
      a: 1.523688,
      e: 0.093405 + 2.516e-9 * d,
      M: norm360(18.6021 + 0.5240207766 * d),
    },
    jupiter: {
      N: norm360(100.4542 + 2.76854e-5 * d),
      i: 1.3030 - 1.557e-7 * d,
      w: norm360(273.8777 + 1.64505e-5 * d),
      a: 5.20256,
      e: 0.048498 + 4.469e-9 * d,
      M: norm360(19.8950 + 0.0830853001 * d),
    },
    saturn: {
      N: norm360(113.6634 + 2.38980e-5 * d),
      i: 2.4886 - 1.081e-7 * d,
      w: norm360(339.3939 + 2.97661e-5 * d),
      a: 9.55475,
      e: 0.055546 - 9.499e-9 * d,
      M: norm360(316.9670 + 0.0334442282 * d),
    },
  };
}

/** Returns heliocentric ecliptic x/y/z for a planet given its orbital elements */
function helioXYZ(el: OrbElems): { x: number; y: number; z: number } {
  const v = trueAnomaly(el.M, el.e);
  const E = solveKepler(norm360(el.M), el.e);
  const r = radius(E, el.e, el.a);
  const vw = v + el.w;

  const x = r * (cos(el.N) * cos(vw) - sin(el.N) * sin(vw) * cos(el.i));
  const y = r * (sin(el.N) * cos(vw) + cos(el.N) * sin(vw) * cos(el.i));
  const z = r * sin(vw) * sin(el.i);
  return { x, y, z };
}

/** Convert heliocentric planet coords to geocentric ecliptic longitude */
function geocentricLon(
  planet: { x: number; y: number; z: number },
  earth: { x: number; y: number }
): { lon: number; lat: number } {
  const xg = planet.x - earth.x;
  const yg = planet.y - earth.y;
  const zg = planet.z;

  const lon = norm360(atan2d(yg, xg));
  const lat = atan2d(zg, Math.sqrt(xg * xg + yg * yg));
  return { lon, lat };
}

// ─── Moon's Nodes (Rahu/Ketu) ─────────────────────────────────────────────────

function rahuLongitude(jd: number): number {
  // Mean North Node (Rahu) — Meeus Ch.47
  const T_ = T(jd);
  const rahu = norm360(
    125.04452
    - 1934.136261 * T_
    + 0.0020708 * T_ * T_
    + T_ * T_ * T_ / 450000
  );
  return rahu;
}

// ─── Ascendant ────────────────────────────────────────────────────────────────

/**
 * Computes the tropical ecliptic longitude of the Ascendant.
 * Uses the standard RAMC-based formula.
 */
function ascendantTropical(jd: number, latDeg: number, lonDeg: number): number {
  const LST  = localSiderealTime(jd, lonDeg); // degrees (= RAMC in degrees)
  const eps  = obliquity(jd);

  // Standard ascendant formula
  const RAMC = LST;
  const asc = norm360(
    atan2d(
      cos(RAMC),
      -(sin(RAMC) * cos(eps) + tan(latDeg) * sin(eps))
    )
  );
  return asc;
}

// ─── Sign & House ─────────────────────────────────────────────────────────────

function signOf(siderealDeg: number): { sign: string; index: number; degree: number } {
  const idx = Math.floor(siderealDeg / 30) % 12;
  return {
    sign: SIGNS[idx],
    index: idx,
    degree: siderealDeg % 30,
  };
}

/**
 * Whole sign house number (1-12) of a planet given ascendant sign index.
 */
function wholeSignHouse(planetSignIdx: number, ascSignIdx: number): number {
  return ((planetSignIdx - ascSignIdx + 12) % 12) + 1;
}

// ─── Nakshatra ────────────────────────────────────────────────────────────────

export function nakshatraOf(moonSiderealDeg: number): NakshatraInfo {
  const idx  = Math.floor(moonSiderealDeg / NAKSHATRA_SPAN);
  const frac = (moonSiderealDeg % NAKSHATRA_SPAN) / NAKSHATRA_SPAN;
  const pada = Math.floor(frac * 4) + 1;

  return {
    name:  NAKSHATRAS[idx],
    pada,
    lord:  NAKSHATRA_LORDS[idx],
    index: idx,
  };
}

// ─── Vimshottari Dasha ────────────────────────────────────────────────────────

function addYears(date: Date, years: number): Date {
  const ms = years * DAYS_PER_YEAR * 24 * 60 * 60 * 1000;
  return new Date(date.getTime() + ms);
}

function isoDate(d: Date): string {
  return d.toISOString().split("T")[0];
}

export function computeDasha(moonSiderealDeg: number, birthDate: Date): DashaInfo {
  const nakshatraIdx = Math.floor(moonSiderealDeg / NAKSHATRA_SPAN);
  const dashaLordIdx = NAKSHATRA_TO_DASHA_LORD[nakshatraIdx];

  // How far through the birth nakshatra the Moon is
  const elapsedFrac = (moonSiderealDeg % NAKSHATRA_SPAN) / NAKSHATRA_SPAN;

  // Balance of the birth dasha
  const birthDashaYears = VIMSHOTTARI[dashaLordIdx].years * (1 - elapsedFrac);

  const today = new Date();

  // Walk through dashas from birth until we find the current one
  let mahaStart = new Date(birthDate);
  let currentMaha: DashaEntry | null = null;
  let currentMahaIdx = dashaLordIdx;

  for (let cycle = 0; cycle < 3; cycle++) { // 3 full Vimshottari cycles = 360 years
    for (let i = 0; i < 9; i++) {
      const idx = (dashaLordIdx + i) % 9;
      const years = (cycle === 0 && i === 0) ? birthDashaYears : VIMSHOTTARI[idx].years;
      const mahaEnd = addYears(mahaStart, years);

      if (mahaStart <= today && today < mahaEnd) {
        currentMaha = {
          planet: VIMSHOTTARI[idx].planet,
          startDate: isoDate(mahaStart),
          endDate: isoDate(mahaEnd),
          yearsRemaining: (mahaEnd.getTime() - today.getTime()) / (DAYS_PER_YEAR * 86400000),
        };
        currentMahaIdx = idx;
        break;
      }
      mahaStart = mahaEnd;
    }
    if (currentMaha) break;
  }

  if (!currentMaha) {
    // Fallback: just return first dasha
    const mahaEnd = addYears(birthDate, birthDashaYears);
    currentMaha = {
      planet: VIMSHOTTARI[dashaLordIdx].planet,
      startDate: isoDate(birthDate),
      endDate: isoDate(mahaEnd),
    };
    currentMahaIdx = dashaLordIdx;
  }

  // ── Antardasha within current Mahadasha ──
  const mahaYears = parseFloat(
    ((new Date(currentMaha.endDate).getTime() - new Date(currentMaha.startDate).getTime()) /
      (DAYS_PER_YEAR * 86400000)).toFixed(4)
  );

  let antarStart = new Date(currentMaha.startDate);
  let currentAntar: DashaEntry | null = null;
  let currentAntarIdx = currentMahaIdx;

  for (let i = 0; i < 9; i++) {
    const idx = (currentMahaIdx + i) % 9;
    const antarYears = (mahaYears * VIMSHOTTARI[idx].years) / 120;
    const antarEnd = addYears(antarStart, antarYears);

    if (antarStart <= today && today < antarEnd) {
      currentAntar = {
        planet: VIMSHOTTARI[idx].planet,
        startDate: isoDate(antarStart),
        endDate: isoDate(antarEnd),
      };
      currentAntarIdx = idx;
      break;
    }
    antarStart = antarEnd;
  }

  if (!currentAntar) {
    const idx = currentMahaIdx;
    const antarYears = (mahaYears * VIMSHOTTARI[idx].years) / 120;
    currentAntar = {
      planet: VIMSHOTTARI[idx].planet,
      startDate: currentMaha.startDate,
      endDate: isoDate(addYears(new Date(currentMaha.startDate), antarYears)),
    };
    currentAntarIdx = idx;
  }

  // ── Pratyantardasha within current Antardasha ──
  const antarYearsActual = parseFloat(
    ((new Date(currentAntar.endDate).getTime() - new Date(currentAntar.startDate).getTime()) /
      (DAYS_PER_YEAR * 86400000)).toFixed(4)
  );

  let pratStart = new Date(currentAntar.startDate);
  let currentPrat: DashaEntry | null = null;

  for (let i = 0; i < 9; i++) {
    const idx = (currentAntarIdx + i) % 9;
    const pratYears = (antarYearsActual * VIMSHOTTARI[idx].years) / 120;
    const pratEnd = addYears(pratStart, pratYears);

    if (pratStart <= today && today < pratEnd) {
      currentPrat = {
        planet: VIMSHOTTARI[idx].planet,
        startDate: isoDate(pratStart),
        endDate: isoDate(pratEnd),
      };
      break;
    }
    pratStart = pratEnd;
  }

  if (!currentPrat) {
    currentPrat = { ...currentAntar };
  }

  return {
    mahadasha: currentMaha,
    antardasha: currentAntar!,
    pratyantardasha: currentPrat,
  };
}

// ─── Transit Chart (current planetary positions) ──────────────────────────────

export function computeTransits(jd: number): Record<string, { sign: string; degree: number }> {
  const ayanamsa = lahiriAyanamsa(jd);
  const d = dJ2000(jd);
  const earth = earthXY(d);
  const elems = orbitalElems(d);

  const result: Record<string, { sign: string; degree: number }> = {};

  const sun = sunLongitude(jd);
  const sunSid = toSidereal(sun.lon, ayanamsa);
  const sunSign = signOf(sunSid);
  result.sun = { sign: sunSign.sign, degree: parseFloat(sunSign.degree.toFixed(2)) };

  const moon = moonLongitude(jd);
  const moonSid = toSidereal(moon.lon, ayanamsa);
  const moonSign = signOf(moonSid);
  result.moon = { sign: moonSign.sign, degree: parseFloat(moonSign.degree.toFixed(2)) };

  for (const [name, el] of Object.entries(elems)) {
    const xyz = helioXYZ(el);
    const { lon } = geocentricLon(xyz, earth);
    const sid = toSidereal(lon, ayanamsa);
    const s = signOf(sid);
    result[name] = { sign: s.sign, degree: parseFloat(s.degree.toFixed(2)) };
  }

  const rahu = rahuLongitude(jd);
  const rahuSid = toSidereal(rahu, ayanamsa);
  const rahuSign = signOf(rahuSid);
  result.rahu = { sign: rahuSign.sign, degree: parseFloat(rahuSign.degree.toFixed(2)) };

  const ketuSid = norm360(rahuSid + 180);
  const ketuSign = signOf(ketuSid);
  result.ketu = { sign: ketuSign.sign, degree: parseFloat(ketuSign.degree.toFixed(2)) };

  return result;
}

// ─── Main Chart Computation ───────────────────────────────────────────────────

/**
 * Computes a full Vedic natal chart.
 *
 * @param jd     Julian Day Number of the birth moment (in UT)
 * @param lat    Geographic latitude in decimal degrees (N positive)
 * @param lon    Geographic longitude in decimal degrees (E positive)
 * @param birthDate  JS Date of birth (for dasha calendar)
 */
export function computeNatalChart(
  jd: number,
  lat: number,
  lon: number,
  birthDate: Date
): NatalChart {
  const ayanamsa = lahiriAyanamsa(jd);
  const d = dJ2000(jd);
  const earth = earthXY(d);
  const elems = orbitalElems(d);

  // ── Ascendant ──
  const ascTrop = ascendantTropical(jd, lat, lon);
  const ascSid  = toSidereal(ascTrop, ayanamsa);
  const ascSign = signOf(ascSid);

  // ── Sun ──
  const sunTrop = sunLongitude(jd).lon;
  const sunSid  = toSidereal(sunTrop, ayanamsa);
  const sunSign = signOf(sunSid);

  // ── Moon ──
  const moonTrop = moonLongitude(jd).lon;
  const moonSid  = toSidereal(moonTrop, ayanamsa);
  const moonSign = signOf(moonSid);

  // ── Planets ──
  const planetData: Record<string, PlanetPosition> = {};

  const buildPlanet = (
    name: string,
    tropDeg: number,
    retrograde = false
  ): PlanetPosition => {
    const sid = toSidereal(tropDeg, ayanamsa);
    const s = signOf(sid);
    return {
      tropicalDeg: parseFloat(tropDeg.toFixed(4)),
      siderealDeg: parseFloat(sid.toFixed(4)),
      sign: s.sign,
      signIndex: s.index,
      signDegree: parseFloat(s.degree.toFixed(4)),
      house: wholeSignHouse(s.index, ascSign.index),
      retrograde,
    };
  };

  planetData.sun    = buildPlanet("sun", sunTrop);
  planetData.moon   = buildPlanet("moon", moonTrop);

  for (const [name, el] of Object.entries(elems)) {
    const xyz = helioXYZ(el);
    const { lon: geoLon } = geocentricLon(xyz, earth);
    planetData[name] = buildPlanet(name, geoLon);
  }

  // Rahu (North Node) — mean node, always retrograde in mean-motion convention
  const rahuTrop = rahuLongitude(jd);
  planetData.rahu = buildPlanet("rahu", rahuTrop, true);

  // Ketu = Rahu + 180°, always retrograde
  const ketuTrop = norm360(rahuTrop + 180);
  planetData.ketu = buildPlanet("ketu", ketuTrop, true);

  // ── Whole Sign Houses ──
  const houses: Record<number, string> = {};
  for (let h = 1; h <= 12; h++) {
    const signIdx = (ascSign.index + h - 1) % 12;
    houses[h] = SIGNS[signIdx];
  }

  // ── Nakshatra + Dasha ──
  const nk    = nakshatraOf(moonSid);
  const dasha = computeDasha(moonSid, birthDate);

  return {
    ascendant: buildPlanet("ascendant", ascTrop),
    planets: planetData,
    houses,
    nakshatra: nk,
    dasha,
    ayanamsa: parseFloat(ayanamsa.toFixed(4)),
  };
}
