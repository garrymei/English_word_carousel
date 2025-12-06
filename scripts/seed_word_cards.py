#!/usr/bin/env python3
"""
Seed 5 word cards into Supabase via REST API.

Usage:
  SUPABASE_URL=https://<project>.supabase.co \
  SUPABASE_ANON_KEY=<anon_or_service_key> \
  # Optional: use minimal payload for simple schemas
  SEED_MINIMAL_FIELDS=true \
  # Optional: attribute rows to a specific user
  SEED_USER_ID=<uuid> \
  python3 scripts/seed_word_cards.py

Notes:
  - Default payload uses a minimal schema: word, chinese, created_at (+ optional user_id)
  - Full payload (when SEED_MINIMAL_FIELDS is not set/false) expects columns:
    word, chinese, phonetic, phrase, phrase_cn, sentence_en, sentence_cn,
    related_enabled (bool), related (json[]), enabled (bool), audio_us, audio_uk, user_id, created_at
  - RLS must allow inserts for your auth context (anon or authenticated).
"""

import os
import sys
import json
import datetime
import urllib.request
import ssl


def _env(name: str) -> str:
    v = os.environ.get(name, '').strip()
    if not v:
        print(f"[error] Missing environment variable: {name}")
    return v


def _http_post(url: str, headers: dict, body: dict | list, insecure_ssl: bool = False) -> tuple[int, dict | list | str]:
    data = json.dumps(body).encode('utf-8')
    req = urllib.request.Request(url, method='POST', data=data)
    for k, v in headers.items():
        req.add_header(k, v)
    try:
        ctx = None
        if insecure_ssl:
            ctx = ssl._create_unverified_context()
        with urllib.request.urlopen(req, context=ctx) as resp:
            charset = resp.headers.get_content_charset() or 'utf-8'
            text = resp.read().decode(charset)
            try:
                return resp.status, json.loads(text)
            except Exception:
                return resp.status, text
    except urllib.error.HTTPError as e:
        try:
            text = e.read().decode('utf-8')
        except Exception:
            text = str(e)
        return e.code, text
    except Exception as e:
        return 0, str(e)


def main() -> int:
    base_url = _env('SUPABASE_URL')
    anon_key = _env('SUPABASE_ANON_KEY')
    minimal = os.environ.get('SEED_MINIMAL_FIELDS', '').strip().lower() in ('1', 'true', 'yes', 'on')
    seed_user_id = os.environ.get('SEED_USER_ID', '').strip() or None
    insecure_ssl = os.environ.get('SEED_INSECURE_SSL', '').strip().lower() in ('1', 'true', 'yes', 'on')
    if not base_url or not anon_key:
        print('\n[hint] Set envs, e.g.:')
        print('  SUPABASE_URL=https://xyzcompany.supabase.co')
        print('  SUPABASE_ANON_KEY=eyJ...')
        return 2

    rest_url = base_url.rstrip('/') + '/rest/v1/word_cards'
    now_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()

    def full_item(word: str, chinese: str, phonetic: str, phrase: str, phrase_cn: str, se: str, sc: str):
        item = {
            "word": word,
            "chinese": chinese,
            "phonetic": phonetic,
            "phrase": phrase,
            "phrase_cn": phrase_cn,
            "sentence_en": se,
            "sentence_cn": sc,
            "related_enabled": False,
            "related": [],
            "enabled": True,
            "created_at": now_iso,
        }
        if seed_user_id:
            item["user_id"] = seed_user_id
        return item

    def minimal_item(word: str, chinese: str):
        item = {
            "word": word,
            "chinese": chinese,
            "created_at": now_iso,
        }
        if seed_user_id:
            item["user_id"] = seed_user_id
        return item

    payload = (
        [
            full_item("humble", "谦逊的；不起眼的", "ˈhʌm.bəl", "humble beginnings", "卑微的出身",
                      "Stay humble even after great success.", "即使取得巨大成功，也要保持谦逊。"),
            full_item("luminous", "发光的；光明的；清楚的", "ˈluː.mə.nəs", "luminous ideas", "闪耀的想法",
                      "A luminous screen lit the dark room.", "发光的屏幕照亮了黑暗的房间。"),
            full_item("catalyst", "催化剂；促进因素", "ˈkæt.əl.ɪst", "a catalyst for change", "变革的催化剂",
                      "Education is a catalyst for social progress.", "教育是社会进步的催化剂。"),
            full_item("resonate", "共鸣；引起共鸣", "ˈrez.ə.neɪt", "resonate with", "与…产生共鸣",
                      "The message resonates with many young people.", "这条信息引起了许多年轻人的共鸣。"),
            full_item("tenacity", "韧性；坚韧不拔", "təˈnæs.ɪ.ti", "with great tenacity", "以极大的韧性",
                      "Her tenacity helped her overcome setbacks.", "她的韧性帮助她克服了挫折。"),
        ]
        if not minimal else
        [
            minimal_item("humble", "谦逊的；不起眼的"),
            minimal_item("luminous", "发光的；光明的；清楚的"),
            minimal_item("catalyst", "催化剂；促进因素"),
            minimal_item("resonate", "共鸣；引起共鸣"),
            minimal_item("tenacity", "韧性；坚韧不拔"),
        ]
    )

    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'apikey': anon_key,
        'Authorization': f'Bearer {anon_key}',
        'Prefer': 'return=representation',  # return inserted rows
    }

    status, result = _http_post(rest_url, headers, payload, insecure_ssl)
    if status in (200, 201):
        print('[ok] Inserted 5 word cards:')
        try:
            for r in result:
                print(f" - id={r.get('id')} word={r.get('word')}")
        except Exception:
            print(result)
        return 0
    else:
        print(f"[error] HTTP {status} inserting word_cards")
        print(result)
        print('\nCommon causes & fixes:')
        print(' - 400 unknown column: enable SEED_MINIMAL_FIELDS=true to send only word/chinese/created_at')
        print(' - 401/403 RLS forbidden: use a service role key or an authenticated user JWT')
        print(' - 404 route: ensure PostgREST enabled and table is in exposed schemas (public)')
        print(' - 0 network/SSL: set SEED_INSECURE_SSL=true if local CA store issues')
        return 1


if __name__ == '__main__':
    sys.exit(main())