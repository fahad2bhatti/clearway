import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/clearway_strings.dart';
import '../../core/username_rules.dart';
import '../../data/local_save.dart';
import 'onboarding_feedback.dart';
import 'onboarding_theme.dart';
import 'onboarding_widgets.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({
    super.key,
    required this.save,
    required this.onFinished,
  });

  final LocalSave save;
  final ValueChanged<String> onFinished;

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  late final TextEditingController _controller;
  String? _error;
  bool _busy = false;

  ClearwayStrings get strings => ClearwayStrings(widget.save.language);

  static const _suggestions = ['RoadKing', 'TruckStar', 'ArrowAce', 'YardBoss'];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.save.username);
    _controller.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate() {
    final result = UsernameRules.validate(_controller.text);
    return switch (result) {
      null => null,
      UsernameError.tooShort => strings.usernameTooShort,
      UsernameError.tooLong => strings.usernameTooLong,
      UsernameError.invalidCharacters => strings.usernameInvalid,
    };
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final name = _controller.text.trim();
      if (UsernameRules.validate(name) != null) return;
      OnboardingFeedback.success(widget.save);
      if (mounted) widget.onFinished(name);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.length;
    final isValid = _validate() == null && length >= 3;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasError = _error != null;

    return OnboardingPage(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset > 0 ? 12 : 28),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OnboardingKicker('Last step'),
                  const SizedBox(height: 8),
                  Text(
                    'Pick your driver name',
                    style: OnboardingTheme.display(44),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _controller,
                    maxLength: UsernameRules.maxLength,
                    style: const TextStyle(
                      color: OnboardingTheme.cream,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    cursorColor: OnboardingTheme.accent,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (isValid && !_busy) _submit();
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                    ],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: OnboardingTheme.surface,
                      counterText: '',
                      hintText: 'DriverName',
                      hintStyle: const TextStyle(color: OnboardingTheme.muted),
                      suffixText: '$length/${UsernameRules.maxLength}',
                      suffixStyle: const TextStyle(
                        color: OnboardingTheme.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: _border(OnboardingTheme.line),
                      enabledBorder: _border(
                        hasError ? OnboardingTheme.hot : OnboardingTheme.line,
                      ),
                      focusedBorder: _border(
                        hasError ? OnboardingTheme.hot : OnboardingTheme.accent,
                        1.5,
                      ),
                    ),
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: OnboardingTheme.hot,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (isValid) ...[
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: OnboardingTheme.teal,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Nice! This name looks good.',
                          style: TextStyle(
                            color: OnboardingTheme.teal,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Text('SUGGESTIONS', style: OnboardingTheme.label),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions.map((name) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          _controller.text = name;
                          _controller.selection = TextSelection.collapsed(
                            offset: name.length,
                          );
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: OnboardingTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: OnboardingTheme.line),
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: OnboardingTheme.cream,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    strings.usernameHelp,
                    style: const TextStyle(
                      color: OnboardingTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          OnboardingButton(
            label: 'Start driving',
            busy: _busy,
            onTap: isValid && !_busy
                ? () {
                    OnboardingFeedback.tap(widget.save);
                    _submit();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
