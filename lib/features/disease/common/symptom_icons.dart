import 'package:flutter/material.dart';

/// Picture for each symptom (key = "icon" in the JSON library).
/// Real illustrations can replace these later without touching the screens.
const Map<String, (IconData, Color)> kSymptomIcons = {
  // Fish
  'ulcer': (Icons.healing, Color(0xFFC62828)),
  'fin_rot': (Icons.content_cut, Color(0xFF6D4C41)),
  'tail_rot': (Icons.call_split, Color(0xFF6D4C41)),
  'belly': (Icons.egg, Color(0xFFEF6C00)),
  'eye': (Icons.visibility_off, Color(0xFF546E7A)),
  'white_spot': (Icons.grain, Color(0xFF78909C)),
  'floating': (Icons.vertical_align_top, Color(0xFF1565C0)),
  'not_eating': (Icons.no_food, Color(0xFFAD1457)),
  'parasite': (Icons.bug_report, Color(0xFF4E342E)),
  'water_smell': (Icons.water_damage, Color(0xFF5D4037)),
  // Crop
  'yellow_leaf': (Icons.eco, Color(0xFFF9A825)),
  'brown_spot': (Icons.blur_on, Color(0xFF795548)),
  'leaf_dead': (Icons.grass, Color(0xFF8D6E63)),
  'leaf_curl': (Icons.loop, Color(0xFF2E7D32)),
  'insect': (Icons.pest_control, Color(0xFF4E342E)),
  'fruit_rot': (Icons.donut_large, Color(0xFFC62828)),
  'root_rot': (Icons.yard, Color(0xFF5D4037)),
  'stunted': (Icons.height, Color(0xFF558B2F)),
  'white_powder': (Icons.ac_unit, Color(0xFF90A4AE)),
};

(IconData, Color) symptomIcon(String key) =>
    kSymptomIcons[key] ?? (Icons.help_outline, const Color(0xFF757575));
