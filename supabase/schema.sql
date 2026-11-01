-- Chashibondhu — Supabase schema (optional cloud backup).
-- Run in Supabase → SQL editor. Then:
--   1. Authentication → Providers → enable "Anonymous sign-ins"
--      (the app signs in silently; no login screen. A phone number can be
--       linked to the same user later.)
--   2. This script creates the storage bucket 'report-photos' (private).
-- Column names match lib/core/sync/sync_tables.dart.

create extension if not exists "pgcrypto";

-- ---------- users (one row per phone/app install) ----------
create table if not exists public.users (
  id           uuid primary key references auth.users(id) on delete cascade,
  phone        text,                 -- later: optional phone profile
  district_id  text,
  upazila      text,
  app_version  text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- ---------- ponds ----------
create table if not exists public.ponds (
  id           uuid primary key,
  owner_id     uuid not null references auth.users(id) on delete cascade,
  name         text not null,
  area_shotok  numeric not null,
  species      text not null,        -- pangas|tilapia|rui|katla|mrigel|chingri|shing|magur|koi|… |other
  species_name text default '',       -- typed name when species = other
  stock_count  integer not null,
  stock_date   date not null,
  avg_weight_g numeric not null,
  created_at   timestamptz not null,
  updated_at   timestamptz not null
);

-- ---------- pond_logs (daily diary) ----------
create table if not exists public.pond_logs (
  id          uuid primary key,
  pond_id     uuid not null references public.ponds(id) on delete cascade,
  owner_id    uuid not null references auth.users(id) on delete cascade,
  log_date    date not null,
  feed_kg     numeric not null default 0,
  dead_count  integer not null default 0,
  water_color text,                  -- lightGreen|darkGreen|clear|muddy|redBlack
  behavior    text,                  -- normal|lessEating|slow|gasping|wounds
  note        text default '',
  created_at  timestamptz not null,
  updated_at  timestamptz not null
);
create index if not exists pond_logs_pond_idx on public.pond_logs(pond_id, log_date desc);

-- ---------- disease_reports (fish + crop) ----------
-- pond_id has no foreign key on purpose: a report stays after its pond is deleted.
create table if not exists public.disease_reports (
  id          uuid primary key,
  owner_id    uuid not null references auth.users(id) on delete cascade,
  kind        text not null check (kind in ('fish','crop')),
  pond_id     uuid,
  pond_name   text,
  crop        text,                  -- dhan|alu|morich|begun|lau|tomato|peyaj
  crop_label  text,
  report_date date not null,
  photo_path  text,                  -- path in bucket report-photos
  symptoms    text[] not null default '{}',
  results     jsonb not null default '[]',  -- [{problemId,name,likelihood}]
  created_at  timestamptz not null
);

-- ---------- reminders ----------
create table if not exists public.reminders (
  id          uuid primary key,
  owner_id    uuid not null references auth.users(id) on delete cascade,
  type        text not null,         -- feed|lime|net|harvest
  pond_id     uuid,
  pond_name   text,
  due_at      timestamptz not null,
  done        boolean not null default false,
  done_day    integer,               -- yyyymmdd, for daily reminders
  created_at  timestamptz not null,
  updated_at  timestamptz not null
);

-- ---------- biosecurity_checks (weekly) ----------
create table if not exists public.biosecurity_checks (
  id          uuid primary key,
  owner_id    uuid not null references auth.users(id) on delete cascade,
  week_start  date not null,
  items       text[] not null default '{}',
  score       integer not null,
  updated_at  timestamptz not null
);

-- ---------- market_prices (filled by admin; app only reads) ----------
create table if not exists public.market_prices (
  id           uuid primary key default gen_random_uuid(),
  item_id      text not null,        -- rui|katla|pangas|tilapia|chingri|dhan|alu|peyaj
  label        text not null,        -- Bangla name, e.g. 'রুই'
  emoji        text,
  price_per_kg numeric not null,
  market       text not null,
  district_id  text,                 -- null = national
  price_date   date not null,
  created_at   timestamptz not null default now()
);
create index if not exists market_prices_date_idx on public.market_prices(price_date desc);

-- ---------- Row level security: each user sees only their own rows ----------
alter table public.users              enable row level security;
alter table public.ponds              enable row level security;
alter table public.pond_logs          enable row level security;
alter table public.disease_reports    enable row level security;
alter table public.reminders          enable row level security;
alter table public.biosecurity_checks enable row level security;
alter table public.market_prices      enable row level security;

create policy "own user row" on public.users
  for all using (id = auth.uid()) with check (id = auth.uid());

create policy "own ponds" on public.ponds
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own pond logs" on public.pond_logs
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own reports" on public.disease_reports
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own reminders" on public.reminders
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own biosecurity" on public.biosecurity_checks
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- Everyone signed in (including anonymous) can read prices; only admins
-- (dashboard / service role) can write.
create policy "read prices" on public.market_prices
  for select using (true);

-- ---------- Storage: private bucket, each user writes to their own folder ----------
insert into storage.buckets (id, name, public)
values ('report-photos', 'report-photos', false)
on conflict (id) do nothing;

create policy "upload own photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'report-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "update own photos" on storage.objects
  for update to authenticated
  using (bucket_id = 'report-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "read own photos" on storage.objects
  for select to authenticated
  using (bucket_id = 'report-photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------- Example: add today's prices (admin) ----------
-- insert into public.market_prices (item_id, label, emoji, price_per_kg, market, price_date)
-- values ('rui','রুই','🐟',320,'ময়মনসিংহ মাছবাজার', current_date);

-- Upgrading from 0.3: add the new column
alter table public.ponds add column if not exists species_name text default '';
