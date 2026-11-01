/// One row in the price table: price per kg (taka), market name, date.
class MarketPrice {
  const MarketPrice({
    required this.itemId,
    required this.label,
    required this.emoji,
    required this.pricePerKg,
    required this.market,
    required this.date,
  });

  final String itemId;
  final String label;
  final String emoji;
  final double pricePerKg;
  final String market;
  final DateTime date;

  Map<String, dynamic> toMap() => {
        'id': itemId,
        'label': label,
        'emoji': emoji,
        'price': pricePerKg,
        'market': market,
        'date': date.toIso8601String().substring(0, 10),
      };

  factory MarketPrice.fromMap(Map<dynamic, dynamic> m) => MarketPrice(
        itemId: m['id'] as String,
        label: (m['label'] as String?) ?? '',
        emoji: (m['emoji'] as String?) ?? '🛒',
        pricePerKg: (m['price'] as num?)?.toDouble() ?? 0,
        market: (m['market'] as String?) ?? '',
        date: DateTime.tryParse((m['date'] as String?) ?? '') ?? DateTime(2000),
      );
}

class MarketPriceSet {
  const MarketPriceSet({required this.items, required this.sample, required this.source});

  final List<MarketPrice> items;

  /// true = example numbers, not real prices. The screen shows a warning.
  final bool sample;

  /// 'asset' | 'supabase' | later: an official price API.
  final String source;

  Map<String, dynamic> toMap() => {
        'sample': sample,
        'source': source,
        'items': [for (final i in items) i.toMap()],
      };

  factory MarketPriceSet.fromMap(Map<dynamic, dynamic> m) => MarketPriceSet(
        sample: m['sample'] == true,
        source: (m['source'] as String?) ?? 'asset',
        items: [
          for (final i in (m['items'] as List<dynamic>? ?? const []))
            if (i is Map) MarketPrice.fromMap(i),
        ],
      );
}

/// Where prices come from. Add a new source (e.g. an official API, with
/// permission) without touching the screen.
abstract class MarketPriceSource {
  /// Returns null if not available (offline, not configured).
  Future<MarketPriceSet?> fetch();
}
