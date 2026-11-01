import 'package:hive_flutter/hive_flutter.dart';

/// Local offline database (Hive). Records are stored as plain maps keyed by
/// their uuid, so there is no code generation and adding a field later is safe
/// (old records just read the default).
class LocalDb {
  LocalDb._();

  static const ponds = 'ponds';
  static const pondLogs = 'pond_logs';
  static const diseaseReports = 'disease_reports';
  static const reminders = 'reminders';
  static const biosecurity = 'biosecurity_checks';
  static const marketPrices = 'market_prices';
  static const syncOutbox = 'sync_outbox';
  static const settings = 'settings';

  /// Farmer's own records. "Clear offline data" empties these.
  static const dataBoxes = [
    ponds,
    pondLogs,
    diseaseReports,
    reminders,
    biosecurity,
    marketPrices,
    syncOutbox,
  ];

  static Future<void> init() async {
    await Hive.initFlutter('chashibondhu');
    await Future.wait([
      for (final name in [...dataBoxes, settings]) Hive.openBox<dynamic>(name),
    ]);
  }

  static Box<dynamic> box(String name) => Hive.box<dynamic>(name);
}
