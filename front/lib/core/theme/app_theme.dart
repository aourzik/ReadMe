import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design tokens exactement calés sur le design ReadMe ──────────────────────

class AppColors {
  // ── Light theme ──
  static const bgLight         = Color(0xFFFDF6ED);
  static const surfaceLight    = Color(0xFFFFFAF2);
  static const surfaceAltLight = Color(0xFFF7ECDC);
  static const surfaceHiLight  = Color(0xFFFFFFFF);
  static const inkLight        = Color(0xFF1A1612);
  static const inkSoftLight    = Color(0xFF3A342C);
  static const inkMutedLight   = Color(0xFF6B5D50);
  static const inkDimLight     = Color(0xFFA09588);

  // ── Dark theme ──
  static const bgDark          = Color(0xFF0A0D12);
  static const surfaceDark     = Color(0xFF13171E);
  static const surfaceAltDark  = Color(0xFF1B202A);
  static const surfaceHiDark   = Color(0xFF222936);
  static const inkDark         = Color(0xFFF4EBDE);
  static const inkSoftDark     = Color(0xFFC8BDAA);
  static const inkMutedDark    = Color(0xFF8A8175);
  static const inkDimDark      = Color(0xFF5D5550);

  // ── Accent palettes ──
  // Rose poudré (default)
  static const accentRoseLight        = Color(0xFFF5D3D7);
  static const accentRoseStrongLight  = Color(0xFFD99AA3);
  static const accentRoseInkLight     = Color(0xFF6B2A36);
  static const accentRoseSubtleLight  = Color(0xFFFBE7E9);

  static const accentRoseDark         = Color(0xFFD4A5AB);
  static const accentRoseStrongDark   = Color(0xFFE8B5BB);
  static const accentRoseInkDark      = Color(0xFF1A0C10);
  static const accentRoseSubtleDark   = Color(0xFF3A2228);

  // Champagne
  static const accentChampagneLight   = Color(0xFFE9D4A8);
  static const accentChampagneStrongL = Color(0xFFC9A87A);
  static const accentChampagneInkL    = Color(0xFF5A3F1A);

  // Sauge
  static const accentSaugeLight       = Color(0xFFCFD9C5);
  static const accentSaugeStrongL     = Color(0xFF9AAF8A);
  static const accentSaugeInkL        = Color(0xFF3A4A30);

  // Status colors
  static const statusReading  = Color(0xFF9AAF8A);
  static const statusRead     = Color(0xFFD4A5AB);
  static const statusWishlist = Color(0xFFC9A87A);
  static const statusOverdue  = Color(0xFFC2557A);
}

// ─── Theme builder ────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: ColorScheme.light(
        primary:    AppColors.accentRoseStrongLight,
        onPrimary:  AppColors.accentRoseInkLight,
        secondary:  AppColors.accentRoseLight,
        onSecondary:AppColors.accentRoseInkLight,
        surface:    AppColors.surfaceLight,
        onSurface:  AppColors.inkLight,
        background: AppColors.bgLight,
        onBackground:AppColors.inkLight,
      ),
    );
    return base.copyWith(textTheme: _textTheme(Brightness.light));
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: ColorScheme.dark(
        primary:    AppColors.accentRoseDark,
        onPrimary:  AppColors.accentRoseInkDark,
        secondary:  AppColors.accentRoseSubtleDark,
        onSecondary:AppColors.inkDark,
        surface:    AppColors.surfaceDark,
        onSurface:  AppColors.inkDark,
        background: AppColors.bgDark,
        onBackground:AppColors.inkDark,
      ),
    );
    return base.copyWith(textTheme: _textTheme(Brightness.dark));
  }

  static TextTheme _textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final inkColor = isDark ? AppColors.inkDark : AppColors.inkLight;
    final manrope = GoogleFonts.manropeTextTheme().apply(
      bodyColor: inkColor,
      displayColor: inkColor,
    );
    return manrope;
  }
}

// ─── Typography helpers ───────────────────────────────────────────────────────

class AppText {
  // Cormorant Garamond — titres display
  static TextStyle display({
    double size = 56,
    bool italic = true,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) => TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: size,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    fontWeight: weight,
    letterSpacing: -1.5,
    height: 0.95,
    color: color,
  );

  static TextStyle displayMd({bool italic = true, Color? color}) =>
      display(size: 28, italic: italic, color: color);

  static TextStyle displaySm({bool italic = true, Color? color}) =>
      display(size: 22, italic: italic, color: color);

  static TextStyle displayBook({bool italic = true, Color? color}) =>
      display(size: 18, italic: italic, color: color);

  // Manrope — corps, labels
  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
  }) => GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );

  static TextStyle eyebrow({Color? color}) => GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: color,
  );

  static TextStyle label({double size = 12, Color? color}) => GoogleFonts.manrope(
    fontSize: size,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: color,
  );
}

// ─── Spacing & radius constants ───────────────────────────────────────────────

class AppSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 14.0;
  static const lg  = 20.0;
  static const xl  = 28.0;
  static const xxl = 40.0;
}

class AppRadius {
  static const sm   = Radius.circular(6);
  static const md   = Radius.circular(10);
  static const lg   = Radius.circular(14);
  static const xl   = Radius.circular(22);
  static const pill = Radius.circular(999);
  static const card = BorderRadius.all(Radius.circular(14));
  static const cardLg = BorderRadius.all(Radius.circular(16));
}

// ─── Shadow helpers ───────────────────────────────────────────────────────────

class AppShadows {
  static List<BoxShadow> cardLight = [
    BoxShadow(color: Color(0x0A3C2814), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F3C2814), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> cardDark = [
    BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> soft({bool dark = false}) => dark
      ? [BoxShadow(color: Color(0x4D000000), blurRadius: 2, offset: Offset(0, 1))]
      : [BoxShadow(color: Color(0x0F3C2814), blurRadius: 2, offset: Offset(0, 1))];
}
