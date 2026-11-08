import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_identity.dart';
import 'onboarding_theme.dart';

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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: OnboardingTheme.background),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                children: [
                  const SizedBox(height: 24),
                  const _BuntingStrip(),
                  const Spacer(),
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          // Real app logo (same asset as TermsGate / home).
                          Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(34),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFF8A4B00),
                                  offset: Offset(0, 8),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(34),
                              child: Image.asset(
                                'assets/images/clearway_mark.png',
                                width: 128,
                                height: 128,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppIdentity.name.toUpperCase(),
                            style: OnboardingTheme.wordmark,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppIdentity.tagline,
                            style: OnboardingTheme.tagline,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 85),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _bar.value,
                            minHeight: 12,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            color: OnboardingTheme.gold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Loading the yard...',
                          style: TextStyle(
                            color: OnboardingTheme.muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BuntingStrip extends StatelessWidget {
  const _BuntingStrip();

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFFF6B6B),
      Color(0xFFFFB627),
      Color(0xFF4ECDC4),
      Color(0xFF45B7D1),
      Color(0xFF96CEB4),
      Color(0xFFFFEAA7),
    ];
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          13,
          (i) => Container(
            width: 18,
            height: 22,
            decoration: BoxDecoration(
              color: colors[i % colors.length],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
