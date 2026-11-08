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
import '../../widgets/game_ui.dart';
import '../onboarding/onboarding_theme.dart';

const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=${AppIdentity.applicationId}';

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
    if (mounted) {
      setState(() => _version = '${info.version}+${info.buildNumber}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.save.language;
    return RedesignTheme(
      child: Scaffold(
        backgroundColor: OnboardingTheme.bgTop,
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: strings.settings, onBack: widget.onBack),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _profileCard(),
                    const SizedBox(height: 20),
                    SectionLabel(
                      title: strings.settingsPreferences,
                      language: language,
                    ),
                    _group([
                      _toggleRow(
                        Icons.volume_up_rounded,
                        OnboardingTheme.accent,
                        strings.sound,
                        widget.save.sound,
                        (value) => _update(() => widget.save.sound = value),
                      ),
                      _toggleRow(
                        Icons.music_note_rounded,
                        OnboardingTheme.hot,
                        strings.music,
                        widget.save.music,
                        (value) => _update(() => widget.save.music = value),
                      ),
                      _toggleRow(
                        Icons.vibration_rounded,
                        OnboardingTheme.teal,
                        strings.haptics,
                        widget.save.haptics,
                        (value) => _update(() => widget.save.haptics = value),
                      ),
                      _toggleRow(
                        Icons.notifications_rounded,
                        OnboardingTheme.coin,
                        strings.notifications,
                        widget.save.notifications,
                        _toggleNotifications,
                      ),
                      _row(
                        icon: Icons.language_rounded,
                        color: OnboardingTheme.accent,
                        label: strings.languageLabel,
                        trailing: LanguageSwitch(
                          value: widget.save.language,
                          onChanged: (value) =>
                              _update(() => widget.save.language = value),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    SectionLabel(
                      title: strings.settingsAbout,
                      language: language,
                    ),
                    _group([
                      _linkRow(
                        Icons.star_rounded,
                        OnboardingTheme.coin,
                        strings.rateUs,
                        _rateUs,
                      ),
                      _linkRow(
                        Icons.chat_bubble_rounded,
                        OnboardingTheme.teal,
                        strings.sendFeedback,
                        _sendFeedback,
                      ),
                      _linkRow(
                        Icons.privacy_tip_rounded,
                        OnboardingTheme.accent,
                        strings.privacyPolicy,
                        () => _open(LegalLinks.privacyUrl),
                      ),
                      _linkRow(
                        Icons.gavel_rounded,
                        OnboardingTheme.muted,
                        strings.terms,
                        () => _open(LegalLinks.termsUrl),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OnboardingTheme.hot,
                        side: const BorderSide(color: OnboardingTheme.hot),
                        minimumSize: const Size.fromHeight(50),
                        shape: const StadiumBorder(),
                      ),
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_forever_rounded),
                      label: Text(
                        strings.deleteAccount,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (_version.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${strings.appVersion} $_version',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: OnboardingTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard() {
    final name = widget.save.username.isEmpty
        ? AppIdentity.name
        : widget.save.username;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OnboardingTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OnboardingTheme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: OnboardingTheme.accent,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: OnboardingTheme.onAccent,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: OnboardingTheme.display(24),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: OnboardingTheme.teal.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    strings.anonymousAccount,
                    style: const TextStyle(
                      color: OnboardingTheme.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(List<Widget> rows) => Material(
    color: OnboardingTheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: OnboardingTheme.line),
    ),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: OnboardingTheme.line,
            ),
          rows[i],
        ],
      ],
    ),
  );

  Widget _row({
    required IconData icon,
    required Color color,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: OnboardingTheme.cream,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    ),
  );

  Widget _toggleRow(
    IconData icon,
    Color color,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Semantics(
    toggled: value,
    child: _row(
      icon: icon,
      color: color,
      label: label,
      trailing: GameToggle(value: value),
      onTap: () => onChanged(!value),
    ),
  );

  Widget _linkRow(
    IconData icon,
    Color color,
    String label,
    VoidCallback onTap,
  ) => _row(
    icon: icon,
    color: color,
    label: label,
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: OnboardingTheme.muted,
    ),
    onTap: onTap,
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
      builder: (context) => RedesignTheme(child: AlertDialog(
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
      )),
    );
    if (confirmed != true || !mounted) return;
    final granted = await NotificationService.instance.requestPermission();
    await _update(() => widget.save.notifications = granted);
    if (!granted) await NotificationService.instance.disable();
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
        widget.onBack();
      }
    } catch (_) {
      _message(strings.accountDeleteFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => RedesignTheme(child: AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.confirm),
            ),
          ],
        )),
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
        builder: (context) => RedesignTheme(child: AlertDialog(
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
        )),
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
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) _message(strings.linkOpenError);
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
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
  Widget build(BuildContext context) => RedesignTheme(child: AlertDialog(
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
  ));
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
  Widget build(BuildContext context) => RedesignTheme(child: AlertDialog(
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
  ));
}
