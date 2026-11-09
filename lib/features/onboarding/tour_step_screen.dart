import 'package:flutter/material.dart';

import '../../core/clearway_strings.dart';
import '../../data/local_save.dart';
import 'onboarding_feedback.dart';
import 'onboarding_theme.dart';
import 'onboarding_widgets.dart';

class TourStep {
  const TourStep({
    required this.title,
    required this.body,
    required this.accent,
  });

  final String title;
  final String body;

  /// Colour of the highlighted tile in this step's illustration.
  final Color accent;
}

class TourStepScreen extends StatelessWidget {
  const TourStepScreen({
    super.key,
    required this.save,
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final LocalSave save;
  final TourStep step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  ClearwayStrings get _s => ClearwayStrings(save.language);

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;
    final counter = display(22);
    final totalLabel = '$total'.padLeft(2, '0');

    return OnboardingPage(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${index + 1}'.padLeft(2, '0'),
                      style: counter,
                    ),
                    TextSpan(
                      text: ' / $totalLabel',
                      style: display(22, color: OnboardingTheme.muted),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onSkip,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: OnboardingTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: OnboardingTheme.line),
                  ),
                  child: Text(
                    _s.obSkip,
                    style: const TextStyle(
                      color: OnboardingTheme.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _heroCard()),
          const SizedBox(height: 24),
          Text(step.title, style: OnboardingTheme.display(40)),
          const SizedBox(height: 10),
          Text(
            step.body,
            style: const TextStyle(
              color: OnboardingTheme.muted,
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          OnboardingProgress(index: index, total: total),
          const SizedBox(height: 20),
          OnboardingButton(
            label: isLast ? _s.obStartPlaying : _s.obNext,
            onTap: () {
              OnboardingFeedback.tap(save);
              onNext();
            },
          ),
        ],
      ),
    );
  }

  TextStyle display(double size, {Color color = OnboardingTheme.cream}) =>
      OnboardingTheme.display(size, color: color);

  Widget _heroCard() {
    final onHero = step.accent.computeLuminance() > 0.5
        ? OnboardingTheme.bgTop
        : OnboardingTheme.onAccent;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: OnboardingTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OnboardingTheme.line),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            bottom: -34,
            child: Text(
              '${index + 1}',
              style: OnboardingTheme.display(
                190,
                color: step.accent.withValues(alpha: 0.1),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ArrowGridArt(
                step: index,
                tile: OnboardingTheme.line,
                glyph: OnboardingTheme.muted.withValues(alpha: 0.7),
                hero: step.accent,
                heroGlyph: onHero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
