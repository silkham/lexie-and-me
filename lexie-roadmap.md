# Lexie & Me — Roadmap (LOCKED)

> Status: LOCKED 2026-06-24. Thesis, design north star, IA and decisions A/B/C all agreed.

## Thesis
**From "a basic planner that drifted" → "the premium planning & discovery tool Christine
and I run Lexie's days with."** Two unlocks, learned from Stride:
1. **Premium feel earns daily use.** Stride became loved through craft + depth, not features.
2. **Discovery is the real job.** The app exists to *find and organise things to do with
   Lexie* — not the thin curated list / meals it drifted into.

Built for **two people** (Lachlan + Christine), already shared live via Supabase.

## Design north star — premium, but keep the soul
Stride got premium by adding **atmosphere + motion + substance** on top of a strong
identity. Apply the *lesson*, not the *look*:
- **Keep & deepen the warm "paper & ink" editorial identity** (Young Serif / Newsreader /
  Instrument Sans, pine accent, soft cards). It suits a baby app far better than Stride's
  emerald-on-black. **Do NOT port the dark system over.** (Decision: agreed.)
- Premium = real **place photography/illustration**, generous editorial layout, tasteful
  **motion** (staggered entrances, count-ups, draw-ons), live touches ("open now",
  distance, weather-matched), characterful empty states, satisfying micro-interactions.
- The bar: every screen should feel considered enough that you *want* to open it.

## Information architecture (4 tabs + tasks)
- **Today** — "what's on today": today's meals, the day's activity / booked class, weather,
  what to pack, anything you need to know. A premium Stride-style hero. *(Mostly recomposes
  what exists — low risk; the place to set the craft standard.)*
- **Meals** — the weekly meal list both of you plan from. *(Decision B below.)*
- **Discover** *(the activity planner — the heart of the app)* — a big, browsable,
  filterable database of **places** (not events/classes): National Trust, English Heritage,
  historic homes, aquariums, farms, parks, soft play, and more. Each with **opening hours,
  cost, indoor/outdoor, rain-friendly / sun-friendly, age suitability, travel time, and
  membership-free flags (NT/EH)**. Used by you *and* Christine to decide where to go.
  *(Decision A below.)* Booked classes (e.g. Hartbeeps) are **not** DB places — they're
  personal bookings on the Calendar/Today.
- **Calendar** — month view of planned activities + booked classes, shared between you two,
  with **two-way sync to a real "Lexie" phone calendar**. *(Decision C below.)*
- **Tasks** — lightweight shared checklist for baby admin (jabs, shopping, nursery, errands).

## What we already have for free
The Supabase sync (built 2026-06-24) means **Today, Meals, the in-app Calendar and Tasks
are already shared between you and Christine** — that foundation is done. Stride's
**Health Auto Export pattern** (a secondary app/Shortcut bridging Apple data → Supabase on a
schedule) is the proven template for the two-way phone-calendar bridge (Decision C, Path 1).

## Decisions (LOCKED)
- **A — Discover = a curated database of *places*, in Supabase.** The target is **places to
  go**, not events/classes — and places (NT, EH, historic homes, parks, aquariums…) are
  stable institutions whose core details don't change, so a big curated DB is robust. Only
  hours/cost drift: handle with a **"last checked"** date + **tap-through to the official
  site** for live hours. Seed a curated core into a Supabase **`places`** table that you and
  Christine can **add to and correct**. Booked classes (Hartbeeps) are NOT places — they're
  personal Calendar/Today bookings.
- **B — Meals = one shared family plan; Lexie eats what you eat.** Single source of truth in
  Supabase **`week_plans`** (the table Stride already uses), read/written by both apps —
  plan dinner once, it shows in Stride *and* Lexie & Me. Lexie's only addition is an optional
  **"serving for Lexie"** note (how to adapt that meal for baby-led weaning).
- **C — Calendar = shared in-app now, then bidirectional with a real phone calendar.** v1 =
  the shared in-app month calendar (already have via Supabase). Bidirectional IS achievable
  (not deferred) — two paths:
  - **Path 1 (chosen): the Shortcuts bridge** — the direct analogue of the Health Auto Export
    trick. Two iOS Shortcut automations against Supabase: *Phone→App* ("Find Calendar Events"
    in a dedicated **"Lexie" calendar** → POST upsert by UID) and *App→Phone* (GET app items
    → add/update events, dedup by app id). Conflict handling = the same last-write-wins-by-
    `updated_at`, id-keyed model the app sync already uses. Free, no OAuth, proven style.
  - **Path 2 (backup): Google Calendar API** — full two-way REST; foreground read/write works
    client-side from the PWA (Google Identity Services, Pages domain as authorised origin);
    background sync would want a small Cloudflare Worker holding a refresh token. Cleaner UX
    but Google-bound + a one-time Google Cloud setup.

## Data model shift
Activities move from the hardcoded `seedActivities` JS array → a Supabase **`places`** table:
`name, category, area, lat/lng, travel_mins, cost, membership (nt/eh/none), indoor/outdoor,
rain_ok, sun_ok, age_min, age_max, opening_hours, website, notes, last_checked`. Day plans /
bookings stay in the existing shared `household_state` blob (or graduate to their own table
if needed).

## Sequencing
- **v1.0 — premium bar + foundation:** redesign pass on **Today** + the app shell; establish
  the craft standard everything else is held to.
- **v1.1 — the heart:** **Discover** tab — `places` table in Supabase, browse/filter/detail
  views, "open now" + distance + weather-match, add-your-own booked classes.
- **v1.2 — calendar + tasks:** shared month **Calendar** (Supabase) + **Tasks** list; then
  the **Shortcuts bridge** for two-way "Lexie" phone-calendar sync.
- **v1.3 — meals:** weekly **Meals** reading/writing the shared `week_plans` (same as Stride)
  + the optional "serving for Lexie" note.

Premium-first on purpose: v1.0 sets the standard, so the big Discover build (v1.1) is held
to it from the start.

## To start v1.0
Redesign **Today** to the premium bar (richer hero, motion, real imagery direction) and lock
the **`places`** schema so v1.1 can begin against a real table.
