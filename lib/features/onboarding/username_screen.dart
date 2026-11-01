import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/clearway_strings.dart';
import '../../core/username_rules.dart';
import '../../data/local_save.dart';
import 'onboarding_feedback.dart';
import 'onboarding_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.length;
    final isValid = _validate() == null && length >= 3;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: OnboardingTheme.background),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset > 0 ? 12 : 32),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      children: [
                        Text(
                          'STEP 1 OF 1',
                          style: TextStyle(
                            color: OnboardingTheme.teal,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pick your driver name',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: OnboardingTheme.cream,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4B3AB5), Color(0xFF241A4A)],
                            ),
                            border: Border.all(
                              color: OnboardingTheme.gold,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: OnboardingTheme.gold
                                    .withValues(alpha: 0.35),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_filled_rounded,
                            size: 44,
                            color: OnboardingTheme.gold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF33256B),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: OnboardingTheme.gold,
                              width: 2.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  maxLength: UsernameRules.maxLength,
                                  style: const TextStyle(
                                    color: OnboardingTheme.cream,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  cursorColor: OnboardingTheme.gold,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) {
                                    if (isValid && !_busy) _submit();
                                  },
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9_]'),
                                    ),
                                  ],
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                    hintText: 'DriverName',
                                    hintStyle: TextStyle(
                                      color: OnboardingTheme.muted,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '$length/${UsernameRules.maxLength}',
                                style: TextStyle(
                                  color: OnboardingTheme.muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontSize: 13,
                            ),
                          ),
                        ] else if (isValid) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: OnboardingTheme.teal,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
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
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Suggestions',
                            style: TextStyle(
                              color: OnboardingTheme.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _suggestions.map((name) {
                            return GestureDetector(
                              onTap: () {
                                _controller.text = name;
                                _controller.selection =
                                    TextSelection.collapsed(
                                  offset: name.length,
                                );
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: OnboardingTheme.gold
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: OnboardingTheme.gold,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: OnboardingTheme.gold,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          strings.usernameHelp,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: OnboardingTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: isValid && !_busy
                      ? () {
                          OnboardingFeedback.tap(widget.save);
                          _submit();
                        }
                      : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: isValid && !_busy ? 1.0 : 0.45,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: OnboardingTheme.primaryButton,
                      alignment: Alignment.center,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: OnboardingTheme.deepPurple,
                              ),
                            )
                          : const Text(
                              'START DRIVING',
                              style: TextStyle(
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
}
