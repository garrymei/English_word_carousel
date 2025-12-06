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

## 📥 纯文本导入模板（JSON Lines）
- 格式：每行一个 JSON 对象（UTF‑8），支持以 `#` 开头的注释行。
- 必填字段：`word`, `chinese`
- 可选字段：`phonetic`, `phrase`, `phrase_cn`, `sentence_en`, `sentence_cn`, `related`(数组)，`enabled`，`tags`(逗号分隔)，`tag_ids`(逗号分隔)，`visibility`（`public` 为公共卡，其他值或缺省为个人卡）。
- `enabled` 支持：`true/false`、`1/0`、`yes/no`、`是/否`、`启用/禁用`、`真/假`。
- `related` 示例：`[{"text":"desert","chinese":"遗弃"},{"text":"quit","chinese":"退出"}]`

示例（可直接保存为 `.txt` 或 `.jsonl`）：
```
# JSON Lines 文本模板 (UTF-8)
# 每行一个 JSON 对象；支持注释行以 # 开头
{"word":"abandon","chinese":"放弃","phonetic":"əˈbændən","phrase":"abandon hope","sentence_en":"They abandoned the project.","sentence_cn":"他们放弃了这个项目。","enabled":true,"tags":"核心词,动词","related":[{"text":"desert","chinese":"遗弃"},{"text":"quit","chinese":"退出"}]}
{"word":"ability","chinese":"能力","enabled":"是","visibility":"public"}
```

导入入口：在“单词卡列表”页面右上角使用“导入文本”按钮，支持 `.txt/.jsonl/.json` 文件。点击按钮会弹出说明对话框，可先“下载模板”，或直接“继续选择文件”。导入完成会提示成功条数与错误示例。

## 🤝 Contributing
- Keep PRs small and focused
- Add/update docs in `docs/` when changing data models

## 📄 License
MIT
