import 'package:flutter/material.dart';

import '../../core/clearway_strings.dart';
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

  ClearwayStrings get _s => ClearwayStrings(save.language);

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingKicker(_s.obTourKicker),
          const SizedBox(height: 8),
          Text(_s.obTourOfferTitle, style: OnboardingTheme.display(48)),
          const SizedBox(height: 12),
          Text(
            _s.obTourOfferBody,
            style: const TextStyle(
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
                  _row(1, _s.obOffer1Title, _s.obOffer1Body),
                  _row(2, _s.obOffer2Title, _s.obOffer2Body),
                  _row(3, _s.obOffer3Title, _s.obOffer3Body),
                  _row(4, _s.obOffer4Title, _s.obOffer4Body),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OnboardingButton(
            label: _s.obShowAround,
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
              child: Text(
                _s.obSkipTour,
                style: const TextStyle(
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
