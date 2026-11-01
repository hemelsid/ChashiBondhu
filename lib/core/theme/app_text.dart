import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Large, readable text styles. Nothing smaller than 15 in the app.
class AppText {
  AppText._();

  static const big = TextStyle(
      fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.textDark);
  static const title = TextStyle(
      fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark);
  static const label = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark);
  static const body = TextStyle(fontSize: 18, color: AppColors.textDark);
  static const muted = TextStyle(fontSize: 16, color: AppColors.textMuted);
}
