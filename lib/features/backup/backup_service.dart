import 'dart:io';

import 'package:file_selector/file_selector.dart'
    show XFile, XTypeGroup, getSaveLocation, openFile;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../../core/storage/app_settings.dart';
import '../../core/storage/local_db.dart';
import '../../core/sync/sync_outbox.dart';
import '../../core/utils/platform_info.dart';
import '../disease/common/disease_report_repository.dart';
import '../pond/data/pond_repository.dart';
import '../reminders/reminder_repository.dart';
import 'backup_codec.dart';

enum ExportOutcome { done, cancelled }

class ImportResult {
  const ImportResult(this.added, this.skipped);

  /// New or newer records written.
  final int added;

  /// Already on this device (same or newer).
  final int skipped;
}

/// Backup file + Excel (CSV) export. On phone the file is shared
/// (WhatsApp, Bluetooth, Drive …); on PC a "save as" window opens.
class BackupService {
  BackupService._();

  static Future<ExportOutcome> exportBackup() {
    final now = DateTime.now();
    final text = BackupCodec.encode(
      data: {for (final b in BackupCodec.boxes) b: LocalDb.box(b).toMap()},
      settings: {for (final k in BackupCodec.settingKeys) k: AppSettings.get(k)},
      at: now,
    );
    return _deliver('chashibondhu-backup-${BackupCodec.fileDate(now)}.json', text,
        'application/json', 'json');
  }

  static Future<ExportOutcome> exportPondLogsCsv() {
    final repo = PondRepository.instance;
    final rows = <List<Object?>>[];
    for (final p in repo.allPonds()) {
      for (final l in repo.logsFor(p.id).reversed) {
        rows.add([
          BackupCodec.fileDate(l.date),
          p.name,
          p.speciesLabel,
          BackupCodec.numText(l.feedKg),
          l.deadCount,
          l.waterColor?.label ?? '',
          l.behavior?.label ?? '',
          l.note,
        ]);
      }
    }
    final text = BackupCodec.csv(
      ['তারিখ', 'পুকুর', 'মাছ', 'খাবার (কেজি)', 'মরা মাছ', 'পানির রং', 'মাছের আচরণ', 'নোট'],
      rows,
    );
    return _deliver('pukurer-hisab-${BackupCodec.fileDate(DateTime.now())}.csv', text,
        'text/csv', 'csv');
  }

  static Future<ExportOutcome> exportReportsCsv() {
    final rows = [
      for (final r in DiseaseReportRepository.instance.all().reversed)
        [
          BackupCodec.fileDate(r.date),
          r.kind.title,
          r.subject,
          r.symptomLabels.join(' + '),
          [for (final x in r.results) '${x.name} (${x.likelihood.label})'].join(' | '),
        ],
    ];
    final text = BackupCodec.csv(
        ['তারিখ', 'চেক', 'পুকুর / ফসল', 'লক্ষণ', 'সম্ভাব্য সমস্যা (সম্ভাবনা)'], rows);
    return _deliver('rog-check-${BackupCodec.fileDate(DateTime.now())}.csv', text,
        'text/csv', 'csv');
  }

  static Future<ExportOutcome> _deliver(
      String name, String text, String mime, String ext) async {
    if (PlatformInfo.isDesktop) {
      final loc = await getSaveLocation(
        suggestedName: name,
        acceptedTypeGroups: [XTypeGroup(label: ext, extensions: [ext])],
      );
      if (loc == null) return ExportOutcome.cancelled;
      await File(loc.path).writeAsString(text, flush: true);
      return ExportOutcome.done;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(text, flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: mime, name: name)]);
    return ExportOutcome.done;
  }

  /// Opens a backup file and adds what is new. Never deletes anything.
  /// Returns null if cancelled; throws [FormatException] for a wrong file.
  static Future<ImportResult?> importBackup() async {
    final XFile? file = await openFile(
      // Phones often label .json from WhatsApp as "unknown", so no filter there.
      acceptedTypeGroups: PlatformInfo.isDesktop
          ? [const XTypeGroup(label: 'চাষিবন্ধু ব্যাকআপ', extensions: ['json'])]
          : const [],
    );
    if (file == null) return null;
    final data = BackupCodec.decode(await file.readAsString());

    var added = 0;
    for (final boxName in BackupCodec.boxes) {
      final box = LocalDb.box(boxName);
      final incoming = data.boxes[boxName] ?? const {};
      final toWrite = BackupCodec.newerRecords(box.toMap(), incoming);
      for (final e in toWrite.entries) {
        final rec = e.value;
        if (boxName == LocalDb.diseaseReports) {
          // Photo lives on the other device.
          final path = rec['photoPath'] as String?;
          if (path != null && !File(path).existsSync()) rec['photoPath'] = null;
        }
        if (boxName == LocalDb.reminders) {
          rec['notificationId'] = await AppSettings.nextNotificationId();
        }
        await box.put(e.key, rec);
        await SyncOutbox.upsert(boxName, e.key);
        added++;
      }
    }

    // Area / officer numbers: only fill what this device does not have yet.
    for (final k in BackupCodec.settingKeys) {
      final v = data.settings[k];
      final cur = AppSettings.get(k);
      if (v != null && (cur == null || (cur is String && cur.isEmpty))) {
        await AppSettings.put(k, v);
      }
    }

    await ReminderRepository.instance.rescheduleAll();
    return ImportResult(added, data.total - added);
  }
}
