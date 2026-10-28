# Database setup

This repo owns only its app's tables. The fresh-database baseline includes explicit
Data API grants, RLS policies, and constraints. It contains no production data.
Supabase manages the auth and storage schemas.

## Fresh local database

Install the [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started)
and a Docker-compatible runtime, then run from the repository root:

```sh
supabase start
supabase db reset --local
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -v ON_ERROR_STOP=1 -f supabase/tests/access.sql
```

The SQL test runs in a transaction and rolls back its test users and data. It checks
successful access as the owner, rejected cross-user access, denied anonymous access
where appropriate, and service-role access. Run it against a disposable local database.

For a new hosted project with no app tables, link to that project, review
`supabase db push --dry-run`, and apply with `supabase db push`. Configure the app's
Supabase URL, publishable/anon key, and auth redirect URLs for that project.

## Existing deployed database

This is a fresh-install baseline, not a production upgrade. Do not run it against
an existing app database: the tables already exist. Existing tables keep their
permissions through the October 30, 2026 change.

Before adopting CLI deployment for an existing project, compare its schema and
migration history with this baseline, reconcile any differences, and mark the
baseline as applied with `supabase migration repair --status applied <version>`
only once they match. Inspect `supabase migration list --linked` and
`supabase db push --dry-run` first. Never reset the linked production database.

For every future table, include only the grants the app needs, enable RLS, and add
ownership policies in the same migration. RLS and grants are both required; never
fix a permission error by disabling RLS or exposing a service-role key in the app.

## Good Faith details

Creates `public.good_faith_ledgers` with array-validated `people` and `scenarios`
JSON, one row per auth user, and deletion when the auth user is deleted.
Authenticated users can select, insert, and update only their own ledger; no
anonymous access or client table-level delete grant is needed.

Fresh setup already includes `scenarios`. The old `db/think_ahead.sql` patch is
only for older existing tables that lack that column, not for a fresh database.
The current frontend points at the shared hosted project in `src/Supabase.js`;
update its URL and publishable/anon key to use a different project.
