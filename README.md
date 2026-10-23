# Clearway: Arrow Puzzle

Flutter + Flame port of the browser Clearway truck-yard puzzle. The Android
application id is `com.fahadapps.clearway`; the game engine and level catalog
run locally so puzzles remain playable offline.

## Implemented browser-game features

- 80 deterministic levels and date-seeded daily challenges. The first ten
  levels are the easy band; later ten-level chapters add grid space, vehicles
  and longer routes, up to a 19×19 board. Larger boards support pinch zoom and
  pan.
- Solver-backed hints and move safety, 3 lives, stars, chapter progression,
  cones, one-way gates, crossing buses from level 40, truck/rickshaw convoys,
  boss markers, and larger boards.
- Local progress for unlocked level, stars, coins, hints, undos, daily streak,
  sound, music, haptics, theme, color-blind preference, and language selection.
- Android Firebase initialization, anonymous guest auth, Firestore progress
  merge, security rules and emulator configuration. Local play stays available
  when auth, Firestore or the network is unavailable.
- Level picker, daily entry, offline practice-reward shop, settings, and
  original truck-art-inspired vehicle, cone, and gate vector art.

## Run

```sh
flutter pub get
flutter run
```

`flutter analyze` checks app and test sources. `flutter test` includes engine
and catalog checks, including all 80 levels and mechanic unlock points. See
[`docs/ROADMAP.md`](docs/ROADMAP.md) for remaining work and Firebase console setup.

## Scope

The browser source provides local saves and mock practice rewards. Firebase
callable/scheduled functions have an initial server scaffold; score replay,
purchase verification, real ads/IAP, full daily-cloud client flow, licensed
audio, iOS setup and release automation remain production work. See
[`docs/ROADMAP.md`](docs/ROADMAP.md) for setup and status.
