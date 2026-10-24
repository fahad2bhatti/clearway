import 'package:clearway/services/progress_sync_debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

ProgressSyncSignature _sig(int level) => ProgressSyncSignature.fromProgress(
  level,
  {for (var i = 1; i < level; i++) i: 3},
);

const _delay = Duration(milliseconds: 20);

Future<void> _pause([int ms = 80]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  group('failed syncs are not forgotten', () {
    test('progress that failed offline is sent on the next flush', () async {
      var online = false;
      var calls = 0;
      ProgressSyncSignature? cloud;
      final debouncer = ProgressSyncDebouncer(
        delay: _delay,
        operation: (force) async {
          calls++;
          if (!online) return null;
          return cloud = _sig(5);
        },
      );
      addTearDown(debouncer.dispose);

      debouncer.request(_sig(5));
      await _pause();
      expect(calls, 1);

      online = true;
      await debouncer.flush();

      expect(cloud, _sig(5));
    });

    test(
      'progress that failed with an exception is sent on the next flush',
      () async {
        var healthy = false;
        ProgressSyncSignature? cloud;
        final debouncer = ProgressSyncDebouncer(
          delay: _delay,
          operation: (force) async {
            if (!healthy) throw StateError('unavailable');
            return cloud = _sig(3);
          },
        );
        addTearDown(debouncer.dispose);

        debouncer.request(_sig(3));
        await _pause();
        healthy = true;
        await debouncer.flush();

        expect(cloud, _sig(3));
      },
    );

    test(
      'the same progress requested again after a failure is retried',
      () async {
        var online = false;
        var calls = 0;
        final debouncer = ProgressSyncDebouncer(
          delay: _delay,
          operation: (force) async {
            calls++;
            return online ? _sig(4) : null;
          },
        );
        addTearDown(debouncer.dispose);

        debouncer.request(_sig(4));
        await _pause();
        online = true;
        debouncer.request(_sig(4));
        await _pause();

        expect(calls, 2);
      },
    );

    test('a failing cloud is not hammered by an endless retry loop', () async {
      var calls = 0;
      final debouncer = ProgressSyncDebouncer(
        delay: _delay,
        operation: (force) async {
          calls++;
          return null;
        },
      );
      addTearDown(debouncer.dispose);

      debouncer.request(_sig(2));
      await _pause(300);

      expect(calls, 1);
    });
  });

  group('500 players with a flaky cloud', () {
    test('coalesces writes and every player syncs once the cloud recovers', () async {
      const players = 500;
      const changesPerPlayer = 30;
      var cloudUp = false;
      var operations = 0;
      var requests = 0;
      final attempts = List<int>.filled(players, 0);
      final cloud = List<ProgressSyncSignature?>.filled(players, null);
      final latest = List<ProgressSyncSignature?>.filled(players, null);
      final debouncers = <ProgressSyncDebouncer>[];

      for (var player = 0; player < players; player++) {
        debouncers.add(
          ProgressSyncDebouncer(
            delay: const Duration(milliseconds: 30),
            operation: (force) async {
              operations++;
              await Future<void>.delayed(
                Duration(milliseconds: 1 + operations % 7),
              );
              // Every third call of a player fails even while the cloud is up.
              attempts[player]++;
              if (!cloudUp || attempts[player] % 3 == 0) return null;
              return cloud[player] = latest[player];
            },
          ),
        );
      }

      await Future.wait([
        for (var player = 0; player < players; player++)
          () async {
            for (var step = 1; step <= changesPerPlayer; step++) {
              latest[player] = _sig(step);
              requests++;
              debouncers[player].request(latest[player]!);
              await Future<void>.delayed(Duration(milliseconds: step % 6));
            }
          }(),
      ]);

      // Cloud outage: nothing may be lost. Then the cloud recovers and every
      // player's app is backgrounded (flush) a few times to ride out faults.
      await _pause(150);
      cloudUp = true;
      for (var round = 0; round < 6; round++) {
        await Future.wait([for (final d in debouncers) d.flush()]);
        await _pause(60);
      }

      final stale = [
        for (var i = 0; i < players; i++)
          if (cloud[i] != latest[i]) i,
      ];
      expect(stale.length, 0, reason: 'players not synced');
      expect(requests / operations, greaterThan(2), reason: 'no coalescing');

      for (final debouncer in debouncers) {
        debouncer.dispose();
      }
    });
  });
}
