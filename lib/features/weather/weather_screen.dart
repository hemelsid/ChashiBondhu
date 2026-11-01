import 'package:flutter/material.dart';

import '../../core/data/bd_districts.dart';
import '../../core/domain/signal.dart';
import '../../core/storage/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/signal_style.dart';
import '../../core/utils/bangla.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/signal_banner.dart';
import 'district_picker_screen.dart';
import 'weather_models.dart';
import 'weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  District? _district;
  WeatherForecast? _forecast;
  bool _loading = false;
  bool _fromCache = false;

  @override
  void initState() {
    super.initState();
    _district = districtById(AppSettings.districtId);
    final d = _district;
    if (d == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickDistrict());
    } else {
      _forecast = WeatherService.cached(d.id);
      _refresh();
    }
  }

  Future<void> _pickDistrict() async {
    final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const DistrictPickerScreen()));
    if (!mounted) return;
    if (saved == true) {
      setState(() {
        _district = districtById(AppSettings.districtId);
        _forecast = null;
      });
      _refresh();
    } else if (_district == null) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _refresh() async {
    final d = _district;
    if (d == null) return;
    setState(() => _loading = true);
    final r = await WeatherService.load(d);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _fromCache = r.fromCache;
      _forecast = r.forecast ?? _forecast;
    });
  }

  String _dayName(DateTime d) {
    final today = Bn.dateOnly(DateTime.now());
    final diff = Bn.dateOnly(d).difference(today).inDays;
    if (diff == 0) return 'আজ';
    if (diff == 1) return 'আগামীকাল';
    if (diff == 2) return 'পরশু';
    return Bn.date(d);
  }

  @override
  Widget build(BuildContext context) {
    final district = _district;
    final forecast = _forecast;
    final upazila = AppSettings.upazila;

    return Scaffold(
      appBar: AppBar(
        title: const Text('আবহাওয়া'),
        backgroundColor: AppColors.cardWeather,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (district != null)
              Row(
                children: [
                  const Icon(Icons.place, color: AppColors.cardWeather, size: 28),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      upazila.isEmpty ? district.name : '$upazila, ${district.name}',
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDistrict,
                    child: const Text('বদলান', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            if (_loading && forecast == null)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_loading && forecast == null && district != null)
              const _OfflineCard(),
            if (forecast != null) ...[
              if (_fromCache)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'ইন্টারনেট নেই — শেষ খবর: ${Bn.relativeDate(forecast.fetchedAt)}',
                    style: const TextStyle(fontSize: 16, color: AppColors.warnText),
                  ),
                ),
              Builder(builder: (_) {
                final tip = WeatherRules.tip(forecast.days);
                return SignalBanner(signal: tip.signal, title: tip.title, subtitle: tip.text);
              }),
              const SizedBox(height: 8),
              for (final d in forecast.days) _DayCard(day: d, name: _dayName(d.date)),
            ],
            const SizedBox(height: 16),
            BigButton(
              label: _loading ? 'আনা হচ্ছে…' : 'আবার দেখুন',
              icon: Icons.refresh,
              color: AppColors.cardWeather,
              onPressed: _loading ? null : _refresh,
            ),
            const SizedBox(height: 8),
            const Text('তথ্য: ওপেন-মেটিও। সরকারি সতর্ক সংকেতের জন্য রেডিও/টিভি শুনুন।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _OfflineCard extends StatelessWidget {
  const _OfflineCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(Icons.wifi_off, size: 80, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text('ইন্টারনেট নেই', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text('ইন্টারনেট চালু করে আবার দেখুন',
              style: TextStyle(fontSize: 18, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.name});

  final DayForecast day;
  final String name;

  @override
  Widget build(BuildContext context) {
    final storm = day.storm;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: storm == Signal.ok ? AppColors.border : storm.color, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(WeatherRules.emoji(day.code), style: const TextStyle(fontSize: 46)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(WeatherRules.label(day.code),
                        style: const TextStyle(fontSize: 17, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${Bn.number(day.tMax, maxDecimals: 0)}°',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  Text('রাতে ${Bn.number(day.tMin, maxDecimals: 0)}°',
                      style: const TextStyle(fontSize: 16, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Pill(
                  icon: Icons.water_drop,
                  color: AppColors.cardPond,
                  text: 'বৃষ্টি ${Bn.digits(day.rainChance)}%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Pill(
                  icon: storm.icon,
                  color: storm.textColor,
                  text: storm == Signal.ok
                      ? 'ঝড় নেই'
                      : storm == Signal.warn
                          ? 'ঝড়ো হাওয়া'
                          : 'ঝড় সতর্ক!',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        // withOpacity works on all Flutter 3.x (newer SDKs only mark it deprecated).
        // ignore: deprecated_member_use
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}
