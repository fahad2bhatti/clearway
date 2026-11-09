import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_identity.dart';
import 'onboarding_theme.dart';
import 'onboarding_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _fade;
  late final Animation<double> _bar;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
      ),
    );

    _bar = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.95, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/clearway_mark.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppIdentity.name.toUpperCase(),
                        style: OnboardingTheme.display(60, letterSpacing: 6),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppIdentity.tagline.toUpperCase(),
                        style: OnboardingTheme.label.copyWith(
                          fontSize: 12,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 160,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _bar.value,
                        minHeight: 3,
                        backgroundColor: OnboardingTheme.line,
                        color: OnboardingTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'LOADING THE YARD...',
                      style: OnboardingTheme.label,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
