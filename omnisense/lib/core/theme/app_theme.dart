// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────
class OmniColors {
  OmniColors._();

  // Backgrounds
  static const Color bgDeep        = Color(0xFF0A0A0A);
  static const Color bgSurface     = Color(0xFF121212);
  static const Color bgCard        = Color(0xFF1A1A1A);
  static const Color bgCardHover   = Color(0xFF222222);
  static const Color bgBorder      = Color(0xFF2A2A2A);

  // Accents
  static const Color neonGreen     = Color(0xFF39FF14); // Active / Granted
  static const Color neonGreenDim  = Color(0xFF1DB800);
  static const Color crimsonRed    = Color(0xFFDC143C); // Alert / Unauthorized
  static const Color crimsonRedDim = Color(0xFF8B0020);
  static const Color amberWarning  = Color(0xFFFFBF00); // Warning / Flagged
  static const Color cyanAccent    = Color(0xFF00E5FF); // Info / Interactive
  static const Color cyanDim       = Color(0xFF007A99);

  // Text
  static const Color textPrimary   = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textDisabled  = Color(0xFF424242);
  static const Color textOnAccent  = Color(0xFF000000);

  // Gradient stops
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF39FF14), Color(0xFF00C300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFDC143C), Color(0xFF8B0020)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E1E), Color(0xFF141414)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
class OmniTextStyles {
  OmniTextStyles._();

  static TextStyle hudTitle(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: OmniColors.textPrimary,
        letterSpacing: 2.5,
      );

  static TextStyle hudSubtitle(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: OmniColors.textSecondary,
        letterSpacing: 1.8,
      );

  static TextStyle metricValue(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: OmniColors.neonGreen,
        letterSpacing: 1.0,
      );

  static TextStyle metricLabel(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: OmniColors.textSecondary,
        letterSpacing: 2.0,
      );

  static TextStyle sectionHeader(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: OmniColors.textSecondary,
        letterSpacing: 3.0,
      );

  static TextStyle bodyLarge(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: OmniColors.textPrimary,
      );

  static TextStyle bodySmall(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: OmniColors.textSecondary,
      );

  static TextStyle memberId(BuildContext context) =>
      GoogleFonts.robotoMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: OmniColors.cyanAccent,
        letterSpacing: 0.8,
      );

  static TextStyle statusChip(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      );
}

// ─── Theme ────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: OmniColors.bgSurface,
      colorScheme: const ColorScheme.dark(
        primary:       OmniColors.neonGreen,
        onPrimary:     OmniColors.textOnAccent,
        secondary:     OmniColors.cyanAccent,
        onSecondary:   OmniColors.textOnAccent,
        error:         OmniColors.crimsonRed,
        onError:       OmniColors.textPrimary,
        surface:       OmniColors.bgCard,
        onSurface:     OmniColors.textPrimary,
        surfaceContainerHighest: OmniColors.bgBorder,
        outline:       OmniColors.bgBorder,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyLarge:   GoogleFonts.inter(color: OmniColors.textPrimary,   fontSize: 15),
        bodyMedium:  GoogleFonts.inter(color: OmniColors.textSecondary, fontSize: 13),
        labelLarge:  GoogleFonts.rajdhani(
          color: OmniColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: OmniColors.bgDeep,
        foregroundColor: OmniColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: OmniColors.textPrimary,
          letterSpacing: 2.0,
        ),
        iconTheme: IconThemeData(color: OmniColors.textSecondary),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: OmniColors.bgDeep,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: OmniColors.bgCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: OmniColors.bgBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: OmniColors.bgBorder,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return OmniColors.crimsonRed;
          return OmniColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return OmniColors.crimsonRedDim;
          return OmniColors.bgBorder;
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: OmniColors.neonGreen,
          foregroundColor: OmniColors.textOnAccent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.rajdhani(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OmniColors.neonGreen,
          side: const BorderSide(color: OmniColors.neonGreen, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OmniColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: OmniColors.bgBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: OmniColors.bgBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: OmniColors.neonGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: OmniColors.crimsonRed),
        ),
        labelStyle: const TextStyle(color: OmniColors.textSecondary),
        hintStyle:  const TextStyle(color: OmniColors.textDisabled),
        prefixIconColor: OmniColors.textSecondary,
        suffixIconColor: OmniColors.textSecondary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: OmniColors.bgCard,
        contentTextStyle: GoogleFonts.inter(color: OmniColors.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: OmniColors.bgBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: OmniColors.bgDeep,
        indicatorColor: OmniColors.neonGreen.withAlpha(30),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: OmniColors.neonGreen, size: 22);
          }
          return const IconThemeData(color: OmniColors.textSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.rajdhani(
              color: OmniColors.neonGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            );
          }
          return GoogleFonts.rajdhani(
            color: OmniColors.textSecondary,
            fontSize: 11,
            letterSpacing: 1.0,
          );
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: OmniColors.bgDeep,
        selectedItemColor: OmniColors.neonGreen,
        unselectedItemColor: OmniColors.textSecondary,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: OmniColors.bgCard,
        iconColor: OmniColors.textSecondary,
        textColor: OmniColors.textPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: OmniColors.neonGreen,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: OmniColors.neonGreen,
        foregroundColor: OmniColors.textOnAccent,
      ),
    );
  }
}
