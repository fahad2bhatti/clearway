import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Generated from the registered Clearway Android Firebase app config.
/// Run `flutterfire configure` again when iOS Firebase is registered.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Clearway Firebase is not configured for web.');
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => throw UnsupportedError(
        'Register the Clearway iOS app and run flutterfire configure.',
      ),
      _ => throw UnsupportedError(
        'Clearway Firebase is not configured for this platform.',
      ),
    };
  }

  static const android = FirebaseOptions(
    apiKey: "AIzaSyDUDLRFyNV73IYNekgUeOD6r8L-_xtPtt4",
    appId: "1:292946924069:android:a29e97aab33ab6a4f325cc",
    messagingSenderId: "292946924069",
    projectId: "clearway-ac80b",
    storageBucket: "clearway-ac80b.firebasestorage.app",
  );
}
