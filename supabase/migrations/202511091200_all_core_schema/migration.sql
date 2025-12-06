-- All-in-one core schema for English Word Carousel (Option B)
-- CLI-compatible migration directory. No data migration required.

-- Extensions
create extension if not exists pgcrypto;

-- Utility trigger function
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Users (custom user table, not Supabase Auth)
create table if not exists public.users (
  id          text primary key,
  email       text not null,
  username    text not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create unique index if not exists idx_users_email on public.users (lower(email));
create unique index if not exists idx_users_username on public.users (lower(username));
alter table public.users enable row level security;
drop policy if exists "allow anon users all" on public.users;
create policy "allow anon users all" on public.users for all using (true) with check (true);
drop trigger if exists t_users_updated_at on public.users;
create trigger t_users_updated_at before update on public.users
for each row execute procedure public.touch_updated_at();

-- Word cards
create table if not exists public.word_cards (
  id uuid primary key default gen_random_uuid(),
  word text not null,
  chinese text not null,
  phonetic text,
  phrase text,
  phrase_cn text,
  sentence_en text,
  sentence_cn text,
  related jsonb default '[]'::jsonb,
  related_enabled boolean default false,
  enabled boolean default true,
  audio_us text,
  audio_uk text,
  user_id text,
  tags text[] default array[]::text[],
  source text default 'EWC',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists word_cards_created_at_idx on public.word_cards (created_at desc);
create index if not exists word_cards_user_id_idx on public.word_cards (user_id);
create index if not exists word_cards_enabled_idx on public.word_cards (enabled);
alter table public.word_cards enable row level security;
drop policy if exists "allow anon word_cards all" on public.word_cards;
create policy "allow anon word_cards all" on public.word_cards for all using (true) with check (true);
drop trigger if exists word_cards_touch_updated_at on public.word_cards;
create trigger word_cards_touch_updated_at before update on public.word_cards
for each row execute procedure public.touch_updated_at();

-- Tags
create table if not exists public.tags (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  color text not null default '#3B82F6',
  description text default '',
  user_id text,
  sync_version integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_tags_user on public.tags (user_id);
alter table public.tags enable row level security;
drop policy if exists "allow anon tags all" on public.tags;
create policy "allow anon tags all" on public.tags for all using (true) with check (true);
drop trigger if exists t_tags_updated_at on public.tags;
create trigger t_tags_updated_at before update on public.tags
for each row execute procedure public.touch_updated_at();

-- Word-Tag linking
create table if not exists public.word_card_tags (
  word_id uuid not null,
  tag_id uuid not null,
  primary key (word_id, tag_id),
  foreign key (word_id) references public.word_cards(id) on delete cascade,
  foreign key (tag_id) references public.tags(id) on delete cascade
);
create index if not exists idx_word_card_tags_tag on public.word_card_tags(tag_id);
create index if not exists idx_word_card_tags_word on public.word_card_tags(word_id);
alter table public.word_card_tags enable row level security;
drop policy if exists "allow anon word_card_tags all" on public.word_card_tags;
create policy "allow anon word_card_tags all" on public.word_card_tags for all using (true) with check (true);

-- Study logs
create table if not exists public.study_logs (
  id uuid primary key default gen_random_uuid(),
  user_id text,
  word_id uuid,
  session_id text,
  duration integer not null,
  viewed_at timestamptz not null default now()
);
create index if not exists idx_study_logs_user on public.study_logs(user_id);
create index if not exists idx_study_logs_session on public.study_logs(session_id);
create index if not exists idx_study_logs_word on public.study_logs(word_id);
alter table public.study_logs enable row level security;
drop policy if exists "allow anon study_logs all" on public.study_logs;
create policy "allow anon study_logs all" on public.study_logs for all using (true) with check (true);

-- User settings
create table if not exists public.user_settings (
  user_id text primary key,
  sync_enabled boolean not null default true,
  last_sync_at timestamptz,
  preferences jsonb default '{}'::jsonb
);
alter table public.user_settings enable row level security;
drop policy if exists "allow anon user_settings all" on public.user_settings;
create policy "allow anon user_settings all" on public.user_settings for all using (true) with check (true);

-- Study plans
create table if not exists public.study_plans (
  user_id text primary key,
  target_words integer not null default 10,
  review_cycle integer not null default 7,
  reminder_time text default '20:00',
  streak_days integer not null default 0,
  completed_today integer not null default 0,
  updated_at timestamptz not null default now()
);
alter table public.study_plans enable row level security;
drop policy if exists "allow anon study_plans all" on public.study_plans;
create policy "allow anon study_plans all" on public.study_plans for all using (true) with check (true);

-- Carousel plans
create table if not exists public.carousel_plans (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  user_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_carousel_plans_user on public.carousel_plans(user_id);
alter table public.carousel_plans enable row level security;
drop policy if exists "allow anon carousel_plans all" on public.carousel_plans;
create policy "allow anon carousel_plans all" on public.carousel_plans for all using (true) with check (true);
drop trigger if exists t_carousel_plans_updated_at on public.carousel_plans;
create trigger t_carousel_plans_updated_at before update on public.carousel_plans
for each row execute procedure public.touch_updated_at();

-- Carousel plan-word linking
create table if not exists public.carousel_plan_words (
  plan_id uuid not null,
  word_id uuid not null,
  primary key (plan_id, word_id),
  foreign key (plan_id) references public.carousel_plans(id) on delete cascade,
  foreign key (word_id) references public.word_cards(id) on delete cascade
);
create index if not exists idx_cpw_plan on public.carousel_plan_words(plan_id);
create index if not exists idx_cpw_word on public.carousel_plan_words(word_id);
alter table public.carousel_plan_words enable row level security;
drop policy if exists "allow anon carousel_plan_words all" on public.carousel_plan_words;
create policy "allow anon carousel_plan_words all" on public.carousel_plan_words for all using (true) with check (true);

-- End of core schema
-- NOTE: RLS policies are intentionally permissive for bring-up. Tighten for production.