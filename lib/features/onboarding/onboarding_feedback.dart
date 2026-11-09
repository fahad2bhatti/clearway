import 'package:flutter/services.dart';

import '../../data/local_save.dart';

/// Lightweight feedback for onboarding buttons.
/// Very light ticks, never blocks UI, and respects the Haptics setting.
abstract final class OnboardingFeedback {
  static void tap(LocalSave save) {
    if (save.haptics) {
      HapticFeedback.selectionClick();
    }
  }

  static void success(LocalSave save) {
    if (save.haptics) {
      HapticFeedback.lightImpact();
    }
  }
}
