import '../app_info.dart';
import '../storage/app_settings.dart';
import '../storage/local_db.dart';

/// How a local Hive record becomes a Supabase row. Column names match
/// supabase/schema.sql. Pure functions on plain maps (no feature imports).
class SyncTable {
  const SyncTable({
    required this.table,
    required this.box,
    required this.order,
    required this.toRemote,
  });

  final String table;

  /// Local Hive box name (null = built from settings, e.g. users).
  final String? box;

  /// Parents first when saving, children first when deleting.
  final int order;
  final Map<String, dynamic> Function(Map<dynamic, dynamic> local, String uid) toRemote;
}

String _iso(dynamic ms) => DateTime.fromMillisecondsSinceEpoch((ms as num?)?.toInt() ?? 0)
    .toUtc()
    .toIso8601String();

/// Local calendar date (Bangladesh), e.g. 2026-11-01.
String _day(dynamic ms) {
  final d = DateTime.fromMillisecondsSinceEpoch((ms as num?)?.toInt() ?? 0);
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> usersRow(String uid) => {
      'id': uid,
      'district_id': AppSettings.districtId,
      'upazila': AppSettings.upazila,
      'app_version': AppInfo.version,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

final Map<String, SyncTable> kSyncTables = {
  'users': SyncTable(
    table: 'users',
    box: null,
    order: 0,
    toRemote: (_, uid) => usersRow(uid),
  ),
  'ponds': SyncTable(
    table: 'ponds',
    box: LocalDb.ponds,
    order: 1,
    toRemote: (m, uid) => {
      'id': m['id'],
      'owner_id': uid,
      'name': m['name'],
      'area_shotok': m['areaShotok'],
      'species': m['species'],
      'stock_count': m['stockCount'],
      'stock_date': _day(m['stockDate']),
      'avg_weight_g': m['avgWeightG'],
      'created_at': _iso(m['createdAt']),
      'updated_at': _iso(m['updatedAt']),
    },
  ),
  'pond_logs': SyncTable(
    table: 'pond_logs',
    box: LocalDb.pondLogs,
    order: 2,
    toRemote: (m, uid) => {
      'id': m['id'],
      'pond_id': m['pondId'],
      'owner_id': uid,
      'log_date': _day(m['date']),
      'feed_kg': m['feedKg'],
      'dead_count': m['deadCount'],
      'water_color': m['waterColor'],
      'behavior': m['behavior'],
      'note': m['note'] ?? '',
      'created_at': _iso(m['createdAt']),
      'updated_at': _iso(m['updatedAt']),
    },
  ),
  'disease_reports': SyncTable(
    table: 'disease_reports',
    box: LocalDb.diseaseReports,
    order: 3,
    toRemote: (m, uid) => {
      'id': m['id'],
      'owner_id': uid,
      'kind': m['kind'],
      'pond_id': m['pondId'],
      'pond_name': m['pondName'],
      'crop': m['cropId'],
      'crop_label': m['cropLabel'],
      'report_date': _day(m['date']),
      'photo_path': m['remotePhotoPath'],
      'symptoms': List<String>.from(m['symptomIds'] as List? ?? const []),
      'results': [
        for (final r in (m['results'] as List? ?? const []))
          if (r is Map) Map<String, dynamic>.from(r),
      ],
      'created_at': _iso(m['createdAt']),
    },
  ),
  'reminders': SyncTable(
    table: 'reminders',
    box: LocalDb.reminders,
    order: 3,
    toRemote: (m, uid) => {
      'id': m['id'],
      'owner_id': uid,
      'type': m['type'],
      'pond_id': m['pondId'],
      'pond_name': m['pondName'],
      'due_at': _iso(m['dueAt']),
      'done': m['done'] == true,
      'done_day': m['doneDay'],
      'created_at': _iso(m['createdAt']),
      'updated_at': _iso(m['updatedAt']),
    },
  ),
  'biosecurity_checks': SyncTable(
    table: 'biosecurity_checks',
    box: LocalDb.biosecurity,
    order: 3,
    toRemote: (m, uid) => {
      'id': m['id'],
      'owner_id': uid,
      'week_start': _day(m['weekStart']),
      'items': List<String>.from(m['ticked'] as List? ?? const []),
      'score': m['score'],
      'updated_at': _iso(m['updatedAt']),
    },
  ),
};
