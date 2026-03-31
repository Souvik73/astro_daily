import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const Color canvas = Color(0xFFF7EFE3);
  static const Color canvasSoft = Color(0xFFFFFBF5);
  static const Color ink = Color(0xFF1D1B2A);
  static const Color inkSoft = Color(0xFF625F72);
  static const Color border = Color(0xFFE2D5C6);
  static const Color teal = Color(0xFF0C6E6A);
  static const Color gold = Color(0xFFE7A43B);
  static const Color coral = Color(0xFFC86A5C);
  static const Color berry = Color(0xFFA05369);
  static const Color midnight = Color(0xFF21263F);
  static const Color cream = Color(0xFFFFFCF7);

  static const LinearGradient heroGradient = LinearGradient(
    colors: <Color>[
      Color(0xFF1F2745),
      Color(0xFF865469),
      Color(0xFFF0B767),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: <Color>[
      Color(0xFFFFF9F1),
      Color(0xFFF7ECDC),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData light() {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: teal,
      onPrimary: Colors.white,
      secondary: gold,
      onSecondary: ink,
      error: coral,
      onError: Colors.white,
      surface: cream,
      onSurface: ink,
      surfaceContainerHighest: Color(0xFFF1E5D7),
      onSurfaceVariant: inkSoft,
      outline: border,
      outlineVariant: Color(0xFFEADFD2),
      shadow: Color(0x261D1B2A),
      scrim: Color(0x661D1B2A),
      inverseSurface: midnight,
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFF8ED7C4),
      tertiary: berry,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFF2D8DF),
      onTertiaryContainer: ink,
    );

    final TextTheme baseText = GoogleFonts.manropeTextTheme();
    final TextTheme textTheme = baseText.copyWith(
      displayLarge: GoogleFonts.cormorantGaramond(
        fontSize: 60,
        height: 0.95,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      displayMedium: GoogleFonts.cormorantGaramond(
        fontSize: 48,
        height: 0.96,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      displaySmall: GoogleFonts.cormorantGaramond(
        fontSize: 40,
        height: 0.96,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineLarge: GoogleFonts.cormorantGaramond(
        fontSize: 36,
        height: 0.97,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineMedium: GoogleFonts.cormorantGaramond(
        fontSize: 30,
        height: 0.98,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineSmall: GoogleFonts.cormorantGaramond(
        fontSize: 25,
        height: 1.0,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      titleSmall: GoogleFonts.manrope(
        fontSize: 14,
        height: 1.25,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 15,
        height: 1.55,
        fontWeight: FontWeight.w500,
        color: inkSoft,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 13.5,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: inkSoft,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w600,
        color: inkSoft,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: inkSoft,
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 10.5,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w800,
        color: inkSoft,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: midnight.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: border),
        ),
      ),
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: teal, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: coral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: coral, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: midnight,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: ink,
          backgroundColor: Colors.white,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.titleSmall,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: berry,
          textStyle: textTheme.titleSmall,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: midnight,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        side: const BorderSide(color: border),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: textTheme.labelMedium,
      ),
    );
  }
}
