import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bangla.dart';
import '../../../core/widgets/big_button.dart';
import '../../pond/data/pond_repository.dart';
import '../../pond/ui/pond_form_screen.dart';
import '../common/check_draft.dart';
import '../common/disease_library.dart';
import '../common/kind_ui.dart';
import '../common/photo_step_screen.dart';

/// PukurBondhu — মাছের রোগ চেক. Step 1: which pond?
class FishCheckStartScreen extends StatelessWidget {
  const FishCheckStartScreen({super.key});

  void _start(BuildContext context, {String? pondId, String? pondName}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PhotoStepScreen(
        draft: CheckDraft(kind: DiseaseKind.fish, pondId: pondId, pondName: pondName),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final repo = PondRepository.instance;
    const kind = DiseaseKind.fish;
    return Scaffold(
      appBar: AppBar(title: const Text('পুকুরবন্ধু'), backgroundColor: kind.color),
      body: AnimatedBuilder(
        animation: repo.changes,
        builder: (context, _) {
          final ponds = repo.allPonds();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('কোন পুকুরের মাছ?',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (ponds.isEmpty)
                BigButton(
                  label: 'নতুন পুকুর যোগ করুন',
                  icon: Icons.add,
                  color: AppColors.cardPond,
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PondFormScreen())),
                ),
              for (final p in ponds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    elevation: 1,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _start(context, pondId: p.id, pondName: p.name),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: Color(p.species.tint), shape: BoxShape.circle),
                              child: Text(p.species.emoji,
                                  style: const TextStyle(fontSize: 30)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          fontSize: 21, fontWeight: FontWeight.bold)),
                                  Text(
                                      '${p.species.label} · ${Bn.number(p.areaShotok)} শতক',
                                      style: const TextStyle(
                                          fontSize: 16, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward, size: 32, color: kind.color),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              BigButton(
                label: 'পুকুর না বেছে চেক করুন',
                icon: Icons.arrow_forward,
                outlined: true,
                color: kind.color,
                onPressed: () => _start(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
