import 'package:flutter/material.dart';

import 'disease_library.dart';

extension DiseaseKindUi on DiseaseKind {
  Color get color => this == DiseaseKind.fish
      ? const Color(0xFF00796B)
      : const Color(0xFF558B2F);

  IconData get icon => this == DiseaseKind.fish ? Icons.set_meal : Icons.spa;

  String get photoPrompt => this == DiseaseKind.fish
      ? 'অসুস্থ মাছের ছবি তুলুন'
      : 'আক্রান্ত পাতা বা গাছের ছবি তুলুন';

  String get symptomPrompt =>
      this == DiseaseKind.fish ? 'মাছে কী দেখছেন?' : 'গাছে কী দেখছেন?';
}
