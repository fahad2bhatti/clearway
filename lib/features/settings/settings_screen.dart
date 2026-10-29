import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_identity.dart';
import '../../core/clearway_strings.dart';
import '../../data/local_save.dart';
import '../../services/cloud_progress_sync.dart';

const _privacyUrl = 'https://fahad2bhatti.github.io/clearway/privacy-policy.html';
const _termsUrl = 'https://fahad2bhatti.github.io/clearway/terms.html';
const _playStoreUrl = 'https://play.google.com/store/apps/details?id=${AppIdentity.applicationId}';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.save,
    required this.cloud,
    required this.onBack,
  });

  final LocalSave save;
  final CloudProgressSync cloud;
  final VoidCallback onBack;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _busy = false;

  ClearwayStrings get strings => ClearwayStrings(widget.save.language);

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(strings.settings),
        ),
        body: ListView(
          children: [
            _heading(strings.settingsAccount),
            ListTile(
              leading: const Icon(Icons.account_circle_rounded),
              title: Text(widget.cloud.hasLinkedProvider ? strings.linkedAccount : strings.anonymousAccount),
              subtitle: Text(widget.cloud.accountEmail ?? widget.cloud.accountUid ?? ''),
            ),
            if (!widget.cloud.hasLinkedProvider)
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: Text(strings.linkAccount),
                onTap: () => _message(strings.accountActionUnavailable),
              ),
            if (widget.cloud.hasLinkedProvider)
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: Text(strings.logout),
                onTap: _confirmLogout,
              ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded),
              title: Text(strings.deleteAccount),
              onTap: _confirmDelete,
            ),
            _heading(strings.settings),
            _toggle(strings.sound, widget.save.sound, (value) => _update(() => widget.save.sound = value)),
            _toggle(strings.music, widget.save.music, (value) => _update(() => widget.save.music = value)),
            _toggle(strings.haptics, widget.save.haptics, (value) => _update(() => widget.save.haptics = value)),
            _toggle(strings.notifications, widget.save.notifications, (value) => _update(() => widget.save.notifications = value)),
            ListTile(
              title: Text(strings.languageLabel),
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'en', label: Text('EN')),
                  ButtonSegment(value: 'ur', label: Text('اردو')),
                ],
                selected: {widget.save.language},
                onSelectionChanged: (value) => _update(() => widget.save.language = value.first),
              ),
            ),
            _heading(''),
            ListTile(leading: const Icon(Icons.star_rate_rounded), title: Text(strings.rateUs), onTap: _rateUs),
            ListTile(leading: const Icon(Icons.feedback_rounded), title: Text(strings.sendFeedback), onTap: _sendFeedback),
            ListTile(leading: const Icon(Icons.privacy_tip_rounded), title: Text(strings.privacyPolicy), onTap: () => _open(_privacyUrl)),
            ListTile(leading: const Icon(Icons.gavel_rounded), title: Text(strings.terms), onTap: () => _open(_termsUrl)),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(strings.appVersion),
              trailing: Text(_version.isEmpty ? '…' : _version),
            ),
          ],
        ),
      );

  Widget _heading(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      );

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: onChanged,
      );

  Future<void> _update(VoidCallback update) async {
    setState(update);
    await widget.save.save();
  }

  Future<void> _confirmLogout() async {
    if (!await _confirm(strings.logoutConfirm)) return;
    try {
      await widget.cloud.signOut();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      _message(error.toString());
    }
  }

  Future<void> _confirmDelete() async {
    if (!await _confirm(strings.deleteAccountConfirm)) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final deleted = await widget.cloud.deleteAccount();
      if (!deleted) throw StateError(strings.accountDeleteFailed);
      await widget.save.reset();
      if (mounted) {
        _message(strings.accountDeleted);
        Navigator.pop(context);
      }
    } on FirebaseFunctionsException catch (error) {
      _message(error.message ?? strings.accountDeleteFailed);
    } catch (_) {
      _message(strings.accountDeleteFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String message) async => await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.confirm)),
          ],
        ),
      ) ??
      false;

  Future<void> _rateUs() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await _open(_playStoreUrl);
      }
    } catch (_) {
      _message(strings.rateUnavailable);
    }
  }

  Future<void> _sendFeedback() async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => _FeedbackDialog(strings: strings),
    );
    final value = text?.trim() ?? '';
    if (value.isEmpty) {
      if (text != null) _message(strings.feedbackEmpty);
      return;
    }
    try {
      await widget.cloud.sendFeedback(text: value, appVersion: _version);
      _message(strings.feedbackSent);
    } catch (_) {
      _message(strings.feedbackUnavailable);
    }
  }

  Future<void> _open(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      _message(strings.linkPrivacy);
    }
  }

  void _message(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog({required this.strings});

  final ClearwayStrings strings;

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

final class _FeedbackDialogState extends State<_FeedbackDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.strings.sendFeedback),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 2000,
      maxLines: 5,
      decoration: InputDecoration(hintText: widget.strings.feedbackPrompt),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(widget.strings.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: Text(widget.strings.confirm),
      ),
    ],
  );
}
