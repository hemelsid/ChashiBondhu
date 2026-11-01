import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Which check: fish (PukurBondhu) or crop.
enum DiseaseKind {
  fish(
    asset: 'assets/data/fish_diseases.json',
    title: 'মাছের রোগ চেক',
    officer: 'উপজেলা মৎস্য কর্মকর্তা বা ভেট',
    disclaimer:
        'এটা প্রাথমিক ধারণা মাত্র, চিকিৎসা নয়। বড় ক্ষতি হলে অবশ্যই মৎস্য অফিসার / ভেট এর পরামর্শ নিন।',
  ),
  crop(
    asset: 'assets/data/crop_diseases.json',
    title: 'ফসলের রোগ চেক',
    officer: 'উপজেলা কৃষি কর্মকর্তা',
    disclaimer:
        'এটা প্রাথমিক ধারণা মাত্র, চিকিৎসা নয়। বড় ক্ষতি হলে অবশ্যই কৃষি অফিসারের পরামর্শ নিন।',
  );

  const DiseaseKind({
    required this.asset,
    required this.title,
    required this.officer,
    required this.disclaimer,
  });

  final String asset;
  final String title;

  /// Who to call ("কখন ডাকবেন" section heading uses this).
  final String officer;
  final String disclaimer;

  static DiseaseKind fromKey(String? key) =>
      key == 'crop' ? DiseaseKind.crop : DiseaseKind.fish;
}

/// Fixed safety line for every crop result (no pesticide names, ever).
const String kCropMedicineRule =
    'অনুমোদিত ওষুধ লেবেল অনুযায়ী ব্যবহার করুন, আর কৃষি অফিসারের পরামর্শ নিন।';

class Symptom {
  const Symptom({required this.id, required this.label, required this.icon});

  final String id;
  final String label;
  final String icon;
}

class CropInfo {
  const CropInfo({required this.id, required this.label, required this.emoji});

  final String id;
  final String label;
  final String emoji;
}

class DiseaseProblem {
  const DiseaseProblem({
    required this.id,
    required this.name,
    required this.crops,
    required this.weights,
    required this.lokkhon,
    required this.karon,
    required this.korben,
    required this.korbenNa,
    required this.officer,
  });

  final String id;
  final String name;

  /// Crop ids this applies to. Empty for fish.
  final List<String> crops;

  /// symptom id -> how strongly it points to this problem.
  final Map<String, double> weights;
  final String lokkhon;
  final List<String> karon;
  final List<String> korben;
  final List<String> korbenNa;
  final List<String> officer;

  double get totalWeight => weights.values.fold(0, (a, b) => a + b);
}

/// Local JSON library of problems. Edit the JSON files to add problems;
/// no code change needed.
class DiseaseLibrary {
  const DiseaseLibrary({
    required this.kind,
    required this.symptoms,
    required this.problems,
    this.crops = const [],
  });

  final DiseaseKind kind;
  final List<Symptom> symptoms;
  final List<DiseaseProblem> problems;
  final List<CropInfo> crops;

  Symptom? symptom(String id) {
    for (final s in symptoms) {
      if (s.id == id) return s;
    }
    return null;
  }

  DiseaseProblem? problem(String id) {
    for (final p in problems) {
      if (p.id == id) return p;
    }
    return null;
  }

  CropInfo? crop(String? id) {
    for (final c in crops) {
      if (c.id == id) return c;
    }
    return null;
  }

  factory DiseaseLibrary.fromJson(DiseaseKind kind, Map<String, dynamic> json) {
    List<String> strings(dynamic v) =>
        (v as List<dynamic>? ?? const []).map((e) => e.toString()).toList();

    return DiseaseLibrary(
      kind: kind,
      crops: [
        for (final c in (json['crops'] as List<dynamic>? ?? const []))
          CropInfo(
            id: c['id'] as String,
            label: c['label'] as String,
            emoji: (c['emoji'] as String?) ?? '🌱',
          ),
      ],
      symptoms: [
        for (final s in json['symptoms'] as List<dynamic>)
          Symptom(
            id: s['id'] as String,
            label: s['label'] as String,
            icon: (s['icon'] as String?) ?? s['id'] as String,
          ),
      ],
      problems: [
        for (final p in json['problems'] as List<dynamic>)
          DiseaseProblem(
            id: p['id'] as String,
            name: p['name'] as String,
            crops: strings(p['crops']),
            weights: {
              for (final e in (p['weights'] as Map<String, dynamic>).entries)
                e.key: (e.value as num).toDouble(),
            },
            lokkhon: (p['lokkhon'] as String?) ?? '',
            karon: strings(p['karon']),
            korben: strings(p['korben']),
            korbenNa: strings(p['korben_na']),
            officer: strings(p['officer']),
          ),
      ],
    );
  }

  static final Map<DiseaseKind, Future<DiseaseLibrary>> _cache = {};

  /// Loads once from the bundled asset (works offline).
  static Future<DiseaseLibrary> load(DiseaseKind kind) {
    return _cache.putIfAbsent(kind, () async {
      final text = await rootBundle.loadString(kind.asset);
      return DiseaseLibrary.fromJson(kind, jsonDecode(text) as Map<String, dynamic>);
    });
  }
}
