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
  bool _busy = false;

  ClearwayStrings get strings => ClearwayStrings(widget.save.language);

  static const _suggestions = ['RoadKing', 'TruckStar', 'ArrowAce', 'YardBoss'];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.save.username);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _messageFor(UsernameError error) => switch (error) {
    UsernameError.tooShort => strings.usernameTooShort,
    UsernameError.tooLong => strings.usernameTooLong,
    UsernameError.invalidCharacters => strings.usernameInvalid,
  };

  void _submit() {
    final name = _controller.text.trim();
    if (_busy || UsernameRules.validate(name) != null) return;
    setState(() => _busy = true);
    OnboardingFeedback.success(widget.save);
    widget.onFinished(name);
  }

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.length;
    final rule = UsernameRules.validate(_controller.text);
    final isValid = rule == null;
    final hardError =
        length > 0 && rule != null && rule != UsernameError.tooShort;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
                  OnboardingKicker(strings.obUsernameKicker),
                  const SizedBox(height: 8),
                  Text(
                    strings.obUsernameTitle,
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
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9_]'),
                      ),
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
                        hardError ? OnboardingTheme.hot : OnboardingTheme.line,
                      ),
                      focusedBorder: _border(
                        hardError
                            ? OnboardingTheme.hot
                            : OnboardingTheme.accent,
                        1.5,
                      ),
                    ),
                  ),
                  if (length > 0 && rule != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _messageFor(rule),
                      style: TextStyle(
                        color: hardError
                            ? OnboardingTheme.hot
                            : OnboardingTheme.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (isValid) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: OnboardingTheme.teal,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          strings.obUsernameOk,
                          style: const TextStyle(
                            color: OnboardingTheme.teal,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  OnboardingLabel(strings.obSuggestions),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions.map((name) {
                      return Material(
                        color: OnboardingTheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: OnboardingTheme.line),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            OnboardingFeedback.tap(widget.save);
                            _controller.text = name;
                            _controller.selection = TextSelection.collapsed(
                              offset: name.length,
                            );
                            setState(() {});
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Center(
                                widthFactor: 1,
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: OnboardingTheme.cream,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
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
            label: strings.obStartDriving,
            busy: _busy,
            onTap: isValid && !_busy ? _submit : null,
          ),
        ],
      ),
    );
  }
}
