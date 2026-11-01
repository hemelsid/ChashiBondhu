import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Bundled Bangla font (assets/fonts). Set on every explicit style below,
/// because AppBar / button styles do not inherit the theme font.
const kAppFont = 'NotoSansBengali';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
  );
  final radius = BorderRadius.circular(16);

  return ThemeData(
    useMaterial3: true,
    fontFamily: kAppFont,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      toolbarHeight: 64,
      titleTextStyle: TextStyle(
          fontFamily: kAppFont,
          fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      iconTheme: IconThemeData(size: 30, color: Colors.white),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 64),
        textStyle: const TextStyle(
            fontFamily: kAppFont, fontSize: 21, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 64),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 2),
        textStyle: const TextStyle(
            fontFamily: kAppFont, fontSize: 21, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(fontFamily: kAppFont, fontSize: 18, color: Color(0xFF9E9E9E)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      contentTextStyle:
          TextStyle(fontFamily: kAppFont, fontSize: 18, color: Colors.white),
    ),
  );
}
