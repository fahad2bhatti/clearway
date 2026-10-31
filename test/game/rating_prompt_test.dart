import 'package:clearway/game/rating_prompt.dart';
import 'package:clearway/data/local_save.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('prompts only at the configured winning milestones', () {
    expect(
      shouldShowRatingPrompt(
        level: 10,
        won: true,
        daily: false,
        shownMilestones: {},
      ),
      isTrue,
    );
    expect(
      shouldShowRatingPrompt(
        level: 11,
        won: true,
        daily: false,
        shownMilestones: {},
      ),
      isFalse,
    );
  });

  test('does not prompt after losses or daily challenges', () {
    for (final daily in [false, true]) {
      expect(
        shouldShowRatingPrompt(
          level: 25,
          won: false,
          daily: daily,
          shownMilestones: {},
        ),
        isFalse,
      );
    }
    expect(
      shouldShowRatingPrompt(
        level: 25,
        won: true,
        daily: true,
        shownMilestones: {},
      ),
      isFalse,
    );
  });

  test('each milestone is prompted at most once and the history caps at three',
      () {
    final shown = {10, 25, 50};
    expect(
      shouldShowRatingPrompt(
        level: 10,
        won: true,
        daily: false,
        shownMilestones: shown,
      ),
      isFalse,
    );
    expect(
      shouldShowRatingPrompt(
        level: 50,
        won: true,
        daily: false,
        shownMilestones: {10, 25},
      ),
      isTrue,
    );
    expect(
      shouldShowRatingPrompt(
        level: 25,
        won: true,
        daily: false,
        shownMilestones: {10, 25, 50},
      ),
      isFalse,
    );
  });

  test('prompt history persists in the local save', () async {
    final save = LocalSave()..ratingPromptMilestonesShown.add(10);
    await save.save();

    final restored = LocalSave();
    await restored.load();

    expect(restored.ratingPromptMilestonesShown, {10});
    save.dispose();
    restored.dispose();
  });
}
