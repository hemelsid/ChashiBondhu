import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bangla.dart';
import 'disease_library.dart';
import 'disease_matcher.dart';
import 'disease_report.dart';
import 'disease_report_repository.dart';
import 'disease_result_screen.dart';
import 'kind_ui.dart';

/// One row for a saved report. Used in the pond detail and in the diary.
class ReportTile extends StatelessWidget {
  const ReportTile({super.key, required this.report});

  final DiseaseReport report;

  @override
  Widget build(BuildContext context) {
    final photo = report.photoPath;
    final top = report.results.isEmpty ? null : report.results.first;
    final hasPhoto = photo != null && File(photo).existsSync();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DiseaseResultScreen(report: report, fromDiary: true))),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: hasPhoto
                        ? Image.file(File(photo), fit: BoxFit.cover, cacheWidth: 200)
                        : Container(
                            color: AppColors.background,
                            child: Icon(report.kind.icon, color: report.kind.color, size: 34),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        top?.name ?? 'মিল পাওয়া যায়নি',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${report.subject} · ${Bn.relativeDate(report.date)}',
                        style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
                      ),
                      if (top != null)
                        Text('সম্ভাবনা: ${top.likelihood.label}',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: top.likelihood == Likelihood.high
                                    ? AppColors.danger
                                    : AppColors.warnText)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 30, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// All saved disease reports (fish and crop).
class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key, this.kind});

  final DiseaseKind? kind;

  @override
  Widget build(BuildContext context) {
    final repo = DiseaseReportRepository.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('রোগ চেকের রিপোর্ট'),
        backgroundColor: kind?.color ?? AppColors.cardDiary,
      ),
      body: ValueListenableBuilder(
        valueListenable: repo.changes,
        builder: (context, _, __) {
          final reports = repo.all(kind: kind);
          if (reports.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('এখনো কোনো রিপোর্ট নেই',
                    style: TextStyle(fontSize: 20, color: AppColors.textMuted)),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final r in reports) ReportTile(report: r)],
          );
        },
      ),
    );
  }
}
