import 'disease_library.dart';
import 'disease_matcher.dart';

class ReportResult {
  const ReportResult({
    required this.problemId,
    required this.name,
    required this.likelihood,
  });

  final String problemId;

  /// Name stored too, so old reports still read well if the library changes.
  final String name;
  final Likelihood likelihood;

  Map<String, dynamic> toMap() =>
      {'problemId': problemId, 'name': name, 'likelihood': likelihood.name};

  factory ReportResult.fromMap(Map<dynamic, dynamic> m) => ReportResult(
        problemId: m['problemId'] as String,
        name: (m['name'] as String?) ?? '',
        likelihood: Likelihood.fromKey(m['likelihood'] as String?),
      );
}

/// One saved disease check (fish or crop). Shown in the diary.
class DiseaseReport {
  const DiseaseReport({
    required this.id,
    required this.kind,
    this.pondId,
    this.pondName,
    this.cropId,
    this.cropLabel,
    required this.date,
    this.photoPath,
    this.remotePhotoPath,
    required this.symptomIds,
    required this.symptomLabels,
    required this.results,
    required this.createdAt,
  });

  final String id;
  final DiseaseKind kind;
  final String? pondId;
  final String? pondName;
  final String? cropId;
  final String? cropLabel;
  final DateTime date;

  /// Local photo file (offline). [remotePhotoPath] is set after upload.
  final String? photoPath;
  final String? remotePhotoPath;
  final List<String> symptomIds;
  final List<String> symptomLabels;
  final List<ReportResult> results;
  final DateTime createdAt;

  /// Pond name for fish, crop name for crop.
  String get subject =>
      (kind == DiseaseKind.fish ? pondName : cropLabel) ?? kind.title;

  DiseaseReport withRemotePhoto(String path) => DiseaseReport(
        id: id,
        kind: kind,
        pondId: pondId,
        pondName: pondName,
        cropId: cropId,
        cropLabel: cropLabel,
        date: date,
        photoPath: photoPath,
        remotePhotoPath: path,
        symptomIds: symptomIds,
        symptomLabels: symptomLabels,
        results: results,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'pondId': pondId,
        'pondName': pondName,
        'cropId': cropId,
        'cropLabel': cropLabel,
        'date': date.millisecondsSinceEpoch,
        'photoPath': photoPath,
        'remotePhotoPath': remotePhotoPath,
        'symptomIds': symptomIds,
        'symptomLabels': symptomLabels,
        'results': [for (final r in results) r.toMap()],
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory DiseaseReport.fromMap(Map<dynamic, dynamic> m) {
    DateTime date(String key) =>
        DateTime.fromMillisecondsSinceEpoch((m[key] as num?)?.toInt() ?? 0);
    List<String> strings(String key) =>
        (m[key] as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
    return DiseaseReport(
      id: m['id'] as String,
      kind: DiseaseKind.fromKey(m['kind'] as String?),
      pondId: m['pondId'] as String?,
      pondName: m['pondName'] as String?,
      cropId: m['cropId'] as String?,
      cropLabel: m['cropLabel'] as String?,
      date: date('date'),
      photoPath: m['photoPath'] as String?,
      remotePhotoPath: m['remotePhotoPath'] as String?,
      symptomIds: strings('symptomIds'),
      symptomLabels: strings('symptomLabels'),
      results: [
        for (final r in (m['results'] as List<dynamic>? ?? const []))
          if (r is Map) ReportResult.fromMap(r),
      ],
      createdAt: date('createdAt'),
    );
  }
}
