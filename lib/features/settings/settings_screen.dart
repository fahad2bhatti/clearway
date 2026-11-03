import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_identity.dart';
import '../../app/legal_links.dart';
import '../../app/theme_pack.dart';
import '../../core/clearway_strings.dart';
import '../../data/local_save.dart';
import '../../services/cloud_progress_sync.dart';
import '../../services/notification_service.dart';
import '../../widgets/game_ui.dart';

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
    const pack = ThemePack.arrowNight;
    final ur = widget.save.language == 'ur';
    return Scaffold(
      body: GameBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      style: IconButton.styleFrom(
                        backgroundColor: pack.ivory.withValues(alpha: 0.1),
                        minimumSize: const Size(44, 44),
                      ),
                      icon: Icon(Icons.arrow_back_rounded, color: pack.ivory),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.settings,
                        style: TextStyle(
                          fontFamily: GameFonts.display,
                          fontSize: 30,
                          color: pack.ivory,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _profileCard(pack),
                    const SizedBox(height: 20),
                    _heading(pack, strings.settingsPreferences, ur),
                    _group(pack, [
                      _toggleRow(
                        pack,
                        Icons.volume_up_rounded,
                        pack.accent,
                        strings.sound,
                        widget.save.sound,
                        (value) => _update(() => widget.save.sound = value),
                      ),
                      _toggleRow(
                        pack,
                        Icons.music_note_rounded,
                        pack.floralMagenta,
                        strings.music,
                        widget.save.music,
                        (value) => _update(() => widget.save.music = value),
                      ),
                      _toggleRow(
                        pack,
                        Icons.vibration_rounded,
                        pack.turquoise,
                        strings.haptics,
                        widget.save.haptics,
                        (value) => _update(() => widget.save.haptics = value),
                      ),
                      _toggleRow(
                        pack,
                        Icons.notifications_rounded,
                        pack.coral,
                        strings.notifications,
                        widget.save.notifications,
                        _toggleNotifications,
                      ),
                      _row(
                        pack,
                        icon: Icons.language_rounded,
                        color: pack.accent,
                        label: strings.languageLabel,
                        trailing: LanguageSwitch(
                          value: widget.save.language,
                          onChanged: (value) =>
                              _update(() => widget.save.language = value),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _heading(pack, strings.settingsAbout, ur),
                    _group(pack, [
                      _linkRow(
                        pack,
                        Icons.star_rounded,
                        pack.accent,
                        strings.rateUs,
                        _rateUs,
                      ),
                      _linkRow(
                        pack,
                        Icons.chat_bubble_rounded,
                        pack.turquoise,
                        strings.sendFeedback,
                        _sendFeedback,
                      ),
                      _linkRow(
                        pack,
                        Icons.privacy_tip_rounded,
                        pack.floralMagenta,
                        strings.privacyPolicy,
                        () => _open(LegalLinks.privacyUrl),
                      ),
                      _linkRow(
                        pack,
                        Icons.gavel_rounded,
                        pack.textMuted,
                        strings.terms,
                        () => _open(LegalLinks.termsUrl),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: pack.coral,
                        side: BorderSide(color: pack.coral, width: 2),
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
                        style: TextStyle(color: pack.textMuted, fontSize: 12),
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

  Widget _profileCard(ThemePack pack) {
    final name = widget.save.username.isEmpty
        ? AppIdentity.name
        : widget.save.username;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: pack.accent, width: 3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pack.panelActive, pack.panel],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pack.asphalt,
              border: Border.all(color: pack.accent, width: 3),
            ),
            child: BusIllustration(
              body: pack.floralMagenta,
              stripe: pack.coral,
              width: 44,
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
                  style: TextStyle(
                    fontFamily: GameFonts.display,
                    fontSize: 22,
                    color: pack.ivory,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: pack.turquoise.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    strings.anonymousAccount,
                    style: TextStyle(
                      color: pack.turquoise,
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

  Widget _heading(ThemePack pack, String title, bool ur) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 6, right: 6),
    child: Text(
      ur ? title : title.toUpperCase(),
      style: TextStyle(
        color: pack.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: letterSpacingFor(widget.save.language, 2),
      ),
    ),
  );

  Widget _group(ThemePack pack, List<Widget> rows) => Material(
    color: pack.panel,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: pack.panelActive, width: 2),
    ),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: pack.ivory.withValues(alpha: 0.08),
            ),
          rows[i],
        ],
      ],
    ),
  );

  Widget _row(
    ThemePack pack, {
    required IconData icon,
    required Color color,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: pack.ivory,
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
    ThemePack pack,
    IconData icon,
    Color color,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Semantics(
    toggled: value,
    child: _row(
      pack,
      icon: icon,
      color: color,
      label: label,
      trailing: GameToggle(value: value),
      onTap: () => onChanged(!value),
    ),
  );

  Widget _linkRow(
    ThemePack pack,
    IconData icon,
    Color color,
    String label,
    VoidCallback onTap,
  ) => _row(
    pack,
    icon: icon,
    color: color,
    label: label,
    trailing: Icon(Icons.chevron_right_rounded, color: pack.textMuted),
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
        builder: (context) => AlertDialog(
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
