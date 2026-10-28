-- Fresh-database baseline captured from the live schema on 2026-10-28.
-- Existing projects: follow supabase/README.md before using db push.
begin;

create table public.good_faith_ledgers (
  "user_id" uuid not null,
  "people" jsonb default '[]'::jsonb not null,
  "scenarios" jsonb default '[]'::jsonb not null,
  PRIMARY KEY (user_id),
  CHECK (jsonb_typeof(scenarios) = 'array'::text),
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CHECK (jsonb_typeof(people) = 'array'::text)
);
alter table public.good_faith_ledgers enable row level security;


grant usage on schema public to authenticated, service_role;
revoke all on public.good_faith_ledgers from public, anon, authenticated;
grant select, insert, update on public.good_faith_ledgers to authenticated;
grant select, insert, update, delete on public.good_faith_ledgers to service_role;
create policy "own_select" on public.good_faith_ledgers
  for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "own_insert" on public.good_faith_ledgers
  for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "own_update" on public.good_faith_ledgers
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

commit;
