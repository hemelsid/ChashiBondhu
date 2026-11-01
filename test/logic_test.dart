import 'package:chashibondhu/core/domain/fish_species.dart';
import 'package:chashibondhu/core/domain/signal.dart';
import 'package:chashibondhu/core/utils/bangla.dart';
import 'package:chashibondhu/features/feed/feed_calculator.dart';
import 'package:chashibondhu/features/pond/data/pond_log.dart';
import 'package:chashibondhu/features/water/water_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bangla helpers', () {
    test('digits both ways', () {
      expect(Bn.digits(2026), '২০২৬');
      expect(Bn.parse('১২.৫'), 12.5);
      expect(Bn.parse('1২'), 12);
      expect(Bn.parse(''), isNull);
      expect(Bn.parseInt('১০,০০০'), 10000);
      expect(Bn.parseInt('২.৫'), isNull);
    });

    test('number, count, weight', () {
      expect(Bn.number(2.50), '২.৫');
      expect(Bn.number(3.0), '৩');
      expect(Bn.count(12000), '১২,০০০');
      expect(Bn.weight(0.25), '২৫০ গ্রাম');
      expect(Bn.weight(2.5), '২.৫ কেজি');
    });

    test('relative date', () {
      final now = DateTime(2026, 11, 1, 10);
      expect(Bn.relativeDate(DateTime(2026, 11, 1), now: now), 'আজ');
      expect(Bn.relativeDate(DateTime(2026, 10, 31), now: now), 'গতকাল');
      expect(Bn.relativeDate(DateTime(2026, 10, 1), now: now), '১ অক্টোবর ২০২৬');
    });
  });

  group('Feed calculator', () {
    test('1000 pangas at 100 g -> 100 kg fish, 3% = 3 kg/day', () {
      final r = FeedCalculator.calculate(
          species: FishSpecies.pangas, count: 1000, avgWeightG: 100);
      expect(r.biomassKg, closeTo(100, 0.001));
      expect(r.ratePercent, 3);
      expect(r.dailyKg, closeTo(3, 0.001));
      expect(r.morningKg + r.eveningKg, closeTo(r.dailyKg, 0.0001));
      expect(r.morningKg, closeTo(1.5, 0.001));
    });

    test('carps get a lower rate than pangas at same size', () {
      expect(FeedCalculator.ratePercent(FishSpecies.rui, 100),
          lessThan(FeedCalculator.ratePercent(FishSpecies.pangas, 100)));
    });

    test('small fish eat a higher % than big fish', () {
      expect(FeedCalculator.ratePercent(FishSpecies.tilapia, 3),
          greaterThan(FeedCalculator.ratePercent(FishSpecies.tilapia, 300)));
    });

    test('shrimp get more feed in the evening', () {
      final r = FeedCalculator.calculate(
          species: FishSpecies.chingri, count: 5000, avgWeightG: 20);
      expect(r.eveningKg, greaterThan(r.morningKg));
    });
  });

  group('Water rules', () {
    test('all good -> green', () {
      final r = WaterRules.check(ph: 7.5, oxygen: 6, ammonia: 0.1, temperature: 29);
      expect(r.overall, Signal.ok);
    });

    test('low oxygen -> red', () {
      final r = WaterRules.check(oxygen: 2);
      expect(r.overall, Signal.danger);
      expect(r.results.single.actions, isNotEmpty);
    });

    test('slightly acidic -> yellow', () {
      expect(WaterRules.check(ph: 6.2).overall, Signal.warn);
    });

    test('moderate ammonia becomes red when pH is high', () {
      expect(WaterRules.check(ammonia: 0.3).overall, Signal.warn);
      expect(WaterRules.check(ammonia: 0.3, ph: 8.8).overall, Signal.danger);
    });

    test('worst problems listed first', () {
      final r = WaterRules.check(ph: 7.5, temperature: 37);
      expect(r.results.first.param, WaterParam.temperature);
    });

    test('typing mistakes are caught', () {
      expect(WaterRules.isPlausible(WaterParam.ph, 75), isFalse);
      expect(WaterRules.isPlausible(WaterParam.ph, 7.5), isTrue);
    });
  });

  group('Daily log signal', () {
    test('dead fish thresholds', () {
      expect(PondLog.deadSignal(0, 1000), Signal.ok);
      expect(PondLog.deadSignal(3, 1000), Signal.warn);
      expect(PondLog.deadSignal(10, 1000), Signal.danger);
      expect(PondLog.deadSignal(30, 5000), Signal.warn);
      expect(PondLog.deadSignal(50, 5000), Signal.danger);
    });
  });
}
