<div align="center">

# Clearway: Arrow Puzzle

**Tap an arrow. Slide it out. Clear the way.**

A calm-but-tricky mobile puzzle game built with Flutter + Flame, playable fully offline.

![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-Flame-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Crashlytics-FFCA28?logo=firebase&logoColor=black)
![Status](https://img.shields.io/badge/status-Google%20Play%20closed%20testing-blue)

`com.fahadapps.clearway`

</div>

---

## About

Clearway is a tap-to-clear puzzle. Every level is a board packed with arrow-shaped paths. Tap an arrow and it slides out along its path, but only if nothing is blocking its way. Work out the right order, clear the board, and earn your stars.

The game engine and level catalog run locally, so every puzzle is playable without a network connection. Cloud features (guest sign-in, progress sync, daily seed) are optional extras that never block local play.

## Features

### Gameplay
- **Arrow-path puzzles:** each arrow is a curved path drawn as a rounded line with an arrow head. Tap one to slide it out of the board; if it is blocked, it bumps and you lose a life.
- **80 deterministic levels:** the same level number always generates the same board. Every level is verified solvable.
- **Difficulty ramp:** the first ten levels are an easy start. Boards then grow chapter by chapter, with more arrows and longer, twistier paths. Large boards support pinch-to-zoom and pan.
- **Breather levels and boss boards:** lighter levels give you a rest, and boss levels use silhouette boards (heart, diamond, cross, ellipse).
- **Daily challenge:** a new puzzle every day, seeded by the UTC date so every player gets the same board. A calendar and monthly trophy view track completion.
- **Hints, undo and lives:** solver-backed hints and safe-move checks, 3 lives per attempt, stars for clean clears, and a coin-based revive.
- **Safe tapping:** an arrow moves only on a quick, still, single-finger tap. Panning, zooming and long presses never cost a life.

### Experience
- **Guided tutorial** for the first three levels, plus tips for boss shapes, breather levels and big boards.
- **Settings:** sound, music, haptics, light/dark theme, color-blind mode (dash patterns) and language (English / Urdu with right-to-left layout).
- **Local progress:** unlocked level, stars, coins, hints, undos, daily streak and settings are saved on device, with a last-known-good backup to recover from corrupted saves.
- **Resume anywhere:** current level, remaining arrows, lives and undo history resume after an app restart.

### Online (optional, offline-first)
- Anonymous guest sign-in with Firebase Authentication.
- Cloud progress merge via Cloud Firestore: only the highest level and best stars sync, so progress never shrinks.
- Crashlytics crash reporting.
- Banner ads via Google Mobile Ads (AdMob).
- Cloud Functions v2 scaffold: daily reward ledger, account export and deletion, scheduled daily seed.

## Tech stack

| Layer | Technology |
|---|---|
| App framework | Flutter (Dart SDK `^3.13.5`) |
| Game rendering | [Flame](https://flame-engine.org/) `^1.38.2` |
| State management | `provider` |
| Local storage | `shared_preferences` |
| Backend | Firebase Auth, Cloud Firestore, Crashlytics, Cloud Functions v2 |
| Monetization | `google_mobile_ads` |
| Tooling | `flutter_launcher_icons`, `flutter_lints` |

## Project structure

```
clearway/
├── lib/            # App code: game engine, level generator, UI, services
├── test/           # Engine, catalog, codec and widget tests
├── bin/            # Dev tools (e.g. level_generation_report.dart)
├── assets/         # Images and app icon sources
├── docs/           # ROADMAP.md and project documentation
├── functions/      # Firebase Cloud Functions + Firestore rules tests
├── android/        # Android project (applicationId com.fahadapps.clearway)
├── ios/            # iOS project (not yet configured for release)
├── firestore.rules
├── firestore.indexes.json
└── firebase.json
```

## Getting started

### Prerequisites
- Flutter SDK matching `sdk: ^3.13.5`
- Android Studio or the Android SDK, plus a device or emulator
- (Optional) Node.js and the Firebase CLI for backend work

### Run the game

```bash
git clone https://github.com/fahad2bhatti/clearway.git
cd clearway
flutter pub get
flutter run
```

The game is fully playable offline. Firebase features need the setup below.

### Check code quality

```bash
dart format .
flutter analyze
flutter test
```

`flutter test` covers the engine, the progress codec, all 80 levels (solvability) and 365 daily puzzles.

### Measure level generation speed

```bash
dart run bin/level_generation_report.dart
```

## Firebase setup

1. In the Firebase Console, enable **Authentication → Anonymous** and create a **Cloud Firestore** database in `asia-south1` (the location cannot be changed later).
2. Put your Android config at `android/app/google-services.json` (it must match `com.fahadapps.clearway`).
3. Log in to the CLI: `firebase login --reauth`.
4. Deploy rules and indexes:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```
5. Test the rules:
   ```bash
   cd functions && npm install && npm run test:rules:emulator
   ```
6. Build and deploy Functions (needs a billing plan):
   ```bash
   cd functions && npm run build
   firebase deploy --only functions
   ```
7. Local emulator play:
   ```bash
   firebase emulators:start --only auth,firestore,functions
   flutter run --dart-define=CLEARWAY_FIREBASE_EMULATORS=true
   ```

> Never commit signing keys, store credentials or server secrets. Use `functions/.env.example` as the template for Functions configuration.

## Build for release

```bash
flutter build appbundle --release
```

Sign the app bundle with your own upload key before uploading to Google Play. iOS release needs a registered Firebase iOS app, a macOS build runner and signing, and is planned after the Android launch.

## Status

Clearway is in **Google Play closed testing**. Android is the first target, with iOS planned later. See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the full checklist, including:

- More levels and achievements
- Score replay and leaderboards
- In-app purchases with server verification
- Remote Config, Analytics and notifications
- CI and release automation

## Offline-first principle

Local play always works. Cloud sync, daily seeds and ads must never block a player from solving puzzles.

## License

© Fahad Apps. All rights reserved.
