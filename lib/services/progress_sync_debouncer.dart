import 'dart:async';

import '../data/progress_codec.dart';
import '../data/local_save.dart';

/// Stable identity for exactly the progress fields stored in Firestore.
final class ProgressSyncSignature {
  const ProgressSyncSignature._(this.value);

  factory ProgressSyncSignature.fromSave(LocalSave save) =>
      ProgressSyncSignature.fromProgress(
        save.level,
        save.stars,
        arrowSkins: save.ownedArrowSkins,
        selectedArrowSkin: save.selectedArrowSkin,
        claimedMilestones: save.claimedMilestones,
      );

  factory ProgressSyncSignature.fromProgress(
    int highestLevel,
    Map<int, int> stars,
    {
    Set<String> arrowSkins = const {'classic'},
    String selectedArrowSkin = 'classic',
    Set<String> claimedMilestones = const {},
    }
  ) {
    return ProgressSyncSignature._(
      '$highestLevel|${ProgressCodec.encode(stars, throughLevel: highestLevel)}'
      '|${(arrowSkins.toList()..sort()).join(",")}'
      '|$selectedArrowSkin'
      '|${(claimedMilestones.toList()..sort()).join(",")}',
    );
  }

  final String value;

  @override
  bool operator ==(Object other) =>
      other is ProgressSyncSignature && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

typedef ProgressSyncOperation = Future<ProgressSyncSignature?> Function(
  bool force,
);

/// Coalesces local progress changes and records only signatures the cloud
/// confirms as synchronized. The callback is injectable for unit tests.
final class ProgressSyncDebouncer {
  ProgressSyncDebouncer({
    required ProgressSyncOperation operation,
    this.delay = const Duration(seconds: 8),
  }) : _sync = operation;

  final ProgressSyncOperation _sync;
  final Duration delay;
  Timer? _timer;
  ProgressSyncSignature? _pending;
  ProgressSyncSignature? _lastSynced;
  var _busy = false;
  var _flushAgain = false;
  var _forceAgain = false;
  var _disposed = false;

  void request(ProgressSyncSignature signature) {
    if (_disposed || signature == _lastSynced) return;
    if (signature == _pending && _timer != null) return;
    _pending = signature;
    _schedule();
  }

  void markSynced(ProgressSyncSignature signature) {
    if (_disposed) return;
    _lastSynced = signature;
    if (_pending == signature) {
      _pending = null;
      _timer?.cancel();
      _timer = null;
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(flush()));
  }

  Future<void> flush({bool force = false}) async {
    if (_disposed) return;
    _timer?.cancel();
    _timer = null;
    if (_busy) {
      _flushAgain = true;
      _forceAgain = _forceAgain || force;
      return;
    }
    if (_pending == null && !force) return;
    if (_pending == _lastSynced && !force) {
      _pending = null;
      return;
    }

    final attempted = _pending;
    var failed = false;
    _pending = null;
    _busy = true;
    try {
      final synced = await _sync(force);
      if (synced == null) {
        failed = true;
      } else {
        markSynced(synced);
      }
    } catch (_) {
      // Keep local play independent of cloud availability.
      failed = true;
    } finally {
      _busy = false;
      final flushAgain = _flushAgain;
      final forceAgain = _forceAgain;
      _flushAgain = false;
      _forceAgain = false;
      if (!_disposed && (_pending != null || (flushAgain && forceAgain))) {
        if (flushAgain) {
          await flush(force: forceAgain);
        } else {
          _schedule();
        }
      }
    }
    // Keep a failed attempt queued, without a retry timer: the next flush
    // (level won, app paused, manual retry) sends it instead of losing it.
    if (failed && !_disposed) _pending ??= attempted;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }
}
