import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/storage/local_db.dart';
import '../../core/sync/sync_outbox.dart';
import '../../core/utils/ids.dart';
import 'biosecurity.dart';

class BiosecurityRepository {
  BiosecurityRepository._();

  static final BiosecurityRepository instance = BiosecurityRepository._();

  static const table = 'biosecurity_checks';

  Box<dynamic> get _box => LocalDb.box(LocalDb.biosecurity);

  ValueListenable<Box<dynamic>> get changes => _box.listenable();

  /// Newest week first.
  List<BioCheck> all() {
    final list = _box.values.whereType<Map>().map(BioCheck.fromMap).toList();
    list.sort((a, b) => b.weekStart.compareTo(a.weekStart));
    return list;
  }

  BioCheck? forWeek(DateTime weekStart) {
    for (final c in all()) {
      if (c.weekStart == weekStart) return c;
    }
    return null;
  }

  /// Saves this week's ticks (one record per week).
  Future<BioCheck> saveWeek(DateTime weekStart, Set<String> ticked) async {
    final existing = forWeek(weekStart);
    final check = BioCheck(
      id: existing?.id ?? newId(),
      weekStart: weekStart,
      ticked: ticked,
      updatedAt: DateTime.now(),
    );
    await _box.put(check.id, check.toMap());
    await SyncOutbox.upsert(table, check.id);
    return check;
  }
}
