import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/app_info.dart';
import '../../../core/storage/app_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bangla.dart';
import '../../../core/utils/phone_call.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/disclaimer_box.dart';
import '../../contacts/contacts_screen.dart';
import '../crop/crop_check_start_screen.dart';
import '../fish/fish_check_start_screen.dart';
import 'check_draft.dart';
import 'disease_library.dart';
import 'disease_matcher.dart';
import 'disease_report.dart';
import 'disease_report_repository.dart';
import 'kind_ui.dart';
import 'photo_step_screen.dart';

/// Shows a saved report: disclaimer, top 2–3 likely problems with simple
/// advice. Used right after a check and when opening it from the diary.
class DiseaseResultScreen extends StatelessWidget {
  const DiseaseResultScreen({super.key, required this.report, this.fromDiary = false});

  final DiseaseReport report;
  final bool fromDiary;

  String get _officerPhone {
    final saved = report.kind == DiseaseKind.fish
        ? AppSettings.fishOfficerPhone
        : AppSettings.cropOfficerPhone;
    return saved.isNotEmpty ? saved : AppInfo.helplineNumber;
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await confirmDialog(context,
        title: 'রিপোর্ট মুছবেন?',
        message: 'এই রিপোর্ট ও ছবি মুছে যাবে।',
        confirmLabel: 'হ্যাঁ, মুছুন');
    if (!ok || !context.mounted) return;
    Navigator.of(context).pop();
    await DiseaseReportRepository.instance.delete(report);
  }

  @override
  Widget build(BuildContext context) {
    final kind = report.kind;
    final hasSavedOfficer = (kind == DiseaseKind.fish
            ? AppSettings.fishOfficerPhone
            : AppSettings.cropOfficerPhone)
        .isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('সম্ভাব্য সমস্যা'),
        backgroundColor: kind.color,
        actions: [
          if (fromDiary)
            IconButton(
              iconSize: 30,
              tooltip: 'মুছুন',
              icon: const Icon(Icons.delete),
              onPressed: () => _delete(context),
            ),
        ],
      ),
      body: FutureBuilder<DiseaseLibrary>(
        future: DiseaseLibrary.load(kind),
        builder: (context, snap) {
          final lib = snap.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ReportHeader(report: report),
              const SizedBox(height: 12),
              DisclaimerBox(kind.disclaimer),
              const SizedBox(height: 4),
              if (lib == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (report.results.isEmpty)
                const _NoMatchCard()
              else
                for (var i = 0; i < report.results.length; i++)
                  _ProblemCard(
                    result: report.results[i],
                    problem: lib.problem(report.results[i].problemId),
                    kind: kind,
                    initiallyExpanded: i == 0,
                  ),
              const SizedBox(height: 20),
              // Several checks in a row: same pond/crop again, or another one.
              if (!fromDiary) ...[
                BigButton(
                  label: 'আবার চেক করুন: ${report.subject}',
                  icon: Icons.add_a_photo,
                  color: kind.color,
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => PhotoStepScreen(
                      draft: CheckDraft(
                        kind: kind,
                        pondId: report.pondId,
                        pondName: report.pondName,
                        cropId: report.cropId,
                        cropLabel: report.cropLabel,
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 12),
                BigButton(
                  label: kind == DiseaseKind.fish ? 'অন্য পুকুরের মাছ চেক' : 'অন্য ফসল চেক',
                  icon: Icons.playlist_add,
                  outlined: true,
                  color: kind.color,
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => kind == DiseaseKind.fish
                        ? const FishCheckStartScreen()
                        : const CropCheckStartScreen(),
                  )),
                ),
                const SizedBox(height: 12),
              ],
              BigButton(
                label: hasSavedOfficer ? 'অফিসারকে ফোন করুন' : AppInfo.helplineLabel,
                icon: Icons.call,
                color: AppColors.primary,
                onPressed: () => callNumber(context, _officerPhone),
              ),
              const SizedBox(height: 12),
              BigButton(
                label: 'আরও যোগাযোগ (অফিস, হেল্পলাইন)',
                icon: Icons.support_agent,
                outlined: true,
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const ContactsScreen())),
              ),
              const SizedBox(height: 12),
              BigButton(
                label: fromDiary ? 'ফিরে যান' : 'হোমে যান',
                icon: fromDiary ? Icons.arrow_back : Icons.home,
                outlined: true,
                onPressed: () => fromDiary
                    ? Navigator.of(context).pop()
                    : Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.report});

  final DiseaseReport report;

  @override
  Widget build(BuildContext context) {
    final photo = report.photoPath;
    final hasPhoto = photo != null && File(photo).existsSync();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: hasPhoto
                      ? Image.file(File(photo), fit: BoxFit.cover, cacheWidth: 300)
                      : Container(
                          color: AppColors.background,
                          child: Icon(report.kind.icon,
                              size: 48, color: report.kind.color),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.subject,
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                    Text(Bn.date(report.date),
                        style: const TextStyle(fontSize: 17, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('যা দেখেছেন:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final s in report.symptomLabels)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.selectedBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s, style: const TextStyle(fontSize: 16)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoMatchCard extends StatelessWidget {
  const _NoMatchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: const Column(
        children: [
          Icon(Icons.help_outline, size: 56, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text('মিল পাওয়া যায়নি',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('ছবি নিয়ে অফিসারকে দেখান বা কল সেন্টারে ফোন করুন।',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({
    required this.result,
    required this.problem,
    required this.kind,
    required this.initiallyExpanded,
  });

  final ReportResult result;
  final DiseaseProblem? problem;
  final DiseaseKind kind;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final high = result.likelihood == Likelihood.high;
    final chipColor = high ? AppColors.danger : AppColors.warn;
    final p = problem;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: chipColor, width: 2.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Remove ExpansionTile divider lines.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: AppColors.textDark,
          collapsedIconColor: AppColors.textDark,
          title: Text(result.name,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('সম্ভাবনা: ${result.likelihood.label}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: high ? Colors.white : const Color(0xFF3E2C00))),
                ),
              ],
            ),
          ),
          children: p == null
              ? const [Text('বিস্তারিত পাওয়া যায়নি', style: TextStyle(fontSize: 17))]
              : [
                  _Section(
                      icon: Icons.visibility,
                      color: AppColors.cardWater,
                      title: 'লক্ষণ কী',
                      lines: [p.lokkhon]),
                  _Section(
                      icon: Icons.help_outline,
                      color: AppColors.cardWeather,
                      title: 'সম্ভাব্য কারণ',
                      lines: p.karon),
                  _Section(
                      icon: Icons.check_circle,
                      color: AppColors.ok,
                      title: 'কী করবেন',
                      lines: [
                        ...p.korben.where((l) => l != kCropMedicineRule),
                        if (kind == DiseaseKind.crop) kCropMedicineRule,
                      ]),
                  _Section(
                      icon: Icons.cancel,
                      color: AppColors.danger,
                      title: 'কী করবেন না',
                      lines: p.korbenNa),
                  _Section(
                      icon: Icons.call,
                      color: AppColors.primary,
                      title: 'কখন ${kind.officer}কে ডাকবেন',
                      lines: p.officer),
                ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 9),
                    child: Icon(Icons.circle, size: 8, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l, style: const TextStyle(fontSize: 18, height: 1.35))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
