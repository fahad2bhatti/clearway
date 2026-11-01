import 'package:flutter/services.dart';

import '../../data/local_save.dart';

/// Lightweight feedback for onboarding buttons.
/// Never blocks UI. Respects user settings.
abstract final class OnboardingFeedback {
  static void tap(LocalSave save) {
    if (save.haptics) {
      HapticFeedback.lightImpact();
    }
  }

  static void success(LocalSave save) {
    if (save.haptics) {
      HapticFeedback.mediumImpact();
    }
  }
}
