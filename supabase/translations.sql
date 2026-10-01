-- PolyLearn French: shared translations (one translation per language and text, for every user).
-- Run ONCE in Supabase → SQL Editor. Only the server (/api/translate, service role)
-- can read or write it; the public anon key has no access.

create table if not exists public.translations (
  lang text not null check (lang in ('fr', 'ar', 'uk', 'it', 'ti', 'tr', 'id')),
  hash text not null check (hash ~ '^[0-9a-f]{16}$'),   -- first 16 hex chars of sha1(source)
  source text not null check (char_length(source) <= 6000),
  translated text not null check (char_length(translated) <= 20000),
  created_at timestamptz not null default now(),
  primary key (lang, hash)
);

alter table public.translations enable row level security;
revoke all on public.translations from anon, authenticated;
