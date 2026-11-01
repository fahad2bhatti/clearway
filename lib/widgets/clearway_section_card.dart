import 'package:flutter/material.dart';

class ClearwaySectionCard extends StatelessWidget {
  const ClearwaySectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF25343A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3D5154) : const Color(0xFFE8E0D0),
        ),
      ),
      child: child,
    );
  }
}
