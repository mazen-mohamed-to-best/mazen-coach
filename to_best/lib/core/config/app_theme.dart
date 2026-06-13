import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextStyle _cairo(TextStyle base) => GoogleFonts.cairo(textStyle: base);

  static ThemeData darkTheme(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: AppColors.primaryGreen,
        surface: AppColors.darkSurface,
        background: AppColors.darkBg,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkText,
        onBackground: AppColors.darkText,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: AppColors.darkText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardTheme(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.cairo(color: AppColors.darkSubText),
        labelStyle: GoogleFonts.cairo(color: AppColors.darkSubText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: _textTheme(AppColors.darkText, AppColors.darkSubText),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 0.5),
      iconTheme: const IconThemeData(color: AppColors.darkSubText),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: accent,
        unselectedItemColor: AppColors.darkSubText,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: accent.withOpacity(0.15),
        labelTextStyle: MaterialStateProperty.all(
          GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected) ? accent : AppColors.darkSubText,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected) ? accent.withOpacity(0.4) : AppColors.darkBorder,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkCard,
        selectedColor: accent.withOpacity(0.2),
        labelStyle: GoogleFonts.cairo(fontSize: 13),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: GoogleFonts.cairo(color: AppColors.darkText),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }

  static ThemeData lightTheme(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: AppColors.primaryGreen,
        surface: AppColors.lightSurface,
        background: AppColors.lightBg,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightText,
        onBackground: AppColors.lightText,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightText),
      ),
      cardTheme: CardTheme(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.cairo(color: AppColors.lightSubText),
        labelStyle: GoogleFonts.cairo(color: AppColors.lightSubText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: _textTheme(AppColors.lightText, AppColors.lightSubText),
      dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 0.5),
      iconTheme: const IconThemeData(color: AppColors.lightSubText),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: accent,
        unselectedItemColor: AppColors.lightSubText,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: accent.withOpacity(0.15),
        labelTextStyle: MaterialStateProperty.all(
          GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected) ? accent : AppColors.lightSubText,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected) ? accent.withOpacity(0.4) : AppColors.lightBorder,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightCard,
        selectedColor: accent.withOpacity(0.2),
        labelStyle: GoogleFonts.cairo(fontSize: 13),
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightSurface,
        contentTextStyle: GoogleFonts.cairo(color: AppColors.lightText),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return GoogleFonts.cairoTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 32),
        displayMedium: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 28),
        displaySmall: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 24),
        headlineLarge: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 22),
        headlineMedium: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 20),
        headlineSmall: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 18),
        titleLarge: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 16),
        titleMedium: TextStyle(color: primary, fontWeight: FontWeight.w500, fontSize: 14),
        titleSmall: TextStyle(color: secondary, fontWeight: FontWeight.w500, fontSize: 12),
        bodyLarge: TextStyle(color: primary, fontSize: 15),
        bodyMedium: TextStyle(color: primary, fontSize: 14),
        bodySmall: TextStyle(color: secondary, fontSize: 12),
        labelLarge: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 14),
        labelMedium: TextStyle(color: secondary, fontSize: 12),
        labelSmall: TextStyle(color: secondary, fontSize: 10),
      ),
    );
  }
}
