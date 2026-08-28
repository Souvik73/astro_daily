-- ============================================================
-- Astro Daily: Push notification device tokens
-- Migration: 20260821000000_push_tokens.sql
-- ============================================================

-- ----------------------------------------------------------------
-- push_tokens
--    One row per (user, device). Registered/removed directly by the
--    Flutter app when the user flips the "Daily push notifications"
--    setting on/off — no edge function needed since there's no
--    server-side validation beyond "you can only touch your own rows".
--    A user with zero rows here is treated as opted out.
-- ----------------------------------------------------------------
create table if not exists public.push_tokens (
  user_id     uuid        not null references auth.users(id) on delete cascade,
  token       text        not null,        -- FCM registration token
  platform    text        not null,        -- 'android' | 'ios'
  updated_at  timestamptz not null default now(),
  primary key (user_id, token)
);

alter table public.push_tokens enable row level security;

-- Users manage only their own device tokens directly (no service-role
-- edge function in the loop for register/unregister).
create policy "push_tokens_self_select"
  on public.push_tokens
  for select
  using (user_id = auth.uid());

create policy "push_tokens_self_insert"
  on public.push_tokens
  for insert
  with check (user_id = auth.uid());

create policy "push_tokens_self_update"
  on public.push_tokens
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "push_tokens_self_delete"
  on public.push_tokens
  for delete
  using (user_id = auth.uid());

create index if not exists push_tokens_user_id_idx on public.push_tokens (user_id);
