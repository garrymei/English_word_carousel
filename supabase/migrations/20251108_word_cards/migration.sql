-- Create extension for UUID generation if not present
create extension if not exists pgcrypto;

-- Main word_cards table aligned with app model
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

-- Indexes for common queries
create index if not exists word_cards_created_at_idx on public.word_cards (created_at desc);
create index if not exists word_cards_user_id_idx on public.word_cards (user_id);
create index if not exists word_cards_enabled_idx on public.word_cards (enabled);

-- Trigger to keep updated_at fresh
create or replace function public.touch_updated_at() returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;$$ language plpgsql;

drop trigger if exists word_cards_touch_updated_at on public.word_cards;
create trigger word_cards_touch_updated_at
before update on public.word_cards
for each row execute procedure public.touch_updated_at();

-- Enable Row Level Security
alter table public.word_cards enable row level security;

-- TEST policies (for initial smoke tests with anon role). Remove or restrict later.
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'word_cards' and policyname = 'Anon select word_cards'
  ) then
    create policy "Anon select word_cards" on public.word_cards for select to anon using (true);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'word_cards' and policyname = 'Anon insert word_cards'
  ) then
    create policy "Anon insert word_cards" on public.word_cards for insert to anon with check (true);
  end if;
end $$;

-- PRODUCTION example policies (use when integrating Supabase Auth)
-- Uncomment after you have authenticated users and store user_id = auth.uid()
-- revoke all on table public.word_cards from anon;
-- create policy "Users select own word_cards" on public.word_cards
--   for select to authenticated using (user_id = auth.uid());
-- create policy "Users insert own word_cards" on public.word_cards
--   for insert to authenticated with check (user_id = auth.uid());
-- create policy "Users update own word_cards" on public.word_cards
--   for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Notes:
-- 1) This migration is generated from docs/supabase/word_cards_schema.sql with sensitive artifacts removed.
-- 2) Keep TEST policies only during bring-up. Tighten to authenticated users for production.
-- 3) The app's demo insert uses columns: word, chinese, tags[], source.