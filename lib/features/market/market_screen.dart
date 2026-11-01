import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bangla.dart';
import 'market_price.dart';
import 'market_price_repository.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  MarketPriceSet? _set;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = MarketPriceRepository.instance;
    final local = await repo.current();
    if (mounted) setState(() => _set = local);
    final fresh = await repo.refresh();
    if (mounted) setState(() => _set = fresh);
  }

  @override
  Widget build(BuildContext context) {
    final set = _set;
    return Scaffold(
      appBar: AppBar(title: const Text('বাজার দর'), backgroundColor: AppColors.cardWeather),
      body: set == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (set.sample)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warnBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.warn, width: 2),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.warnText, size: 30),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('এগুলো নমুনা দর, আসল দর নয়। বিক্রির আগে বাজারে জেনে নিন।',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warnText)),
                          ),
                        ],
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text('পণ্য',
                                style: TextStyle(fontSize: 16, color: AppColors.textMuted))),
                        Text('দাম / কেজি',
                            style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  for (final p in set.items) _PriceRow(price: p),
                ],
              ),
            ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.price});

  final MarketPrice price;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Text(price.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(price.label,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                Text('${price.market} · ${Bn.date(price.date)}',
                    style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text('৳${Bn.number(price.pricePerKg, maxDecimals: 0)}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
