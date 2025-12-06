-- Cleanup script for public.word_cards
-- Use this in Supabase SQL Editor. Read notes carefully before running.

/*
Steps:
1) Inspect current distribution and sample rows
2) Choose either TRUNCATE (clear all) or targeted DELETE by user_id
3) Verify results after deletion

RLS note: Running in SQL Editor uses elevated privileges and bypasses anon limits.
*/

-- 1) Inspect counts by user_id (including shared where user_id IS NULL)
SELECT user_id, COUNT(*) AS cnt
FROM public.word_cards
GROUP BY user_id
ORDER BY user_id;

-- Optional: preview latest rows per user (adjust LIMIT as needed)
SELECT id, word, user_id, enabled, created_at
FROM public.word_cards
ORDER BY created_at DESC
LIMIT 50;

-- 2A) Clear ALL rows (DANGEROUS: removes every row)
-- Use this if you intend to re-import everything from scratch
TRUNCATE TABLE public.word_cards RESTART IDENTITY;

-- 2B) Targeted delete by user_id (safer alternative)
-- Uncomment the lines you need and run instead of TRUNCATE
-- DELETE FROM public.word_cards WHERE user_id = '123456';
-- DELETE FROM public.word_cards WHERE user_id = 'u_1';
-- DELETE FROM public.word_cards WHERE user_id IS NULL; -- shared/public data

-- 3) Verify cleanup results
SELECT user_id, COUNT(*) AS cnt
FROM public.word_cards
GROUP BY user_id
ORDER BY user_id;

-- Optional: confirm table is empty
SELECT COUNT(*) AS total FROM public.word_cards;

/*
Post-cleanup checklist:
- Refresh the web preview and confirm word list is empty
- Re-import data while logged in as the intended username (e.g., '123456')
- For shared content, set visibility=public during import so user_id is NULL
- Ensure build flags: SUPABASE_READ_REMOTE=true, SUPABASE_WRITE_REMOTE=true
*/