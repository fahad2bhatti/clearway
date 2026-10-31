import 'package:clearway/services/feedback_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('queued feedback persists with its fields', () async {
    final item = await FeedbackQueue.enqueue(
      text: 'Nice game',
      appVersion: '1.0.0+3',
    );

    final stored = await FeedbackQueue.pending();
    expect(item, isNotNull);
    expect(stored, hasLength(1));
    expect(stored.single.id, item!.id);
    expect(stored.single.text, 'Nice game');
    expect(stored.single.appVersion, '1.0.0+3');
  });

  test('queue refuses new feedback once it is full', () async {
    final ids = <String>{};
    for (var i = 0; i < FeedbackQueue.maxItems; i++) {
      final item = await FeedbackQueue.enqueue(text: 'm$i', appVersion: '1');
      ids.add(item!.id);
    }

    expect(ids, hasLength(FeedbackQueue.maxItems));
    expect(await FeedbackQueue.enqueue(text: 'extra', appVersion: '1'), isNull);
    expect(await FeedbackQueue.pending(), hasLength(FeedbackQueue.maxItems));
  });

  test('remove only deletes the delivered item', () async {
    final first = await FeedbackQueue.enqueue(text: 'a', appVersion: '1');
    await FeedbackQueue.enqueue(text: 'b', appVersion: '1');

    await FeedbackQueue.remove(first!.id);

    final stored = await FeedbackQueue.pending();
    expect(stored.map((item) => item.text), ['b']);
  });

  test('concurrent enqueue and remove do not lose items', () async {
    final first = await FeedbackQueue.enqueue(text: 'a', appVersion: '1');

    await Future.wait([
      FeedbackQueue.remove(first!.id),
      FeedbackQueue.enqueue(text: 'b', appVersion: '1'),
    ]);

    final stored = await FeedbackQueue.pending();
    expect(stored.map((item) => item.text), ['b']);
  });

  test('corrupted stored data is ignored', () async {
    SharedPreferences.setMockInitialValues({
      FeedbackQueue.storageKey: 'not json',
    });

    expect(await FeedbackQueue.pending(), isEmpty);
  });
}
