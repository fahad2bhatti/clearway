# Clearway: Arrow Puzzle

Clearway is a mobile puzzle game built with Flutter and Flame. Every board is packed with arrows, and your job is to tap each one so it slides out of the grid without hitting another. Clear the whole board to win.

Developed by **Fahad Apps** · Android first, iOS planned · Status: Google Play closed testing

## Gameplay

- **Tap to clear**: tap an arrow and it slides out along its direction. Blocked arrows cost you, so plan the order.
- **Fully filled boards**: no empty cells, with different shapes and patterns across levels.
- **Rising difficulty**: arrow count and difficulty grow every 10 levels.
- **Monster stages**: a very hard level every 5 to 6 levels for players who want a real challenge.
- **Daily Rush Hour level**: a fresh board every day.
- **Hints, Undo and Grid Assist** to get unstuck.
- **Coins and Shop**: earn coins, spend them on hints and undos.
- **Daily offers**: watch a rewarded ad to get bonus hints and coins.
- **Sound effects** that follow the media volume.
- **Accounts**: unique username, with Terms & Conditions and Privacy Policy accepted before play.

## Tech stack

- Flutter and Dart
- Flame for the game board and animations
- `flame_audio` for sound effects
- Firebase (Auth, Firestore)
- Google Mobile Ads (AdMob) for banner and rewarded ads
- `flutter_local_notifications` and `flutter_timezone` for reminders

## Getting started

Requirements: Flutter SDK, Android SDK, a device or emulator.

```bash
git clone https://github.com/fahad2bhatti/clearway.git
cd clearway
flutter pub get
flutter run
```

### Firebase

`android/app/google-services.json` is not in the repository. Create your own Firebase project, add an Android app with the package name `com.fahadapps.clearway`, and place its `google-services.json` in `android/app/`.

### Ads

The app ships with Google test ad unit IDs in debug. Release builds use the real AdMob unit IDs set as defaults in `ad_service.dart`. Use your own AdMob IDs if you fork this project.

### Release build

Create an upload keystore, then add `android/key.properties` (this file and `*.jks` are git-ignored):

```properties
storeFile=/absolute/path/to/upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

```bash
flutter build appbundle --release
```

## Tests

```bash
flutter analyze
flutter test
```

## Known notes

- Impeller is disabled in `AndroidManifest.xml` (`EnableImpeller=false`) because of a Vulkan crash seen on Pixel 7a.

## License

Copyright (c) 2026 Fahad Apps. All rights reserved. Third-party packages remain under their own licenses.

## Contact

Fahad Apps, Faisalabad, Pakistan
