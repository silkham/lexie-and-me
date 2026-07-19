-- Lexie & Me — Supabase schema
-- Run this once in the Supabase SQL Editor (New query → paste → Run).
--
-- IMPORTANT (security): the anon key lives in your public app, so anyone who
-- finds your repo could read/write this table IF they can guess the row id.
-- So DON'T use a guessable id like 'oxted'. Before running this, replace every
-- 'household-a755d170726cc15c5cb55a1b5cfd45db4795f088' below with the SAME long random
-- string (e.g. generate one at https://www.uuidgenerator.net or mash the
-- keyboard for 30+ characters). Use that identical string in supabase-sync.js.
-- It acts as a shared secret only you and Christine know.
--
-- Design: the app keeps its entire state as one JSON blob (baby profile,
-- commitments, plans, meals, day meals, history). We store that blob in a
-- single row, keyed by a fixed "household" id so you and Christine read and
-- write the same record. Simple, and a faithful mirror of how the app already
-- holds state in S = {...}.

create table if not exists household_state (
  id text primary key,            -- we use a single fixed id, e.g. 'household-a755d170726cc15c5cb55a1b5cfd45db4795f088'
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  household_id uuid               -- (build 19) ties the row to the LifeOS household for membership RLS
    default '13b5e642-3f21-403c-8336-56976f177269'
);

-- Seed the one row the app will use.
insert into household_state (id, state)
values ('household-a755d170726cc15c5cb55a1b5cfd45db4795f088', '{}'::jsonb)
on conflict (id) do nothing;

-- Row Level Security (build 19: membership-scoped).
-- Originally the policies keyed on `id=` only, which meant the public anon key
-- could read/write the row if it knew the id. Now that the app authenticates as
-- the shared household, we require actual household membership: the single policy
-- below is `to authenticated` and gated on lifeos.my_household_ids() (a
-- SECURITY DEFINER fn returning the households the current auth.uid() belongs to,
-- via public.household_memberships). Anon has NO matching policy → fully denied.
-- Mirrors the lifeos.signals RLS on the same project. The app is unchanged; it
-- still queries by `id` under its authed JWT.
alter table household_state enable row level security;

create policy "household members rw"
  on household_state for all to authenticated
  using      (household_id in (select lifeos.my_household_ids()))
  with check (household_id in (select lifeos.my_household_ids()));

-- Optional: let the app subscribe to live changes (so Christine's phone updates
-- without a manual refresh). Safe to run; ignore any "already member" notice.
alter publication supabase_realtime add table household_state;
