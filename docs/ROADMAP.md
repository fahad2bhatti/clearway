# Clearway Roadmap

Last updated: 2026-11-01
Application ID: `com.fahadapps.clearway` (Android first; iOS is not configured)

**Status:** ✅ done · 🟡 partial · ⬜ not started

## Shipped in the current release (local-only economy, Spark plan)

- ✅ 80 deterministic, solver-checked levels in 8 chapters; boss and silhouette boards; pinch zoom and pan on large boards.
- ✅ Daily "Rush Hour" challenge seeded from the UTC date alone, with a calendar and streak.
- ✅ Hints, undo, lives, revive; tutorial for levels 1-3; resume of the current board after a restart.
- ✅ Local economy (coins, hints, undos), shop, arrow skins (classic, sunset, spectrum), milestones, achievements, daily missions, rewarded-ad offers with daily limits.
- ✅ First-launch gate: terms plus a device-only username.
- ✅ English and Urdu strings with right-to-left layout.
- ✅ Anonymous Firebase Auth, progress sync to Firestore, feedback reports (offline queue), Crashlytics.
- ✅ AdMob banner, interstitial and rewarded ads with the Google consent form.
- ✅ Local notifications and a rating prompt (levels 10, 25, 50).
- ✅ Delete Account: removes cloud progress, the player's feedback reports and the Auth user.
- ✅ Firestore rules with rules tests (`rules_test/`).

## Known gaps

- 🟡 The Music switch in Settings has no effect (there is no music yet).
- 🟡 Light/dark theme and colour-blind mode exist in the code but have no switch in Settings.
- 🟡 The local economy can be edited on a rooted device or by clearing app data. This is accepted on the Spark plan.
- ⬜ Rewarded-ad offers for undos have no daily limit.

## Version 1.1 (planned)

- ⬜ Google account linking so progress survives a reinstall.
- ⬜ Unique usernames and a leaderboard (needs a server).

## Blaze phase (not scheduled)

The Cloud Functions backend is archived in the `archive/functions-blaze` git tag. Before restoring it:

- ⬜ Server-authoritative economy (coins, hints, undos, ad rewards).
- ⬜ Server-side username claim and leaderboard.
- ⬜ App Check, Remote Config, Analytics.
- ⬜ In-app purchases with server verification (the Remove Ads item was removed from the shop until then).

## Later

- ⬜ More levels and chapters.
- ⬜ CI (format, analyze, tests, rules emulator tests).
- ⬜ Dev/staging/prod Firebase projects and flavors.
- ⬜ iOS (Firebase iOS app, signing, TestFlight).
- ⬜ Accessibility pass (semantics, high contrast, tablet and foldable layouts).

## Working rules

1. Keep the game playable offline; cloud and ad services must never block play.
2. Do not mark a task done until its code exists and the checks pass.
3. Never commit signing keys, `key.properties`, `.env` files or service accounts.
4. Deploy Firestore rules only from the newest branch: `firebase deploy --only firestore:rules`.
