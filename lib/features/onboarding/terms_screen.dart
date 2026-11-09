import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/legal_links.dart';
import '../../core/clearway_strings.dart';
import '../../data/local_save.dart';
import 'onboarding_feedback.dart';
import 'onboarding_theme.dart';
import 'onboarding_widgets.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key, required this.save, required this.onContinue});

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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.linkOpenError)));
      }
    }
  }

  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    OnboardingFeedback.tap(widget.save);
    try {
      await widget.save.acceptTerms();
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
    if (mounted) widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingKicker(strings.obTermsKicker),
          const SizedBox(height: 8),
          Text(strings.obTermsTitle, style: OnboardingTheme.display(44)),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rule(1, strings.obRule1Title, strings.obRule1Body),
                  _rule(2, strings.obRule2Title, strings.obRule2Body),
                  _rule(3, strings.obRule3Title, strings.obRule3Body),
                  _rule(4, strings.obRule4Title, strings.obRule4Body),
                  _rule(5, strings.obRule5Title, strings.obRule5Body),
                  const SizedBox(height: 8),
                  Wrap(
                    children: [
                      TextButton(
                        onPressed: () => _open(LegalLinks.termsUrl),
                        child: Text(
                          strings.obReadTerms,
                          style: const TextStyle(color: OnboardingTheme.accent),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _open(LegalLinks.privacyUrl),
                        child: Text(
                          strings.privacyPolicy,
                          style: const TextStyle(color: OnboardingTheme.accent),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            checked: _agreed,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                OnboardingFeedback.tap(widget.save);
                setState(() => _agreed = !_agreed);
              },
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _agreed
                          ? OnboardingTheme.accent
                          : OnboardingTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _agreed
                            ? OnboardingTheme.accent
                            : OnboardingTheme.line,
                        width: 1.5,
                      ),
                    ),
                    child: _agreed
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: OnboardingTheme.onAccent,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.termsGateCheckbox,
                      style: const TextStyle(
                        color: OnboardingTheme.cream,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          OnboardingButton(
            label: strings.termsGateContinue,
            onTap: _agreed && !_accepting ? _accept : null,
          ),
        ],
      ),
    );
  }

  Widget _rule(int number, String title, String body) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
              style: OnboardingTheme.display(22, color: OnboardingTheme.accent),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
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
