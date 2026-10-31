import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_identity.dart';
import '../../app/legal_links.dart';
import '../../core/clearway_strings.dart';
import '../../data/local_save.dart';
import '../../services/cloud_progress_sync.dart';
import '../../services/notification_service.dart';

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
            _toggle(strings.notifications, widget.save.notifications, _toggleNotifications),
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
            ListTile(leading: const Icon(Icons.privacy_tip_rounded), title: Text(strings.privacyPolicy), onTap: () => _open(LegalLinks.privacyUrl)),
            ListTile(leading: const Icon(Icons.gavel_rounded), title: Text(strings.terms), onTap: () => _open(LegalLinks.termsUrl)),
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

  Future<void> _toggleNotifications(bool enabled) async {
    if (!enabled) {
      await NotificationService.instance.disable();
      await _update(() => widget.save.notifications = false);
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.notificationPermissionTitle),
        content: Text(strings.notificationPermissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.notificationPermissionNotNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.notificationPermissionEnable),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final granted = await NotificationService.instance.requestPermission();
    await _update(() => widget.save.notifications = granted);
    if (!granted) await NotificationService.instance.disable();
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
    final rating = await showDialog<int>(
      context: context,
      builder: (context) => _RatingDialog(strings: strings),
    );
    if (rating == null || !mounted) return;
    if (rating >= 4) {
      final rateNow = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(strings.ratingTitle),
          content: Text(strings.ratingStorePrompt),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.ratingNotNow),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.ratingNow),
            ),
          ],
        ),
      );
      if (rateNow == true) await _requestStoreRating();
      return;
    }
    await _sendFeedback(rating: rating);
  }

  Future<void> _requestStoreRating() async {
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

  Future<void> _sendFeedback({int? rating}) async {
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
      final outcome = await widget.cloud.submitFeedback(
        text: rating == null ? value : '[rating: $rating/5] $value',
        appVersion: _version,
      );
      _message(switch (outcome) {
        FeedbackOutcome.sent => strings.feedbackSent,
        FeedbackOutcome.queued => strings.feedbackQueued,
        FeedbackOutcome.queueFull => strings.feedbackQueueFull,
      });
    } catch (_) {
      _message(strings.feedbackUnavailable);
    }
  }

  Future<void> _open(String url) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) _message(strings.linkOpenError);
  }

  void _message(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _RatingDialog extends StatefulWidget {
  const _RatingDialog({required this.strings});

  final ClearwayStrings strings;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

final class _RatingDialogState extends State<_RatingDialog> {
  var _rating = 0;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.strings.ratingTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.strings.ratingQuestion),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  tooltip: '${index + 1}',
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 34,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.strings.cancel),
          ),
          FilledButton(
            onPressed: _rating == 0 ? null : () => Navigator.pop(context, _rating),
            child: Text(widget.strings.confirm),
          ),
        ],
      );
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
