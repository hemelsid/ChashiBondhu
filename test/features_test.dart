import 'dart:convert';
import 'dart:io';

import 'package:chashibondhu/core/domain/fish_species.dart';
import 'package:chashibondhu/core/domain/signal.dart';
import 'package:chashibondhu/core/sync/sync_tables.dart';
import 'package:chashibondhu/features/biosecurity/biosecurity.dart';
import 'package:chashibondhu/features/disease/common/disease_library.dart';
import 'package:chashibondhu/features/disease/common/disease_matcher.dart';
import 'package:chashibondhu/features/pond/data/pond_log.dart';
import 'package:chashibondhu/features/pond/ui/pond_charts.dart';
import 'package:chashibondhu/features/reminders/reminder.dart';
import 'package:chashibondhu/features/weather/weather_models.dart';
import 'package:flutter_test/flutter_test.dart';

DiseaseLibrary _lib(DiseaseKind kind) => DiseaseLibrary.fromJson(
      kind,
      jsonDecode(File(kind.asset).readAsStringSync()) as Map<String, dynamic>,
    );

void main() {
  group('Disease libraries', () {
    final fish = _lib(DiseaseKind.fish);
    final crop = _lib(DiseaseKind.crop);

    test('sizes and links are correct', () {
      expect(fish.problems.length, 15);
      expect(fish.symptoms.length, 10);
      expect(crop.problems.length, greaterThanOrEqualTo(16));
      expect(crop.crops.take(7).map((c) => c.id),
          ['dhan', 'alu', 'morich', 'begun', 'lau', 'tomato', 'peyaj']);
      expect(crop.crops.length, greaterThanOrEqualTo(15));
      // Every crop has at least one problem to check.
      for (final c in crop.crops) {
        expect(crop.problems.any((p) => p.crops.contains(c.id)), isTrue, reason: c.id);
      }
      for (final lib in [fish, crop]) {
        for (final p in lib.problems) {
          for (final s in p.weights.keys) {
            expect(lib.symptom(s), isNotNull, reason: '${p.id} uses unknown $s');
          }
          expect(p.korben, isNotEmpty);
          expect(p.korbenNa, isNotEmpty);
          expect(p.officer, isNotEmpty);
        }
      }
    });

    test('safety: no doses or medicine names in the libraries', () {
      final text = File(DiseaseKind.fish.asset).readAsStringSync() +
          File(DiseaseKind.crop.asset).readAsStringSync();
      for (final banned in ['mg', 'ml', 'ppm', 'মিলি', 'টেট্রা', 'ফুরাডান', 'কার্বোফুরান']) {
        expect(text.contains(banned), isFalse, reason: 'found "$banned"');
      }
    });

    test('ulcer -> EUS first, likely high', () {
      final m = DiseaseMatcher.match(fish, {'ulcer'});
      expect(m.first.problem.id, 'eus');
      expect(m.first.likelihood, Likelihood.high);
      expect(m.length, lessThanOrEqualTo(3));
    });

    test('only the first result can be "high"', () {
      final m = DiseaseMatcher.match(fish, {'floating', 'water_smell'});
      expect(m.skip(1).every((x) => x.likelihood == Likelihood.medium), isTrue);
    });

    test('a tie stays "medium" (we cannot tell)', () {
      // brown spot alone fits blast and brown-spot equally.
      final m = DiseaseMatcher.match(crop, {'brown_spot'}, cropId: 'dhan');
      expect(m.every((x) => x.likelihood == Likelihood.medium), isTrue);
    });

    test('crop filter: brinjal borer only for begun', () {
      final begun = DiseaseMatcher.match(crop, {'fruit_rot', 'insect'}, cropId: 'begun');
      expect(begun.first.problem.id, 'brinjal_borer');
      final dhan = DiseaseMatcher.match(crop, {'fruit_rot', 'insect'}, cropId: 'dhan');
      expect(dhan.any((x) => x.problem.id == 'brinjal_borer'), isFalse);
    });

    test('nothing ticked -> no results', () {
      expect(DiseaseMatcher.match(fish, {}), isEmpty);
    });
  });

  group('Weather', () {
    test('parses Open-Meteo daily block', () {
      final f = WeatherForecast.fromOpenMeteo({
        'daily': {
          'time': ['2026-11-01', '2026-11-02', '2026-11-03'],
          'weather_code': [0, 61, 95],
          'temperature_2m_max': [30.1, 28.0, 27.5],
          'temperature_2m_min': [22.0, 21.5, 21.0],
          'precipitation_probability_max': [5, 80, null],
          'wind_gusts_10m_max': [12.0, 30.0, 70.0],
        }
      }, 'dhaka', DateTime(2026, 11, 1));
      expect(f.days.length, 3);
      expect(f.days[1].rainChance, 80);
      expect(f.days[2].rainChance, 0); // null -> 0
      expect(f.days[2].storm, Signal.danger);
      expect(WeatherForecast.fromMap(f.toMap()).days[1].code, 61);
    });

    DayForecast day({int code = 0, double tMax = 30, double tMin = 22, int rain = 10, double gust = 10}) =>
        DayForecast(
            date: DateTime(2026, 11, 1),
            tMax: tMax,
            tMin: tMin,
            rainChance: rain,
            gustKmh: gust,
            code: code);

    test('tip priority: storm > rain > heat > cold > ok', () {
      expect(WeatherRules.tip([day(gust: 80), day(rain: 90)]).signal, Signal.danger);
      expect(WeatherRules.tip([day(rain: 75)]).title, 'বৃষ্টির আগে');
      expect(WeatherRules.tip([day(tMax: 36)]).title, 'গরমের আগে');
      expect(WeatherRules.tip([day(tMin: 12)]).title, 'ঠান্ডার আগে');
      expect(WeatherRules.tip([day()]).signal, Signal.ok);
    });
  });

  group('Biosecurity', () {
    test('score and colours', () {
      expect(BioRules.score({}), 0);
      expect(BioRules.score({'disinfect', 'quarantine', 'dead_fish'}), 50);
      expect(BioRules.score(kBioItems.map((i) => i.id).toSet()), 100);
      expect(BioRules.signal(100), Signal.ok);
      expect(BioRules.signal(67), Signal.warn);
      expect(BioRules.signal(33), Signal.danger);
    });

    test('week starts on Saturday', () {
      // 2026-11-01 is a Sunday -> week started Saturday 31 Oct.
      expect(BioRules.weekStart(DateTime(2026, 11, 1, 15)), DateTime(2026, 10, 31));
      expect(BioRules.weekStart(DateTime(2026, 10, 31)), DateTime(2026, 10, 31));
      expect(BioRules.weekStart(DateTime(2026, 11, 6)), DateTime(2026, 10, 31));
    });
  });

  group('Reminders', () {
    test('harvest estimate from stocking date', () {
      final now = DateTime(2026, 11, 1);
      expect(estimateHarvest(FishSpecies.tilapia, DateTime(2026, 10, 1), now: now),
          DateTime(2027, 1, 29));
      // Already past -> one week from now.
      expect(estimateHarvest(FishSpecies.tilapia, DateTime(2025, 1, 1), now: now),
          DateTime(2026, 11, 8));
    });

    test('daily reminder is done only for today', () {
      final r = Reminder(
        id: 'x',
        type: ReminderType.feed,
        dueAt: DateTime(2026, 11, 1, 8),
        notificationId: 1,
        doneDay: dayKey(DateTime(2026, 11, 1)),
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );
      expect(r.isDone(now: DateTime(2026, 11, 1, 20)), isTrue);
      expect(r.isDone(now: DateTime(2026, 11, 2, 7)), isFalse);
    });
  });

  group('Charts', () {
    PondLog log(DateTime d, double feed, int dead) => PondLog(
        id: '$d$feed',
        pondId: 'p',
        date: d,
        feedKg: feed,
        deadCount: dead,
        createdAt: d,
        updatedAt: d);

    test('daily totals: same day summed, oldest first, last 14 days', () {
      final logs = [
        log(DateTime(2026, 10, 2), 2, 1),
        log(DateTime(2026, 10, 1), 1, 0),
        log(DateTime(2026, 10, 2), 3, 4),
      ];
      final t = dailyTotals(logs);
      expect(t.length, 2);
      expect(t.first.date, DateTime(2026, 10, 1));
      expect(t.last.feedKg, 5);
      expect(t.last.dead, 5);

      final many = [for (var i = 1; i <= 20; i++) log(DateTime(2026, 9, i), 1, 0)];
      expect(dailyTotals(many).length, 14);
      expect(dailyTotals(many).first.date, DateTime(2026, 9, 7));
    });
  });

  group('Sync mapping', () {
    test('pond log becomes a Supabase row', () {
      final row = kSyncTables['pond_logs']!.toRemote({
        'id': 'l1',
        'pondId': 'p1',
        'date': DateTime(2026, 11, 1).millisecondsSinceEpoch,
        'feedKg': 2.5,
        'deadCount': 3,
        'waterColor': 'lightGreen',
        'behavior': 'normal',
        'note': '',
        'createdAt': 0,
        'updatedAt': 0,
      }, 'user-1');
      expect(row['owner_id'], 'user-1');
      expect(row['pond_id'], 'p1');
      expect(row['log_date'], '2026-11-01');
      expect(row['feed_kg'], 2.5);
    });

    test('tables are ordered parents first', () {
      expect(kSyncTables['ponds']!.order, lessThan(kSyncTables['pond_logs']!.order));
      expect(kSyncTables.keys, containsAll(
          ['users', 'ponds', 'pond_logs', 'disease_reports', 'reminders', 'biosecurity_checks']));
    });
  });
}
