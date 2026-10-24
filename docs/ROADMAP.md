# Clearway Project Roadmap

Last updated: 2026-10-25
Project: Flutter + Flame, Android first; iOS planned  
Application ID: `com.fahadapps.clearway`

This is the working checklist for the browser-game port and the production
features in the Clearway build brief. It is updated as work is completed.

**Status:** ✅ done · 🟡 in progress or partial · ⬜ not started · ⛔ blocked

## Phase 1 — Offline game and browser port

- ✅ Flutter + Flame app shell, portrait Android setup, Clearway identity.
- ✅ Pure Dart vehicle/grid model, movement validation and solver-backed safe
  moves. The engine still supports cones, one-way gates and convoy pairs
  (covered by `engine_v2_test`), but the arrow-maze generator no longer
  places them.
- ✅ Arrow-maze Flame board rendering: curved buses drawn as rounded lines with
  an arrow head, no visible grid, silhouette boards, snake-style exit and bump
  feedback, hint pulse, colour-blind dash patterns, haptic and system-sound
  feedback controls.
- ✅ Deterministic, lazily loaded 80-level catalog built by
  `MazeLevelGenerator`; all 80 levels are checked solvable. Chapter labels
  cycle every 10 levels.
- ✅ Difficulty ramp: levels 1–3 have 2–4 straight buses on a 4×4 board; from
  level 4 buses start to bend, and boards grow to 38×38 with up to 77 buses
  by level 80. Every 5th level from 15 is a lighter breather; every 10th
  level is a boss yard with a silhouette board (heart, diamond, cross,
  ellipse). Boards 9 cells wide or more support pinch zoom and pan.
- ✅ Tutorial tips: levels 1–3 teach tapping, blocking and order; levels 10, 25
  and 40 show tips for boss shapes, breather levels and big boards.
- 🟡 UTC SHA-256-seeded daily puzzles now use the same client/server seed
  formula, can read the shared Firestore seed without waiting on it, and have
  365-day solvability coverage, and `flutter test` passes on the owner's
  machine (2026-10-25).
- ✅ Local save for level unlocks, stars, coins, hints, undos, streaks and
  settings using SharedPreferences.
- ✅ Home screen, level picker, daily entry, local practice-reward shop and
  settings controls.
- 🟡 Tutorial: guided hand pointer and tips guide the first three levels and
  stop once level 3 is won (`tutorialDone` in the local save; older saves past
  level 3 count as done). A separate onboarding flow remains.
- 🟡 Accessibility: color-blind vehicle labels and larger-cell hit tolerance
  exist; semantics, scalable UI audit, high-contrast mode and device review remain.
- 🟡 Localization: English/Urdu strings are now connected to the main home,
  settings, calendar, gameplay, tips, hints, errors and result dialogs; Urdu
  switches the app to right-to-left layout. Chapter names, remaining decorative
  labels, font coverage and a full translation review remain.
- 🟡 Audio: system click/alert feedback is wired to the sound switch; original
  engine, horn, clear, and music assets/player remain.
- 🟡 Recovery: current level, remaining vehicles, lives, mistakes and undo
  snapshot resume locally after app restart. A last-known-good local save backup
  now recovers malformed primary saves; low-memory recovery and device
  validation remain.

## Phase 2 — Firebase setup and offline-first sync

- ✅ Firebase Android config file is valid, matches `com.fahadapps.clearway`,
  and is at `android/app/google-services.json`.
- ✅ Add `firebase_core`, `firebase_auth`, and `cloud_firestore`; Android Google
  Services Gradle plugin is configured.
- ✅ Android Firebase options are generated from the checked app config; app
  startup initializes Firebase without blocking offline play.
- ✅ Anonymous sign-in and local-first cloud progress merge are implemented;
  only highest level and best stars sync from the client. Home has a sync badge
  and manual retry button. Progress now uses a compact positional `starsCode`
  format, reads legacy stars maps for migration, and writes only schema v2.
- ✅ Firestore rules, indexes file and Auth/Firestore emulator ports are added.
- 🟡 User setup: enable Anonymous Auth and create the Firestore database in the
  Firebase Console, then deploy rules/indexes.
- ⛔ FlutterFire CLI refresh could not reach Firebase/Google APIs in this
  workspace. Android options were generated from the local config; rerun
  `flutterfire configure` after network/auth is available.
- 🟡 Firestore rules now validate compact progress documents and prevent
  progress shrinkage. The 15 rules tests pass on the owner's machine
  (2026-10-25); CI remains.
- ⬜ App Check on supported production clients.
- ✅ Crashlytics dependency and Flutter fatal-error handlers are wired.
- ⬜ Remote Config, Analytics and server-time daily rewards.
- 🟡 Cloud Functions v2 scaffold: idempotent daily reward ledger, account
  deletion/export, server-side daily seed schedule, rate limits and configurable
  region/App Check settings are written. App Check defaults off until client
  integration. Client calls, npm install/build, emulator tests and deployment
  remain.
- ⬜ Server-side score replay and leaderboard submission.
- ⬜ Google Play/App Store purchase verification and refund/revoke handlers;
  these need store API setup and credentials in Secret Manager.
- ⬜ Separate dev/staging/prod Firebase projects and flavors.
- ⬜ iOS Firebase config for bundle ID `com.fahadapps.clearway`.

### Firebase setup commands

1. In Firebase Console, enable **Authentication → Anonymous** and create the
   **Cloud Firestore** database in `asia-south1` (Mumbai), matching the default
   `FUNCTIONS_REGION`. Firestore's location cannot be changed later.
2. Reauthenticate the Firebase CLI if needed: `firebase login --reauth`.
3. From the project root deploy the rules and indexes:
   `firebase deploy --only firestore:rules,firestore:indexes`.
4. Install and run the Firestore rules tests with
   `cd functions && npm install && npm run test:rules:emulator`.
5. Build functions with `cd functions && npm run build`,
   then deploy with `firebase deploy --only functions` (Cloud Functions require
   an eligible billing plan).
6. For local emulator play, run `firebase emulators:start --only auth,firestore,functions`
   and start Flutter with
   `--dart-define=CLEARWAY_FIREBASE_EMULATORS=true`.
7. iOS stays offline-only until a Firebase iOS app is registered and its config
   is generated for `com.fahadapps.clearway`.

## Remaining work before a production-ready handoff

There are **8 large milestones left**. Some are substantial work groups, not
single commits; Git push is intentionally the final step after the owner runs
the app and reviews it.

1. **Finish offline game content:** chapter intros, boss board silhouettes,
   achievements, revive flow, pan/zoom, and expand the
   verified catalog beyond the current 80 levels. The requested 10-level easy
   start and chapter-by-chapter grid/path ramp are now implemented.
2. **Finish product polish:** full English/Urdu translation review, licensed
   fonts and audio, accessibility semantics/high contrast, and device layout
   checks.
3. **Complete Firebase project setup:** enable Anonymous Auth, create Firestore,
   reauthenticate the Firebase CLI, deploy rules/indexes, and set up iOS config
   plus dev/staging/prod projects.
4. **Finish online services:** run emulator/rules tests, install/build/deploy
   Functions, wire the client to callable functions, and add App Check, Remote
   Config, Analytics, score replay/leaderboards and cloud daily rewards.
5. **Finish monetization and compliance:** ads, consent, IAP verification and
   restore/refund flows, store availability, privacy/terms and child-directed
   ads decisions.
6. **Finish account and retention features:** account linking/deletion UI,
   cloud conflict handling, notifications, report/share flows and online daily
   calendar synchronization.
7. **Prepare release builds:** flavors, CI, Android signing/AAB and store assets;
   iOS needs a registered app/configuration and a macOS build/signing runner.
8. **Owner verification and handoff:** run the app and tests on devices, fix
   issues found, review the final diff, then commit and push to Git.

## Phase 3 — Remaining game content and retention

- ⬜ Chapter intro cards and chapter/boss board presentation.
- 🟡 Daily calendar and monthly completion trophy view are implemented; daily
  streak/rewards are local. Achievements and device validation remain.
- 🟡 Guided tutorial in levels 1–3 with completion tracking; the revive flow
  remains. Mid-level board restoration is implemented.
- 🟡 Larger-board pinch zoom and pan are enabled from 9×9 boards; a zoom-lock
  control and physical device review remain.
- ⬜ Feedback/report form, share board/result and rate prompt.
- ⬜ Accessibility semantics and small phone/tablet/foldable layout review.

## Phase 4 — Economy and platform services

- ⬜ Real rewarded/interstitial ads with consent flow and test-build kill switch.
- ⬜ IAP products, server receipt/token verification, restore, refund/revoke path.
- ⬜ Shop state for unsupported region/store, offline state and purchase errors.
- ⬜ Notifications with opt-in flow and Firebase Cloud Messaging.
- ⬜ Privacy policy, terms, Data Safety/App Privacy and child-directed ads decision.

## Phase 5 — Release readiness

- ✅ Dart formatting and static analysis currently pass (`dart analyze lib`).
- ✅ Verified on the owner's machine (2026-10-25): `flutter analyze` reports no
  issues and `flutter test` passes (66 tests).
- ⬜ The Android Gradle build and an on-device run are not recorded as verified
  yet; the earlier AI workspace could not run them.
- ⬜ CI for format, analyze, unit/widget tests, Firebase emulator tests and level
  verification.
- ⬜ Android signing, release AAB, Play internal/closed testing and store assets.
- ⬜ iOS macOS CI/signing/TestFlight workflow and device testing.
- ⬜ Performance, crash-free, accessibility and low-end device QA.

## Pack 2 implementation status (2026-10-24)

- ✅ Compact `ProgressCodec`, legacy-map reads, v2-only writes, `starsCode`
  Firestore rules and rules tests are in the source tree.
- ✅ Daily puzzle keys now use UTC; client and server share the SHA-256 seed
  formula. Daily seed fetch is cache-first for entry and has a 1.5 second
  timeout for the background server lookup.
- ✅ Levels are generated on demand and cached; the next level is queued after
  the win frame. `bin/level_generation_report.dart` measured levels 1, 10, 20,
  40, 60 and 80 at 7.8, 12.4, 30.8, 125.4, 178.3 and 496.9 ms respectively
  in this workspace.
- ✅ Functions use `FUNCTIONS_REGION` (default `asia-south1`) and enable App
  Check only when `ENFORCE_APP_CHECK=true`; see `functions/.env.example`.
- ✅ `dart format .` and `flutter analyze` pass. A direct pure-Dart smoke run
  verified the codec, all catalog levels and 365 daily puzzles.
- ✅ Verified later on the owner's machine (2026-10-25): `flutter test` passes
  and the Firestore rules tests pass (15 of 15) with
  `npm run test:rules:emulator` in `functions/`. `npm run build` and
  `npm run test:daily` are not recorded as run yet.
- ✅ The `functions/` dev dependency `firebase` is pinned to `^11.10.0` because
  `@firebase/rules-unit-testing@4` needs `firebase@^11`. Firebase 13 with
  rules-unit-testing 6 needs Node 24.12 or newer and did not reduce the
  `npm audit` findings, so it was not adopted.
- ⬜ Remaining `npm audit` findings: `uuid` through `firebase-admin` (needs a
  `firebase-admin` 14 upgrade) and `@grpc/grpc-js` in the test-only firebase
  client. Try the `firebase-admin` upgrade on its own branch before deploying
  Functions; do not run `npm audit fix --force`.

## Working rules

1. Update this file after each meaningful implementation milestone.
2. Do not mark a task done until its code/config exists and the available checks
   support that status. Record environment-blocked checks explicitly.
3. Keep the game playable offline; cloud and platform services must not block
   local play.
4. Do not add real product credentials, signing keys or server secrets to Git.
