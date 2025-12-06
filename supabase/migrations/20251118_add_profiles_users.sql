-- Create minimal profiles and users tables for username->email resolution
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  username text unique not null,
  email text unique not null,
  created_at timestamptz default now()
);
alter table public.profiles owner to postgres;

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  username text unique not null,
  email text unique not null,
  created_at timestamptz default now()
);
alter table public.users owner to postgres;

-- Testing policies: allow anon select to resolve email by username
do $$
begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='profiles' and policyname='Anon select profiles'
  ) then
    create policy "Anon select profiles" on public.profiles for select to anon using (true);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='users' and policyname='Anon select users'
  ) then
    create policy "Anon select users" on public.users for select to anon using (true);
  end if;
end $$;

grant select on table public.profiles to anon;
grant select on table public.users to anon;

-- Note: This is a test-friendly setup. Tighten RLS for production.