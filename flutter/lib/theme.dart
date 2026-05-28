import 'package:flutter/material.dart';

/// Design tokens extracted from design.pen (mirrors app/src/lib/theme.ts).
class AppColors {
  static const primary = Color(0xFF0047B3);
  static const primaryDark = Color(0xFF003080);
  static const primaryLight = Color(0xFFE8F0FE);

  static const bg = Color(0xFFF5F7FA);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgWhite = Color(0xFFFFFFFF);
  static const surfaceTinted = Color(0xFFF5F7FA);

  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF0F0F0);

  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  // Darkened from #9CA3AF (2.65:1) to pass WCAG AA on bg (#F5F7FA) and bgWhite.
  // Differentiate from textSecondary via weight/size, not color.
  static const textMuted = Color(0xFF6B7280);
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
  static const double xs = 4;
  static const double pill = 7;
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

class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 1),
      blurRadius: 4,
    ),
  ];
  static const panel = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];
  static const input = [
    BoxShadow(
      color: Color(0x12000000),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];
  static const popover = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
  static const sheet = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, -3),
      blurRadius: 8,
    ),
  ];
  static const pin = [
    BoxShadow(
      color: Color(0x2E000000),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];
  static const pill = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 1),
      blurRadius: 4,
    ),
  ];
}

/// Minimum hit-area size for tappable controls (iOS HIG: 44pt).
const double kMinTouchTarget = 44;

/// Type scale. Apply role-based styles, then `.copyWith(color: ...)` at the
/// use site. Sizes are floor-tested at 11pt (single-char glyphs like the
/// route-detail "P" marker are the only legitimate exception).
class AppTextStyles {
  // 11pt — captions & tertiary labels
  static const captionStrong = TextStyle(fontSize: 11, fontWeight: FontWeight.w700);
  static const caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
  static const captionLight = TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
  /// Small-caps style label paired with a primary number above
  /// ("vapaana" under "22").
  static const availabilityLabel = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3);

  // 12pt — pill / chip labels, chevron captions
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
  static const labelLight = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

  // 13pt — body small
  static const bodySmallEmphasis = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
  static const bodySmall = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
  /// 13pt paragraph with comfortable line-height for prose.
  static const paragraph = TextStyle(fontSize: 13, height: 1.45);

  // 14pt — body
  static const bodyEmphasis = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static const bodyRegular = TextStyle(fontSize: 14);

  // 15pt — list item titles
  static const itemPrice = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
  static const itemTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const itemBody = TextStyle(fontSize: 15, fontWeight: FontWeight.w500);

  // 16pt — section title
  static const sectionTitleStrong = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
  static const sectionTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  // 17pt — screen / app-bar title
  static const screenTitle = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);

  // Display
  static const subhero = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);
  /// Big number inside a fixed-width column (availability count "22").
  static const heroNumber = TextStyle(fontSize: 22, fontWeight: FontWeight.w800);
  /// Big number on a full-width row (route detail "24 min").
  static const heroNumberLarge = TextStyle(fontSize: 24, fontWeight: FontWeight.w700);
  /// Top-of-page title ("Suosikit", "Asetukset").
  static const pageTitle = TextStyle(fontSize: 28, fontWeight: FontWeight.w700);
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
