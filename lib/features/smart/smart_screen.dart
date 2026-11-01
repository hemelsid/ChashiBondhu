import 'package:flutter/material.dart';

import '../../core/domain/signal.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/signal_style.dart';
import '../../core/utils/bangla.dart';
import '../biosecurity/biosecurity_screen.dart';
import '../disease/common/disease_report_repository.dart';
import '../disease/common/disease_result_screen.dart';
import '../feed/feed_screen.dart';
import '../pond/data/pond_repository.dart';
import '../pond/ui/daily_log_screen.dart';
import '../pond/ui/pond_detail_screen.dart';
import '../reminders/reminder_list_screen.dart';
import '../water/water_check_screen.dart';
import '../weather/weather_screen.dart';
import 'smart_rules.dart';
import 'smart_service.dart';

/// Thin strip on Home: "২টি জরুরি কাজ" (or "সব ঠিক আছে"). Not a 7th card.
class SmartBanner extends StatelessWidget {
  const SmartBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SmartService.changes,
      builder: (context, _) {
        final list = SmartService.insights();
        final urgent = list.where((i) => i.signal != Signal.ok).length;
        final tips = list.length - urgent;
        final signal = list.isEmpty ? Signal.ok : list.first.signal;
        final text = urgent > 0
            ? 'আজকের কাজ: ${Bn.digits(urgent)}টি জরুরি'
            : tips > 0
                ? 'সব ঠিক আছে · ${Bn.digits(tips)}টি পরামর্শ'
                : 'সব ঠিক আছে';

        return Material(
          color: signal.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: signal.color, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SmartScreen())),
            child: SizedBox(
              height: 58,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(urgent > 0 ? signal.icon : Icons.lightbulb,
                      color: urgent > 0 ? signal.color : AppColors.ok, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: urgent > 0 ? signal.textColor : AppColors.textDark)),
                  ),
                  const Icon(Icons.chevron_right, size: 32, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SmartScreen extends StatelessWidget {
  const SmartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('আজকের কাজ')),
      body: AnimatedBuilder(
        animation: SmartService.changes,
        builder: (context, _) {
          final list = SmartService.insights();
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 100, color: AppColors.ok),
                    SizedBox(height: 12),
                    Text('সব ঠিক আছে',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    Text('আজ জরুরি কিছু নেই। প্রতিদিন হিসাব লিখতে থাকুন।',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: AppColors.textMuted)),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('আপনার হিসাব দেখে অ্যাপ নিজে থেকে এগুলো খুঁজে পেয়েছে',
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
              for (final i in list) _InsightCard(insight: i),
            ],
          );
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final Insight insight;

  String get _buttonLabel => switch (insight.action) {
        InsightAction.dailyLog => 'হিসাব লিখুন',
        InsightAction.waterCheck => 'পানি চেক করুন',
        InsightAction.feed => 'খাবার হিসাব',
        InsightAction.pondDetail => 'পুকুর দেখুন',
        InsightAction.diseaseReport => 'রিপোর্ট দেখুন',
        InsightAction.weather => 'আবহাওয়া দেখুন',
        InsightAction.biosecurity => 'চেকলিস্ট খুলুন',
        InsightAction.reminders => 'রিমাইন্ডার দেখুন',
      };

  Widget? _target() {
    final id = insight.targetId;
    final repo = PondRepository.instance;
    final pond = id == null ? null : repo.pond(id);
    switch (insight.action) {
      case InsightAction.dailyLog:
        return pond == null ? null : DailyLogScreen(summary: repo.summary(pond));
      case InsightAction.waterCheck:
        return const WaterCheckScreen();
      case InsightAction.feed:
        if (pond == null) return const FeedScreen();
        return FeedScreen(
          initialSpecies: pond.species,
          initialCount: repo.summary(pond).currentStock,
          initialWeightG: pond.avgWeightG,
        );
      case InsightAction.pondDetail:
        return id == null ? null : PondDetailScreen(pondId: id);
      case InsightAction.diseaseReport:
        final r = id == null ? null : DiseaseReportRepository.instance.byId(id);
        return r == null ? null : DiseaseResultScreen(report: r, fromDiary: true);
      case InsightAction.weather:
        return const WeatherScreen();
      case InsightAction.biosecurity:
        return const BiosecurityScreen();
      case InsightAction.reminders:
        return const ReminderListScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = insight.signal;
    final isTip = s == Signal.ok;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTip ? Colors.white : s.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isTip ? AppColors.border : s.color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(isTip ? Icons.lightbulb : s.icon,
                  size: 30, color: isTip ? const Color(0xFFF9A825) : s.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(insight.title,
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: isTip ? AppColors.textDark : s.textColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(insight.detail, style: const TextStyle(fontSize: 17, height: 1.35)),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                final page = _target();
                if (page != null) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
                }
              },
              child: Text(_buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
