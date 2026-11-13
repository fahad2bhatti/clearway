import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/local_save.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';
import 'terms_screen.dart';
import 'age_step.dart';
import 'username_screen.dart';
import 'tour_offer_screen.dart';
import 'tour_step_screen.dart';
import '../../core/clearway_strings.dart';
import 'onboarding_theme.dart';

enum _Step {
  splash,
  welcome,
  terms,
  age,
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

  // onboarding-fixes-a
  bool _finishing = false;

  /// Username is kept here until tour finishes / is skipped.
  /// completeOnboarding() is only called at the very end so main.dart
  /// does not swap to Home mid-tour.
  String _pendingUsername = '';

  void _go(_Step next) => setState(() => _step = next);

  Future<void> _finishOnboarding() async {
    if (_finishing) return;
    _finishing = true;
    if (_pendingUsername.isEmpty) {
      _pendingUsername = widget.save.username;
    }
    final ok = await widget.save.completeOnboarding(_pendingUsername);
    if (!ok) _finishing = false;
    if (!ok && mounted) {
      // Validation failed somehow — send user back to username.
      _go(_Step.username);
    }
    // On success, LocalSave notifies → main.dart rebuilds to Home.
  }

  List<TourStep> get _tourSteps {
    final s = ClearwayStrings(widget.save.language);
    return [
      TourStep(
        title: s.obTour1Title,
        body: s.obTour1Body,
        accent: OnboardingTheme.gold,
      ),
      TourStep(
        title: s.obTour2Title,
        body: s.obTour2Body,
        accent: OnboardingTheme.hot,
      ),
      TourStep(
        title: s.obTour3Title,
        body: s.obTour3Body,
        accent: OnboardingTheme.teal,
      ),
    ];
  }

  _Step? get _previous => switch (_step) {
    _Step.terms => _Step.welcome,
    _Step.age => _Step.terms,
    _Step.username => _Step.terms,
    _Step.tourOffer => _Step.username,
    _Step.tour0 => _Step.tourOffer,
    _Step.tour1 => _Step.tour0,
    _Step.tour2 => _Step.tour1,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _previous == null,
      onPopInvokedWithResult: (didPop, _) {
        final previous = _previous;
        if (!didPop && previous != null) _go(previous);
      },
      child: _buildStep(),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      _Step.splash => SplashScreen(
        save: widget.save,
        onFinished: () => _go(_Step.welcome),
      ),
      _Step.welcome => WelcomeScreen(
        save: widget.save,
        onContinue: () => _go(_Step.terms),
      ),
      _Step.terms => TermsScreen(
        save: widget.save,
        onContinue: () => _go(_Step.age),
      ),
      _Step.age => AgeGateStep(
        save: widget.save,
        onPassed: () => _go(_Step.username),
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
        total: _tourSteps.length,
        onNext: () => _go(_Step.tour1),
        onSkip: () {
          unawaited(_finishOnboarding());
        },
      ),
      _Step.tour1 => TourStepScreen(
        save: widget.save,
        step: _tourSteps[1],
        index: 1,
        total: _tourSteps.length,
        onNext: () => _go(_Step.tour2),
        onSkip: () {
          unawaited(_finishOnboarding());
        },
      ),
      _Step.tour2 => TourStepScreen(
        save: widget.save,
        step: _tourSteps[2],
        index: 2,
        total: _tourSteps.length,
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
