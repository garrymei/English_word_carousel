-- Migration: Create custom users and playback (carousel) plan tables
-- Strategy B: use our own user system (not Supabase Auth)
-- NOTE: RLS policies here are TEMPORARY for debug (allow anon all). For production,
--       tighten policies to authenticated/service role only.

-- Ensure UUID generation support
create extension if not exists pgcrypto;

-- Utility: touch updated_at on update
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Users table (custom user system)
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

-- Seed a debug user for local testing
insert into public.users (id, email, username)
values ('debug-user-id', 'debug@example.com', 'debug')
on conflict (id) do nothing;

-- Carousel plans (playback plans)
create table if not exists public.carousel_plans (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  user_id     text null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists idx_carousel_plans_user on public.carousel_plans (user_id);

alter table public.carousel_plans enable row level security;
drop policy if exists "allow anon carousel_plans all" on public.carousel_plans;
create policy "allow anon carousel_plans all" on public.carousel_plans for all using (true) with check (true);

drop trigger if exists t_carousel_plans_updated_at on public.carousel_plans;
create trigger t_carousel_plans_updated_at before update on public.carousel_plans
for each row execute procedure public.touch_updated_at();

-- Plan-word linking table
create table if not exists public.carousel_plan_words (
  plan_id uuid not null,
  word_id uuid not null,
  primary key (plan_id, word_id),
  constraint fk_cpw_plan foreign key (plan_id) references public.carousel_plans(id) on delete cascade,
  constraint fk_cpw_word foreign key (word_id) references public.word_cards(id) on delete cascade
);
create index if not exists idx_cpw_plan on public.carousel_plan_words (plan_id);
create index if not exists idx_cpw_word on public.carousel_plan_words (word_id);

alter table public.carousel_plan_words enable row level security;
drop policy if exists "allow anon carousel_plan_words all" on public.carousel_plan_words;
create policy "allow anon carousel_plan_words all" on public.carousel_plan_words for all using (true) with check (true);

-- End of migration