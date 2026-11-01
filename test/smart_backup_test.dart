import 'package:chashibondhu/core/domain/fish_species.dart';
import 'package:chashibondhu/core/domain/signal.dart';
import 'package:chashibondhu/features/backup/backup_codec.dart';
import 'package:chashibondhu/features/biosecurity/biosecurity.dart';
import 'package:chashibondhu/features/disease/common/disease_library.dart';
import 'package:chashibondhu/features/disease/common/disease_matcher.dart';
import 'package:chashibondhu/features/disease/common/disease_report.dart';
import 'package:chashibondhu/features/pond/data/pond.dart';
import 'package:chashibondhu/features/pond/data/pond_log.dart';
import 'package:chashibondhu/features/reminders/reminder.dart';
import 'package:chashibondhu/features/smart/smart_rules.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 10, 18, 0); // Tuesday, 6 pm

Pond _pond({
  DateTime? stock,
  DateTime? updated,
  FishSpecies species = FishSpecies.pangas,
  int count = 1000,
  double weight = 100,
}) =>
    Pond(
      id: 'p1',
      name: 'বাড়ির পুকুর',
      areaShotok: 33,
      species: species,
      stockCount: count,
      stockDate: stock ?? DateTime(2026, 10, 1),
      avgWeightG: weight,
      createdAt: DateTime(2026, 10, 1),
      updatedAt: updated ?? DateTime(2026, 11, 5),
    );

PondLog _log(int daysAgo, {double feed = 3, int dead = 0}) {
  final d = DateTime(_now.year, _now.month, _now.day - daysAgo);
  return PondLog(
      id: 'l$daysAgo', pondId: 'p1', date: d, feedKg: feed, deadCount: dead,
      createdAt: d, updatedAt: d);
}

List<Insight> _run({
  Pond? pond,
  List<PondLog> logs = const [],
  List<DiseaseReport> reports = const [],
  List<Reminder> reminders = const [],
  BioCheck? bio,
  DateTime? now,
}) {
  final p = pond ?? _pond();
  return SmartRules.build(SmartInputs(
    now: now ?? _now,
    ponds: [PondSnapshot(pond: p, logs: logs, currentStock: p.stockCount)],
    reports: reports,
    reminders: reminders,
    thisWeekBio: bio,
  ));
}

bool _has(List<Insight> l, String part) => l.any((i) => i.title.contains(part));

void main() {
  group('Smart rules', () {
    test('all fine -> no urgent items', () {
      final l = _run(logs: [_log(0), _log(1), _log(2)]);
      expect(l.where((i) => i.signal != Signal.ok), isEmpty);
    });

    test('no log for 3+ days -> warn', () {
      expect(_has(_run(logs: [_log(4)]), 'হিসাব লেখা হয়নি'), isTrue);
    });

    test('no log today, evening -> gentle tip only', () {
      final l = _run(logs: [_log(1)]);
      final i = l.firstWhere((i) => i.title.contains('আজকের হিসাব'));
      expect(i.signal, Signal.ok);
    });

    test('dead fish rising -> warn, many dead -> danger', () {
      final rising = _run(logs: [_log(0, dead: 4), _log(1, dead: 3), _log(4, dead: 1)]);
      expect(rising.firstWhere((i) => i.title.contains('মরা মাছ বাড়ছে')).signal, Signal.warn);

      final many = _run(logs: [_log(0, dead: 20), _log(1, dead: 15)]);
      expect(many.first.signal, Signal.danger);
      expect(many.first.action, InsightAction.waterCheck);
    });

    test('over-feeding vs calculator (1000 pangas × 100 g needs 3 kg)', () {
      expect(_has(_run(logs: [_log(0, feed: 5)]), 'খাবার বেশি'), isTrue);
      expect(_has(_run(logs: [_log(0, feed: 3.5)]), 'খাবার বেশি'), isFalse);
    });

    test('weight not updated for 15+ days -> tip', () {
      final l = _run(pond: _pond(updated: DateTime(2026, 10, 1)), logs: [_log(0)]);
      expect(l.firstWhere((i) => i.title.contains('ওজন বদলান')).signal, Signal.ok);
    });

    test('harvest within 14 days -> tip (tilapia 120 days)', () {
      final p = _pond(species: FishSpecies.tilapia, stock: DateTime(2026, 7, 20));
      expect(_has(_run(pond: p, logs: [_log(0)]), 'মাছ ধরার সময়'), isTrue);
      final far = _pond(species: FishSpecies.tilapia, stock: DateTime(2026, 10, 20));
      expect(_has(_run(pond: far, logs: [_log(0)]), 'মাছ ধরার সময়'), isFalse);
    });

    test('recent "high" disease report -> warn', () {
      final r = DiseaseReport(
        id: 'r1',
        kind: DiseaseKind.fish,
        pondName: 'বাড়ির পুকুর',
        date: DateTime(2026, 11, 9),
        symptomIds: const ['ulcer'],
        symptomLabels: const ['গায়ে ঘা / ক্ষত'],
        results: const [
          ReportResult(problemId: 'eus', name: 'ক্ষত রোগ (ইইউএস)', likelihood: Likelihood.high)
        ],
        createdAt: DateTime(2026, 11, 9),
      );
      final l = _run(logs: [_log(0)], reports: [r]);
      expect(l.firstWhere((i) => i.action == InsightAction.diseaseReport).targetId, 'r1');
    });

    test('low biosecurity score -> warn', () {
      final bio = BioCheck(
          id: 'b', weekStart: DateTime(2026, 11, 7), ticked: const {'disinfect'},
          updatedAt: _now);
      expect(_has(_run(logs: [_log(0)], bio: bio), 'জীবাণু-নিরাপত্তা'), isTrue);
    });

    test('due and overdue reminders show up (PC has no phone alert)', () {
      Reminder r(ReminderType t, DateTime due) => Reminder(
          id: t.name, type: t, dueAt: due, notificationId: 1,
          createdAt: _now, updatedAt: _now);
      final l = _run(logs: [_log(0)], reminders: [
        r(ReminderType.feed, DateTime(2026, 11, 1, 8)), // daily 8 am, now 6 pm -> due
        r(ReminderType.lime, DateTime(2026, 11, 8, 7)), // 2 days ago -> overdue
        r(ReminderType.net, DateTime(2026, 11, 20, 7)), // future -> not shown
      ]);
      final rem = l.where((i) => i.action == InsightAction.reminders).toList();
      expect(rem.length, 2);
      expect(rem.any((i) => i.title.contains('সময় পার')), isTrue);
    });

    test('urgent items come first', () {
      final l = _run(
          pond: _pond(updated: DateTime(2026, 10, 1)),
          logs: [_log(0, dead: 20, feed: 6), _log(1, dead: 15)]);
      expect(l.first.signal, Signal.danger);
      expect(l.last.signal, Signal.ok);
    });
  });

  group('Backup file', () {
    test('round trip keeps records and settings', () {
      final text = BackupCodec.encode(
        data: {
          'ponds': {
            'p1': {'id': 'p1', 'name': 'পুকুর', 'updatedAt': 5}
          },
          'pond_logs': <dynamic, dynamic>{},
        },
        settings: {'districtId': 'mymensingh'},
        at: DateTime(2026, 11, 2),
      );
      final d = BackupCodec.decode(text);
      expect(d.boxes['ponds']!['p1']!['name'], 'পুকুর');
      expect(d.boxes['reminders'], isEmpty);
      expect(d.settings['districtId'], 'mymensingh');
      expect(d.total, 1);
    });

    test('wrong file is refused', () {
      expect(() => BackupCodec.decode('{"hello": 1}'), throwsFormatException);
      expect(() => BackupCodec.decode('not json'), throwsFormatException);
    });

    test('import keeps the newer copy', () {
      final existing = {
        'a': {'id': 'a', 'updatedAt': 10},
        'b': {'id': 'b', 'updatedAt': 10},
      };
      final incoming = {
        'a': {'id': 'a', 'updatedAt': 5}, // older -> skip
        'b': {'id': 'b', 'updatedAt': 20}, // newer -> write
        'c': {'id': 'c', 'createdAt': 1}, // new -> write
      };
      expect(BackupCodec.newerRecords(existing, incoming).keys, ['b', 'c']);
    });

    test('CSV: BOM for Excel, commas and quotes escaped', () {
      final c = BackupCodec.csv(['ক', 'খ'], [
        ['১, ২', 'বলল "হ্যাঁ"']
      ]);
      expect(c.startsWith('﻿'), isTrue);
      expect(c, contains('"১, ২","বলল ""হ্যাঁ"""'));
      expect(BackupCodec.numText(2.5), '2.5');
    });
  });
}
