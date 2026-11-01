import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/domain/signal.dart';
import '../../../core/storage/local_db.dart';
import '../../../core/sync/sync_outbox.dart';
import 'pond.dart';
import 'pond_log.dart';

/// Pond + summary numbers computed from its diary.
class PondSummary {
  const PondSummary({
    required this.pond,
    required this.logs,
    required this.totalDead,
    required this.totalFeedKg,
  });

  final Pond pond;

  /// Newest first.
  final List<PondLog> logs;
  final int totalDead;
  final double totalFeedKg;

  int get currentStock => max(0, pond.stockCount - totalDead);

  PondLog? get lastLog => logs.isEmpty ? null : logs.first;

  Signal? get latestSignal => lastLog?.signalFor(currentStock);

  int get daysSinceStock {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day).difference(DateTime(
        pond.stockDate.year, pond.stockDate.month, pond.stockDate.day));
    return max(0, d.inDays);
  }
}

/// All pond reads/writes go through here. Offline (Hive) now; each write is
/// also queued in [SyncOutbox] for Supabase later.
class PondRepository {
  PondRepository._();

  static final PondRepository instance = PondRepository._();

  static const pondsTable = 'ponds';
  static const logsTable = 'pond_logs';

  Box<dynamic> get _ponds => LocalDb.box(LocalDb.ponds);
  Box<dynamic> get _logs => LocalDb.box(LocalDb.pondLogs);

  /// Rebuild UI when ponds or logs change.
  Listenable get changes =>
      Listenable.merge([_ponds.listenable(), _logs.listenable()]);

  // ---------- Ponds ----------

  List<Pond> allPonds() {
    final list = _ponds.values.whereType<Map>().map(Pond.fromMap).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Pond? pond(String id) {
    final m = _ponds.get(id);
    return m is Map ? Pond.fromMap(m) : null;
  }

  Future<void> savePond(Pond pond) async {
    final p = pond.copyWith(updatedAt: DateTime.now());
    await _ponds.put(p.id, p.toMap());
    await SyncOutbox.upsert(pondsTable, p.id);
  }

  /// Deletes the pond and all its diary entries.
  Future<void> deletePond(String id) async {
    final logIds = _logs.values
        .whereType<Map>()
        .where((m) => m['pondId'] == id)
        .map((m) => m['id'] as String)
        .toList();
    await _logs.deleteAll(logIds);
    for (final logId in logIds) {
      await SyncOutbox.delete(logsTable, logId);
    }
    await _ponds.delete(id);
    await SyncOutbox.delete(pondsTable, id);
  }

  // ---------- Daily logs ----------

  /// Newest first.
  List<PondLog> logsFor(String pondId) {
    final list = _logs.values
        .whereType<Map>()
        .where((m) => m['pondId'] == pondId)
        .map(PondLog.fromMap)
        .toList();
    list.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  Future<void> saveLog(PondLog log) async {
    await _logs.put(log.id, log.toMap());
    await SyncOutbox.upsert(logsTable, log.id);
  }

  Future<void> deleteLog(String id) async {
    await _logs.delete(id);
    await SyncOutbox.delete(logsTable, id);
  }

  // ---------- Summary ----------

  PondSummary summary(Pond pond) {
    final logs = logsFor(pond.id);
    var dead = 0;
    var feed = 0.0;
    for (final l in logs) {
      dead += l.deadCount;
      feed += l.feedKg;
    }
    return PondSummary(pond: pond, logs: logs, totalDead: dead, totalFeedKg: feed);
  }
}
