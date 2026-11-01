import 'package:flutter/material.dart';

import '../domain/signal.dart';
import 'app_colors.dart';

/// How each signal looks on screen.
extension SignalStyle on Signal {
  Color get color => switch (this) {
        Signal.ok => AppColors.ok,
        Signal.warn => AppColors.warn,
        Signal.danger => AppColors.danger,
      };

  Color get background => switch (this) {
        Signal.ok => AppColors.okBg,
        Signal.warn => AppColors.warnBg,
        Signal.danger => AppColors.dangerBg,
      };

  /// Text colour that is readable on [background].
  Color get textColor => switch (this) {
        Signal.ok => AppColors.ok,
        Signal.warn => AppColors.warnText,
        Signal.danger => AppColors.danger,
      };

  /// Icon colour that is readable on [color].
  Color get onColor => this == Signal.warn ? const Color(0xFF3E2C00) : Colors.white;

  String get label => switch (this) {
        Signal.ok => 'ঠিক আছে',
        Signal.warn => 'সতর্ক থাকুন',
        Signal.danger => 'বিপদ!',
      };

  IconData get icon => switch (this) {
        Signal.ok => Icons.check_circle,
        Signal.warn => Icons.warning_amber_rounded,
        Signal.danger => Icons.dangerous,
      };
}
