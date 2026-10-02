-- PolyLearn French: live duels (waiting room + everyone starts at the same time).
-- Run ONCE in Supabase → SQL Editor (after duels.sql). Only the server
-- (/api/duel, service role) can read or write; the public anon key has no access.

-- Who created the duel (a secret only the creator's app knows) and when it starts.
alter table public.duels add column if not exists host_key text check (host_key is null or char_length(host_key) between 16 and 64);
alter table public.duels add column if not exists host_name text check (host_name is null or char_length(host_name) <= 24);
alter table public.duels add column if not exists started_at timestamptz;

-- The players waiting in (or playing) each duel.
create table if not exists public.duel_players (
  code text not null references public.duels (code) on delete cascade,
  name_key text not null check (char_length(name_key) between 1 and 24),  -- lower-case name, one entry per person
  name text not null check (char_length(name) between 1 and 24),
  joined_at timestamptz not null default now(),
  primary key (code, name_key)
);

alter table public.duel_players enable row level security;
revoke all on public.duel_players from anon, authenticated;
