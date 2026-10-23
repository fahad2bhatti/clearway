# Firebase client configuration
`lib/firebase_options.dart` contains normal Firebase client configuration, including a project-identifying API key.
Restrict that key in Google Cloud Console to the Android package and signing certificate SHA-1 values.
Add release and Play App Signing SHA-1 values when those certificates are available.
Limit the key to the Firebase APIs required by this app after confirming the app still works.
Never commit keystores, `key.properties`, `.env` files, service account keys or other server credentials.
After changing restrictions, verify anonymous sign-in and Firestore progress sync in a debug build.
