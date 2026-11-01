import '../../../core/domain/fish_species.dart';

class Pond {
  const Pond({
    required this.id,
    required this.name,
    required this.areaShotok,
    required this.species,
    required this.stockCount,
    required this.stockDate,
    required this.avgWeightG,
    required this.createdAt,
    required this.updatedAt,
    this.customSpecies = '',
  });

  final String id;
  final String name;

  /// আয়তন, শতক
  final double areaShotok;
  final FishSpecies species;

  /// মজুদ সংখ্যা (number released)
  final int stockCount;

  /// ছাড়ার তারিখ
  final DateTime stockDate;

  /// গড় ওজন, গ্রাম
  final double avgWeightG;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Name typed by the farmer when [species] is "অন্য মাছ".
  final String customSpecies;

  /// What to show: the typed name for "অন্য মাছ", else the species name.
  String get speciesLabel =>
      species == FishSpecies.other && customSpecies.trim().isNotEmpty
          ? customSpecies.trim()
          : species.label;

  Pond copyWith({
    String? name,
    double? areaShotok,
    FishSpecies? species,
    int? stockCount,
    DateTime? stockDate,
    double? avgWeightG,
    DateTime? updatedAt,
    String? customSpecies,
  }) {
    return Pond(
      id: id,
      name: name ?? this.name,
      areaShotok: areaShotok ?? this.areaShotok,
      species: species ?? this.species,
      stockCount: stockCount ?? this.stockCount,
      stockDate: stockDate ?? this.stockDate,
      avgWeightG: avgWeightG ?? this.avgWeightG,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customSpecies: customSpecies ?? this.customSpecies,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'areaShotok': areaShotok,
        'species': species.name,
        'stockCount': stockCount,
        'stockDate': stockDate.millisecondsSinceEpoch,
        'avgWeightG': avgWeightG,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'customSpecies': customSpecies,
      };

  factory Pond.fromMap(Map<dynamic, dynamic> m) {
    DateTime date(String key) =>
        DateTime.fromMillisecondsSinceEpoch((m[key] as num?)?.toInt() ?? 0);
    return Pond(
      id: m['id'] as String,
      name: (m['name'] as String?) ?? '',
      areaShotok: (m['areaShotok'] as num?)?.toDouble() ?? 0,
      species: FishSpecies.fromKey(m['species'] as String?) ?? FishSpecies.rui,
      stockCount: (m['stockCount'] as num?)?.toInt() ?? 0,
      stockDate: date('stockDate'),
      avgWeightG: (m['avgWeightG'] as num?)?.toDouble() ?? 0,
      createdAt: date('createdAt'),
      updatedAt: date('updatedAt'),
      customSpecies: (m['customSpecies'] as String?) ?? '',
    );
  }
}
