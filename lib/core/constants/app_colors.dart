import 'package:flutter/material.dart';

class AppColors {
  static const primaryPurple = Color(0xFF534AB7);
  static const primaryPink = Color(0xFFE8587A);

  static const background = Color(0xFFF0EFF8);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1F1F2E);
  static const textSecondary = Color(0xFF6E6E87);

  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
  static const border = Color(0xFFE6E4F2);

  static LinearGradient primaryGradient() => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [primaryPurple, primaryPink],
      );
}
