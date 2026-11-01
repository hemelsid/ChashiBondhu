import 'package:flutter/material.dart';

import '../../../core/widgets/choice_grid.dart';
import '../common/check_draft.dart';
import '../common/disease_library.dart';
import '../common/kind_ui.dart';
import '../common/photo_step_screen.dart';

/// ফসলের রোগ চেক. Step 1: which crop? (one tap goes to the photo step)
class CropCheckStartScreen extends StatelessWidget {
  const CropCheckStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const kind = DiseaseKind.crop;
    return Scaffold(
      appBar: AppBar(title: Text(kind.title), backgroundColor: kind.color),
      body: FutureBuilder<DiseaseLibrary>(
        future: DiseaseLibrary.load(kind),
        builder: (context, snap) {
          final lib = snap.data;
          if (lib == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('কোন ফসল?',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ChoiceGrid<CropInfo>(
                columns: 2,
                tileHeight: 120,
                options: [
                  for (final c in lib.crops)
                    ChoiceOption(value: c, label: c.label, emoji: c.emoji),
                ],
                selected: null,
                onSelected: (c) => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PhotoStepScreen(
                    draft: CheckDraft(kind: kind, cropId: c.id, cropLabel: c.label),
                  ),
                )),
              ),
            ],
          );
        },
      ),
    );
  }
}
