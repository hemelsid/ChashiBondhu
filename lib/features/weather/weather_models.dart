import '../../core/domain/signal.dart';

class DayForecast {
  const DayForecast({
    required this.date,
    required this.tMax,
    required this.tMin,
    required this.rainChance,
    required this.gustKmh,
    required this.code,
  });

  final DateTime date;
  final double tMax;
  final double tMin;

  /// 0..100
  final int rainChance;
  final double gustKmh;

  /// WMO weather code from Open-Meteo.
  final int code;

  Signal get storm => WeatherRules.stormSignal(code, gustKmh);

  Map<String, dynamic> toMap() => {
        'date': date.millisecondsSinceEpoch,
        'tMax': tMax,
        'tMin': tMin,
        'rain': rainChance,
        'gust': gustKmh,
        'code': code,
      };

  factory DayForecast.fromMap(Map<dynamic, dynamic> m) => DayForecast(
        date: DateTime.fromMillisecondsSinceEpoch((m['date'] as num).toInt()),
        tMax: (m['tMax'] as num).toDouble(),
        tMin: (m['tMin'] as num).toDouble(),
        rainChance: (m['rain'] as num).toInt(),
        gustKmh: (m['gust'] as num).toDouble(),
        code: (m['code'] as num).toInt(),
      );
}

class WeatherForecast {
  const WeatherForecast({
    required this.districtId,
    required this.fetchedAt,
    required this.days,
  });

  final String districtId;
  final DateTime fetchedAt;
  final List<DayForecast> days;

  /// Parses the Open-Meteo `daily` block. Missing values become 0.
  factory WeatherForecast.fromOpenMeteo(
      Map<String, dynamic> json, String districtId, DateTime fetchedAt) {
    final daily = json['daily'] as Map<String, dynamic>;
    final times = (daily['time'] as List<dynamic>).cast<String>();
    double num0(String key, int i) {
      final list = daily[key] as List<dynamic>?;
      final v = (list != null && i < list.length) ? list[i] : null;
      return v is num ? v.toDouble() : 0;
    }

    return WeatherForecast(
      districtId: districtId,
      fetchedAt: fetchedAt,
      days: [
        for (var i = 0; i < times.length; i++)
          DayForecast(
            date: DateTime.parse(times[i]),
            tMax: num0('temperature_2m_max', i),
            tMin: num0('temperature_2m_min', i),
            rainChance: num0('precipitation_probability_max', i).round(),
            gustKmh: num0('wind_gusts_10m_max', i),
            code: num0('weather_code', i).round(),
          ),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
        'districtId': districtId,
        'fetchedAt': fetchedAt.millisecondsSinceEpoch,
        'days': [for (final d in days) d.toMap()],
      };

  factory WeatherForecast.fromMap(Map<dynamic, dynamic> m) => WeatherForecast(
        districtId: m['districtId'] as String,
        fetchedAt: DateTime.fromMillisecondsSinceEpoch((m['fetchedAt'] as num).toInt()),
        days: [
          for (final d in (m['days'] as List<dynamic>))
            if (d is Map) DayForecast.fromMap(d),
        ],
      );
}

class WeatherTip {
  const WeatherTip(this.signal, this.title, this.text);

  final Signal signal;
  final String title;
  final String text;
}

class WeatherRules {
  WeatherRules._();

  static const gustDanger = 62.0; // km/h
  static const gustWarn = 40.0;
  static const rainHigh = 70; // %
  static const hotDay = 34.0; // °C
  static const coldNight = 15.0;

  static Signal stormSignal(int code, double gust) {
    if (code >= 95 || gust >= gustDanger) return Signal.danger;
    if (gust >= gustWarn || code == 65 || code == 82) return Signal.warn;
    return Signal.ok;
  }

  static String label(int code) {
    if (code == 0) return 'রোদ';
    if (code <= 2) return 'হালকা মেঘ';
    if (code == 3) return 'মেঘলা';
    if (code == 45 || code == 48) return 'কুয়াশা';
    if (code >= 51 && code <= 57) return 'গুঁড়ি গুঁড়ি বৃষ্টি';
    if (code >= 61 && code <= 67) return 'বৃষ্টি';
    if (code >= 80 && code <= 82) return 'ঝড়ো বৃষ্টি';
    if (code >= 95) return 'বজ্রসহ ঝড়';
    return 'মেঘলা';
  }

  static String emoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 2) return '⛅';
    if (code == 3) return '☁️';
    if (code == 45 || code == 48) return '🌫️';
    if (code >= 51 && code <= 67) return '🌧️';
    if (code >= 80 && code <= 82) return '🌧️';
    if (code >= 95) return '⛈️';
    return '☁️';
  }

  /// One simple pond tip for the coming days (most urgent first).
  static WeatherTip tip(List<DayForecast> days) {
    if (days.isEmpty) {
      return const WeatherTip(Signal.ok, 'পুকুরের পরামর্শ', 'নিয়মমতো খাবার দিন, পানির রং দেখুন।');
    }
    if (days.any((d) => d.storm == Signal.danger)) {
      return const WeatherTip(Signal.danger, 'ঝড়ের আগে',
          'পুকুরের পাড় উঁচু করুন, চারপাশে জাল দিয়ে ঘিরে দিন, খাবার কম দিন। সরকারি সতর্ক সংকেত রেডিও/টিভিতে শুনুন।');
    }
    if (days.any((d) => d.rainChance >= rainHigh)) {
      return const WeatherTip(Signal.warn, 'বৃষ্টির আগে',
          'বৃষ্টির দিন খাবার কম দিন। বৃষ্টির পর প্রতি শতকে ২৫০ গ্রাম চুন দিন, পাড় দেখে নিন যেন মাছ বেরিয়ে না যায়।');
    }
    if (days.any((d) => d.tMax >= hotDay)) {
      return const WeatherTip(Signal.warn, 'গরমের আগে',
          'দুপুরে খাবার দেবেন না, সকাল-বিকালে দিন। পুকুরে পানি বাড়ান, ভোরে এরেটর চালান বা পানি নাড়ুন।');
    }
    if (days.any((d) => d.tMin <= coldNight)) {
      return const WeatherTip(Signal.warn, 'ঠান্ডার আগে',
          'খাবার কমিয়ে দিন, রোদ উঠলে খাবার দিন। মাছের গায়ে দাগ দেখলে রোগ চেক করুন।');
    }
    return const WeatherTip(Signal.ok, 'আবহাওয়া ভালো',
        'নিয়মমতো খাবার দিন, প্রতিদিন পানির রং ও মাছের আচরণ দেখুন।');
  }
}
