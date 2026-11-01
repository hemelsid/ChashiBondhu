import 'package:flutter/material.dart';

import '../../core/utils/bangla.dart';
import 'reminder.dart';

extension ReminderTypeUi on ReminderType {
  IconData get icon => switch (this) {
        ReminderType.feed => Icons.rice_bowl,
        ReminderType.lime => Icons.science,
        ReminderType.net => Icons.phishing,
        ReminderType.harvest => Icons.shopping_basket,
      };

  Color get color => switch (this) {
        ReminderType.feed => const Color(0xFFE65100),
        ReminderType.lime => const Color(0xFF6A1B9A),
        ReminderType.net => const Color(0xFF1565C0),
        ReminderType.harvest => const Color(0xFF2E7D32),
      };
}

/// "সকাল ৮:০০" style time in Bangla.
String bnTime(int hour, int minute) {
  final String part;
  if (hour < 5) {
    part = 'রাত';
  } else if (hour < 12) {
    part = 'সকাল';
  } else if (hour < 16) {
    part = 'দুপুর';
  } else if (hour < 18) {
    part = 'বিকাল';
  } else if (hour < 20) {
    part = 'সন্ধ্যা';
  } else {
    part = 'রাত';
  }
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$part ${Bn.digits(h12)}:${Bn.digits(minute.toString().padLeft(2, '0'))}';
}
