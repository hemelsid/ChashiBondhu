import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bangla.dart';
import '../../../core/widgets/simple_bar_chart.dart';
import '../data/pond_log.dart';

class DayTotals {
  const DayTotals(this.date, this.feedKg, this.dead);

  final DateTime date;
  final double feedKg;
  final int dead;
}

/// Sums logs per day, oldest first, last [days] days that have entries.
List<DayTotals> dailyTotals(List<PondLog> logs, {int days = 14}) {
  final map = <DateTime, (double, int)>{};
  for (final l in logs) {
    final d = Bn.dateOnly(l.date);
    final (f, dead) = map[d] ?? (0.0, 0);
    map[d] = (f + l.feedKg, dead + l.deadCount);
  }
  final keys = map.keys.toList()..sort();
  final recent = keys.length > days ? keys.sublist(keys.length - days) : keys;
  return [for (final k in recent) DayTotals(k, map[k]!.$1, map[k]!.$2)];
}

/// Mortality and feed over time (works offline, no chart package).
class PondCharts extends StatelessWidget {
  const PondCharts({super.key, required this.logs});

  final List<PondLog> logs;

  @override
  Widget build(BuildContext context) {
    final totals = dailyTotals(logs);
    if (totals.length < 2) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('২ দিনের হিসাব লিখলে এখানে চার্ট দেখা যাবে',
            style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
      );
    }
    final labels = [
      for (final t in totals) '${Bn.digits(t.date.day)}/${Bn.digits(t.date.month)}'
    ];
    return Column(
      children: [
        _ChartCard(
          icon: Icons.remove_circle_outline,
          title: 'মরা মাছ (প্রতিদিন)',
          color: AppColors.danger,
          child: SimpleBarChart(
            values: [for (final t in totals) t.dead.toDouble()],
            labels: labels,
            color: AppColors.warn,
            highlight: (v) => v >= 10 ? AppColors.danger : null,
          ),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          icon: Icons.rice_bowl,
          title: 'খাবার (কেজি, প্রতিদিন)',
          color: AppColors.cardFeed,
          child: SimpleBarChart(
            values: [for (final t in totals) t.feedKg],
            labels: labels,
            color: AppColors.cardFeed,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
