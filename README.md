# Astro Daily

**Your personal Vedic astrology companion — powered by real celestial calculations and AI.**

Astro Daily turns your exact date, time, and place of birth into a living astrological profile. Every reading, every chart, every conversation is computed from your unique birth chart — not from generic sun-sign columns. The app combines the precision of Swiss Ephemeris planetary calculations with Google Gemini AI to deliver guidance that is genuinely yours.

---

## What makes Astro Daily different

Most astrology apps give the same reading to every Virgo or every Scorpio. Astro Daily doesn't. From the moment you complete your birth profile, the app computes your full Vedic natal chart server-side using the same Swiss Ephemeris engine that powers professional astrology software. Every feature — daily horoscope, chat, compatibility, gemstones — pulls from *your* chart, not a template.

- **Real Vedic astrology** — Lahiri ayanamsa sidereal zodiac, all nine Jyotish planets (Sun through Ketu), 12 houses, nakshatras, and the full Vimshottari dasha system.
- **AI that knows your chart** — Gemini 2.5 Flash receives your complete planetary positions, current transits, and active dasha period before answering any question.
- **No stale data** — Transits are refreshed every four hours; your chart is recomputed whenever your birth details change.
- **Privacy by design** — Your Gemini API key never touches the app binary. All AI calls route through Supabase edge functions running on your account's server.

---

## Features

### Daily Horoscope
Open the app each morning to a personalized reading built from your chart and the day's planetary transits. You get a concise AI-written summary of the day's energy, your lucky colour, your lucky number, and four practical Do's and Don'ts — all derived from your current Mahadasha lord and active transits, not a generic sun-sign blurb.

### Horoscope Chat — AI Companion
Ask your personal Vedic astrology advisor anything. The chat is powered by Gemini 2.5 Flash with your full birth chart embedded in every conversation. Ask about career timing, a relationship question, a health concern, or what your Saturn placement means for the next year. The AI cites specific placements by name ("your Saturn in Capricorn in the 10th house") and never gives generic filler. After each reply, three contextual follow-up question chips appear so you can dig deeper with a single tap.

- **Conversational context** — the last six turns of your session are included in every request, so the AI remembers what you were discussing.
- **Language aware** — responds in the language you write in; Hindi–English mixing is fully supported.
- **Quota:** 3 questions per day on the free plan, 30 per day on Premium.

### Kundli — Your Birth Chart
A full Vedic birth chart summary showing your ascendant (Lagna), sun sign, moon sign, and current life focus area. Tap through to see all nine planets with their signs, houses, and exact degrees, all 12 house cusps, your birth nakshatra and pada, and your active Mahadasha and Antardasha periods with their end dates.

### Compatibility Matching
Enter a partner's date, time, and place of birth to get a compatibility score and analysis. The engine compares ascendants, moon signs, and elemental triplicities from both charts to produce a score, a rating (Excellent / Good / Average / Challenging), and a narrative that explains what the placements actually mean for the relationship.

### Numerology
Your life path number is calculated from your date of birth using Pythagorean digit reduction — including master numbers 11, 22, and 33. The result comes with an archetypal title ("The Leader", "The Visionary", "The Creative") and a paragraph of guidance grounded in what that number represents.

### Gemstone Recommendations
Based on your ascendant and active dasha lord, the app recommends a primary gemstone and an alternative. Each recommendation includes the planetary rulership behind it and a summary of how wearing the stone is said to support your current life phase.

---

## Getting Started

1. **Sign up** with email and password, Google, or Apple.
2. **Complete your birth profile** — enter your full name, date of birth, time of birth, and city. The app geocodes your city to get the precise latitude, longitude, and timezone needed for accurate chart calculation.
3. Your natal chart is computed on the server and cached. From this point every feature is personalised to you.
4. Open the **Daily Horoscope** to see today's reading, or tap the chat button to ask your first question.

---

## Free vs Premium

| Feature | Free | Premium |
|---|---|---|
| Daily Horoscope | Unlimited | Unlimited |
| Horoscope Chat | 3 questions / day | 30 questions / day |
| Kundli (birth chart) | 1 view / week | Unlimited |
| Numerology | 1 reading / day | Unlimited |
| Compatibility Matching | 1 check / day | Unlimited |
| Gemstones | 1 reading / week | Unlimited |
| Ads / reward prompts | Yes | No |

Premium is available as a monthly or yearly subscription. Free users can watch a short rewarded ad to unlock one additional use per period for most features.

---

## Tech Stack

| Layer | Technology |
|---|---|
| App | Flutter (Material 3) |
| State management | BLoC / Cubit |
| Backend | Supabase (Postgres + Edge Functions) |
| Authentication | Supabase Auth — email, Google, Apple |
| AI | Google Gemini 2.5 Flash |
| Ephemeris | Swiss Ephemeris (Deno / WASM) |
| Geocoding | Nominatim |
| Astrology system | Vedic / Jyotish, Lahiri ayanamsa |

---

## Developer Setup

### Prerequisites
- Flutter 3.11+
- A Supabase project
- A Google AI Studio API key (for Gemini)
- Google OAuth and Apple Sign-In credentials (optional for social login)

### Environment variables

Create a `.env` file at the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=your-ios-client-id.apps.googleusercontent.com
GOOGLE_MACOS_SIGN_IN_ENABLED=false
APPLE_SIGN_IN_ENABLED=true
```

### Supabase secrets

```bash
supabase secrets set GEMINI_API_KEY=your-gemini-api-key
```

### Run

```bash
flutter pub get
flutter run
```

### Deploy edge functions

```bash
supabase functions deploy chat --project-ref your-project-ref
supabase functions deploy astro --project-ref your-project-ref
supabase functions deploy compute-chart --project-ref your-project-ref
```

### Social sign-in notes
- **Google on iOS** — add the reversed iOS client ID URL scheme to `ios/Runner/Info.plist`.
- **Google on macOS** — requires Apple development signing and keychain sharing; disabled by default (`GOOGLE_MACOS_SIGN_IN_ENABLED=false`).
- **Apple** — enable Sign in with Apple in the Apple Developer portal and in the Supabase Auth dashboard.
