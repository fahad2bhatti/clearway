# Copilot instructions for Clearway

## Project shape

Clearway is a Flutter app using Flame for the interactive puzzle board. Android
is the primary target (`com.fahadapps.clearway`); iOS scaffolding exists, while
web is not configured.

The app is organized around these boundaries:

- `lib/main.dart` owns app startup, portrait orientation, Crashlytics handlers,
  Firebase initialization, local-save lifecycle, and routing between the home
  and game screens.
- `lib/game/engine/` is the platform-independent puzzle model and rules:
  `GameLevel`, `Vehicle`, `MoveValidator`, and `LevelSolver`. Keep gameplay
  rules here rather than in widgets or Flame rendering code.
- `lib/game/generator/` creates deterministic boards. `LevelCatalog` lazily
  caches the 80 main levels; daily boards are generated from a UTC day key and
  a shared seed.
- `lib/game/components/yard_game.dart` is the Flame renderer, hit testing, tap
  feedback, and exit animation. `lib/game/game_screen.dart` coordinates UI
  state, lives, hints, undo, revive, tutorials, and persistence around it.
- `lib/data/local_save.dart` is the offline source of truth for player progress.
  `lib/services/cloud_progress_sync.dart` and
  `lib/services/progress_sync_debouncer.dart` perform optional anonymous-auth
  Firestore synchronization without blocking local play.
- The project is on the Firebase Spark plan: no server code runs. The Cloud
  Functions backend is archived in the `archive/functions-blaze` git tag.
  `firestore.rules` only allows `users/{uid}/progress/state` and `reports`;
  `rules_test/` holds the rules tests.

## Commands

Run these from the repository root unless noted:

```sh
flutter pub get
flutter analyze
flutter test
flutter test test/game/engine/move_validator_test.dart
flutter test test/game/engine/move_validator_test.dart -n "test name"
dart format .
flutter run
```

Use `flutter test <path>` for one Dart test file, or add `-n "..."` to select
one named test. Tests cover the pure engine, generator/catalog solvability,
local persistence, UI/game behavior, and sync resilience.

Firestore rules tests run from `rules_test/`:

```sh
npm install
npm run test:rules:emulator
```

The rules emulator test starts Firebase's Firestore emulator through
`firebase emulators:exec`. `flutter analyze` is the app's configured static
check.

To run the Flutter client against local Firebase emulators:

```sh
firebase emulators:start --only auth,firestore
flutter run --dart-define=CLEARWAY_FIREBASE_EMULATORS=true
```

The default Android emulator host is `10.0.2.2`; override it with
`CLEARWAY_FIREBASE_EMULATOR_HOST` when needed. Deploy only the rules, from the
newest branch: `firebase deploy --only firestore:rules`. Never deploy
functions on the Spark plan.

## Implementation conventions

- Preserve offline-first behavior. Firebase initialization, authentication,
  Firestore reads/writes, and daily-seed refreshes must be optional and must
  not prevent a locally playable game.
- Keep engine and generation logic pure Dart and deterministic where possible.
  `MoveValidator` is the single movement authority used by both gameplay and
  `LevelSolver`; generated levels must remain solvable by that same solver.
- Main levels and daily puzzles are deterministic contracts. The daily seed
  comes from the UTC date key alone (`DailyClock.seedFor`, SHA-256), so every
  player gets the same board; its vector tests pin the formula.
- `LocalSave` persists a versioned JSON shape in `SharedPreferences` and keeps
  a last-known-good backup. Validate/clamp persisted values and preserve
  recovery behavior when extending the save format.
- Cloud progress is intentionally limited to monotonic highest level and stars.
  `ProgressCodec` stores stars as an index-preserving compact string; new
  Firestore progress writes must use schema version 2 and match
  `firestore.rules`. The coin/hint/undo economy is local-only (Spark plan).
- Use `ChangeNotifier` for the existing save/cloud service state flow and keep
  debounced sync requests behind `ProgressSyncDebouncer`; do not introduce a
  second state-management pattern for a localized change.
- Flame owns board painting and hit testing, while Flutter widgets own dialogs,
  navigation, controls, and persistence. `TapGate` deliberately rejects
  drags, pinch gestures, long presses, and stale pointer state so only an
  intentional quick single-finger tap moves a vehicle.
- Keep localization and layout direction through `ClearwayStrings` and the
  app-level English/Urdu `Directionality`; avoid hard-coded user-facing text in
  gameplay widgets.
- Respect the existing level model invariants: vehicle paths are connected,
  vehicle IDs are unique, convoy IDs occur in pairs, and obstacles cannot
  overlap vehicles or each other.
- Keep secrets, signing material, Firebase credentials, and production
  configuration out of Git.

## Repository references

- `README.md` describes the product scope and normal Flutter run commands.
- `docs/ROADMAP.md` records the shipped scope and the planned work. Update it
  when a meaningful milestone changes.
- `analysis_options.yaml` excludes generated Android/iOS/build output from Dart
  analysis.
