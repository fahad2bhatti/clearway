import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/legal_links.dart';
import '../../core/clearway_strings.dart';
import '../../data/local_save.dart';
import 'onboarding_feedback.dart';
import 'onboarding_theme.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({
    super.key,
    required this.save,
    required this.onContinue,
  });

  final LocalSave save;
  final VoidCallback onContinue;

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _agreed = false;

  ClearwayStrings get strings => ClearwayStrings(widget.save.language);

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.linkOpenError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: OnboardingTheme.background),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              children: [
                Text(
                  'ONE QUICK THING',
                  style: TextStyle(
                    color: OnboardingTheme.teal,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rules of the road',
                  style: TextStyle(
                    color: OnboardingTheme.cream,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF241A4A).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: OnboardingTheme.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _rule(1, 'Play fair',
                              'No cheats, bots or hacks. Be kind with your driver name.'),
                          _rule(2, 'Your data',
                              'Progress and coins are stored on your device and in your account.'),
                          _rule(3, 'Ads & shop',
                              'Rewarded ads are optional. Coins and hints have no real-money value.'),
                          _rule(4, 'You are in control',
                              'You can delete your account any time from Settings.'),
                          _rule(5, 'Updates',
                              'We may improve these rules. Big changes are shown in the app.'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () => _open(LegalLinks.termsUrl),
                                child: Text(
                                  'Read full Terms',
                                  style: TextStyle(color: OnboardingTheme.gold),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _open(LegalLinks.privacyUrl),
                                child: Text(
                                  'Privacy Policy',
                                  style: TextStyle(color: OnboardingTheme.gold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => setState(() => _agreed = !_agreed),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _agreed
                              ? OnboardingTheme.gold
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: OnboardingTheme.gold,
                            width: 2,
                          ),
                        ),
                        child: _agreed
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: OnboardingTheme.deepPurple,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strings.termsGateCheckbox,
                          style: TextStyle(
                            color: OnboardingTheme.cream,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _agreed
                      ? () async {
                          OnboardingFeedback.tap(widget.save);
                          await widget.save.acceptTerms();
                          widget.onContinue();
                        }
                      : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _agreed ? 1.0 : 0.45,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: OnboardingTheme.primaryButton,
                      alignment: Alignment.center,
                      child: Text(
                        strings.termsGateContinue,
                        style: const TextStyle(
                          color: OnboardingTheme.deepPurple,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
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

  Widget _rule(int number, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: OnboardingTheme.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: OnboardingTheme.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: OnboardingTheme.cream,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    color: OnboardingTheme.muted,
                    fontSize: 13,
                    height: 1.35,
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
