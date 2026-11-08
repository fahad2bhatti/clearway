import 'package:flutter/material.dart';

import '../app/theme_pack.dart';
import '../features/onboarding/onboarding_theme.dart';

/// Optional bundled fonts. Without them Flutter falls back to the system font.
abstract final class GameFonts {
  static const display = 'LilitaOne';
  static const body = 'Nunito';
}

/// Letter spacing breaks joined Urdu letters, so it only applies to English.
double letterSpacingFor(String language, double value) =>
    language == 'ur' ? 0 : value;

/// Dark theme for the redesigned full screens (Shop, Settings). It re-skins
/// the dialogs, snackbars and buttons they open so nothing falls back to the
/// old slate palette, whatever the app-wide light/dark setting is.
final _redesignTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: OnboardingTheme.bgTop,
  colorScheme: const ColorScheme.dark(
    primary: OnboardingTheme.accent,
    onPrimary: OnboardingTheme.onAccent,
    secondary: OnboardingTheme.teal,
    surface: OnboardingTheme.surface,
    onSurface: OnboardingTheme.cream,
    error: OnboardingTheme.hot,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: OnboardingTheme.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      side: BorderSide(color: OnboardingTheme.line),
    ),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: OnboardingTheme.line,
    contentTextStyle: TextStyle(color: OnboardingTheme.cream),
    actionTextColor: OnboardingTheme.accent,
  ),
);

class RedesignTheme extends StatelessWidget {
  const RedesignTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Theme(data: _redesignTheme, child: child);
}

/// Flat bordered back button + display title (+ optional trailing widget).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 20, 8),
    child: Row(
      children: [
        Tooltip(
          message: MaterialLocalizations.of(context).backButtonTooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: OnboardingTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OnboardingTheme.line),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: OnboardingTheme.cream,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OnboardingTheme.display(30),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Small muted uppercase label above a group of cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.title, required this.language});

  final String title;
  final String language;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 6, right: 6),
    child: Text(
      language == 'ur' ? title : title.toUpperCase(),
      style: OnboardingTheme.label.copyWith(
        letterSpacing: letterSpacingFor(language, 1.6),
      ),
    ),
  );
}

/// Round on/off switch with a sliding knob. Purely visual: the row around it
/// handles taps so the whole row is the touch target.
class GameToggle extends StatelessWidget {
  const GameToggle({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    width: 48,
    height: 28,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: value ? OnboardingTheme.accent : OnboardingTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: value ? OnboardingTheme.accent : OnboardingTheme.line,
      ),
    ),
    child: AnimatedAlign(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: value
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? OnboardingTheme.onAccent : OnboardingTheme.muted,
        ),
      ),
    ),
  );
}

/// EN / Urdu pill switch.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: OnboardingTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: OnboardingTheme.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _segment('en', 'EN'),
        const SizedBox(width: 2),
        _segment('ur', 'اردو'),
      ],
    ),
  );

  Widget _segment(String code, String label) {
    final selected = value == code;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selected ? null : () => onChanged(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? OnboardingTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: selected ? OnboardingTheme.onAccent : OnboardingTheme.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chunky game button with a 3D edge that presses down when tapped.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? foreground;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  var _down = false;

  bool get _enabled => widget.onPressed != null;

  void _setDown(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    const pack = ThemePack.arrowNight;
    final color = widget.color ?? pack.accent;
    final edge = Color.lerp(color, Colors.black, 0.32)!;
    final pressed = _down && _enabled;
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: Opacity(
        opacity: _enabled ? 1 : 0.45,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setDown(true) : null,
          onTapUp: _enabled ? (_) => _setDown(false) : null,
          onTapCancel: () => _setDown(false),
          onTap: widget.onPressed,
          child: SizedBox(
            height: 62,
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                margin: EdgeInsets.only(top: pressed ? 4 : 0),
                width: double.infinity,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(offset: Offset(0, pressed ? 1 : 5), color: edge),
                  ],
                ),
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: GameFonts.display,
                    fontSize: 20,
                    color: widget.foreground ?? pack.asphalt,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
