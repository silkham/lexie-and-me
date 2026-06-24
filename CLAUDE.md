# Lexie & Me

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
- **`cloudflare-worker.js`** — Cloudflare Worker that proxies the Anthropic API and
  injects the `ANTHROPIC_API_KEY` secret (keeps the key out of the public repo).
  CORS-restricted via an `ALLOWED` origins array. **Deployed** at
  `https://lexie-and-me.lachlanmclean1990-2a4.workers.dev/`. NOTE: the `ALLOWED`
  array in the committed file still has the placeholder `https://YOURNAME.github.io`.
- **`supabase-schema.sql`** — one-table cloud store (`household_state`): the whole
  app state as a single JSON blob in one row, keyed by a shared-secret household id,
  RLS locked to that id, realtime enabled. Placeholder id must be replaced before use.
- **`supabase-sync.js`** — three paste-in blocks (A/B/C) that wire Supabase sync into
  `index.html`. **Instructions only — NOT yet applied** (see Status below).

## How it works
- **State:** one JS object `S` persisted to `localStorage['lexieme.v1']`. Shape:
  `{baby, commitments, plans, meals:{bf,ln}, dayMeals, history, pack}`. Migration
  guards at load() reshape older saved blobs. `save()` writes localStorage.
- **Tabs (bottom nav):** Today · Week · Plan · Meals · You. Plus a floating ✨ button
  (AI concierge).
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
- **AI concierge (✨)** — POSTs to the Cloudflare Worker with a rich system prompt
  (Lexie's age, naps, commitments, recent history, the full activity library) and asks
  for ONE warm, specific suggestion. Offline fallback picks from the local pool.
  Model string in code: `claude-sonnet-4-20250514` (outdated — newer ids exist).

## Status: working vs half-finished (as of 2026-06-24)
**Live and working:** the whole planner — Today/Week/Plan/Meals/You, weather, activity
& meal libraries, dashboard — runs client-side and is **live at the canonical home
https://silkham.github.io/lexie-and-me/** (GitHub Pages, main/root). Also mirrored at a
Cloudflare Worker `https://lexie-and-me.lachlanmclean1990-2a4.workers.dev/` that
auto-deploys static assets from this repo (secondary; safe to delete).

**Half-finished / not wired:**
- **The AI concierge proxy is NOT actually deployed.** The app POSTs to the
  `…workers.dev/` URL, but that serves the static APP (GET=200 HTML, POST=405) — it is
  NOT the `cloudflare-worker.js` proxy. So nothing injects the Anthropic key; the
  concierge fails and falls back to local `suggestOffline()` suggestions. **Deliberately
  deferred.** To finish: deploy `cloudflare-worker.js` as a SEPARATE Worker (in the
  Cloudflare dashboard) with the `ANTHROPIC_API_KEY` secret and `ALLOWED` =
  `https://silkham.github.io`, then point the app's AI fetch at that new proxy URL.
- **Cloud sync between the two phones is NOT live.** `supabase-sync.js` is paste-in
  instructions only; `index.html` has zero Supabase code (`grep supabase index.html` = 0).
  State is local-only per device. To finish: create the Supabase project, fill the
  placeholders (URL, anon key, a single long random `HOUSEHOLD_ID` used identically in the
  SQL and Block A), run the SQL, and paste Blocks A/B/C into `index.html`.
- **Not a true installable PWA** — has apple-mobile-web-app meta tags but no
  `manifest.json` or service worker, so no offline/install.

## Git
- Remote: **`silkham/lexie-and-me`** (public), default branch `main`. Linked 2026-06-24.
- Git author: `silkham <lachlanmclean1990@gmail.com>`.
- ⚠️ The local `index.html` differs from the remote by ONE line and is a **regression**:
  it points the AI fetch at `api.anthropic.com` directly instead of the Worker proxy.
  Do NOT push local index.html as-is — restore the worker URL first, or the AI breaks.
- The three helper files (`cloudflare-worker.js`, `supabase-schema.sql`,
  `supabase-sync.js`) are genuinely new locally and not yet on the remote.

## Conventions
- Single-file app: edit `index.html` directly; keep everything inline, no build tooling.
- No Node in this environment — to syntax/functional-test inline JS, use JavaScriptCore
  (`jsc`), same approach as the sibling Fitness app.
- British English and UK context throughout (£, "nappies", Oxted/Surrey place names).
