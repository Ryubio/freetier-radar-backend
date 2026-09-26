import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeType { catppuccin, nord, tokyoNight }

class AppColors {
  final Color surface;
  final Color mantle;
  final Color surface0;
  final Color primary;
  final Color secondary;
  final Color error;
  final Color warning;
  final Color text;
  final Color subtext;
  final Color border;

  const AppColors({
    required this.surface,
    required this.mantle,
    required this.surface0,
    required this.primary,
    required this.secondary,
    required this.error,
    required this.warning,
    required this.text,
    required this.subtext,
    required this.border,
  });
}

class AppTheme {
  // Catppuccin Mocha Palette (backward compat)
  static const Color surfaceColor = Color(0xFF1E1E2E);
  static const Color mantleColor = Color(0xFF181825);
  static const Color surface0Color = Color(0xFF313244);
  
  static const Color primaryBlue = Color(0xFF89B4FA);
  static const Color secondaryGreen = Color(0xFFA6E3A1);
  static const Color errorRed = Color(0xFFF38BA8);
  static const Color warningPeach = Color(0xFFFAB387);
  
  static const Color textColor = Color(0xFFCDD6F4);
  static const Color subtextColor = Color(0xFFA6ADC8);

  static AppColors getColors(AppThemeType type) {
    switch (type) {
      case AppThemeType.catppuccin:
        return const AppColors(
          surface: Color(0xFF1E1E2E),
          mantle: Color(0xFF181825),
          surface0: Color(0xFF313244),
          primary: Color(0xFF89B4FA),
          secondary: Color(0xFFA6E3A1),
          error: Color(0xFFF38BA8),
          warning: Color(0xFFFAB387),
          text: Color(0xFFCDD6F4),
          subtext: Color(0xFFA6ADC8),
          border: Color(0xFF45475A),
        );
      case AppThemeType.nord:
        return const AppColors(
          surface: Color(0xFF2E3440),
          mantle: Color(0xFF242933),
          surface0: Color(0xFF3B4252),
          primary: Color(0xFF88C0D0),
          secondary: Color(0xFFA3BE8C),
          error: Color(0xFFBF616A),
          warning: Color(0xFFEBCB8B),
          text: Color(0xFFECEFF4),
          subtext: Color(0xFFD8DEE9),
          border: Color(0xFF4C566A),
        );
      case AppThemeType.tokyoNight:
        return const AppColors(
          surface: Color(0xFF1A1B26),
          mantle: Color(0xFF16161E),
          surface0: Color(0xFF24283B),
          primary: Color(0xFF7AA2F7),
          secondary: Color(0xFF9ECE6A),
          error: Color(0xFFF7768E),
          warning: Color(0xFFE0AF68),
          text: Color(0xFFC0CAF5),
          subtext: Color(0xFF9AA5CE),
          border: Color(0xFF292E42),
        );
    }
  }

  static ThemeData getTheme(AppThemeType type) {
    final colors = getColors(type);
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.mantle,
      colorScheme: ColorScheme.dark(
        primary: colors.primary,
        secondary: colors.secondary,
        surface: colors.surface,
        background: colors.mantle,
        error: colors.error,
        onPrimary: colors.mantle,
        onSecondary: colors.mantle,
        onSurface: colors.text,
        onBackground: colors.text,
        onError: colors.surface,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: colors.text),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: colors.text),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: colors.text),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: colors.subtext),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: colors.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colors.text),
      ),
      cardTheme: CardThemeData(
        color: colors.surface0,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primary.withOpacity(0.2),
        disabledColor: colors.surface0,
        labelStyle: GoogleFonts.inter(color: colors.subtext, fontSize: 13),
        secondaryLabelStyle: GoogleFonts.inter(color: colors.primary, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.border),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.subtext,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary),
        ),
        hintStyle: GoogleFonts.inter(color: colors.subtext.withOpacity(0.5)),
      ),
    );
  }

  static ThemeData get darkTheme => getTheme(AppThemeType.catppuccin);

  // Helper method for code-like text style
  static TextStyle get codeStyle => GoogleFonts.jetBrainsMono(
    color: secondaryGreen,
    fontSize: 13,
  );
}
