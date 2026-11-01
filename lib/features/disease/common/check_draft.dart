import 'disease_library.dart';

/// What the farmer has chosen so far while going through the check steps.
class CheckDraft {
  CheckDraft({
    required this.kind,
    this.pondId,
    this.pondName,
    this.cropId,
    this.cropLabel,
  });

  final DiseaseKind kind;
  final String? pondId;
  final String? pondName;
  final String? cropId;
  final String? cropLabel;
  String? photoPath;
}
