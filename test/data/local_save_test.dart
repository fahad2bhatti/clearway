import 'package:clearway/data/local_save.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('persisting only the active board does not notify listeners', () async {
    final save = LocalSave();
    var notifications = 0;
    save.addListener(() => notifications++);

    save.activeBoard = {
      'level': 4,
      'remaining': ['truck-1'],
    };
    await save.save(notify: false);

    expect(notifications, 0);
    save.dispose();
  });

  test('level and star progress saves notify listeners', () async {
    final save = LocalSave();
    var notifications = 0;
    save.addListener(() => notifications++);

    save.level = 2;
    await save.save();
    expect(notifications, 1);

    save.stars[2] = 3;
    await save.save();
    expect(notifications, 2);
    save.dispose();
  });
}
