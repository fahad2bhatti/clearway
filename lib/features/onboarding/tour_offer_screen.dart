import 'package:flutter/material.dart';

import '../../data/local_save.dart';
import 'onboarding_feedback.dart';
import 'onboarding_theme.dart';

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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: OnboardingTheme.background),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Icon(
                  Icons.directions_bus_rounded,
                  size: 72,
                  color: OnboardingTheme.gold.withValues(alpha: 0.95),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Want a quick tour?',
                  style: TextStyle(
                    color: OnboardingTheme.cream,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '30 seconds. Learn everything before\nyour first level.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: OnboardingTheme.muted,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                _learnCard(
                  icon: Icons.touch_app_rounded,
                  iconBg: OnboardingTheme.gold.withValues(alpha: 0.2),
                  iconColor: OnboardingTheme.gold,
                  title: 'Tap to clear',
                  body: 'Send buses out of the yard',
                ),
                const SizedBox(height: 10),
                _learnCard(
                  icon: Icons.my_location_rounded,
                  iconBg: const Color(0xFFF0455A).withValues(alpha: 0.2),
                  iconColor: const Color(0xFFF0455A),
                  title: 'Hold to aim',
                  body: 'A laser shows the exit path',
                ),
                const SizedBox(height: 10),
                _learnCard(
                  icon: Icons.lightbulb_rounded,
                  iconBg: OnboardingTheme.teal.withValues(alpha: 0.2),
                  iconColor: OnboardingTheme.teal,
                  title: 'Hints & coins',
                  body: 'Stuck? Spend coins on a hint',
                ),
                const SizedBox(height: 10),
                _learnCard(
                  icon: Icons.calendar_today_rounded,
                  iconBg: const Color(0xFFFF6FB1).withValues(alpha: 0.2),
                  iconColor: const Color(0xFFFF6FB1),
                  title: 'Daily Rush',
                  body: '100 buses, new every day',
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    OnboardingFeedback.tap(save);
                    onStartTour();
                  },
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    decoration: OnboardingTheme.primaryButton,
                    alignment: Alignment.center,
                    child: const Text(
                      'SHOW ME AROUND',
                      style: TextStyle(
                        color: OnboardingTheme.deepPurple,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onSkip,
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Text(
                      'Skip, I will figure it out',
                      style: TextStyle(
                        color: OnboardingTheme.muted,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _learnCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF241A4A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF33256B), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: OnboardingTheme.cream,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  body,
                  style: TextStyle(
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
