import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/remote/remote_data.dart';
import '../../core/storage/local_db.dart';
import '../../core/sync/sync_manager.dart';
import 'market_price.dart';

/// Bundled JSON (inside the app — works with no internet).
class AssetMarketPriceSource implements MarketPriceSource {
  const AssetMarketPriceSource();

  @override
  Future<MarketPriceSet?> fetch() async {
    final text = await RemoteData.asset('market_prices.json');
    final m = jsonDecode(text) as Map<String, dynamic>;
    return MarketPriceSet.fromMap({...m, 'source': 'asset'});
  }
}

/// The same file on GitHub, downloaded by [RemoteData]. Edit
/// assets/data/market_prices.json on GitHub and every app gets it.
class GithubMarketPriceSource implements MarketPriceSource {
  const GithubMarketPriceSource();

  /// Used by RemoteData to accept a downloaded file.
  static bool isValid(String text) {
    try {
      final set = MarketPriceSet.fromMap(jsonDecode(text) as Map<String, dynamic>);
      return set.items.isNotEmpty && set.items.every((i) => i.pricePerKg >= 0);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<MarketPriceSet?> fetch() async {
    final text = RemoteData.text('market_prices.json');
    if (text == null || !isValid(text)) return null;
    final m = jsonDecode(text) as Map<String, dynamic>;
    return MarketPriceSet.fromMap({...m, 'source': 'online'});
  }
}

/// Supabase `market_prices` table, filled by an admin. Latest row per item.
class SupabaseMarketPriceSource implements MarketPriceSource {
  const SupabaseMarketPriceSource();

  @override
  Future<MarketPriceSet?> fetch() async {
    final client = SyncManager.instance.client;
    if (client == null) return null;
    final rows = await client
        .from('market_prices')
        .select()
        .order('price_date', ascending: false)
        .limit(200);
    final latest = <String, MarketPrice>{};
    for (final r in rows) {
      final id = r['item_id'] as String?;
      if (id == null || latest.containsKey(id)) continue;
      latest[id] = MarketPrice(
        itemId: id,
        label: (r['label'] as String?) ?? id,
        emoji: (r['emoji'] as String?) ?? '🛒',
        pricePerKg: (r['price_per_kg'] as num?)?.toDouble() ?? 0,
        market: (r['market'] as String?) ?? '',
        date: DateTime.tryParse('${r['price_date']}') ?? DateTime.now(),
      );
    }
    if (latest.isEmpty) return null;
    return MarketPriceSet(items: latest.values.toList(), sample: false, source: 'supabase');
  }
}

class MarketPriceRepository {
  MarketPriceRepository._();

  static final MarketPriceRepository instance = MarketPriceRepository._();

  /// Tried in order on refresh; first non-empty wins.
  final List<MarketPriceSource> remoteSources = const [
    SupabaseMarketPriceSource(),
    GithubMarketPriceSource(),
  ];

  Box<dynamic> get _box => LocalDb.box(LocalDb.marketPrices);

  /// Saved prices, or the bundled sample if nothing saved yet.
  Future<MarketPriceSet> current() async {
    final m = _box.get('current');
    if (m is Map) return MarketPriceSet.fromMap(m);
    return await const GithubMarketPriceSource().fetch() ??
        (await const AssetMarketPriceSource().fetch())!;
  }

  /// Tries online sources; keeps the old prices if offline.
  Future<MarketPriceSet> refresh() async {
    for (final source in remoteSources) {
      try {
        final set = await source.fetch();
        if (set != null && set.items.isNotEmpty) {
          await _box.put('current', set.toMap());
          return set;
        }
      } catch (_) {
        // offline or not configured — fall through
      }
    }
    return current();
  }
}
