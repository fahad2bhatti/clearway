import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local_save.dart';
import 'onboarding_theme.dart';
import 'onboarding_widgets.dart';

enum AgeGateStatus { unknown, passed, blocked }

class AgeGateService {
  static const int minAge = 16;
  static const _key = 'age_gate_status';

  static Future<AgeGateStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_key)) {
      case 'passed':
        return AgeGateStatus.passed;
      case 'blocked':
        return AgeGateStatus.blocked;
      default:
        return AgeGateStatus.unknown;
    }
  }

  /// DOB save nahi hoti, sirf pass/blocked result save hota hai.
  static Future<AgeGateStatus> submit(DateTime dob) async {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    final status = age >= minAge ? AgeGateStatus.passed : AgeGateStatus.blocked;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      status == AgeGateStatus.passed ? 'passed' : 'blocked',
    );
    return status;
  }
}

/// Purane users (onboarding pehle complete) ke liye guard.
/// main.dart ke MaterialApp.builder mein lagta hai.
class AgeGuard extends StatefulWidget {
  const AgeGuard({
    super.key,
    required this.save,
    required this.active,
    required this.child,
  });

  final LocalSave save;
  final bool active;
  final Widget child;

  @override
  State<AgeGuard> createState() => _AgeGuardState();
}

class _AgeGuardState extends State<AgeGuard> {
  bool? _passed;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(covariant AgeGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _passed = null;
      _check();
    }
  }

  Future<void> _check() async {
    final s = await AgeGateService.getStatus();
    if (!mounted) return;
    setState(() => _passed = s == AgeGateStatus.passed);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || _passed == true) return widget.child;
    if (_passed == null) {
      return const ColoredBox(color: OnboardingTheme.bgTop);
    }
    return AgeGateStep(
      save: widget.save,
      onPassed: () => setState(() => _passed = true),
    );
  }
}

/// Onboarding ka step (terms ke baad).
class AgeGateStep extends StatefulWidget {
  const AgeGateStep({super.key, required this.save, required this.onPassed});

  final LocalSave save;
  final VoidCallback onPassed;

  @override
  State<AgeGateStep> createState() => _AgeGateStepState();
}

class _AgeGateStepState extends State<AgeGateStep> {
  AgeGateStatus? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AgeGateService.getStatus();
    if (!mounted) return;
    if (s == AgeGateStatus.passed) {
      widget.onPassed();
      return;
    }
    setState(() => _status = s);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      return const ColoredBox(color: OnboardingTheme.bgTop);
    }
    return _AgeScreen(
      save: widget.save,
      blocked: status == AgeGateStatus.blocked,
      onResult: (r) {
        if (r == AgeGateStatus.passed) {
          widget.onPassed();
        } else {
          setState(() => _status = r);
        }
      },
    );
  }
}

class _AgeScreen extends StatefulWidget {
  const _AgeScreen({
    required this.save,
    required this.blocked,
    required this.onResult,
  });

  final LocalSave save;
  final bool blocked;
  final ValueChanged<AgeGateStatus> onResult;

  @override
  State<_AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<_AgeScreen> {
  static const int _firstYear = 1930;
  late final List<int> _years = [
    for (var y = _firstYear; y <= DateTime.now().year; y++) y,
  ];
  late final FixedExtentScrollController _dayC = FixedExtentScrollController();
  late final FixedExtentScrollController _monC = FixedExtentScrollController();
  late final FixedExtentScrollController _yearC = FixedExtentScrollController(
    initialItem: 2000 - _firstYear,
  );

  int _d = 1;
  int _m = 1;
  int _y = 2000;
  bool _touched = false;
  bool _busy = false;

  bool get _ur => widget.save.language == 'ur';

  static const _monthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _monthsUr = [
    'جنوری',
    'فروری',
    'مارچ',
    'اپریل',
    'مئی',
    'جون',
    'جولائی',
    'اگست',
    'ستمبر',
    'اکتوبر',
    'نومبر',
    'دسمبر',
  ];

  @override
  void dispose() {
    _dayC.dispose();
    _monC.dispose();
    _yearC.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_touched || _busy) return;
    setState(() => _busy = true);
    final maxDay = DateTime(_y, _m + 1, 0).day;
    final dob = DateTime(_y, _m, _d > maxDay ? maxDay : _d);
    final status = await AgeGateService.submit(dob);
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onResult(status);
  }

  @override
  Widget build(BuildContext context) {
    final ur = _ur;
    return OnboardingPage(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: widget.blocked ? _blockedView(ur) : _formView(ur),
    );
  }

  Widget _blockedView(bool ur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingKicker(ur ? 'معذرت' : 'SORRY'),
        const SizedBox(height: 8),
        Text(
          ur ? 'دستیاب نہیں' : 'Not available',
          style: OnboardingTheme.display(44),
        ),
        const SizedBox(height: 16),
        Text(
          ur
              ? 'معذرت، یہ گیم آپ کی عمر کے لیے دستیاب نہیں ہے۔'
              : 'Sorry, this game is not available for your age.',
          style: const TextStyle(
            color: OnboardingTheme.muted,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _formView(bool ur) {
    final months = ur ? _monthsUr : _monthsEn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingKicker(ur ? 'ایک آسان قدم' : 'ONE QUICK STEP'),
        const SizedBox(height: 8),
        Text(
          ur ? 'تاریخِ پیدائش' : 'Your birthday',
          style: OnboardingTheme.display(44),
        ),
        const SizedBox(height: 12),
        Text(
          ur
              ? 'جاری رکھنے کے لیے اپنی تاریخِ پیدائش درج کریں۔'
              : 'Enter your date of birth to continue.',
          style: const TextStyle(
            color: OnboardingTheme.muted,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        Expanded(
          child: Center(
            child: SizedBox(
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: OnboardingTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OnboardingTheme.line),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Wheel(
                          controller: _dayC,
                          labels: [for (var i = 1; i <= 31; i++) '$i'],
                          onChanged: (i) => setState(() {
                            _d = i + 1;
                            _touched = true;
                          }),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _Wheel(
                          controller: _monC,
                          labels: months,
                          onChanged: (i) => setState(() {
                            _m = i + 1;
                            _touched = true;
                          }),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _Wheel(
                          controller: _yearC,
                          labels: [for (final y in _years) '$y'],
                          onChanged: (i) => setState(() {
                            _y = _years[i];
                            _touched = true;
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Text(
          ur
              ? 'صرف اہلیت چیک کرنے کے لیے۔ محفوظ نہیں کی جاتی۔'
              : 'Only used to check eligibility. Not stored.',
          style: const TextStyle(color: OnboardingTheme.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        OnboardingButton(
          label: ur ? 'جاری رکھیں' : 'Continue',
          onTap: _touched && !_busy ? _continue : null,
        ),
      ],
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.labels,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 46,
      diameterRatio: 1.7,
      perspective: 0.004,
      overAndUnderCenterOpacity: 0.35,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildListDelegate(
        children: [
          for (final l in labels)
            Center(
              child: Text(
                l,
                style: const TextStyle(
                  color: OnboardingTheme.cream,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
