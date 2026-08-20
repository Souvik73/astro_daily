import tzLookup from "tz-lookup";

export interface GeoResult {
  lat: number;
  lon: number;
  tz: string;      // IANA timezone e.g. "Asia/Kolkata"
  displayName: string;
}

/**
 * Geocodes a place name string to lat/lon + IANA timezone.
 * Uses Nominatim (OpenStreetMap) — free, no API key required.
 * Rate limit: 1 req/sec (fine for our use case — one call per user lifetime).
 */
export async function geocodePlace(place: string): Promise<GeoResult> {
  const url =
    `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(place)}&format=json&limit=1`;

  const response = await fetch(url, {
    headers: {
      // Nominatim requires a User-Agent header identifying your app
      "User-Agent": "AstroDailyApp/1.0 (innoclaudepro@gmail.com)",
      "Accept-Language": "en",
    },
  });

  if (!response.ok) {
    throw new Error(`Nominatim geocoding failed: ${response.status}`);
  }

  const results = await response.json();

  if (!results || results.length === 0) {
    throw new Error(`Place not found: "${place}"`);
  }

  const { lat, lon, display_name } = results[0];
  const latNum = parseFloat(lat);
  const lonNum = parseFloat(lon);

  // Resolve IANA timezone from coordinates using offline tz-lookup (no API key)
  const tz = tzLookup(latNum, lonNum);

  return {
    lat: latNum,
    lon: lonNum,
    tz,
    displayName: display_name,
  };
}
