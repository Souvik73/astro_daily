-- ============================================================
-- Astro Daily: Track profiles + birth_details schema
-- Migration: 20260828200409_profiles_birth_details.sql
--
-- These two tables already exist in production — they were created
-- out-of-band (dashboard/SQL editor) before this repo tracked
-- migrations, so their schema was invisible to version control.
-- This migration captures their VERIFIED live schema, introspected
-- directly via `supabase db query --linked` against
-- information_schema / pg_catalog (not guessed from client code).
-- Every statement is written to be a safe no-op against the existing
-- tables/policies, and a correct bootstrap if ever run against a
-- fresh database.
-- ============================================================

-- ----------------------------------------------------------------
-- 1. profiles
--    One row per user. `display_name` is the value the app treats as
--    the source of truth (see AuthLocalDataSource._buildUser) —
--    auth user_metadata is only a fallback if this row is missing.
-- ----------------------------------------------------------------
create table if not exists public.profiles (
  user_id      uuid        primary key
                            references auth.users(id) on delete cascade,
  display_name text,
  updated_at   timestamptz default now()
);

alter table public.profiles enable row level security;

do $$
begin
  create policy "own profile rw"
    on public.profiles
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
exception
  when duplicate_object then null;
end $$;

create index if not exists profiles_user_id_idx on public.profiles (user_id);

-- ----------------------------------------------------------------
-- 2. birth_details
--    One row per user. Written alongside `birth_charts` whenever
--    profile completion or the profile-edit flow runs; also read as
--    a fallback source for chart computation in the `chat` function
--    if `birth_charts` is somehow missing.
--    Note: dates are stored as text (ISO 8601 string), not `date` —
--    matches BirthProfile.dateOfBirth.toIso8601String() on write.
-- ----------------------------------------------------------------
create table if not exists public.birth_details (
  user_id        uuid        primary key
                              references auth.users(id) on delete cascade,
  zodiac_sign    text,
  date_of_birth  text,
  time_of_birth  text,
  place_of_birth text,
  updated_at     timestamptz default now()
);

alter table public.birth_details enable row level security;

do $$
begin
  create policy "own birth rw"
    on public.birth_details
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
exception
  when duplicate_object then null;
end $$;

create index if not exists birth_details_user_id_idx on public.birth_details (user_id);
