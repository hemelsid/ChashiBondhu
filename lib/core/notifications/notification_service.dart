import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../utils/platform_info.dart';

/// Offline local reminders (flutter_local_notifications 17.x).
/// Time zone is fixed to Bangladesh, so no extra time-zone plugin is needed.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'রিমাইন্ডার',
      channelDescription: 'খাবার, চুন, জাল টানা ও মাছ ধরার রিমাইন্ডার',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    // The plugin version used here has no Windows support: do nothing on PC.
    if (_ready || !PlatformInfo.hasReminderAlerts) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
      await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ));
      _ready = true;
    } catch (e) {
      debugPrint('notifications init failed: $e');
    }
  }

  /// Android 13+ asks the farmer once. Returns false if refused.
  Future<bool> requestPermission() async {
    if (!PlatformInfo.hasReminderAlerts) return false;
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  /// [daily] = repeat every day at the time of [when].
  /// Returns false if the time is already past (one-time reminders).
  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    bool daily = false,
  }) async {
    await init();
    if (!_ready) return false;
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, when.year, when.month, when.day, when.hour, when.minute);
    if (daily) {
      at = tz.TZDateTime(tz.local, now.year, now.month, now.day, when.hour, when.minute);
      if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    } else if (!at.isAfter(now)) {
      return false;
    }
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        at,
        _details,
        // Inexact = no special alarm permission needed; may be a few minutes late.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: daily ? DateTimeComponents.time : null,
      );
      return true;
    } catch (e) {
      debugPrint('schedule failed: $e');
      return false;
    }
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }
}
