/// Fish species supported in the app. Pure Dart (no Flutter import) so the
/// calculators and tests can use it directly.
///
/// The first [mainCount] are the most common and shown first; the rest
/// appear under "আরও মাছ". [other] lets the farmer type any name.
/// Stored by `name`, so never rename an existing value.
enum FishSpecies {
  pangas('পাঙাশ', '🐟', 0xFF607D8B),
  tilapia('তেলাপিয়া', '🐟', 0xFF78909C),
  rui('রুই', '🐟', 0xFFC0CA33),
  katla('কাতলা', '🐟', 0xFF8D6E63),
  mrigel('মৃগেল', '🐟', 0xFFFF8A65),
  chingri('চিংড়ি', '🦐', 0xFFE57373),
  // More species
  shing('শিং', '🐟', 0xFF5D4037),
  magur('মাগুর', '🐟', 0xFF4E342E),
  koi('কৈ', '🐟', 0xFF8D6E63),
  pabda('পাবদা', '🐟', 0xFF90A4AE),
  gulsha('গুলশা', '🐟', 0xFFA1887F),
  sharpunti('সরপুঁটি', '🐟', 0xFFB0BEC5),
  silverCarp('সিলভার কার্প', '🐟', 0xFFCFD8DC),
  grassCarp('গ্রাস কার্প', '🐟', 0xFF9E9D24),
  commonCarp('কমন কার্প', '🐟', 0xFFBCAAA4),
  bighead('বিগহেড কার্প', '🐟', 0xFF78909C),
  kalibaus('কালিবাউশ', '🐟', 0xFF424242),
  other('অন্য মাছ', '🐠', 0xFF26A69A);

  const FishSpecies(this.label, this.emoji, this.tint);

  final String label;
  final String emoji;
  final int tint;

  /// How many are shown before "আরও মাছ".
  static const mainCount = 6;

  static List<FishSpecies> get main => values.sublist(0, mainCount);
  static List<FishSpecies> get more => values.sublist(mainCount);

  /// Carps also eat natural food in the pond → a little less feed.
  bool get isCarp => const {
        rui, katla, mrigel, silverCarp, grassCarp, commonCarp, bighead, kalibaus, sharpunti,
      }.contains(this);

  static FishSpecies? fromKey(String? key) {
    for (final s in values) {
      if (s.name == key) return s;
    }
    return null;
  }
}
