import '../../core/domain/fish_species.dart';

class FeedResult {
  const FeedResult({
    required this.species,
    required this.count,
    required this.avgWeightG,
    required this.biomassKg,
    required this.ratePercent,
    required this.dailyKg,
    required this.morningKg,
    required this.eveningKg,
  });

  final FishSpecies species;
  final int count;
  final double avgWeightG;

  /// Total fish weight in the pond (kg).
  final double biomassKg;

  /// Feed per day as % of body weight.
  final double ratePercent;
  final double dailyKg;
  final double morningKg;
  final double eveningKg;
}

/// Daily feed = total fish weight × feeding rate (% of body weight).
///
/// Rates are general field guidelines for supplementary pellet feed and are
/// deliberately on the safe (lower) side, because over-feeding spoils water.
/// Tune the tables below with your fisheries expert — logic stays the same.
class FeedCalculator {
  FeedCalculator._();

  /// (upper weight limit in g, % body weight) — first match wins.
  static const List<(double, double)> fishTable = [
    (5, 10),
    (20, 7),
    (50, 5),
    (100, 4),
    (250, 3),
    (500, 2.5),
    (1000, 2),
    (double.infinity, 1.5),
  ];

  static const List<(double, double)> shrimpTable = [
    (5, 8),
    (15, 6),
    (30, 4),
    (50, 3),
    (double.infinity, 2.5),
  ];

  /// Carps (rui, katla, mrigel) also eat natural food in the pond.
  static const double carpFactor = 0.8;

  static double ratePercent(FishSpecies species, double avgWeightG) {
    final table = species == FishSpecies.chingri ? shrimpTable : fishTable;
    var rate = table.last.$2;
    for (final (limit, r) in table) {
      if (avgWeightG < limit) {
        rate = r;
        break;
      }
    }
    return species.isCarp ? rate * carpFactor : rate;
  }

  static FeedResult calculate({
    required FishSpecies species,
    required int count,
    required double avgWeightG,
  }) {
    final biomassKg = count * avgWeightG / 1000;
    final rate = ratePercent(species, avgWeightG);
    final daily = biomassKg * rate / 100;
    // Shrimp feed more at dusk; fish get two equal meals.
    final morningShare = species == FishSpecies.chingri ? 0.4 : 0.5;
    return FeedResult(
      species: species,
      count: count,
      avgWeightG: avgWeightG,
      biomassKg: biomassKg,
      ratePercent: rate,
      dailyKg: daily,
      morningKg: daily * morningShare,
      eveningKg: daily * (1 - morningShare),
    );
  }
}
