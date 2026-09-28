alter table public.good_faith_ledgers
  add column scenarios jsonb not null default '[]'::jsonb
  check (jsonb_typeof(scenarios) = 'array');
