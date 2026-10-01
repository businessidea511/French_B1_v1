-- PolyLearn French: table for "Duel entre amis" scores.
-- Run ONCE in Supabase → SQL Editor. Only the server (/api/duel, service role)
-- can read or write it; the public anon key has no access.

create table if not exists public.duel_scores (
  id bigint generated always as identity primary key,
  code text not null check (code ~ '^[A-Z0-9]{6}$'),
  name text not null check (char_length(name) between 1 and 24),
  score int not null check (score between 0 and 5000),
  correct int not null check (correct between 0 and 10),
  seconds int not null check (seconds between 0 and 3600),
  created_at timestamptz not null default now()
);

create index if not exists duel_scores_code_idx on public.duel_scores (code, score desc);

alter table public.duel_scores enable row level security;
revoke all on public.duel_scores from anon, authenticated;
