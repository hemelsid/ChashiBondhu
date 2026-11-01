import 'package:flutter/material.dart';

import '../../core/utils/bangla.dart';
import 'water_rules.dart';

/// Bangla labels, units and icons for each water parameter.
extension WaterParamUi on WaterParam {
  String get label => switch (this) {
        WaterParam.ph => 'পিএইচ',
        WaterParam.oxygen => 'অক্সিজেন (ডিও)',
        WaterParam.ammonia => 'অ্যামোনিয়া',
        WaterParam.temperature => 'পানির তাপমাত্রা',
      };

  String? get unit => switch (this) {
        WaterParam.ph => null,
        WaterParam.oxygen => 'মি.গ্রা./লি.',
        WaterParam.ammonia => 'মি.গ্রা./লি.',
        WaterParam.temperature => '°সে.',
      };

  IconData get icon => switch (this) {
        WaterParam.ph => Icons.science,
        WaterParam.oxygen => Icons.bubble_chart,
        WaterParam.ammonia => Icons.warning_amber,
        WaterParam.temperature => Icons.thermostat,
      };

  String get okRangeText => switch (this) {
        WaterParam.ph =>
          'ভালো: ${Bn.number(WaterLimits.phOkMin)} থেকে ${Bn.number(WaterLimits.phOkMax)}',
        WaterParam.oxygen => 'ভালো: ${Bn.number(WaterLimits.doOkMin)} বা তার বেশি',
        WaterParam.ammonia =>
          'ভালো: ${Bn.number(WaterLimits.ammoniaOkMax)} বা তার কম',
        WaterParam.temperature =>
          'ভালো: ${Bn.number(WaterLimits.tempOkMin)} থেকে ${Bn.number(WaterLimits.tempOkMax)} °সে.',
      };

  String formatValue(double v) {
    final u = unit;
    final n = Bn.number(v, maxDecimals: 2);
    return u == null ? n : '$n $u';
  }
}
