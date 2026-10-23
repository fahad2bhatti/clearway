# Clearway Project Roadmap

Last updated: 2026-10-24
Project: Flutter + Flame, Android first; iOS planned  
Application ID: `com.fahadapps.clearway`

This is the working checklist for the browser-game port and the production
features in the Clearway build brief. It is updated as work is completed.

**Status:** ✅ done · 🟡 in progress or partial · ⬜ not started · ⛔ blocked

## Phase 1 — Offline game and browser port

- ✅ Flutter + Flame app shell, portrait Android setup, Clearway identity.
- ✅ Pure Dart vehicle/grid model, movement validation, cone and one-way gate
  rules, convoy group moves, solver-backed safe moves.
- ✅ Truck-art-inspired Flame board rendering, vehicle exit/bump feedback,
  obstacle art, haptic and system-sound feedback controls.
- 🟡 Deterministic, lazily loaded 80-level catalog with chapter labels, boss markers and
  mechanics introduced at levels 10, 25 and 40.
- ✅ Difficulty ramp: levels 1–10 stay small with at most four short vehicles;
  later 10-level chapters grow from 7×7 to 19×19 by two cells per side, while
  vehicle counts and maximum path lengths rise gradually. Large boards support
  pinch zoom and pan.
- ✅ From level 40, denser boards have more vehicles and two long buses cross
  each other's exit lanes and remain independent: each tap clears only one bus,
  so the player must choose the safe order. Bus paths grow each chapter and the
  crossing orientation alternates.
  Separate truck/rickshaw convoys unlock from level 50.
- 🟡 UTC SHA-256-seeded daily puzzles now use the same client/server seed
  formula, can read the shared Firestore seed without waiting on it, and have
  365-day solvability coverage written; the Flutter test runner still needs a
  local run outside this workspace.
- ✅ Local save for level unlocks, stars, coins, hints, undos, streaks and
  settings using SharedPreferences.
- ✅ Home screen, level picker, daily entry, local practice-reward shop and
  settings controls.
- 🟡 Tutorial: guided hand pointer and mechanic tips now guide the first three
  levels; tutorial completion tracking and a separate onboarding flow remain.
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
  progress shrinkage. Rules tests are written, but need npm install and an
  emulator run; CI remains.
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
   tutorial completion, achievements, revive flow, pan/zoom, and expand the
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
- 🟡 Guided tutorial exists in levels 1–3; tutorial completion flow and revive
  flow remain. Mid-level board restoration is implemented.
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
- 🟡 Catalog and engine tests are written; full `flutter test` run remains.
- ⛔ In this workspace Flutter tests cannot start their loopback server; Android
  Gradle build cannot determine a usable machine IP. Re-run in a normal local
  Flutter/Android environment.
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
- ⛔ `flutter test --reporter expanded` cannot start test isolates because this
  workspace denies the test runner's `127.0.0.1` socket. Functions tests also
  remain unrun: npm dependencies are absent, offline install is `ENOTCACHED`,
  and `npm run test:daily` reports `tsc: not found`. Run the local commands in
  the Pack 2 report before treating the pack as fully verified.

## Working rules

1. Update this file after each meaningful implementation milestone.
2. Do not mark a task done until its code/config exists and the available checks
   support that status. Record environment-blocked checks explicitly.
3. Keep the game playable offline; cloud and platform services must not block
   local play.
4. Do not add real product credentials, signing keys or server secrets to Git.
