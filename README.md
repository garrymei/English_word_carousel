# English Word Carousel

A cross‑platform (Windows / macOS / iOS) vocabulary carousel app focused on spaced exposure and lightweight study sessions.

## ✨ Core Features (MVP)
- Card‑based word deck (EN word, phonetic, CN meaning, example sentence, related words)
- Tag system (many‑to‑many) for filtering decks
- Carousel player with time modes: 5/10/20 min, 1h, or forever
- Optional TTS playback per card
- Local audio cache to reduce bandwidth
- Enable/disable cards, add tags, shuffle, interval per card
- (v1.1) Auth: email **registration**, **username** login (username unique, case‑insensitive)

## 📦 Tech Stack (Suggested)
- **Flutter** for clients (desktop + iOS from one codebase)
- **SQLite** for local storage, JSON import/export
- **TTS**: system TTS first; optional cloud TTS later
- (Optional) **NestJS/Supabase** backend for auth & sync

## 🚀 Quick Start (Flutter)
```bash
# 1) Create Flutter app locally then copy these files in, or use this repo as the app root
flutter pub get
flutter run -d macos   # or windows / ios
```

## 🤝 Contributing
- Keep PRs small and focused
- Add/update docs in `docs/` when changing data models

## 📄 License
MIT
