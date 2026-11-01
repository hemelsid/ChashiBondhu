import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/bangla.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/signal_banner.dart';
import '../data/pond_repository.dart';
import 'pond_detail_screen.dart';
import 'pond_form_screen.dart';

class PondListScreen extends StatelessWidget {
  const PondListScreen({super.key});

  void _addPond(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PondFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final repo = PondRepository.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('আমার পুকুর'),
        backgroundColor: AppColors.cardPond,
      ),
      body: AnimatedBuilder(
        animation: repo.changes,
        builder: (context, _) {
          final ponds = repo.allPonds();
          if (ponds.isEmpty) return _EmptyState(onAdd: () => _addPond(context));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            itemCount: ponds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _PondCard(summary: repo.summary(ponds[i])),
          );
        },
      ),
      floatingActionButton: AnimatedBuilder(
        animation: repo.changes,
        builder: (context, _) => repo.allPonds().isEmpty
            ? const SizedBox.shrink()
            : SizedBox(
                height: 64,
                child: FloatingActionButton.extended(
                  backgroundColor: AppColors.cardPond,
                  foregroundColor: Colors.white,
                  onPressed: () => _addPond(context),
                  icon: const Icon(Icons.add, size: 32),
                  label: const Text('নতুন পুকুর',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.water, size: 110, color: AppColors.cardPond),
          const SizedBox(height: 16),
          const Text('এখনো কোনো পুকুর নেই', style: AppText.title),
          const SizedBox(height: 6),
          const Text('প্রথমে আপনার পুকুর যোগ করুন',
              style: TextStyle(fontSize: 18, color: AppColors.textMuted)),
          const Spacer(),
          BigButton(
            label: 'নতুন পুকুর যোগ করুন',
            icon: Icons.add,
            color: AppColors.cardPond,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _PondCard extends StatelessWidget {
  const _PondCard({required this.summary});

  final PondSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = summary.pond;
    final last = summary.lastLog;
    final signal = summary.latestSignal;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PondDetailScreen(pondId: p.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(p.species.tint),
                  shape: BoxShape.circle,
                ),
                child: Text(p.species.emoji, style: const TextStyle(fontSize: 34)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      '${p.speciesLabel} · ${Bn.count(summary.currentStock)}টি · '
                      '${Bn.number(p.areaShotok)} শতক',
                      style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (signal != null) ...[
                          SignalDot(signal),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            last == null
                                ? 'এখনো হিসাব লেখা হয়নি'
                                : 'শেষ হিসাব: ${Bn.relativeDate(last.date)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 34, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
