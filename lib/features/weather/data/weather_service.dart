// Copyright Luka Löhr 2026

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/weather_models.dart';
import '../../../../utils/app_logger.dart';

class WeatherResult {
  final CurrentWeather current;
  final List<HourlyForecast> hourly; // current hour → midnight
  final List<DailyForecast> daily;   // 3 days

  const WeatherResult({
    required this.current,
    required this.hourly,
    required this.daily,
  });
}

/// Fetches weather data from Open-Meteo (free, no API key, unlimited).
/// Coordinates: LGKA school, Karlsruhe (49.00775°N, 8.375°E), elevation 122 m.
class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  static const _lat = '49.00775';
  static const _lon = '8.375';
  static const _elevation = '122';
  static const _cacheDuration = Duration(hours: 1);

  WeatherResult? _cache;
  DateTime? _cacheTimestamp;

  DateTime? get lastUpdateTime => _cacheTimestamp;

  bool get hasValidCache =>
      _cache != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;

  WeatherResult? get cachedResult => _cache;

  Future<WeatherResult> fetchAll() async {
    if (hasValidCache) {
      AppLogger.debug('Weather: returning cached result', module: 'WeatherService');
      return _cache!;
    }

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$_lat&longitude=$_lon&elevation=$_elevation'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature'
        ',weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m'
        ',pressure_msl,cloud_cover,visibility,uv_index,is_day'
      '&hourly=temperature_2m,relative_humidity_2m,weather_code'
        ',precipitation_probability,wind_speed_10m,wind_direction_10m,is_day'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min'
        ',precipitation_probability_max,uv_index_max,wind_speed_10m_max'
        ',sunrise,sunset'
      '&timezone=Europe%2FBerlin'
      '&forecast_days=3',
    );

    AppLogger.info('Weather: fetching from Open-Meteo', module: 'WeatherService');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Open-Meteo ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // ── Current ──────────────────────────────────────────────────────────────
    final c = json['current'] as Map<String, dynamic>;
    final current = CurrentWeather(
      temp: (c['temperature_2m'] as num).toDouble(),
      feelsLike: (c['apparent_temperature'] as num).toDouble(),
      humidity: c['relative_humidity_2m'] as int,
      windSpeed: (c['wind_speed_10m'] as num).toDouble(),
      windDeg: c['wind_direction_10m'] as int,
      windGust: (c['wind_gusts_10m'] as num).toDouble(),
      pressure: (c['pressure_msl'] as num).round(),
      clouds: c['cloud_cover'] as int,
      visibility: (c['visibility'] as num).toDouble(),
      uvi: (c['uv_index'] as num).toDouble(),
      weatherCode: c['weather_code'] as int,
      isDay: c['is_day'] == 1,
      dt: DateTime.parse(c['time'] as String),
    );

    // ── Hourly (current hour → midnight today) ────────────────────────────────
    final h = json['hourly'] as Map<String, dynamic>;
    final hTimes   = h['time'] as List;
    final hTemps   = h['temperature_2m'] as List;
    final hHumids  = h['relative_humidity_2m'] as List;
    final hCodes   = h['weather_code'] as List;
    final hPops    = h['precipitation_probability'] as List;
    final hWinds   = h['wind_speed_10m'] as List;
    final hDirs    = h['wind_direction_10m'] as List;
    final hIsDays  = h['is_day'] as List;

    final now = DateTime.now();
    final hourStart = DateTime(now.year, now.month, now.day, now.hour);
    final midnight  = DateTime(now.year, now.month, now.day + 1);

    final hourly = <HourlyForecast>[];
    for (var i = 0; i < hTimes.length; i++) {
      final dt = DateTime.parse(hTimes[i] as String);
      if (!dt.isBefore(hourStart) && dt.isBefore(midnight)) {
        hourly.add(HourlyForecast(
          dt: dt,
          temp: (hTemps[i] as num).toDouble(),
          humidity: hHumids[i] as int,
          weatherCode: hCodes[i] as int,
          pop: ((hPops[i] as num) / 100.0),
          windSpeed: (hWinds[i] as num).toDouble(),
          windDeg: hDirs[i] as int,
          isDay: hIsDays[i] == 1,
        ));
      }
    }

    // ── Daily (3 days) ────────────────────────────────────────────────────────
    final d = json['daily'] as Map<String, dynamic>;
    final dTimes    = d['time'] as List;
    final dCodes    = d['weather_code'] as List;
    final dMaxTemps = d['temperature_2m_max'] as List;
    final dMinTemps = d['temperature_2m_min'] as List;
    final dPops     = d['precipitation_probability_max'] as List;
    final dUvis     = d['uv_index_max'] as List;
    final dWinds    = d['wind_speed_10m_max'] as List;
    final dSunrises = d['sunrise'] as List;
    final dSunsets  = d['sunset'] as List;

    final daily = <DailyForecast>[];
    for (var i = 0; i < dTimes.length; i++) {
      daily.add(DailyForecast(
        dt: DateTime.parse(dTimes[i] as String),
        sunrise: DateTime.parse(dSunrises[i] as String),
        sunset: DateTime.parse(dSunsets[i] as String),
        tempMax: (dMaxTemps[i] as num).toDouble(),
        tempMin: (dMinTemps[i] as num).toDouble(),
        pop: ((dPops[i] as num) / 100.0),
        uvi: (dUvis[i] as num).toDouble(),
        windSpeed: (dWinds[i] as num).toDouble(),
        weatherCode: dCodes[i] as int,
      ));
    }

    final result = WeatherResult(current: current, hourly: hourly, daily: daily);
    _cache = result;
    _cacheTimestamp = DateTime.now();

    AppLogger.success(
        'Weather: ${current.temp.round()}° ${current.description} · '
        '${hourly.length}h hourly · ${daily.length} daily',
        module: 'WeatherService');
    return result;
  }

  void invalidateCache() => _cacheTimestamp = null;
}
