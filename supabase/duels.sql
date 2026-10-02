-- PolyLearn French: duels with chosen topics and 5 to 20 questions.
-- Run ONCE in Supabase → SQL Editor (after duel_scores.sql). Only the server
-- (/api/duel, service role) can read or write; the public anon key has no access.

-- The questions of each duel, so every player of a class gets the same ones.
create table if not exists public.duels (
  code text primary key check (code ~ '^[A-Z0-9]{6}$'),
  topics jsonb not null default '[]'::jsonb,
  questions jsonb not null check (jsonb_typeof(questions) = 'array' and pg_column_size(questions) < 100000),
  created_at timestamptz not null default now()
);

alter table public.duels enable row level security;
revoke all on public.duels from anon, authenticated;

-- Scores: up to 20 correct answers now (it was 10).
alter table public.duel_scores drop constraint if exists duel_scores_correct_check;
alter table public.duel_scores add constraint duel_scores_correct_check check (correct between 0 and 20);
