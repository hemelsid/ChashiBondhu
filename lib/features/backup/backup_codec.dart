import 'dart:convert';

import '../../core/storage/local_db.dart';
import '../../core/utils/bangla.dart';

/// Backup file format (JSON) for moving records between phone and PC
/// without internet, plus CSV for Excel. Pure Dart — easy to test.
class BackupCodec {
  BackupCodec._();

  static const format = 'chashibondhu-backup';
  static const version = 1;

  /// Boxes that go into a backup. Names = Supabase table names.
  static const boxes = [
    LocalDb.ponds,
    LocalDb.pondLogs,
    LocalDb.diseaseReports,
    LocalDb.reminders,
    LocalDb.biosecurity,
    LocalDb.contacts,
  ];

  /// Settings worth carrying over (area, officer numbers).
  static const settingKeys = [
    'districtId',
    'upazila',
    'fishOfficerName',
    'fishOfficerPhone',
    'cropOfficerName',
    'cropOfficerPhone',
  ];

  /// Deep copy into plain JSON types (Hive gives Map<dynamic, dynamic>).
  static dynamic plain(dynamic v) {
    if (v is Map) return {for (final e in v.entries) e.key.toString(): plain(e.value)};
    if (v is List) return [for (final x in v) plain(x)];
    return v;
  }

  static String encode({
    required Map<String, Map<dynamic, dynamic>> data,
    required Map<String, dynamic> settings,
    required DateTime at,
  }) {
    return const JsonEncoder.withIndent(' ').convert({
      'format': format,
      'version': version,
      'exportedAt': at.toIso8601String(),
      'settings': plain(settings),
      'boxes': {for (final b in boxes) b: plain(data[b] ?? const {})},
    });
  }

  /// Throws [FormatException] if this is not a চাষিবন্ধু backup.
  static BackupData decode(String text) {
    final dynamic j;
    try {
      j = jsonDecode(text);
    } catch (_) {
      throw const FormatException('not json');
    }
    if (j is! Map || j['format'] != format) throw const FormatException('not ours');
    if ((j['version'] as num? ?? 0) > version) throw const FormatException('newer');
    final rawBoxes = j['boxes'];
    final out = <String, Map<String, Map<String, dynamic>>>{};
    for (final b in boxes) {
      final m = rawBoxes is Map ? rawBoxes[b] : null;
      out[b] = {
        if (m is Map)
          for (final e in m.entries)
            if (e.value is Map) e.key.toString(): Map<String, dynamic>.from(e.value as Map),
      };
    }
    final s = j['settings'];
    return BackupData(
      boxes: out,
      settings: s is Map ? Map<String, dynamic>.from(s) : const {},
    );
  }

  /// When a record was last changed.
  static int stamp(Map<dynamic, dynamic> m) =>
      ((m['updatedAt'] ?? m['createdAt'] ?? 0) as num).toInt();

  /// Records from [incoming] that are new, or newer than what [existing] has.
  static Map<String, Map<String, dynamic>> newerRecords(
    Map<dynamic, dynamic> existing,
    Map<String, Map<String, dynamic>> incoming,
  ) {
    final out = <String, Map<String, dynamic>>{};
    incoming.forEach((id, rec) {
      final old = existing[id];
      if (old is! Map || stamp(rec) > stamp(old)) out[id] = rec;
    });
    return out;
  }

  // ---------- CSV for Excel ----------

  static String _cell(Object? v) {
    final s = (v ?? '').toString();
    final needsQuotes = s.contains(',') || s.contains('"') || s.contains('\n');
    return needsQuotes ? '"${s.replaceAll('"', '""')}"' : s;
  }

  /// UTF-8 with BOM so Excel shows Bangla correctly.
  static String csv(List<String> header, List<List<Object?>> rows) {
    final b = StringBuffer('﻿');
    b.writeln(header.map(_cell).join(','));
    for (final r in rows) {
      b.writeln(r.map(_cell).join(','));
    }
    return b.toString();
  }

  static String fileDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Plain digits in CSV cells so Excel can add them up.
  static String numText(double v) => Bn.toLatin(Bn.number(v, maxDecimals: 2));
}

class BackupData {
  const BackupData({required this.boxes, required this.settings});

  final Map<String, Map<String, Map<String, dynamic>>> boxes;
  final Map<String, dynamic> settings;

  int get total => boxes.values.fold(0, (a, b) => a + b.length);
}
