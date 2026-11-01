import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/data/bd_districts.dart';
import '../../core/remote/remote_data.dart';
import '../../core/storage/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bangla.dart';
import '../../core/utils/phone_call.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/signal_banner.dart';
import '../market/market_price.dart';
import '../market/market_price_repository.dart';
import '../market/market_screen.dart';
import '../weather/weather_models.dart';
import '../weather/weather_screen.dart';
import '../weather/weather_service.dart';
import 'briefing.dart';
import 'farm_calendar.dart';

WeatherTip? _savedWeatherTip() {
  final d = districtById(AppSettings.districtId);
  if (d == null) return null;
  final f = WeatherService.cached(d.id);
  if (f == null || DateTime.now().difference(f.fetchedAt).inHours > 48) return null;
  final today = Bn.dateOnly(DateTime.now());
  final ahead = f.days.where((x) => !x.date.isBefore(today)).toList();
  return ahead.isEmpty ? null : WeatherRules.tip(ahead);
}

/// One line on Home that changes every few seconds: weather tip, this
/// month's farm work, and the latest headlines. Tap → full briefing.
class HeadlineTicker extends StatefulWidget {
  const HeadlineTicker({super.key});

  @override
  State<HeadlineTicker> createState() => _HeadlineTickerState();
}

class _HeadlineTickerState extends State<HeadlineTicker> {
  List<(IconData, String)> _items = const [];
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    RemoteData.revision.addListener(_load);
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && _items.length > 1) setState(() => _i = (_i + 1) % _items.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    RemoteData.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final b = await Briefing.load();
    final month = FarmCalendar.forMonth(DateTime.now().month);
    final tip = _savedWeatherTip();
    final items = <(IconData, String)>[
      if (tip != null) (Icons.wb_sunny, '${tip.title}: ${tip.text}'),
      (Icons.calendar_month, 'এই মাসে: ${month.fish.first}'),
      for (final h in b.items.take(6)) (Icons.newspaper, h.title),
      (Icons.calendar_month, 'এই মাসে: ${month.crop.first}'),
    ];
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    final item = _items.isEmpty ? (Icons.newspaper, 'আজকের খবর ও তথ্য') : _items[_i % _items.length];
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const BriefingScreen())),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(item.$1, color: AppColors.cardWeather, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    item.$2,
                    key: ValueKey(_i),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 28, color: AppColors.textMuted),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// আজকের খবর ও তথ্য — briefing page.
class BriefingScreen extends StatefulWidget {
  const BriefingScreen({super.key});

  @override
  State<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends State<BriefingScreen> {
  late Future<Briefing> _briefing = Briefing.load();
  late final Future<MarketPriceSet> _prices = MarketPriceRepository.instance.current();

  Future<void> _refresh() async {
    await RemoteData.refresh(force: true);
    if (mounted) setState(() => _briefing = Briefing.load());
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = FarmCalendar.forMonth(now.month);
    final tip = _savedWeatherTip();

    return Scaffold(
      appBar: AppBar(title: const Text('খবর ও তথ্য'), backgroundColor: AppColors.cardWeather),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text('আজ ${Bn.date(now)}',
                style: const TextStyle(fontSize: 18, color: AppColors.textMuted)),

            // ---- Weather ----
            const SectionTitle('আবহাওয়া', icon: Icons.wb_sunny),
            if (tip != null)
              SignalBanner(signal: tip.signal, title: tip.title, subtitle: tip.text)
            else
              _ButtonRow(
                text: 'আবহাওয়ার খবর দেখতে চাপুন',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const WeatherScreen())),
              ),

            // ---- Prices ----
            const SectionTitle('বাজার দর', icon: Icons.storefront),
            FutureBuilder<MarketPriceSet>(
              future: _prices,
              builder: (context, snap) {
                final set = snap.data;
                if (set == null) return const SizedBox(height: 40);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (set.sample)
                      const Text('নমুনা দর — আসল দর নয়',
                          style: TextStyle(fontSize: 15, color: AppColors.warnText)),
                    for (final p in set.items.take(4))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(p.emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(p.label, style: const TextStyle(fontSize: 18))),
                            Text('৳${Bn.number(p.pricePerKg, maxDecimals: 0)}/কেজি',
                                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    _ButtonRow(
                      text: 'সব দর দেখুন',
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const MarketScreen())),
                    ),
                  ],
                );
              },
            ),

            // ---- Month ----
            SectionTitle('এই মাসের কাজ — ${month.name}', icon: Icons.calendar_month),
            _TipList(icon: Icons.set_meal, color: AppColors.cardPond, title: 'মাছ', tips: month.fish),
            const SizedBox(height: 8),
            _TipList(icon: Icons.spa, color: AppColors.primary, title: 'ফসল', tips: month.crop),

            // ---- News ----
            const SectionTitle('কৃষি খবর', icon: Icons.newspaper),
            FutureBuilder<Briefing>(
              future: _briefing,
              builder: (context, snap) {
                final b = snap.data;
                if (b == null) return const SizedBox(height: 40);
                if (b.items.isEmpty) {
                  return const Text('ইন্টারনেট চালু হলে এখানে খবর আসবে। নিচে টেনে হালনাগাদ করুন।',
                      style: TextStyle(fontSize: 17, color: AppColors.textMuted));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final h in b.items) _HeadlineCard(h: h),
                    if (b.updated != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('খবর হালনাগাদ: ${bnAgo(b.updated!)} · খবরে চাপলে মূল লেখা খুলবে',
                            style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ButtonRow extends StatelessWidget {
  const _ButtonRow({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        height: 52,
        child: OutlinedButton(onPressed: onTap, child: Text(text)),
      ),
    );
  }
}

class _TipList extends StatelessWidget {
  const _TipList({
    required this.icon,
    required this.color,
    required this.title,
    required this.tips,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: color)),
          ]),
          for (final t in tips)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(Icons.circle, size: 8, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t, style: const TextStyle(fontSize: 17, height: 1.35))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({required this.h});

  final Headline h;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (h.topic.isNotEmpty) h.topic,
      if (h.source.isNotEmpty) h.source,
      if (h.published != null) bnAgo(h.published!),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => openLink(context, h.url),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(meta, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
