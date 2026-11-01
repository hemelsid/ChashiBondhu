/// Fish species supported in the app. Pure Dart (no Flutter import) so the
/// calculators and tests can use it directly.
///
/// `photo` is reserved for real species photos later
/// (e.g. assets/images/species/pangas.jpg). Until then the UI uses [emoji].
enum FishSpecies {
  pangas('পাঙাশ', '🐟', 0xFF607D8B),
  tilapia('তেলাপিয়া', '🐟', 0xFF78909C),
  rui('রুই', '🐟', 0xFFC0CA33),
  katla('কাতলা', '🐟', 0xFF8D6E63),
  mrigel('মৃগেল', '🐟', 0xFFFF8A65),
  chingri('চিংড়ি', '🦐', 0xFFE57373);

  const FishSpecies(this.label, this.emoji, this.tint, {this.photo});

  final String label;
  final String emoji;
  final int tint;
  final String? photo;

  bool get isCarp => this == rui || this == katla || this == mrigel;

  static FishSpecies? fromKey(String? key) {
    for (final s in values) {
      if (s.name == key) return s;
    }
    return null;
  }
}
