import 'dart:io';

import 'package:flutter/foundation.dart';

/// What this device can do. The same app runs on phone and PC (Windows).
class PlatformInfo {
  PlatformInfo._();

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Camera is only on phones; PC picks a photo file instead.
  static bool get hasCamera => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Scheduled phone alerts (reminders). Not available on PC — there the
  /// "আজকের কাজ" list shows due reminders instead.
  static bool get hasReminderAlerts => !kIsWeb && Platform.isAndroid;
}
