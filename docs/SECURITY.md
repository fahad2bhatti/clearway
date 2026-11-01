# Security notes

## Firebase client configuration
`lib/firebase_options.dart` contains normal Firebase client configuration, including a project-identifying API key.
Restrict that key in Google Cloud Console to the Android package and signing certificate SHA-1 values.
Add the release and Play App Signing SHA-1 values when those certificates are available.
Limit the key to the Firebase APIs this app needs after confirming the app still works.
After changing restrictions, verify anonymous sign-in and Firestore progress sync in a debug build.

## Firestore rules
`firestore.rules` allows only what the app uses:

- `users/{uid}/progress/state`: the owner can read, create, update (never lowering progress) and delete it. Writes are validated field by field.
- `reports/{id}`: a signed-in player can create a report for their own uid, and read or delete only their own reports.
- Everything else is denied by default.

Deploy rules only from the newest branch, with `firebase deploy --only firestore:rules`. Older rules would block the account-deletion deletes. Run `cd rules_test && npm run test:rules:emulator` before every deploy.

## Local economy
Coins, hints, undos and ad rewards are stored on the device (SharedPreferences) because the project is on the Spark plan and no server code runs. A player who edits the device storage can give themselves coins. A server-authoritative economy needs the Blaze plan.

## Secrets
Never commit keystores, `key.properties`, `.env` files, service account keys or other server credentials.
