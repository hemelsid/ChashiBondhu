import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/choice_grid.dart';
import '../data/observations.dart';

extension FishBehaviorUi on FishBehavior {
  IconData get icon => switch (this) {
        FishBehavior.normal => Icons.sentiment_satisfied_alt,
        FishBehavior.lessEating => Icons.sentiment_neutral,
        FishBehavior.slow => Icons.slow_motion_video,
        FishBehavior.gasping => Icons.air,
        FishBehavior.wounds => Icons.healing,
      };

  Color get color => switch (signal.index) {
        0 => AppColors.ok,
        1 => const Color(0xFFE09B00),
        _ => AppColors.danger,
      };
}

List<ChoiceOption<WaterColor>> waterColorOptions() => [
      for (final c in WaterColor.values)
        ChoiceOption(value: c, label: c.label, swatch: Color(c.swatch)),
    ];

List<ChoiceOption<FishBehavior>> behaviorOptions() => [
      for (final b in FishBehavior.values)
        ChoiceOption(value: b, label: b.label, icon: b.icon, iconColor: b.color),
    ];
