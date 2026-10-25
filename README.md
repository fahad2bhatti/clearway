# Clearway: Arrow Puzzle

Flutter + Flame arrow-maze puzzle: curved buses are packed onto a yard, and
you tap them out in the right order. The Android application id is `com.fahadapps.clearway`; the game engine and level catalog
run locally so puzzles remain playable offline.

## Implemented browser-game features

- Arrow-maze puzzles: curved buses packed onto a board with no visible grid,
  where the only thing that can block a bus is another bus. Tap a bus and it
  drives straight out along the line in front of its arrow.
- 80 deterministic levels and date-seeded daily Rush Hour boards of 100 buses.
  Boards grow from 4×4 to 38×38 across the 80 levels, buses get longer and
  curvier, every 5th level from 15 is a lighter breather, and every 10th level
  is a boss yard with a silhouette board (heart, diamond, cross or ellipse).
  Boards 9 cells wide or more support pinch zoom and pan, with a zoom-lock
  button. A bus only moves on a quick single-finger tap, so panning, pinching
  and long presses never cost a life.
- Solver-backed hints and move safety, 3 lives (one coin-paid revive per
  attempt), stars, chapter intro cards and chapter progression. Every
  generated board is checked solvable by the same solver used in play.
- Local progress for unlocked level, stars, coins, hints, undos, daily streak,
  sound, music, haptics, theme, color-blind preference, and language selection.
- Android Firebase initialization, anonymous guest auth, Firestore progress
  merge, security rules and emulator configuration. Local play stays available
  when auth, Firestore or the network is unavailable.
- Level picker, daily entry, offline practice-reward shop, settings, and a
  truck-art-inspired color theme for the buses.

## Run

```sh
flutter pub get
flutter run
```

`flutter analyze` checks app and test sources. `flutter test` includes engine
and catalog checks, including solvability of all 80 levels. See
[`docs/ROADMAP.md`](docs/ROADMAP.md) for remaining work and Firebase console setup.

## Scope

The browser source provides local saves and mock practice rewards. Firebase
callable/scheduled functions have an initial server scaffold; score replay,
purchase verification, real ads/IAP, full daily-cloud client flow, licensed
audio, iOS setup and release automation remain production work. See
[`docs/ROADMAP.md`](docs/ROADMAP.md) for setup and status.
