import '../../core/domain/signal.dart';

enum WaterParam { ph, oxygen, ammonia, temperature }

/// Safe ranges for warm-water pond fish. One place to tune with an expert.
class WaterLimits {
  WaterLimits._();

  // pH
  static const phOkMin = 6.5, phOkMax = 8.5;
  static const phDangerMin = 6.0, phDangerMax = 9.0;

  // Dissolved oxygen, mg/L
  static const doOkMin = 5.0;
  static const doDangerBelow = 3.0;

  // Total ammonia, mg/L (as measured by common test kits)
  static const ammoniaOkMax = 0.2;
  static const ammoniaDangerAbove = 0.5;

  // Temperature, °C
  static const tempOkMin = 25.0, tempOkMax = 32.0;
  static const tempDangerMin = 20.0, tempDangerMax = 35.0;

  /// Values outside these are probably typing mistakes.
  static const Map<WaterParam, (double, double)> plausible = {
    WaterParam.ph: (0, 14),
    WaterParam.oxygen: (0, 20),
    WaterParam.ammonia: (0, 10),
    WaterParam.temperature: (0, 45),
  };
}

class ParamResult {
  const ParamResult({
    required this.param,
    required this.value,
    required this.signal,
    required this.message,
    required this.actions,
  });

  final WaterParam param;
  final double value;
  final Signal signal;

  /// One short sentence: what is happening.
  final String message;

  /// এখন কী করবেন — simple steps.
  final List<String> actions;
}

class WaterReport {
  const WaterReport(this.results);

  final List<ParamResult> results;

  Signal get overall => Signal.worst(results.map((r) => r.signal));

  String get headline => switch (overall) {
        Signal.ok => 'পানি ভালো আছে',
        Signal.warn => 'কিছু জিনিস ঠিক করতে হবে',
        Signal.danger => 'এখনই ব্যবস্থা নিন',
      };
}

class WaterRules {
  WaterRules._();

  static bool isPlausible(WaterParam p, double v) {
    final (min, max) = WaterLimits.plausible[p]!;
    return v >= min && v <= max;
  }

  /// Checks whatever the farmer entered; null values are skipped.
  /// Worst problems are listed first.
  static WaterReport check({
    double? ph,
    double? oxygen,
    double? ammonia,
    double? temperature,
  }) {
    final results = <ParamResult>[
      if (ph != null) _ph(ph),
      if (oxygen != null) _oxygen(oxygen),
      if (ammonia != null) _ammonia(ammonia, ph),
      if (temperature != null) _temperature(temperature),
    ];
    results.sort((a, b) => b.signal.index.compareTo(a.signal.index));
    return WaterReport(results);
  }

  static ParamResult _ph(double v) {
    const p = WaterParam.ph;
    if (v < WaterLimits.phDangerMin) {
      return ParamResult(param: p, value: v, signal: Signal.danger,
          message: 'পানি অনেক বেশি অম্ল (টক) — মাছের ক্ষতি হবে।',
          actions: const [
            'প্রতি শতকে ৫০০ গ্রাম থেকে ১ কেজি চুন পানিতে গুলে পুকুরে ছিটিয়ে দিন।',
            'চুন দেওয়ার দিন খাবার কম দিন।',
            '৩ দিন পর আবার মাপুন।',
          ]);
    }
    if (v < WaterLimits.phOkMin) {
      return ParamResult(param: p, value: v, signal: Signal.warn,
          message: 'পানি একটু অম্ল (টক)।',
          actions: const [
            'প্রতি শতকে ২৫০ গ্রাম চুন পানিতে গুলে ছিটিয়ে দিন।',
            '৩–৪ দিন পর আবার মাপুন।',
          ]);
    }
    if (v > WaterLimits.phDangerMax) {
      return ParamResult(param: p, value: v, signal: Signal.danger,
          message: 'পানি অনেক বেশি ক্ষারীয় — অ্যামোনিয়া বিষাক্ত হয়ে যায়।',
          actions: const [
            'চুন ও সার দেওয়া বন্ধ রাখুন।',
            'পুকুরের ৪ ভাগের ১ ভাগ পানি বদলে নতুন পানি দিন।',
            'খাবার কমিয়ে দিন।',
            'বেশি শ্যাওলা থাকলে কিছু তুলে ফেলুন।',
          ]);
    }
    if (v > WaterLimits.phOkMax) {
      return ParamResult(param: p, value: v, signal: Signal.warn,
          message: 'পানি একটু বেশি ক্ষারীয়।',
          actions: const [
            'এখন চুন দেবেন না।',
            'কিছু পানি বদলে নতুন পানি দিন।',
          ]);
    }
    return ParamResult(param: p, value: v, signal: Signal.ok,
        message: 'পিএইচ ঠিক আছে।', actions: const ['কিছু করতে হবে না।']);
  }

  static ParamResult _oxygen(double v) {
    const p = WaterParam.oxygen;
    if (v < WaterLimits.doDangerBelow) {
      return ParamResult(param: p, value: v, signal: Signal.danger,
          message: 'অক্সিজেন খুব কম — মাছ মারা যেতে পারে।',
          actions: const [
            'এখনই এরেটর চালান, না থাকলে বাঁশ দিয়ে পানি পেটান বা সাঁতার কাটুন।',
            'অক্সিজেন বড়ি/পাউডার দিন (প্যাকেটের নিয়ম মেনে)।',
            'আজ খাবার দেবেন না।',
            'পারলে নতুন পানি দিন।',
          ]);
    }
    if (v < WaterLimits.doOkMin) {
      return ParamResult(param: p, value: v, signal: Signal.warn,
          message: 'অক্সিজেন কম।',
          actions: const [
            'ভোরে পানি নাড়ুন বা এরেটর চালান।',
            'খাবার কমিয়ে দিন।',
            'সার দেওয়া বন্ধ রাখুন।',
          ]);
    }
    return ParamResult(param: p, value: v, signal: Signal.ok,
        message: 'অক্সিজেন ঠিক আছে।', actions: const ['কিছু করতে হবে না।']);
  }

  static ParamResult _ammonia(double v, double? ph) {
    const p = WaterParam.ammonia;
    var signal = v > WaterLimits.ammoniaDangerAbove
        ? Signal.danger
        : v > WaterLimits.ammoniaOkMax
            ? Signal.warn
            : Signal.ok;
    // At high pH the same ammonia is much more poisonous.
    final highPh = ph != null && ph > WaterLimits.phOkMax;
    if (signal == Signal.warn && highPh) signal = Signal.danger;

    switch (signal) {
      case Signal.danger:
        return ParamResult(param: p, value: v, signal: signal,
            message: highPh && v <= WaterLimits.ammoniaDangerAbove
                ? 'পিএইচ বেশি, তাই এই অ্যামোনিয়া মাছের জন্য বিষাক্ত।'
                : 'অ্যামোনিয়া অনেক বেশি — মাছের জন্য বিষাক্ত।',
            actions: const [
              'আজ খাবার বন্ধ রাখুন।',
              'পুকুরের ৪ ভাগের ১ ভাগ পানি বদলান।',
              'প্রতি শতকে ২০০–২৫০ গ্রাম জিওলাইট দিন।',
              'পচা খাবার আর মরা মাছ তুলে ফেলুন।',
            ]);
      case Signal.warn:
        return ParamResult(param: p, value: v, signal: signal,
            message: 'অ্যামোনিয়া একটু বেশি।',
            actions: const [
              'খাবার কমিয়ে দিন।',
              'কিছু পানি বদলে নতুন পানি দিন।',
            ]);
      case Signal.ok:
        return ParamResult(param: p, value: v, signal: signal,
            message: 'অ্যামোনিয়া ঠিক আছে।', actions: const ['কিছু করতে হবে না।']);
    }
  }

  static ParamResult _temperature(double v) {
    const p = WaterParam.temperature;
    if (v < WaterLimits.tempDangerMin) {
      return ParamResult(param: p, value: v, signal: Signal.danger,
          message: 'পানি খুব ঠান্ডা — মাছ খাবে কম, রোগ হতে পারে।',
          actions: const [
            'খাবার অর্ধেক বা তারও কম দিন।',
            'পাড়ের গাছের ডাল ছেঁটে রোদ আসতে দিন।',
            'মাছের গায়ে দাগ দেখলে মৎস্য কর্মকর্তাকে জানান।',
          ]);
    }
    if (v < WaterLimits.tempOkMin) {
      return ParamResult(param: p, value: v, signal: Signal.warn,
          message: 'পানি ঠান্ডা — মাছ কম খাবে।',
          actions: const [
            'খাবার কমিয়ে দিন।',
            'রোদ উঠলে খাবার দিন।',
          ]);
    }
    if (v > WaterLimits.tempDangerMax) {
      return ParamResult(param: p, value: v, signal: Signal.danger,
          message: 'পানি খুব গরম — অক্সিজেন কমে যাবে।',
          actions: const [
            'দুপুরে খাবার দেবেন না; সকাল-বিকালে অল্প দিন।',
            'নতুন ঠান্ডা পানি দিন।',
            'পুকুরের এক কোণে কচুরিপানা রেখে ছায়া দিন।',
            'এরেটর থাকলে চালান।',
          ]);
    }
    if (v > WaterLimits.tempOkMax) {
      return ParamResult(param: p, value: v, signal: Signal.warn,
          message: 'পানি গরম।',
          actions: const [
            'দুপুরে খাবার দেবেন না।',
            'পুকুরে পানি বাড়ান।',
          ]);
    }
    return ParamResult(param: p, value: v, signal: Signal.ok,
        message: 'তাপমাত্রা ঠিক আছে।', actions: const ['কিছু করতে হবে না।']);
  }
}
