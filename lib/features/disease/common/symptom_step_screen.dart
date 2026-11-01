import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bangla.dart';
import '../../../core/utils/ids.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/choice_grid.dart';
import '../../../core/widgets/multi_choice_grid.dart';
import 'check_draft.dart';
import 'disease_library.dart';
import 'disease_matcher.dart';
import 'disease_report.dart';
import 'disease_report_repository.dart';
import 'disease_result_screen.dart';
import 'kind_ui.dart';
import 'symptom_icons.dart';

/// Step: tick what you see. Then the report is matched, saved, and shown.
class SymptomStepScreen extends StatefulWidget {
  const SymptomStepScreen({super.key, required this.draft});

  final CheckDraft draft;

  @override
  State<SymptomStepScreen> createState() => _SymptomStepScreenState();
}

class _SymptomStepScreenState extends State<SymptomStepScreen> {
  late final Future<DiseaseLibrary> _library = DiseaseLibrary.load(widget.draft.kind);
  final Set<String> _selected = {};
  bool _saving = false;

  Future<void> _showResult(DiseaseLibrary lib) async {
    setState(() => _saving = true);
    final d = widget.draft;
    final matches = DiseaseMatcher.match(lib, _selected, cropId: d.cropId);
    final now = DateTime.now();
    // Keep symptoms in library order so reports read the same way.
    final ordered = [for (final s in lib.symptoms) if (_selected.contains(s.id)) s];

    final report = DiseaseReport(
      id: newId(),
      kind: d.kind,
      pondId: d.pondId,
      pondName: d.pondName,
      cropId: d.cropId,
      cropLabel: d.cropLabel,
      date: Bn.dateOnly(now),
      photoPath: d.photoPath,
      symptomIds: [for (final s in ordered) s.id],
      symptomLabels: [for (final s in ordered) s.label],
      results: [
        for (final m in matches)
          ReportResult(
              problemId: m.problem.id,
              name: m.problem.name,
              likelihood: m.likelihood),
      ],
      createdAt: now,
    );
    await DiseaseReportRepository.instance.save(report);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('রিপোর্ট ডায়েরিতে রাখা হয়েছে ✓')),
    );
    // Replace the check steps with the result, so "back" goes home-wards.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => DiseaseResultScreen(report: report)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.draft.kind;
    return Scaffold(
      appBar: AppBar(title: Text(kind.title), backgroundColor: kind.color),
      body: FutureBuilder<DiseaseLibrary>(
        future: _library,
        builder: (context, snap) {
          final lib = snap.data;
          if (lib == null) {
            return Center(
              child: snap.hasError
                  ? const Text('তথ্য খোলা যায়নি', style: TextStyle(fontSize: 20))
                  : const CircularProgressIndicator(),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(kind.symptomPrompt,
                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                    const Text('যতগুলো মেলে সব বেছে নিন',
                        style: TextStyle(fontSize: 17, color: AppColors.textMuted)),
                    const SizedBox(height: 12),
                    MultiChoiceGrid<String>(
                      options: [
                        for (final s in lib.symptoms)
                          ChoiceOption(
                            value: s.id,
                            label: s.label,
                            icon: symptomIcon(s.icon).$1,
                            iconColor: symptomIcon(s.icon).$2,
                          ),
                      ],
                      selected: _selected,
                      onToggle: (id) => setState(() {
                        if (!_selected.remove(id)) _selected.add(id);
                      }),
                    ),
                  ],
                ),
              ),
              // Button stays at the bottom, in thumb reach.
              Container(
                color: AppColors.background,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SafeArea(
                  top: false,
                  child: BigButton(
                    label: _selected.isEmpty
                        ? 'অন্তত একটি বেছে নিন'
                        : 'ফলাফল দেখুন (${Bn.digits(_selected.length)}টি)',
                    icon: Icons.search,
                    color: kind.color,
                    onPressed:
                        _selected.isEmpty || _saving ? null : () => _showResult(lib),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
