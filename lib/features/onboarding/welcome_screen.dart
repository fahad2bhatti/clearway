import 'package:flutter/material.dart';

import '../../data/local_save.dart';
import 'onboarding_feedback.dart';
import 'onboarding_theme.dart';
import 'onboarding_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.save,
    required this.onContinue,
  });

  final LocalSave save;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    // Rebuild when language (or any save field) changes.
    return ListenableBuilder(
      listenable: save,
      builder: (context, _) => OnboardingPage(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _LanguageToggle(save: save),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: OnboardingTheme.accent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: ArrowGridArt(
                    tile: Color(0x24000000),
                    glyph: Color(0x66000000),
                    hero: OnboardingTheme.onAccent,
                    heroGlyph: OnboardingTheme.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const OnboardingKicker('Welcome to'),
            const SizedBox(height: 6),
            Text('Clearway', style: OnboardingTheme.display(72)),
            const SizedBox(height: 10),
            const Text(
              'Tap the buses. Clear the road.\nBecome the boss of the yard.',
              style: TextStyle(
                color: OnboardingTheme.muted,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            OnboardingButton(
              label: "Let's roll",
              onTap: () {
                OnboardingFeedback.tap(save);
                onContinue();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.save});

  final LocalSave save;

  @override
  Widget build(BuildContext context) {
    final isEn = save.language == 'en';
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: OnboardingTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OnboardingTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip('EN', isEn, () {
            if (!isEn) {
              save.language = 'en';
              save.save();
            }
          }),
          _chip('UR', !isEn, () {
            if (isEn) {
              save.language = 'ur';
              save.save();
            }
          }),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? OnboardingTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? OnboardingTheme.onAccent : OnboardingTheme.muted,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
