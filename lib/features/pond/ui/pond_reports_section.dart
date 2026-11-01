import 'package:flutter/material.dart';

import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/section_title.dart';
import '../../disease/common/check_draft.dart';
import '../../disease/common/disease_library.dart';
import '../../disease/common/disease_report_repository.dart';
import '../../disease/common/kind_ui.dart';
import '../../disease/common/photo_step_screen.dart';
import '../../disease/common/report_list.dart';
import '../data/pond.dart';

/// Disease check reports saved for this pond (part of the pond diary).
class PondReportsSection extends StatelessWidget {
  const PondReportsSection({super.key, required this.pond});

  final Pond pond;

  @override
  Widget build(BuildContext context) {
    final repo = DiseaseReportRepository.instance;
    return ValueListenableBuilder(
      valueListenable: repo.changes,
      builder: (context, _, __) {
        final reports = repo.all(pondId: pond.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('রোগ চেক', icon: Icons.healing),
            for (final r in reports.take(5)) ReportTile(report: r),
            BigButton(
              label: 'এই পুকুরের মাছের রোগ চেক',
              icon: Icons.add_a_photo,
              outlined: true,
              color: DiseaseKind.fish.color,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PhotoStepScreen(
                  draft: CheckDraft(
                      kind: DiseaseKind.fish, pondId: pond.id, pondName: pond.name),
                ),
              )),
            ),
          ],
        );
      },
    );
  }
}
