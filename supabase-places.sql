-- Lexie & Me — Discover "places" catalogue
-- Run once in the Supabase SQL Editor (same project: dgbbyijhabjozqrkokrq).
--
-- This is the shared, nationwide catalogue of child-worthy places (Decision A):
-- seeded from accreditation/membership directories (NT, EH, Historic Houses, RHS,
-- BIAZA zoos/aquariums, NFAN farm parks, accredited museums, country parks, + a Play
-- gate). It's a public catalogue — readable by everyone, and editable by the app so
-- you and Christine can add/correct entries. (No sensitive data lives here.)

create table if not exists places (
  id           text primary key,           -- stable slug, e.g. 'nt-standen'
  name         text not null,
  category     text,                        -- nt | eh | historic-house | garden | zoo-aquarium | farm | museum | country-park | play | attraction
  source       text,                        -- which directory it came from
  membership   text,                        -- 'nt' | 'eh' | null  → drives the "free for you" lens
  area         text,                         -- town/locality, e.g. 'East Grinstead'
  region       text,                         -- e.g. 'South East'
  lat          double precision,
  lng          double precision,
  cost         text,                         -- display string, e.g. 'NT free', '£18', 'Under-2 free'
  indoor       boolean default false,
  rain_ok      boolean default false,        -- good in the rain
  sun_ok       boolean default true,         -- good on a dry/sunny day
  age_min      int default 0,                -- in months
  age_max      int default 99,
  opening_hours text,                        -- free text / JSON later; live hours via website
  website      text,
  rating       numeric,                      -- for the Play quality gate (4.0+ keeps independents)
  notes        text,
  last_checked date,
  updated_at   timestamptz not null default now()
);

create index if not exists places_category_idx on places (category);
create index if not exists places_membership_idx on places (membership);

-- Public catalogue: anyone can read; the app can add/correct.
alter table places enable row level security;
create policy "read places"   on places for select using (true);
create policy "insert places" on places for insert with check (true);
create policy "update places" on places for update using (true) with check (true);

-- Optional: live catalogue updates across devices.
alter publication supabase_realtime add table places;

-- ============================================================
-- Regional seed (South East + London) — the first real batch.
-- Best-effort coords/details; the app can correct & we widen to
-- nationwide next. Safe to re-run (on conflict do nothing).
-- ============================================================
insert into places (id, name, category, source, membership, area, region, lat, lng, cost, indoor, rain_ok, sun_ok, last_checked) values
-- National Trust (free for you)
('nt-standen','Standen House & Garden','nt','national-trust','nt','East Grinstead','South East',51.118,-0.006,'NT free',false,false,true,'2026-06-24'),
('nt-chartwell','Chartwell','nt','national-trust','nt','Westerham','South East',51.248,0.081,'NT free',false,false,true,'2026-06-24'),
('nt-polesden','Polesden Lacey','nt','national-trust','nt','Great Bookham','South East',51.265,-0.401,'NT free',false,false,true,'2026-06-24'),
('nt-nymans','Nymans','nt','national-trust','nt','Handcross','South East',51.060,-0.197,'NT free',false,false,true,'2026-06-24'),
('nt-emmetts','Emmetts Garden','nt','national-trust','nt','Ide Hill','South East',51.252,0.135,'NT free',false,false,true,'2026-06-24'),
('nt-sheffield-park','Sheffield Park & Garden','nt','national-trust','nt','Uckfield','South East',50.991,0.008,'NT free',false,false,true,'2026-06-24'),
('nt-winkworth','Winkworth Arboretum','nt','national-trust','nt','Godalming','South East',51.151,-0.622,'NT free',false,false,true,'2026-06-24'),
-- English Heritage (free for you)
('eh-eltham','Eltham Palace & Gardens','eh','english-heritage','eh','Eltham','London',51.448,0.052,'EH free',true,true,true,'2026-06-24'),
('eh-down-house','Down House (Home of Darwin)','eh','english-heritage','eh','Downe','London',51.331,0.055,'EH free',false,false,true,'2026-06-24'),
-- Historic houses & castles
('hh-hever','Hever Castle & Gardens','historic-house','historic-houses',null,'Hever','South East',51.186,0.114,'£22',false,false,true,'2026-06-24'),
-- Farm parks
('farm-godstone','Godstone Farm','farm','nfan',null,'Godstone','South East',51.235,-0.063,'Under-2 free',false,true,true,'2026-06-24'),
('farm-bocketts','Bocketts Farm Park','farm','nfan',null,'Fetcham','South East',51.282,-0.346,'Under-2 free',false,true,true,'2026-06-24'),
('farm-priory','Priory Farm','farm','nfan',null,'Nutfield','South East',51.238,-0.146,'£6',false,false,true,'2026-06-24'),
-- Zoos & aquariums
('zoo-bwc','British Wildlife Centre','zoo-aquarium','biaza',null,'Lingfield','South East',51.166,-0.030,'£18',false,false,true,'2026-06-24'),
('zoo-birdworld','Birdworld','zoo-aquarium','biaza',null,'Farnham','South East',51.180,-0.838,'£16',false,false,true,'2026-06-24'),
('zoo-london','ZSL London Zoo','zoo-aquarium','biaza',null,'Regent''s Park','London',51.535,-0.153,'Under-3 free',false,false,true,'2026-06-24'),
('zoo-sealife','SEA LIFE London','zoo-aquarium','biaza',null,'South Bank','London',51.501,-0.119,'Under-3 free',true,true,true,'2026-06-24'),
('zoo-battersea','Battersea Children''s Zoo','zoo-aquarium','biaza',null,'Battersea','London',51.479,-0.157,'£13',false,false,true,'2026-06-24'),
-- Museums (accredited)
('mus-nhm','Natural History Museum','museum','accredited-museum',null,'South Kensington','London',51.496,-0.176,'Free',true,true,true,'2026-06-24'),
('mus-science','Science Museum','museum','accredited-museum',null,'South Kensington','London',51.498,-0.174,'Free',true,true,true,'2026-06-24'),
('mus-young-va','Young V&A','museum','accredited-museum',null,'Bethnal Green','London',51.530,-0.055,'Free',true,true,true,'2026-06-24'),
('mus-transport','London Transport Museum','museum','accredited-museum',null,'Covent Garden','London',51.512,-0.121,'£24 / u18 free',true,true,true,'2026-06-24'),
('mus-tate','Tate Modern','museum','accredited-museum',null,'South Bank','London',51.508,-0.099,'Free',true,true,true,'2026-06-24'),
('mus-maritime','National Maritime Museum','museum','accredited-museum',null,'Greenwich','London',51.481,-0.005,'Free',true,true,true,'2026-06-24'),
-- Gardens, parks & country parks
('gdn-kew','Kew Gardens','garden','rhs',null,'Kew','London',51.478,-0.295,'£22',false,false,true,'2026-06-24'),
('gdn-wisley','RHS Wisley','garden','rhs',null,'Woking','South East',51.315,-0.476,'£18',false,false,true,'2026-06-24'),
('cp-virginia-water','Virginia Water Lake','country-park','country-parks',null,'Egham','South East',51.408,-0.589,'Parking',false,false,true,'2026-06-24'),
('cp-titsey','Titsey Place & Gardens','country-park','country-parks',null,'Limpsfield','South East',51.270,0.018,'Free',false,false,true,'2026-06-24'),
('cp-master-park','Master Park','country-park','country-parks',null,'Oxted','South East',51.258,-0.004,'Free',false,false,true,'2026-06-24')
on conflict (id) do nothing;
