import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/data/bd_districts.dart';
import '../../core/storage/app_settings.dart';
import 'weather_models.dart';

class WeatherResult {
  const WeatherResult(this.forecast, {required this.fromCache});

  final WeatherForecast? forecast;

  /// true = internet failed, showing the last saved forecast.
  final bool fromCache;
}

/// Open-Meteo (free, no API key). The last forecast is saved so the screen
/// still shows something with no internet.
class WeatherService {
  WeatherService._();

  static const _cacheKey = 'weather_cache';

  static WeatherForecast? cached(String districtId) {
    final m = AppSettings.get(_cacheKey);
    if (m is! Map) return null;
    try {
      final f = WeatherForecast.fromMap(m);
      return f.districtId == districtId ? f : null;
    } catch (_) {
      return null;
    }
  }

  static Future<WeatherResult> load(District district) async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': district.lat.toString(),
        'longitude': district.lon.toString(),
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,'
            'precipitation_probability_max,wind_gusts_10m_max',
        'timezone': 'Asia/Dhaka',
        'forecast_days': '3',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('status ${res.statusCode}');
      final forecast = WeatherForecast.fromOpenMeteo(
        jsonDecode(res.body) as Map<String, dynamic>,
        district.id,
        DateTime.now(),
      );
      await AppSettings.put(_cacheKey, forecast.toMap());
      return WeatherResult(forecast, fromCache: false);
    } catch (_) {
      return WeatherResult(cached(district.id), fromCache: true);
    }
  }
}
