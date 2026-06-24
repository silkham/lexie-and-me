# Lexie & Me — Roadmap (LOCKED)

> Status: LOCKED 2026-06-24. Thesis, design system, IA and decisions A/B/C all agreed.
> Design + data validated via rendered concept boards (process now: **boards before build**).

## Thesis
**From "a basic planner that drifted" → "the premium planning & discovery tool Christine
and I run Lexie's days with."** Two unlocks, learned from Stride:
1. **Premium feel earns daily use.** Stride became loved through craft + depth, not features.
2. **Discovery is the real job.** The app exists to *find and organise things to do with
   Lexie* — not the thin curated list / meals it drifted into.

Built for **two people** (Lachlan + Christine), already shared live via Supabase.

## Design system — playful, colourful, premium (LOCKED, replaces the old "paper & ink")
The warm muted editorial direction was tried and **rejected as boring**. The agreed
direction is **bright, joyful and playful** — premium but full of fun (it's an app about
their daughter). Established and approved via concept boards:
- **Type:** rounded, friendly — **Fredoka** (display/headings) + **Nunito** (body). No serif.
- **Canvas:** warm off-white `#FFF8EF`; big rounded corners (cards ~22–30px, phone ~46px).
- **Colour:** a multi-hue playful palette used to *colour-code* content, not one accent —
  coral `#FF7A45`/`#E85D2C` (primary/active), sky `#56B6E8`/`#2A7FB0`, grape `#A98BEA`/`#6E4FB0`,
  leaf `#57C98A`/`#2E8E5A`, sunny `#FFC24B`/`#C77F12`. Tiles/cards each carry their own hue.
- **Imagery:** bespoke **illustration** (sunny skies, hills, little castles, balloons),
  **never stock photos**. Clean **line icons** (Tabler-style), **no emoji** anywhere.
- **Chrome:** bottom nav (Today · Discover · Meals · Calendar) that recolours to the active
  tab; a **profile/settings button** (round "L" avatar) top-right on every screen.
- The bar: bright, rounded, characterful — you *want* to open it.

## Information architecture (4 tabs + settings)
- **Today** — the front page: the day's **adventure** (illustrated discovery card),
  **today's meals** (B/L/D brought onto home), **weather** (Open-Meteo), and the **pack bag**
  (progress). **No naps shown** — 2 naps is a given, not worth surfacing. No fixed clock
  times anywhere.
- **Discover** *(the heart)* — **map-first**: a nationwide map of curated child-worthy
  **places** with coloured pins, **location search** up top (works out & about / on holiday),
  **categories as the filter row**, and a list of places below. Scale on show ("1,240 places").
  *(Data = Decision A below.)* Booked classes (Hartbeeps) are NOT places — Calendar items.
- **Meals** — a **week planner** (every day's B/L/D at a glance; empty days invite a plan).
  Shared + synced to Stride. *(Decision B below.)*
- **Calendar** — month view with colour-dotted bookings, a "coming up" list, an **add-event
  sheet** (name, type chips, date/time, where, repeat-weekly, "add to my phone calendar"),
  and two-way phone-calendar sync. *(Decision C below.)*
- **Settings** (via the top-right profile button) — Lexie's profile, **"what's in your bag"**
  (editable default pack list; weather auto-adds rain covers/SPF), home area, shared-with,
  calendar-sync + meals-sync toggles. (Tasks/baby-admin can live here or as a later add.)

## What we already have for free
The Supabase sync (built 2026-06-24) means **Today, Meals, the in-app Calendar and Tasks
are already shared between you and Christine** — that foundation is done. Stride's
**Health Auto Export pattern** (a secondary app/Shortcut bridging Apple data → Supabase on a
schedule) is the proven template for the two-way phone-calendar bridge (Decision C, Path 1).

## Decisions (LOCKED)
- **A — Discover = an exhaustive, nationwide, directory-sourced `places` DB (1,000+).** The
  killer principle: **don't scrape raw map tags and try to clean the junk — seed from
  accreditation/membership directories, because membership IS the quality filter.** Sources:
  **National Trust (~500, all "free for you")**, **English Heritage (400+, "free for you")**,
  Historic Houses & stately homes (1,400+), RHS & partner gardens (200+), zoos & aquariums
  (BIAZA, ~130), farm parks (NFAN, ~200), Arts-Council-accredited museums (1,700+), and
  designated **Country Parks / Forestry / Royal Parks (~250)**. **Play** (its own gate, no
  single body): soft-play chains + Association of Indoor Play + top-rated independents
  (4★+), plus **destination/adventure playgrounds** (named, with facilities) and playgrounds
  inside already-listed parks. **Filtered out by construction:** OSM `leisure=park`/commons
  (e.g. Oxted's green common), verges, every street swing-set, unrated venues — if it's in
  no recognised directory, it doesn't get in. Memberships held = **NT + EH only** → a **"Free
  for you" lens/filter** surfaces every nearby NT/EH place. Hours/cost drift → **"last
  checked"** date + **tap-through to the official site**. Seed once, refresh periodically;
  Lachlan + Christine can add/correct. Booked classes (Hartbeeps) are NOT places — Calendar items.
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
`name, category, source (nt/eh/historic-houses/biaza/nfan/museum/country-park/play/…),
membership (nt/eh/none), lat/lng, area, cost, indoor/outdoor, rain_ok, sun_ok, age_min,
age_max, opening_hours, website, rating, last_checked, notes`. Seeded nationwide from the
Decision-A directories. Day plans / bookings stay in the shared `household_state` blob (or
their own table if needed); meals use Stride's `week_plans` (Decision B).

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

## Process
**Boards before build.** Design every screen as a rendered concept board, get sign-off, then
implement in `index.html`. Concept boards approved 2026-06-24: Today (adventure + meals +
weather + pack), Discover (map-first), Meals (week planner), Calendar (+ add-event sheet),
Settings (bag + toggles), and the Discover data-source / Play-gate boards.

## To start v1.0
Build the approved **Today** board into `index.html` (Fredoka/Nunito, warm-white, illustrated
adventure card, colour tiles, today's meals, profile button) — matching the signed-off board,
not the old paper version. In parallel, lock the **`places`** schema so v1.1 (Discover) can
begin against a real seeded table.
