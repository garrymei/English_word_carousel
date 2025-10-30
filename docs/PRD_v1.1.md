# PRD v1.1 – English Word Carousel (with Auth)

## 1. Overview
Cross‑platform vocabulary carousel app to strengthen memory via repeated exposure. MVP supports card management, tag filtering, timed carousel, TTS audio with caching, and Auth (email register, username login).

## 2. Core Modules
- Word Cards (fields: word, phonetic, chinese, sentence_en, sentence_cn, related_enabled, related[], enabled, tag_ids[])
- Tags (many‑to‑many with cards)
- Carousel Config (cards, tag_filter, shuffle, play_sound, interval_seconds, duration_mode: 5min/10min/20min/1h/forever)
- Audio Cache (system TTS preferred; optional cloud TTS; prefetch at save or at run; LRU cleanup)
- Auth (email register, **username login**, unique username rule, JWT client session)

## 3. Data Models
### 3.1 WordCard
```
id: string (uuid)
word: string
phonetic: string
chinese: string
sentence_en: string
sentence_cn: string
related_enabled: boolean
related: [{ word, phonetic, chinese }]
enabled: boolean
tag_ids: string[]
audio_path: string
user_id: string
created_at, updated_at: datetime
```

### 3.2 Tag
```
id, name, color, description, user_id, created_at
```

### 3.3 CarouselConfig
```
id, name, card_ids[], tag_filter[], shuffle, play_sound,
interval_seconds, duration_mode, loop_forever, user_id
```

### 3.4 User
```
id, email (unique), username (unique, case‑insensitive),
password_hash, settings{ default_voice, default_duration, dark_mode },
created_at, updated_at
```

## 4. Auth Requirements
- Register via email; login via **username + password**
- Username unique (case‑insensitive), 3–20 chars, [A‑Z0‑9_]
- Password >= 8 chars, letters + numbers
- API:
  - POST /api/auth/register {email, username, password}
  - POST /api/auth/login {username, password} -> {token, user}
- Store token in secure storage (Keychain / EncryptedSharedPrefs)
- Token expiry ~7d

## 5. Carousel Timing
- Modes: 5m / 10m / 20m / 1h / forever
- Show remaining time when not forever
- Interval per card default 5s (configurable)

## 6. Audio Cache
- On save/edit of card -> ensure audio cached
- On run -> prefetch deck audios (progress UI), then play
- Cache path: /cache/audio/{word}_{voice}.mp3
- LRU cleanup weekly, max 500MB

## 7. Non‑Functional
- Offline first; startup <2s
- >90% cache hit ratio after first run
- Crash‑free during long carousel sessions

## 8. Roadmap
v1.2: email verification, password reset, stats dashboard, CSV import, dark mode polish, cloud sync.
