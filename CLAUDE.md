---
project: Lexie & Me
status: active
last_updated: 2026-06-24
next_milestone: Make it a true installable PWA (manifest + service worker)
repo: https://github.com/silkham/lexie-and-me
live_url: https://silkham.github.io/lexie-and-me/
---

# Lexie & Me

<!-- The Status and Roadmap sections below are read by the Project Dashboard.
     Keep them current: Status = where it is now, Roadmap = what's planned.
     Changelog is pulled live from git commit history, so don't maintain one here. -->

## Status
Live and working: the whole planner — Today/Discover/Meals/Calendar, weather, activity &
meal libraries — plus two-phone cloud sync (Supabase `household_state`) and an installable
PWA (manifest + service worker). As of build 13 the app is **gated on a Supabase Auth
session** (login screen) so it can publish into the LifeOS hub; the shared household
account signs in once per device (session persists; sibling apps on `silkham.github.io`
share it). The AI concierge was removed on 2026-06-24.

## Roadmap
- [ ] Tighten `household_state` RLS to require household membership (the app now authenticates,
      but the table's RLS still allows any anon caller by `id` — the real privacy fix)

A single-file PWA that helps a dad on parental leave plan gentle, baby-led days
with his daughter **Lexie** in **Oxted, Surrey**. Warm "paper & ink" editorial
design. Built originally in a Claude chat artifact; the code now lives here.

## What it is
- **Audience:** one family (Lachlan, dad; Christine, partner). Not multi-tenant.
- **Baby profile (default seed):** Lexie, DOB 2025-08-15. Naps am ~9:30 / pm ~13:30,
  3 meals + 2 milk, loves water/music/animals. Age is computed in months.
- **Area:** Oxted/Surrey/Kent + London day-trips. ~50 hand-curated local activities
  (baby classes, farms, National Trust & English Heritage free-with-membership,
  parks/walks, rainy-day, London museums) baked into `seedActivities`.

## Stack & files (no build step, no framework)
- **`index.html`** — the entire app: HTML + CSS + vanilla JS in one file (~58 KB).
  Fonts: Young Serif, Newsreader, Instrument Sans. Single accent (pine green).
- **`supabase-schema.sql`** — one-table cloud store (`household_state`): the whole
  app state as a single JSON blob in one row, keyed by a shared-secret household id,
  RLS locked to that id, realtime enabled. Placeholder id must be replaced before use.
- **`supabase-sync.js`** — three paste-in blocks (A/B/C) that wire Supabase sync into
  `index.html`. **Instructions only — NOT yet applied** (see Status below).

## How it works
- **State:** one JS object `S` persisted to `localStorage['lexieme.v1']`. Shape:
  `{baby, commitments, plans, meals:{bf,ln}, dayMeals, history, pack}`. Migration
  guards at load() reshape older saved blobs. `save()` writes localStorage.
- **Tabs (bottom nav):** Today · Week · Plan · Meals · You.
  - **Today** — a "dayline": breakfast → outing/booked class → lunch. Weather-aware
    header, practical strip (travel/high/rain/nap-fit), a what-to-pack checklist, cost.
  - **Week** — Mon-start 7-day strip; per-day activity + meals; "suggest a different day".
  - **Plan** — filterable activity suggestions (Get out / Rainy / London / NT&EH free /
    under 20 min); assign one to any of the next 14 days.
  - **Meals** — breakfast/lunch idea library; pin (♥ survives shuffle), shuffle, add/edit/
    swap. Per-day meal assignment happens in Week (`dayMeals`).
  - **You** — gentle scores (variety / out-vs-home / outings / new experiences), a nudge,
    Lexie's profile, and the booked-classes/commitments manager.
- **Planning engine** — `planFor(date)`: a booked class IS that day's activity; otherwise
  pick weather-appropriately (rain → indoor/café, else an outing), avoiding recent repeats.
  `napClash()` flags activities that collide with nap windows.
- **Weather** — open-meteo 7-day forecast for Oxted (51.257, -0.005); no API key.
## Status: working vs half-finished (as of 2026-06-24)
**Live and working:** the whole planner — Today/Week/Plan/Meals/You, weather, activity &
meal libraries, dashboard — plus **two-phone cloud sync**, all live at the canonical home
**https://silkham.github.io/lexie-and-me/** (GitHub Pages, main/root). The app is also
mirrored at a Cloudflare Worker `https://lexie-and-me.lachlanmclean1990-2a4.workers.dev/`
that auto-deploys static assets from this repo (secondary; safe to delete).

**Cloud sync (live):** reuses the Fitness Supabase project `dgbbyijhabjozqrkokrq`. URL +
public anon key are baked into `index.html`. State syncs via the `household_state`
table (one JSON-blob row keyed by `HOUSEHOLD_ID`, RLS + realtime); see `supabase-schema.sql`.
**Privacy caveat (still open):** `household_state`'s RLS predicates key on `id=` only, so
any anon caller who knows the id can still read/write the row — even though the app itself
now runs authenticated (build 13). Closing the gap = tightening that table's RLS to require
household membership (roadmap item above); the grants and login are already in place.

**LifeOS integration (build 13):** the app authenticates as the shared household so it can
publish `nudge` signals into `lifeos.signals` on the SAME project. `publishToLifeOS()` runs
fire-and-forget in `boot()`: resolves the household UUID via `sb.schema('lifeos')
.rpc('my_household_ids')`, then upserts one "Nothing planned <day>" nudge per **day-of-week
slot** for the next 7 days (`key='nothing-planned-<dow>'` → self-cleaning; booked days flip
to `status='dismissed'`). `due` uses `dkey()` (now local — see below). Accent violet on the
hub; `state='warn'`. The
`household_state` anon sync is untouched and still works under the authed JWT (its RLS is
role-agnostic; `authenticated` has the same grants as `anon`). See `../LifeOS/CLAUDE.md`.

**Dropped:** the AI concierge was removed entirely on 2026-06-24 per user request.

## Git
- Remote: **`silkham/lexie-and-me`** (public), default branch `main`. Local linked 2026-06-24.
- Git author: `silkham <lachlanmclean1990@gmail.com>`.
- Commits land directly on `main` (GitHub Pages serves `main`/root; that's the deploy path).

## Memberships (Discover "Free for you")
Three household memberships flag places as free entry: **NT**, **EH**, and **Merlin** (Gold
pass, added build 18). The badge + "Free for you" filter key off the `places.membership`
column generically, so flagging a row (`membership='nt'|'eh'|'merlin'`) is all it takes —
no code change needed for the badge. Difference: NT/EH rows also set `category` = the
membership (their filter chip matches by category), but **Merlin spans real categories**
(theme parks, aquariums, museums, castles), so its rows keep their true `category` and the
**Merlin filter chip matches by `membership==='merlin'`** (special-cased in `discoverFiltered`,
like `free`/`fav`). 21 Merlin attractions are flagged in the `places` table. In the planner,
`seedActivities` items mirror this with a `member:'merlin'` field + `cost:'Merlin free'`.

**Closed places (build 18):** no live open/closed API — a place is hidden by manually tapping
"Report permanently closed" in its detail sheet. Closed IDs live in `S.closedPlaces` (synced
household state, so both phones agree; migration-guarded in `load()` + `cloudLoad()`).
`discoverFiltered()` drops them from the map/list, but search (`showSuggestions`, which reads
`PLACES` directly) still finds them so `toggleClosed()` can reopen one. Genuinely-dead venues
that shouldn't be in the dataset at all (e.g. Bear Grylls Adventure NEC, closed Dec 2024) are
deleted from the `places` table instead.

## Conventions
- Single-file app: edit `index.html` directly; keep everything inline, no build tooling.
- No Node in this environment — to syntax/functional-test inline JS, use JavaScriptCore.
  `jsc` is NOT on PATH: `/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Helpers/jsc`.
  Extract inline `<script>` blocks (Ruby, read with `encoding:"UTF-8"` — the file has £/·/emoji)
  and syntax-check each via `new Function(readFile(path))` (compiles without executing, so
  cross-block globals like `sb` don't matter). Logic-test a function by slicing it out + stubbing.
- British English and UK context throughout (£, "nappies", Oxted/Surrey place names).
- **Dates: `dkey(d)` MUST stay local `yyyy-mm-dd`** (`getFullYear/getMonth/getDate`), never
  `toISOString()`. Calendar cells are built at *local* midnight (`new Date(y,m,dn)`); under BST,
  `toISOString()` (UTC) rolls them back a day, so clicking a date opened the previous one
  (fixed build 15, commit 56dcb32). Every calendar/meal/pack/plan key flows through `dkey`, so
  this one function is the single source of truth — don't reintroduce a UTC path.
