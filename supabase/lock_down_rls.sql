-- PolyLearn French: lock down the database.
--
-- Run ONCE in Supabase Dashboard → SQL Editor, AFTER the version that writes
-- through /api/content is live on Vercel (otherwise old builds can't save).
--
-- Result:
--   lessons, grammar      → anyone can READ, nobody can write with the public anon key
--   admin_ai_saved_qas    → no public access at all
--   The Vercel functions use the service role key, which bypasses RLS, so admin
--   edits keep working through /api/content.

begin;

-- 1. Remove every existing policy on these tables (including any "allow all" ones).
do $$
declare
  p record;
begin
  for p in
    select policyname, tablename
    from pg_policies
    where schemaname = 'public'
      and tablename in ('lessons', 'grammar', 'admin_ai_saved_qas')
  loop
    execute format('drop policy %I on public.%I', p.policyname, p.tablename);
  end loop;
end $$;

-- 2. Turn RLS on. With no policy, a role sees and changes nothing.
alter table public.lessons            enable row level security;
alter table public.grammar            enable row level security;
alter table public.admin_ai_saved_qas enable row level security;

-- 3. Public read-only access to course content.
create policy "Anyone can read lessons"
  on public.lessons for select
  to anon, authenticated
  using (true);

create policy "Anyone can read grammar"
  on public.grammar for select
  to anon, authenticated
  using (true);

-- 4. Belt and braces: remove write privileges from the public roles too.
revoke insert, update, delete, truncate on public.lessons, public.grammar from anon, authenticated;
revoke all on public.admin_ai_saved_qas from anon, authenticated;

commit;

-- Check: should list exactly two SELECT policies, and rls_enabled = true for all three tables.
select tablename, policyname, cmd, roles from pg_policies
where schemaname = 'public' and tablename in ('lessons', 'grammar', 'admin_ai_saved_qas');

select relname as table_name, relrowsecurity as rls_enabled
from pg_class
where relnamespace = 'public'::regnamespace
  and relname in ('lessons', 'grammar', 'admin_ai_saved_qas');
