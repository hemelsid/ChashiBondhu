import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'local_db.dart';

/// Small key-value settings stored offline.
class AppSettings {
  AppSettings._();

  static Box<dynamic> get _box => LocalDb.box(LocalDb.settings);

  static ValueListenable<Box<dynamic>> listenable() => _box.listenable();

  // ---- Area (for weather) ----
  static String? get districtId => _box.get('districtId') as String?;
  static String get upazila => (_box.get('upazila') as String?) ?? '';

  static Future<void> setArea(String districtId, String upazila) async {
    await _box.put('districtId', districtId);
    await _box.put('upazila', upazila.trim());
  }

  // ---- Officer contacts ----
  static String get fishOfficerName => (_box.get('fishOfficerName') as String?) ?? '';
  static String get fishOfficerPhone => (_box.get('fishOfficerPhone') as String?) ?? '';
  static String get cropOfficerName => (_box.get('cropOfficerName') as String?) ?? '';
  static String get cropOfficerPhone => (_box.get('cropOfficerPhone') as String?) ?? '';

  static Future<void> setFishOfficer(String name, String phone) async {
    await _box.put('fishOfficerName', name.trim());
    await _box.put('fishOfficerPhone', phone.trim());
  }

  static Future<void> setCropOfficer(String name, String phone) async {
    await _box.put('cropOfficerName', name.trim());
    await _box.put('cropOfficerPhone', phone.trim());
  }

  // ---- Generic helpers (caches, counters) ----
  static dynamic get(String key) => _box.get(key);
  static Future<void> put(String key, dynamic value) => _box.put(key, value);

  /// Unique small int for each scheduled notification.
  static Future<int> nextNotificationId() async {
    final id = ((_box.get('nextNotificationId') as int?) ?? 1000) + 1;
    await _box.put('nextNotificationId', id);
    return id;
  }
}
