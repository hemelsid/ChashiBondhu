import 'package:flutter/material.dart';

import '../../core/domain/signal.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/signal_style.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/signal_banner.dart';
import 'water_rules.dart';
import 'water_ui.dart';

class WaterResultScreen extends StatelessWidget {
  const WaterResultScreen({super.key, required this.report});

  final WaterReport report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('পানির ফলাফল'),
        backgroundColor: AppColors.cardWater,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SignalBanner(signal: report.overall, title: report.headline),
          const SizedBox(height: 8),
          for (final r in report.results) _ParamCard(result: r),
          const SizedBox(height: 20),
          BigButton(
            label: 'আবার চেক করুন',
            icon: Icons.refresh,
            color: AppColors.cardWater,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: 'হোমে যান',
            icon: Icons.home,
            outlined: true,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}

class _ParamCard extends StatelessWidget {
  const _ParamCard({required this.result});

  final ParamResult result;

  @override
  Widget build(BuildContext context) {
    final s = result.signal;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: s.color, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(result.param.icon, size: 30, color: s.textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.param.label,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s.label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: s.onColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(result.param.formatValue(result.value),
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: s.textColor)),
          const SizedBox(height: 4),
          Text(result.message, style: const TextStyle(fontSize: 18)),
          if (s != Signal.ok) ...[
            const SizedBox(height: 10),
            const Text('এখন কী করবেন:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 4),
          for (final a in result.actions)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right_alt, size: 26, color: s.textColor),
                  const SizedBox(width: 6),
                  Expanded(child: Text(a, style: const TextStyle(fontSize: 18))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
