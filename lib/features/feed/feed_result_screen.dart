import 'package:flutter/material.dart';

import '../../core/domain/signal.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bangla.dart';
import '../../core/widgets/big_button.dart';
import '../../core/widgets/signal_banner.dart';
import 'feed_calculator.dart';

class FeedResultScreen extends StatelessWidget {
  const FeedResultScreen({super.key, required this.result});

  final FeedResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('খাবারের হিসাব'),
        backgroundColor: AppColors.cardFeed,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total per day
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.cardFeed, width: 3),
            ),
            child: Column(
              children: [
                Text('${r.species.emoji}  দিনে মোট খাবার',
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(Bn.weight(r.dailyKg),
                      style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cardFeed)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MealCard(
                  icon: Icons.wb_sunny,
                  iconColor: const Color(0xFFF9A825),
                  title: 'সকাল',
                  time: 'সকাল ৮–৯টা',
                  amount: Bn.weight(r.morningKg),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MealCard(
                  icon: Icons.wb_twilight,
                  iconColor: const Color(0xFFE65100),
                  title: 'বিকাল',
                  time: 'বিকাল ৪–৫টা',
                  amount: Bn.weight(r.eveningKg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${Bn.count(r.count)}টি ${r.species.label}, মোট ওজন প্রায় '
            '${Bn.weight(r.biomassKg)}। '
            'প্রতিদিন ওজনের ${Bn.number(r.ratePercent)}% খাবার।',
            style: const TextStyle(fontSize: 17, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const SignalBanner(
            signal: Signal.warn,
            title: 'বেশি খাবার পানি নষ্ট করে',
            subtitle: 'খাবার পড়ে থাকলে পচে যায়, অক্সিজেন কমে, মাছ মরে।',
          ),
          const SizedBox(height: 12),
          const _Tip('খাবার শেষ না হলে পরের বার কম দিন।'),
          const _Tip('মেঘলা দিনে বা মাছ উপরে ভেসে উঠলে খাবার কমান।'),
          const _Tip('প্রতি ১৫ দিনে কয়েকটি মাছ মেপে ওজন ঠিক করুন।'),
          const SizedBox(height: 20),
          BigButton(
            label: 'আবার হিসাব করুন',
            icon: Icons.refresh,
            color: AppColors.cardFeed,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
    required this.amount,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: iconColor),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          Text(time, style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(amount,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, size: 24, color: Color(0xFFF9A825)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 18))),
        ],
      ),
    );
  }
}
