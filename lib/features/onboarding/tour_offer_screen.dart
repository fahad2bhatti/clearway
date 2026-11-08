import 'package:flutter/material.dart';

import '../../data/local_save.dart';
import 'onboarding_feedback.dart';
import 'onboarding_theme.dart';
import 'onboarding_widgets.dart';

class TourOfferScreen extends StatelessWidget {
  const TourOfferScreen({
    super.key,
    required this.save,
    required this.onStartTour,
    required this.onSkip,
  });

  final LocalSave save;
  final VoidCallback onStartTour;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingKicker('30 seconds'),
          const SizedBox(height: 8),
          Text('Want a quick tour?', style: OnboardingTheme.display(48)),
          const SizedBox(height: 12),
          const Text(
            '30 seconds. Learn everything before\nyour first level.',
            style: TextStyle(
              color: OnboardingTheme.muted,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _row(1, 'Tap to clear', 'Send buses out of the yard'),
                  _row(2, 'Hold to aim', 'A laser shows the exit path'),
                  _row(3, 'Hints & coins', 'Stuck? Spend coins on a hint'),
                  _row(4, 'Daily Rush', '100 buses, new every day'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OnboardingButton(
            label: 'Show me around',
            onTap: () {
              OnboardingFeedback.tap(save);
              onStartTour();
            },
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text(
                'Skip, I will figure it out',
                style: TextStyle(
                  color: OnboardingTheme.muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(int number, String title, String body) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: OnboardingTheme.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '$number'.padLeft(2, '0'),
              style: OnboardingTheme.display(26, color: OnboardingTheme.accent),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: OnboardingTheme.cream,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: OnboardingTheme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
