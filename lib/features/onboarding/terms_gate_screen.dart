import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_identity.dart';
import '../../app/legal_links.dart';
import '../../core/clearway_strings.dart';
import '../../data/local_save.dart';

/// Shown until the player accepts the current Terms and Privacy Policy.
/// Accepting saves the version, which makes the app swap to the game.
class TermsGateScreen extends StatefulWidget {
  const TermsGateScreen({super.key, required this.save});

  final LocalSave save;

  @override
  State<TermsGateScreen> createState() => _TermsGateScreenState();
}

class _TermsGateScreenState extends State<TermsGateScreen> {
  var _checked = false;
  var _busy = false;

  ClearwayStrings get strings => ClearwayStrings(widget.save.language);

  Future<void> _open(String url) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.linkOpenError)));
    }
  }

  Future<void> _accept() async {
    if (!_checked || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.save.acceptTerms();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Image.asset(
                        'assets/images/clearway_mark.png',
                        height: 96,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppIdentity.name,
                        textAlign: TextAlign.center,
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        strings.termsGateTitle,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(strings.termsGateBody, style: text.bodyLarge),
                      const SizedBox(height: 16),
                      _link(
                        Icons.gavel_rounded,
                        strings.terms,
                        LegalLinks.termsUrl,
                      ),
                      _link(
                        Icons.privacy_tip_rounded,
                        strings.privacyPolicy,
                        LegalLinks.privacyUrl,
                      ),
                    ],
                  ),
                ),
              ),
              CheckboxListTile(
                value: _checked,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _checked = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(strings.termsGateCheckbox),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _checked && !_busy ? _accept : null,
                child: Text(strings.termsGateContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _link(IconData icon, String label, String url) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label),
    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
    onTap: () => _open(url),
  );
}
