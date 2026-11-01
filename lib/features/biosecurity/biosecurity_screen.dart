import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/signal_style.dart';
import '../../core/utils/bangla.dart';
import '../../core/widgets/signal_dot_row.dart';
import 'biosecurity.dart';
import 'biosecurity_repository.dart';

const Map<String, IconData> _icons = {
  'disinfect': Icons.cleaning_services,
  'quarantine': Icons.timer,
  'dead_fish': Icons.delete_outline,
  'visitors': Icons.no_accounts,
  'feed_dry': Icons.inventory_2,
  'bank_clean': Icons.grass,
};

/// Weekly biosecurity checklist. Every tap saves straight away.
class BiosecurityScreen extends StatefulWidget {
  const BiosecurityScreen({super.key});

  @override
  State<BiosecurityScreen> createState() => _BiosecurityScreenState();
}

class _BiosecurityScreenState extends State<BiosecurityScreen> {
  final _repo = BiosecurityRepository.instance;
  late final DateTime _week = BioRules.weekStart(DateTime.now());
  late Set<String> _ticked = {...?_repo.forWeek(_week)?.ticked};

  Future<void> _toggle(String id) async {
    setState(() {
      _ticked = {..._ticked};
      if (!_ticked.remove(id)) _ticked.add(id);
    });
    await _repo.saveWeek(_week, _ticked);
  }

  @override
  Widget build(BuildContext context) {
    final score = BioRules.score(_ticked);
    final signal = BioRules.signal(score);
    final history = _repo.all().where((c) => c.weekStart != _week).take(6).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('জীবাণু-নিরাপত্তা'),
        backgroundColor: AppColors.cardDiary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: signal.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: signal.color, width: 3),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 10,
                        color: signal.color,
                        backgroundColor: Colors.white,
                      ),
                      Center(
                        child: Text(Bn.digits(score),
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: signal.textColor)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(signal.label,
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: signal.textColor)),
                      const Text('১০০-র মধ্যে নম্বর', style: TextStyle(fontSize: 17)),
                      Text('এই সপ্তাহ: ${Bn.date(_week)} থেকে',
                          style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('এই সপ্তাহে যা করেছেন তাতে টিক দিন',
              style: TextStyle(fontSize: 17, color: AppColors.textMuted)),
          for (final item in kBioItems)
            _CheckTile(
              icon: _icons[item.iconKey] ?? Icons.check,
              label: item.label,
              checked: _ticked.contains(item.id),
              onTap: () => _toggle(item.id),
            ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('আগের সপ্তাহগুলো',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            for (final c in history)
              SignalDotRow(
                signal: BioRules.signal(c.score),
                label: Bn.date(c.weekStart),
                value: Bn.digits(c.score),
              ),
          ],
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.icon,
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: checked ? AppColors.okBg : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: checked ? AppColors.ok : AppColors.border, width: checked ? 3 : 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 36, color: AppColors.cardDiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: checked ? FontWeight.bold : FontWeight.w600)),
                  ),
                  Icon(
                    checked ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 40,
                    color: checked ? AppColors.ok : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
