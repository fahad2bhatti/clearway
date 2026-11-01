import 'package:flutter/material.dart';

import '../../data/local_save.dart';
import 'onboarding_feedback.dart';
import 'onboarding_theme.dart';

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
      builder: (context, _) => Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: OnboardingTheme.background),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _LanguageToggle(save: save),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            OnboardingTheme.cardPurple,
                            OnboardingTheme.cardPurpleDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: OnboardingTheme.gold,
                          width: 3,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 8.0;
                          const barHeight = 10.0;

                          final iconSize =
                              (constraints.maxHeight - spacing - barHeight)
                                  .clamp(0.0, 120.0)
                                  .toDouble();

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_bus_rounded,
                                size: iconSize,
                                color: OnboardingTheme.gold.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                              const SizedBox(height: spacing),
                              Container(
                                height: barHeight,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'WELCOME TO',
                    style: TextStyle(
                      color: OnboardingTheme.teal,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Clearway',
                    style: TextStyle(
                      color: OnboardingTheme.cream,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the buses. Clear the road.\nBecome the boss of the yard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: OnboardingTheme.muted,
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      OnboardingFeedback.tap(save);
                      onContinue();
                    },
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: OnboardingTheme.primaryButton,
                      alignment: Alignment.center,
                      child: const Text(
                        "LET'S ROLL",
                        style: TextStyle(
                          color: OnboardingTheme.deepPurple,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? OnboardingTheme.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? OnboardingTheme.deepPurple : OnboardingTheme.muted,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
