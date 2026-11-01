import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/local_db.dart';
import '../../../core/sync/sync_outbox.dart';
import '../../../core/utils/photo_store.dart';
import 'disease_library.dart';
import 'disease_report.dart';

class DiseaseReportRepository {
  DiseaseReportRepository._();

  static final DiseaseReportRepository instance = DiseaseReportRepository._();

  static const table = 'disease_reports';

  Box<dynamic> get _box => LocalDb.box(LocalDb.diseaseReports);

  ValueListenable<Box<dynamic>> get changes => _box.listenable();

  /// Newest first. Optional filters.
  List<DiseaseReport> all({DiseaseKind? kind, String? pondId}) {
    final list = _box.values
        .whereType<Map>()
        .map(DiseaseReport.fromMap)
        .where((r) => kind == null || r.kind == kind)
        .where((r) => pondId == null || r.pondId == pondId)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  DiseaseReport? byId(String id) {
    final m = _box.get(id);
    return m is Map ? DiseaseReport.fromMap(m) : null;
  }

  Future<void> save(DiseaseReport report) async {
    await _box.put(report.id, report.toMap());
    await SyncOutbox.upsert(table, report.id);
  }

  Future<void> delete(DiseaseReport report) async {
    await _box.delete(report.id);
    await PhotoStore.delete(report.photoPath);
    await SyncOutbox.delete(table, report.id);
  }
}
