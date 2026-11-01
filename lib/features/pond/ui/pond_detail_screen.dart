import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/signal_style.dart';
import '../../../core/utils/bangla.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/signal_banner.dart';
import '../../feed/feed_screen.dart';
import '../data/pond_log.dart';
import '../data/pond_repository.dart';
import 'daily_log_screen.dart';
import 'pond_charts.dart';
import 'pond_reports_section.dart';
import 'observation_ui.dart';
import 'pond_form_screen.dart';

class PondDetailScreen extends StatelessWidget {
  const PondDetailScreen({super.key, required this.pondId});

  final String pondId;

  @override
  Widget build(BuildContext context) {
    final repo = PondRepository.instance;
    return AnimatedBuilder(
      animation: repo.changes,
      builder: (context, _) {
        final pond = repo.pond(pondId);
        if (pond == null) {
          return Scaffold(
            appBar: AppBar(backgroundColor: AppColors.cardPond),
            body: const Center(
                child: Text('পুকুর পাওয়া যায়নি', style: TextStyle(fontSize: 20))),
          );
        }
        final s = repo.summary(pond);
        final signal = s.latestSignal;

        return Scaffold(
          appBar: AppBar(
            title: Text(pond.name),
            backgroundColor: AppColors.cardPond,
            actions: [
              PopupMenuButton<String>(
                iconSize: 32,
                onSelected: (v) {
                  if (v == 'edit') {
                    _edit(context, s);
                  } else {
                    _delete(context, s);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    height: 56,
                    child: Row(children: [
                      Icon(Icons.edit),
                      SizedBox(width: 12),
                      Text('পুকুর বদলান', style: TextStyle(fontSize: 19)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    height: 56,
                    child: Row(children: [
                      Icon(Icons.delete, color: AppColors.danger),
                      SizedBox(width: 12),
                      Text('পুকুর মুছুন', style: TextStyle(fontSize: 19)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _SummaryCard(summary: s),
              if (signal != null) ...[
                const SizedBox(height: 12),
                SignalBanner(
                  signal: signal,
                  title: 'শেষ হিসাব: ${Bn.relativeDate(s.lastLog!.date)}',
                ),
              ],
              const SizedBox(height: 16),
              BigButton(
                label: 'আজকের হিসাব লিখুন',
                icon: Icons.edit_note,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DailyLogScreen(summary: s))),
              ),
              const SizedBox(height: 12),
              BigButton(
                label: 'খাবার হিসাব করুন',
                icon: Icons.calculate,
                outlined: true,
                color: AppColors.cardFeed,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => FeedScreen(
                    initialSpecies: pond.species,
                    initialCount: s.currentStock,
                    initialWeightG: pond.avgWeightG,
                  ),
                )),
              ),
              const SectionTitle('চার্ট', icon: Icons.bar_chart),
              PondCharts(logs: s.logs),
              PondReportsSection(pond: pond),
              const SectionTitle('আগের হিসাব', icon: Icons.history),
              if (s.logs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('এখনো কোনো হিসাব নেই',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: AppColors.textMuted)),
                )
              else
                for (final log in s.logs)
                  _LogTile(log: log, currentStock: s.currentStock),
            ],
          ),
        );
      },
    );
  }

  void _edit(BuildContext context, PondSummary s) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PondFormScreen(existing: s.pond)));
  }

  Future<void> _delete(BuildContext context, PondSummary s) async {
    final ok = await confirmDialog(
      context,
      title: 'পুকুর মুছবেন?',
      message: '"${s.pond.name}" এবং এর সব হিসাব মুছে যাবে।',
      confirmLabel: 'হ্যাঁ, মুছুন',
    );
    if (!ok || !context.mounted) return;
    Navigator.of(context).pop();
    await PondRepository.instance.deletePond(s.pond.id);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final PondSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = summary.pond;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Color(p.species.tint), shape: BoxShape.circle),
                child: Text(p.species.emoji, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.species.label,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${Bn.number(p.areaShotok, maxDecimals: 2)} শতক',
                        style: const TextStyle(fontSize: 17, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _StatRow(
            icon: Icons.set_meal,
            label: 'এখন মাছ আছে',
            value: '${Bn.count(summary.currentStock)}টি',
          ),
          _StatRow(
            icon: Icons.event,
            label: 'ছাড়া হয়েছে',
            value: '${Bn.digits(summary.daysSinceStock)} দিন আগে',
          ),
          _StatRow(
            icon: Icons.scale,
            label: 'গড় ওজন',
            value: '${Bn.number(p.avgWeightG)} গ্রাম',
          ),
          _StatRow(
            icon: Icons.rice_bowl,
            label: 'মোট খাবার দেওয়া',
            value: Bn.weight(summary.totalFeedKg),
          ),
          _StatRow(
            icon: Icons.remove_circle_outline,
            label: 'মোট মরা মাছ',
            value: '${Bn.count(summary.totalDead)}টি',
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 17))),
          Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log, required this.currentStock});

  final PondLog log;
  final int currentStock;

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'এই হিসাব মুছবেন?',
      message: '${Bn.date(log.date)} তারিখের হিসাব মুছে যাবে।',
      confirmLabel: 'হ্যাঁ, মুছুন',
    );
    if (ok) await PondRepository.instance.deleteLog(log.id);
  }

  @override
  Widget build(BuildContext context) {
    final signal = log.signalFor(currentStock);
    final color = log.waterColor;
    final behavior = log.behavior;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: signal.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: signal.color, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: () => _confirmDelete(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(signal.icon, color: signal.color, size: 26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(Bn.relativeDate(log.date),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Text(signal.label,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: signal.textColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _Chip(icon: Icons.rice_bowl, text: Bn.weight(log.feedKg)),
                    _Chip(
                        icon: Icons.remove_circle_outline,
                        text: 'মরা ${Bn.count(log.deadCount)}টি'),
                    if (color != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Color(color.swatch),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(color.label, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    if (behavior != null)
                      _Chip(icon: behavior.icon, text: behavior.label, color: behavior.color),
                  ],
                ),
                if (log.note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(log.note,
                      style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color ?? AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
