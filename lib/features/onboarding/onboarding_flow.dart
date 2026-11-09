import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/local_save.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';
import 'terms_screen.dart';
import 'username_screen.dart';
import 'tour_offer_screen.dart';
import 'tour_step_screen.dart';
import 'onboarding_theme.dart';

enum _Step {
  splash,
  welcome,
  terms,
  username,
  tourOffer,
  tour0,
  tour1,
  tour2,
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.save});

  final LocalSave save;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  _Step _step = _Step.splash;

  /// Username is kept here until tour finishes / is skipped.
  /// completeOnboarding() is only called at the very end so main.dart
  /// does not swap to Home mid-tour.
  String _pendingUsername = '';

  void _go(_Step next) => setState(() => _step = next);

  Future<void> _finishOnboarding() async {
    if (_pendingUsername.isEmpty) {
      _pendingUsername = widget.save.username;
    }
    final ok = await widget.save.completeOnboarding(_pendingUsername);
    if (!ok && mounted) {
      // Validation failed somehow — send user back to username.
      _go(_Step.username);
    }
    // On success, LocalSave notifies → main.dart rebuilds to Home.
  }

  static const _tourSteps = [
    TourStep(
      title: 'Tap a bus to send it out',
      body:
          'Pick any bus and tap it. If the road ahead is clear, it drives away.',
      icon: Icons.touch_app_rounded,
      accent: OnboardingTheme.gold,
    ),
    TourStep(
      title: 'Hold to see the path',
      body:
          'Press and hold a bus. A laser shows exactly where it will exit.',
      icon: Icons.my_location_rounded,
      accent: OnboardingTheme.hot,
    ),
    TourStep(
      title: 'Hints & daily rewards',
      body:
          'Stuck? Spend coins on a hint. Come back every day for free coins.',
      icon: Icons.lightbulb_rounded,
      accent: OnboardingTheme.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _Step.splash => SplashScreen(onFinished: () => _go(_Step.welcome)),
      _Step.welcome => WelcomeScreen(
          save: widget.save,
          onContinue: () => _go(_Step.terms),
        ),
      _Step.terms => TermsScreen(
          save: widget.save,
          onContinue: () => _go(_Step.username),
        ),
      _Step.username => UsernameScreen(
          save: widget.save,
          onFinished: (name) {
            _pendingUsername = name;
            _go(_Step.tourOffer);
          },
        ),
      _Step.tourOffer => TourOfferScreen(
          save: widget.save,
          onStartTour: () => _go(_Step.tour0),
          onSkip: () {
            unawaited(_finishOnboarding());
          },
        ),
      _Step.tour0 => TourStepScreen(
          save: widget.save,
          step: _tourSteps[0],
          index: 0,
          total: 3,
          onNext: () => _go(_Step.tour1),
          onSkip: () {
            unawaited(_finishOnboarding());
          },
        ),
      _Step.tour1 => TourStepScreen(
          save: widget.save,
          step: _tourSteps[1],
          index: 1,
          total: 3,
          onNext: () => _go(_Step.tour2),
          onSkip: () {
            unawaited(_finishOnboarding());
          },
        ),
      _Step.tour2 => TourStepScreen(
          save: widget.save,
          step: _tourSteps[2],
          index: 2,
          total: 3,
          onNext: () {
            unawaited(_finishOnboarding());
          },
          onSkip: () {
            unawaited(_finishOnboarding());
          },
        ),
    };
  }
}
