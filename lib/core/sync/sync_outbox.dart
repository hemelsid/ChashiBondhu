import '../storage/local_db.dart';

/// Every local change is recorded here so it can be pushed to Supabase later.
/// One entry per (table, id); a later change replaces the earlier one.
class SyncOutbox {
  SyncOutbox._();

  /// Set by SyncManager: called after every change (it debounces).
  static void Function()? onChanged;

  static Future<void> upsert(String table, String id) => _put(table, id, 'upsert');

  static Future<void> delete(String table, String id) => _put(table, id, 'delete');

  static Future<void> _put(String table, String id, String op) async {
    await LocalDb.box(LocalDb.syncOutbox).put('$table:$id', {
      'table': table,
      'id': id,
      'op': op,
      'at': DateTime.now().millisecondsSinceEpoch,
    });
    onChanged?.call();
  }

  static int get pendingCount => LocalDb.box(LocalDb.syncOutbox).length;

  static List<Map<dynamic, dynamic>> pending() =>
      LocalDb.box(LocalDb.syncOutbox).values.whereType<Map>().toList();

  /// Removes the entry only if it was not changed again meanwhile.
  static Future<void> markDone(Map<dynamic, dynamic> entry) async {
    final box = LocalDb.box(LocalDb.syncOutbox);
    final key = '${entry['table']}:${entry['id']}';
    final current = box.get(key);
    if (current is Map && current['at'] == entry['at'] && current['op'] == entry['op']) {
      await box.delete(key);
    }
  }
}
