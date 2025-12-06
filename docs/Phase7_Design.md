# Phase 7: Intelligent Oral Evaluation + Leaderboard + Social Learning

## Goals (G1–G6)
- G1 Speech Evaluation: record/upload, backend scoring (accuracy, fluency, completeness, rhythm)
- G2 Feedback Display: show four scores and suggestions, pass threshold highlighting
- G3 Points System: trigger rewards on success; daily/weekly totals
- G4 Leaderboard: global/group leaderboards with Top 3 neon ring effect
- G5 Social Learning: Groups and 7-day Challenge, shared goals and ranking
- G6 Sync: periodic incremental sync (every 30 min) and JWT-based secure APIs

## Architecture
- Flutter App: pages for speech evaluation, leaderboard, groups, challenge
- Backend (NestJS/Supabase): speech scoring service, points service, leaderboard controller
- Storage/DB: PostgreSQL tables for points/records; MinIO/Supabase storage with temporary signed URLs

## Speech Evaluation Flow
1. Record locally → upload via HTTPS + JWT
2. Backend evaluate asynchronously (rate-limit + queue)
3. Return 4-dimension scores and advice JSON
4. Frontend display scores and feedback; trigger points if `score >= 80`

Example Response
```json
{
  "accuracy": 0.86,
  "fluency": 0.83,
  "completeness": 0.88,
  "rhythm": 0.81,
  "score": 86,
  "advice": "Good rhythm, work on /r/ articulation"
}
```

## Points & Experience
- Rules (example):
  - Each evaluation with `score >= 80`: +10 points
  - Continuous 7 days participation: bonus badge
  - Weekly reset with carry-over to total
- Backend endpoints:
  - `POST /points/add` `{ userId, amount, reason }`
  - `GET /points/weekly` `{ userId }`

## Leaderboard System
- Types: Global, Group, Weekly
- Endpoint example: `GET /leaderboard/global?period=weekly`
- Frontend: highlight Top 3 with animated neon rings; show current user rank

## Groups & Challenge
- Group: create/join, share goal and group leaderboard
- Challenge: 7/14-day range, measure study duration + speech score; auto-settle points and badges

## Security & Performance
- Audio Upload: HTTPS + JWT auth
- Storage: temporary signed URL with expiry
- Model Calls: rate-limit, async queue
- Data Sync: incremental every 30 min
- Performance Targets: scoring < 3s; leaderboard render < 1s

## Deliverables (Frontend)
- `/lib/screens/speech/speech_evaluate_screen.dart` (alias to SpeechPractice)
- `/lib/screens/leaderboard/leaderboard_screen.dart` (done)
- `/lib/screens/group/group_screen.dart` (new)
- `/lib/screens/challenge/challenge_screen.dart` (new)
- `/assets/lottie/wave_particle.json` (placeholder)

## Deliverables (Backend)
- `/server/src/speech/evaluate.service.ts` (scoring service)
- `/server/src/points/points.service.ts` (points logic)
- `/server/src/leaderboard/leaderboard.controller.ts` (leaderboard API)

## Acceptance Criteria
- Recording & upload returns scoring result
- Four scores + suggestions shown correctly
- Points update fired on success
- Leaderboard refreshes, no duplicate data
- Challenge can be created and auto-settled
- Response < 3s; no jank; 20 consecutive evaluations without crash

## Development Tasks & Estimates
- A1 Audio record & upload: 1d
- A2 Backend scoring API: 2d
- A3 Points tables & logic: 1d
- A4 Leaderboard API + UI: 2d
- A5 Challenge/Group logic: 2d
- A6 Animations & FX: 1.5d
- A7 Test & regression: 1.5d
Total: ~10–11 dev days