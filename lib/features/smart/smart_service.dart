import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/storage/app_settings.dart';
import '../../core/storage/local_db.dart';
import '../biosecurity/biosecurity.dart';
import '../biosecurity/biosecurity_repository.dart';
import '../disease/common/disease_report_repository.dart';
import '../pond/data/pond_repository.dart';
import '../reminders/reminder_repository.dart';
import '../weather/weather_models.dart';
import '../weather/weather_service.dart';
import 'smart_rules.dart';

/// Gathers the farmer's offline records and runs [SmartRules].
class SmartService {
  SmartService._();

  /// Rebuild when any record changes.
  static Listenable get changes => Listenable.merge([
        PondRepository.instance.changes,
        DiseaseReportRepository.instance.changes,
        ReminderRepository.instance.changes,
        LocalDb.box(LocalDb.biosecurity).listenable(),
        AppSettings.listenable(),
      ]);

  static List<Insight> insights({DateTime? now}) {
    final at = now ?? DateTime.now();
    final pondRepo = PondRepository.instance;
    final ponds = [
      for (final p in pondRepo.allPonds())
        () {
          final s = pondRepo.summary(p);
          return PondSnapshot(pond: p, logs: s.logs, currentStock: s.currentStock);
        }(),
    ];

    return SmartRules.build(SmartInputs(
      now: at,
      ponds: ponds,
      reports: DiseaseReportRepository.instance.all(),
      reminders: ReminderRepository.instance.all(),
      thisWeekBio: BiosecurityRepository.instance.forWeek(BioRules.weekStart(at)),
      weatherTip: _weatherTip(at),
    ));
  }

  static WeatherTip? _weatherTip(DateTime now) {
    final id = AppSettings.districtId;
    if (id == null) return null;
    final f = WeatherService.cached(id);
    if (f == null || now.difference(f.fetchedAt).inHours > 48) return null;
    final today = DateTime(now.year, now.month, now.day);
    final ahead = f.days.where((d) => !d.date.isBefore(today)).toList();
    return ahead.isEmpty ? null : WeatherRules.tip(ahead);
  }
}
