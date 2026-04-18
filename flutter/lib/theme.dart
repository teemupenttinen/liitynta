import 'package:flutter/material.dart';

/// Design tokens extracted from design.pen (mirrors app/src/lib/theme.ts).
class AppColors {
  static const primary = Color(0xFF0047B3);
  static const primaryDark = Color(0xFF003080);
  static const primaryLight = Color(0xFFE8F0FE);

  static const bg = Color(0xFFF5F7FA);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgWhite = Color(0xFFFFFFFF);

  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF0F0F0);

  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const textWhite = Color(0xFFFFFFFF);

  // Transit modes
  static const driveBlue = Color(0xFF3B82F6);
  static const metroOrange = Color(0xFFFF6319);
  static const busBlue = Color(0xFF0078D4);
  static const tramGreen = Color(0xFF00A651);
  static const railPurple = Color(0xFF8B5CF6);
  static const ferryCyan = Color(0xFF06B6D4);
  static const walkGray = Color(0xFF9CA3AF);

  // Availability
  static const availHigh = Color(0xFF10B981);
  static const availMedium = Color(0xFFF59E0B);
  static const availLow = Color(0xFFEF4444);
  static const availNeutral = Color(0xFFB0BEC5);

  static const destRed = Color(0xFFE85A4F);

  static const favBg = Color(0xFFFEF2F2);
  static const favBgActive = Color(0xFFFEE2E2);
}

class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.light,
    ),
    fontFamily: 'DMSans',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textWhite,
    ),
  );
}
