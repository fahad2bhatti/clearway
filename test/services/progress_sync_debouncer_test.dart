import 'package:clearway/services/progress_sync_debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('progress sync signature', () {
    test('same progress has the same signature independent of map order', () {
      final first = ProgressSyncSignature.fromProgress(8, {3: 2, 1: 3});
      final same = ProgressSyncSignature.fromProgress(8, {1: 3, 3: 2});

      expect(first, same);
    });

    test('higher level or star count changes the signature', () {
      final baseline = ProgressSyncSignature.fromProgress(8, {3: 2});

      expect(ProgressSyncSignature.fromProgress(9, {3: 2}), isNot(baseline));
      expect(ProgressSyncSignature.fromProgress(8, {3: 3}), isNot(baseline));
    });
  });

  test('rapid progress changes coalesce into one delayed sync', () async {
    final synced = ProgressSyncSignature.fromProgress(12, {4: 3, 9: 2});
    var calls = 0;
    var forced = false;
    final debouncer = ProgressSyncDebouncer(
      delay: const Duration(milliseconds: 30),
      operation: (force) async {
        calls++;
        forced = force;
        return synced;
      },
    );
    addTearDown(debouncer.dispose);

    debouncer.request(ProgressSyncSignature.fromProgress(10, {4: 2}));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    debouncer.request(ProgressSyncSignature.fromProgress(11, {4: 2}));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    debouncer.request(synced);

    expect(calls, 0);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(calls, 1);
    expect(forced, isFalse);
  });

  test('flush runs a pending sync immediately', () async {
    final signature = ProgressSyncSignature.fromProgress(2, {1: 3});
    var calls = 0;
    final debouncer = ProgressSyncDebouncer(
      delay: const Duration(seconds: 8),
      operation: (force) async {
        calls++;
        return signature;
      },
    );
    addTearDown(debouncer.dispose);

    debouncer.request(signature);
    await debouncer.flush();

    expect(calls, 1);
  });
}
