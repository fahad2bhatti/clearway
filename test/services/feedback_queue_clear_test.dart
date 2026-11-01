import 'package:clearway/services/feedback_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('clear removes every pending feedback item', () async {
    await FeedbackQueue.enqueue(text: 'a', appVersion: '1');
    await FeedbackQueue.enqueue(text: 'b', appVersion: '1');

    await FeedbackQueue.clear();

    expect(await FeedbackQueue.pending(), isEmpty);
  });
}
