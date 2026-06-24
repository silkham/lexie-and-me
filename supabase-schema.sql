-- Lexie & Me — Supabase schema
-- Run this once in the Supabase SQL Editor (New query → paste → Run).
--
-- IMPORTANT (security): the anon key lives in your public app, so anyone who
-- finds your repo could read/write this table IF they can guess the row id.
-- So DON'T use a guessable id like 'oxted'. Before running this, replace every
-- 'household-CHANGE-ME-to-a-long-random-string' below with the SAME long random
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
  id text primary key,            -- we use a single fixed id, e.g. 'household-CHANGE-ME-to-a-long-random-string'
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- Seed the one row the app will use.
insert into household_state (id, state)
values ('household-CHANGE-ME-to-a-long-random-string', '{}'::jsonb)
on conflict (id) do nothing;

-- Row Level Security: keep it on, but allow read+write to the anon key for
-- just this one row. The anon key is public by design; restricting it to a
-- single known id keeps things tidy for a private family app.
alter table household_state enable row level security;

create policy "read oxted row"
  on household_state for select
  using (id = 'household-CHANGE-ME-to-a-long-random-string');

create policy "update oxted row"
  on household_state for update
  using (id = 'household-CHANGE-ME-to-a-long-random-string')
  with check (id = 'household-CHANGE-ME-to-a-long-random-string');

create policy "insert oxted row"
  on household_state for insert
  with check (id = 'household-CHANGE-ME-to-a-long-random-string');

-- Optional: let the app subscribe to live changes (so Christine's phone updates
-- without a manual refresh). Safe to run; ignore any "already member" notice.
alter publication supabase_realtime add table household_state;
