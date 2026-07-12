
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary      = Color(0xFF6C63FF);
  static const Color primaryDark  = Color(0xFF4B44CC);
  static const Color accent       = Color(0xFF00D2FF);

  // Background
  static const Color bgDark       = Color(0xFF0F0F1A);
  static const Color bgCard       = Color(0xFF1A1A2E);
  static const Color bgElevated   = Color(0xFF242440);

  // Surface
  static const Color surface      = Color(0xFF1E1E3A);
  static const Color surfaceLight = Color(0xFF2A2A4A);

  // Text
  static const Color textPrimary  = Color(0xFFEEEEFF);
  static const Color textSecondary= Color(0xFF9999BB);
  static const Color textHint     = Color(0xFF5555AA);

  // Status
  static const Color success      = Color(0xFF00C896);
  static const Color warning      = Color(0xFFFFB347);
  static const Color error        = Color(0xFFFF6B6B);
  static const Color info         = Color(0xFF45B7D1);

  // FTMS Category Colors
  static const Color imageColor   = Color(0xFFFF6B6B);
  static const Color videoColor   = Color(0xFF4ECDC4);
  static const Color audioColor   = Color(0xFF45B7D1);
  static const Color documentColor= Color(0xFF96CEB4);
  static const Color codeColor    = Color(0xFFA29BFE);
  static const Color archiveColor = Color(0xFFFFEAA7);
  static const Color fontColor    = Color(0xFFFD79A8);
  static const Color otherColor   = Color(0xFFB2BEC3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00D2FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Category gradient helper
  static LinearGradient categoryGradient(Color color) => LinearGradient(
    colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
