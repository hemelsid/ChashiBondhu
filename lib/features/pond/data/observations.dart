import '../../../core/domain/signal.dart';

/// Water colour the farmer sees. Signal + short tip for warn/danger.
enum WaterColor {
  lightGreen('হালকা সবুজ', 0xFF9CCC65, Signal.ok, null),
  darkGreen('ঘন সবুজ', 0xFF1B5E20, Signal.warn,
      'পানি ঘন সবুজ — সার দেওয়া বন্ধ রাখুন। ভোরে অক্সিজেন কমে যেতে পারে।'),
  clear('একদম পরিষ্কার', 0xFFD6EEF8, Signal.warn,
      'পানি বেশি পরিষ্কার — প্রাকৃতিক খাবার কম। মৎস্য কর্মকর্তার পরামর্শে সার দিন।'),
  muddy('ঘোলা / মাটির রং', 0xFF8D6E63, Signal.warn,
      'পানি ঘোলা — প্রতি শতকে ২৫০ গ্রাম চুন গুলে ছিটিয়ে দিন।'),
  redBlack('লালচে / কালচে', 0xFF4E342E, Signal.danger,
      'পানি লালচে বা কালচে — পানি নষ্ট হতে পারে। কিছু পানি বদলান, খাবার কমান।');

  const WaterColor(this.label, this.swatch, this.signal, this.tip);

  final String label;
  final int swatch;
  final Signal signal;
  final String? tip;

  static WaterColor? fromKey(String? key) {
    for (final v in values) {
      if (v.name == key) return v;
    }
    return null;
  }
}

/// How the fish are behaving today.
enum FishBehavior {
  normal('স্বাভাবিক', Signal.ok, null),
  lessEating('কম খাচ্ছে', Signal.warn,
      'মাছ কম খাচ্ছে — খাবার কমিয়ে দিন, পানি চেক করুন।'),
  slow('ধীরে ঘুরছে', Signal.warn,
      'মাছ ধীরে ঘুরছে — পানি চেক করুন, অসুস্থ মাছ আলাদা করে দেখুন।'),
  gasping('উপরে খাবি খাচ্ছে', Signal.danger,
      'মাছ উপরে খাবি খাচ্ছে — অক্সিজেন কম। এখনই পানি নাড়ুন বা এরেটর চালান, আজ খাবার কম দিন।'),
  wounds('গায়ে ঘা / দাগ', Signal.danger,
      'মাছের গায়ে ঘা বা দাগ — রোগ হতে পারে। মরা ও অসুস্থ মাছ তুলে ফেলুন, মৎস্য কর্মকর্তার পরামর্শ নিন।');

  const FishBehavior(this.label, this.signal, this.tip);

  final String label;
  final Signal signal;
  final String? tip;

  static FishBehavior? fromKey(String? key) {
    for (final v in values) {
      if (v.name == key) return v;
    }
    return null;
  }
}
