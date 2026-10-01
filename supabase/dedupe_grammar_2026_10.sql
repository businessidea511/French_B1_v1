-- PolyLearn French: remove duplicate grammar topics (October 2026).
-- Run ONCE in Supabase → SQL Editor. Everything it changes is first copied to
-- grammar_backup_2026_10, so nothing is lost.
--
-- One topic per subject is kept. Where a built-in topic exists, the most
-- complete AI version is moved into the built-in row (so the topic keeps its
-- fixed id), then the extra copies are deleted:
--
--   L'Impératif   keep "imperatif"     ← content of custom_grammar_1789719103815 (51 blocks)
--   COD / COI     keep "cod_coi"       ← content of custom_grammar_1781363223189 (26 blocks)
--   Conditionnel  keep "conditionnel"  ← content of custom_grammar_1781781263247 (17 blocks)
--   Superlatif    keep custom_grammar_1781206274994, delete custom_grammar_1781443780858
--
-- Afterwards, open each of these topics in the app → Update → "Rebuild complete topic".

begin;

-- 1. Backup (private: RLS on, no policies)
create table if not exists public.grammar_backup_2026_10 as
  select g.*, now() as backed_up_at from public.grammar g where false;
alter table public.grammar_backup_2026_10 enable row level security;
revoke all on public.grammar_backup_2026_10 from anon, authenticated;

insert into public.grammar_backup_2026_10
select g.*, now() from public.grammar g
where g.id in (
  'imperatif', 'custom_grammar_1779297681826', 'custom_grammar_1789719103815',
  'cod_coi', 'custom_grammar_1781363223189', 'custom_grammar_1790866102041',
  'conditionnel', 'custom_grammar_1781781263247',
  'custom_grammar_1781443780858'
);

-- 2. Move the best version into the built-in rows
update public.grammar k
set content = s.content, subtitle = s.subtitle, description = s.description
from public.grammar s
where (k.id, s.id) in (
  ('imperatif',    'custom_grammar_1789719103815'),
  ('cod_coi',      'custom_grammar_1781363223189'),
  ('conditionnel', 'custom_grammar_1781781263247')
);

-- 3. Delete the extra copies
delete from public.grammar
where id in (
  'custom_grammar_1779297681826', 'custom_grammar_1789719103815',
  'custom_grammar_1781363223189', 'custom_grammar_1790866102041',
  'custom_grammar_1781781263247',
  'custom_grammar_1781443780858'
);

commit;

-- Check: should list 20 topics, each subject once.
select id, title, jsonb_array_length(coalesce(content::jsonb, '[]'::jsonb)) as blocks
from public.grammar
order by title;
