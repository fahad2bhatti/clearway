<div align="center">

# Clearway: Arrow Puzzle

**Tap a vehicle. Clear the way. Empty the yard.**

A tap-to-clear puzzle game for Android, built with Flutter and Flame. Fully playable offline.

`com.fahadapps.clearway`

</div>

---

## About

Every level is a yard packed with vehicles. Tap a vehicle and it drives out along its lane, but only if nothing blocks it. Work out the right order, empty the board and earn up to three stars. A blocked vehicle bumps and costs one of your 3 lives.

All levels are generated on the device from fixed seeds and checked with a solver, so the game never needs a network connection. The cloud features are optional and never block play.

## Features

- **80 levels** in 8 chapters of 10 (`LevelCatalog.totalLevels`). The same level number always produces the same board. Boss levels start at level 5 and come every 5 levels; every 10th level is a silhouette board. Large boards support pinch-to-zoom and pan.
- **Daily challenge ("Rush Hour")**: a 100+ vehicle board for each UTC day. The seed comes from the date alone (`DailyClock.seedFor`, SHA-256 of `clearway:<yyyy-MM-dd>`), so every player gets the same board. The daily screen has a calendar and a streak.
- **Hints, undo, lives and revive**: solver-backed hints, one undo per attempt, 3 lives, and a 30-coin revive.
- **Local economy**: coins, hints and undos live on the device (SharedPreferences). A shop sells hint and undo packs and the Sunset arrow skin for coins; rewarded ads give coins and hints with daily limits. A third skin unlocks free at level 80.
- **Progress extras**: milestones, achievements and daily missions.
- **Safe tapping**: a vehicle moves only on a quick, still, single-finger tap. Panning, zooming and long presses never cost a life.
- **Onboarding**: a first-launch gate (terms and a username, 3-15 characters, letters, digits and `_`) and a guided tutorial for the first three levels.
- **Settings**: sound, haptics, notifications, English and Urdu (right-to-left), rate us, send feedback, and Delete Account.
- **Notifications**: optional reminders scheduled on the device (no push server).
- **Rating prompt** after winning level 10, 25 or 50, and offline-safe feedback (queued on the device and sent when online).

### Online parts (optional)

- Anonymous sign-in with Firebase Authentication.
- Progress sync to Cloud Firestore (`users/{uid}/progress/state`): level, stars, skins, milestones, achievements and missions. The username is not part of it.
- Feedback reports in Firestore (`reports`).
- Firebase Crashlytics crash reports.
- Google AdMob ads (banner, interstitial every 5 levels with a cooldown, rewarded) with the Google consent form (UMP).

## Spark plan limitations

The Firebase project (`clearway-ac80b`) is on the free **Spark** plan, so no server code runs:

- Coins, hints, undos and ad rewards are **local** and can be edited by a determined player. A server-authoritative economy needs the Blaze plan.
- The username is stored on the device only. It is not unique and not synced.
- Anonymous accounts: reinstalling the app loses progress. Google account linking is planned for version 1.1.
- No leaderboard yet.

### Restoring Cloud Functions (when Blaze is available)

The old Cloud Functions backend (daily reward ledger, server economy, username claim, scheduled daily seed) is archived in git. Nothing in the app calls it.

```bash
git fetch --tags
git checkout archive/functions-blaze -- functions
```

That brings back the `functions/` folder. You also need to restore the `functions` block and emulator in `firebase.json` (see that tag), the removed collections in `firestore.rules`, the matching tests, and a client that calls the functions. Never deploy rules from an older branch: the account-deletion rules would be lost.

## Tech stack

| Layer | Technology |
|---|---|
| App | Flutter (Dart SDK `^3.13.5`) |
| Board rendering | [Flame](https://flame-engine.org/) `^1.38.2`, `flame_audio` |
| Local storage | `shared_preferences` (versioned JSON with a last-known-good backup) |
| Backend | Firebase Auth, Cloud Firestore, Crashlytics |
| Ads | `google_mobile_ads` (AdMob + UMP) |
| Other | `flutter_local_notifications`, `in_app_review`, `url_launcher`, `package_info_plus` |

## Project structure

```
clearway/
├── lib/
│   ├── game/        # engine (pure Dart), generator, Flame renderer, game screen
│   ├── features/    # home, shop, settings, onboarding
│   ├── services/    # cloud sync, economy, ads, notifications, feedback queue
│   ├── data/        # local save and progress codec
│   └── core/        # strings (English + Urdu), daily clock, username rules
├── test/            # engine, generator, save, service and widget tests
├── rules_test/      # Firestore security rules tests (Node, emulator)
├── bin/             # dev tools (level_generation_report.dart, maze_preview.dart)
├── docs/            # privacy policy, terms, roadmap, security notes (GitHub Pages)
├── firestore.rules
├── firestore.indexes.json
└── firebase.json
```

## Run, test, build

```bash
flutter pub get
flutter run                 # needs android/app/google-services.json
dart format .
flutter analyze
flutter test
dart run bin/level_generation_report.dart
```

### Firestore rules tests

Needs Node 22, Java and the Firebase CLI:

```bash
cd rules_test
npm install
npm run test:rules:emulator
```

### Deploy (Spark plan)

Deploy **only the rules**, and only from the newest branch:

```bash
firebase deploy --only firestore:rules
```

Never run `firebase deploy` for functions on this plan.

### Release build

```bash
flutter build appbundle --release
```

`build_release.sh` does the same and passes the AdMob unit IDs. Signing needs your own `android/key.properties` and keystore; they are git-ignored and must never be committed.

## License

© Fahad Apps. All rights reserved.
