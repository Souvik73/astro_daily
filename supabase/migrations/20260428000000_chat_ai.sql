-- ============================================================
-- Astro Daily: AI Chat + Birth Chart cache
-- Migration: 20260428000000_chat_ai.sql
-- ============================================================

-- ----------------------------------------------------------------
-- 1. birth_charts
--    One row per user. Computed once on profile completion,
--    re-computed when DOB/time/place changes (dob_hash detects this).
--    The `transits` column is refreshed nightly by pg_cron.
-- ----------------------------------------------------------------
create table if not exists public.birth_charts (
  user_id                uuid        primary key
                                     references auth.users(id) on delete cascade,
  dob_hash               text        not null,        -- sha256(dob||tob||place) to detect changes
  lat                    numeric,                     -- geocoded latitude
  lon                    numeric,                     -- geocoded longitude
  tz                     text,                        -- IANA timezone string e.g. "Asia/Kolkata"
  chart                  jsonb       not null,        -- natal chart: planets, houses, ascendant, nakshatra, dasha
  transits               jsonb,                       -- today's planetary transits (refreshed daily)
  transits_refreshed_at  timestamptz,
  computed_at            timestamptz not null default now()
);

-- Only authenticated owners may read their own row.
-- INSERT / UPDATE is performed exclusively by edge functions using the service-role key.
alter table public.birth_charts enable row level security;

create policy "birth_charts_self_read"
  on public.birth_charts
  for select
  using (user_id = auth.uid());

-- Index for fast lookup (already covered by PK, but explicit for clarity)
create index if not exists birth_charts_user_id_idx on public.birth_charts (user_id);

-- ----------------------------------------------------------------
-- 2. chat_quotas
--    Server-side rate limiting.  One row per (user, UTC day).
--    The edge function does an atomic upsert and returns `remaining`.
--    Rows older than 35 days are pruned by pg_cron.
-- ----------------------------------------------------------------
create table if not exists public.chat_quotas (
  user_id   uuid    not null references auth.users(id) on delete cascade,
  day       date    not null,
  count     integer not null default 0,
  primary key (user_id, day)
);

alter table public.chat_quotas enable row level security;

-- Users can read their own quota (so the Flutter app can pre-check).
-- The edge function uses the service-role key to write.
create policy "chat_quotas_self_read"
  on public.chat_quotas
  for select
  using (user_id = auth.uid());

create index if not exists chat_quotas_user_day_idx on public.chat_quotas (user_id, day);

-- ----------------------------------------------------------------
-- 3. pg_cron jobs (requires the pg_cron extension).
--    These are set up as DO blocks so they are idempotent.
-- ----------------------------------------------------------------

-- Enable pg_cron if available (Supabase Pro has it; free tier may not).
-- Wrapped in a block so the migration doesn't fail on free-tier projects.
do $$
begin
  if exists (
    select 1 from pg_available_extensions where name = 'pg_cron'
  ) then
    create extension if not exists pg_cron schema extensions;

    -- Prune chat_quotas rows older than 35 days — runs at 00:05 UTC daily.
    perform cron.schedule(
      'prune-chat-quotas',
      '5 0 * * *',
      $cron$
        delete from public.chat_quotas where day < current_date - interval '35 days';
      $cron$
    );
  end if;
exception
  when others then
    raise notice 'pg_cron setup skipped: %', sqlerrm;
end;
$$;
