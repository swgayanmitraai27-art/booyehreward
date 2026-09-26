import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Master Amber/Yellow Palette
  static const Color primaryAmber = Color(0xFFFFB900);
  static const Color amberDark = Color(0xFFE5A600);
  static const Color amberLight = Color(0xFFFFF7DB);

  // Clean Light Backgrounds
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // 4-Wallet & Palette Colors
  static const Color adCoinsGold = Color(0xFFFFB900);
  static const Color rewardCoinsAmber = Color(0xFFD97706);
  static const Color depositBlue = Color(0xFF2563EB);
  static const Color winningGreen = Color(0xFF10B981);
  static const Color roseRed = Color(0xFFE11D48);

  // Text colors
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primaryAmber,
        onPrimary: textDark,
        secondary: winningGreen,
        surface: cardWhite,
        onSurface: textDark,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.rajdhani(
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: textDark,
        ),
        displayMedium: GoogleFonts.rajdhani(
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
          color: textDark,
        ),
        titleLarge: GoogleFonts.rajdhani(
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
          color: textDark,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.rajdhani(
          fontWeight: FontWeight.w700,
          color: textDark,
          fontSize: 16,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardWhite,
        elevation: 0.5,
        iconTheme: IconThemeData(color: textDark),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
    );
  }

  static TextStyle gamingTitle({
    double fontSize = 22,
    Color color = textDark,
    bool isItalic = true,
  }) {
    return GoogleFonts.rajdhani(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      color: color,
      letterSpacing: 0.5,
    );
  }

  static TextStyle gamingNumber({
    double fontSize = 18,
    Color color = textDark,
  }) {
    return GoogleFonts.russoOne(
      fontSize: fontSize,
      color: color,
      letterSpacing: 0.5,
    );
  }
}
