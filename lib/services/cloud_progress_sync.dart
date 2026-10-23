import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../data/local_save.dart';

enum CloudSyncStatus { notConfigured, offline, syncing, synced, failed }

/// Anonymous account and conflict-safe progress sync. Local play never waits
/// for Firebase to be reachable.
final class CloudProgressSync extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  CloudSyncStatus status = CloudSyncStatus.notConfigured;
  bool _busy = false;
  bool _ready = false;
  bool _emulatorConfigured = false;
  bool _syncAgain = false;

  bool get isReady => _ready;

  Future<void> retry(LocalSave local) async {
    await initialize();
    await sync(local);
  }

  static const _useEmulators = bool.fromEnvironment(
    'CLEARWAY_FIREBASE_EMULATORS',
    defaultValue: false,
  );
  static const _emulatorHost = String.fromEnvironment(
    'CLEARWAY_FIREBASE_EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        throw StateError('Firebase has not been initialized.');
      }
      _auth ??= FirebaseAuth.instance;
      _firestore ??= FirebaseFirestore.instance;
      if (_useEmulators && !_emulatorConfigured) {
        _auth!.useAuthEmulator(_emulatorHost, 9099);
        _firestore!.useFirestoreEmulator(_emulatorHost, 8080);
        _emulatorConfigured = true;
      }
      if (_auth!.currentUser == null) {
        await _auth!.signInAnonymously();
      }
      _ready = _auth!.currentUser != null;
      status = _ready ? CloudSyncStatus.offline : CloudSyncStatus.failed;
    } catch (_) {
      _ready = false;
      status = CloudSyncStatus.offline;
    }
    notifyListeners();
  }

  Future<void> sync(LocalSave local) async {
    if (!_ready) return;
    if (_busy) {
      _syncAgain = true;
      return;
    }
    final uid = _auth?.currentUser?.uid;
    if (uid == null) {
      _ready = false;
      status = CloudSyncStatus.offline;
      notifyListeners();
      return;
    }
    _busy = true;
    status = CloudSyncStatus.syncing;
    notifyListeners();
    try {
      final ref = _firestore!
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc('state');
      final snapshot = await ref.get();
      final remote = snapshot.data();
      if (remote != null) {
        final remoteLevel = (remote['highestLevel'] as num?)?.toInt() ?? 1;
        final remoteStars = (remote['stars'] as Map<String, dynamic>? ?? {})
            .map(
              (key, value) => MapEntry(int.parse(key), (value as num).toInt()),
            );
        await local.mergeCloudProgress(remoteLevel, remoteStars);
      }
      await ref.set({
        'highestLevel': local.level,
        'stars': {
          for (final entry in local.stars.entries) '${entry.key}': entry.value,
        },
        'schemaVersion': 1,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      status = CloudSyncStatus.synced;
    } on FirebaseException catch (error) {
      status =
          error.code == 'unavailable' || error.code == 'network-request-failed'
          ? CloudSyncStatus.offline
          : CloudSyncStatus.failed;
    } catch (_) {
      status = CloudSyncStatus.failed;
    } finally {
      _busy = false;
      notifyListeners();
      if (_syncAgain) {
        _syncAgain = false;
        await sync(local);
      }
    }
  }
}
