// Copyright Luka Löhr 2026

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/weather_models.dart';
import '../../../../utils/app_logger.dart';

class WeatherResult {
  final CurrentWeather current;
  final List<HourlyForecast> hourly; // up to 48 entries
  final List<DailyForecast> daily; // up to 8 entries

  const WeatherResult({
    required this.current,
    required this.hourly,
    required this.daily,
  });
}

/// Fetches weather data from OpenWeatherMap One Call API 3.0.
/// Coordinates: LGKA school, Karlsruhe (49.00775°N, 8.375°E).
class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  // API key injected at build time: flutter run --dart-define-from-file=.env.local
  static const _apiKey =
      String.fromEnvironment('OWM_API_KEY', defaultValue: '');
  static const _lat = '49.00775';
  static const _lon = '8.375';
  static const _baseUrl =
      'https://api.openweathermap.org/data/3.0/onecall';
  static const _cacheDuration = Duration(minutes: 30);

  WeatherResult? _cache;
  DateTime? _cacheTimestamp;

  DateTime? get lastUpdateTime => _cacheTimestamp;

  bool get hasValidCache =>
      _cache != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;

  WeatherResult? get cachedResult => _cache;

  /// Returns the OWM icon URL for a given icon code, e.g. "02d".
  static String iconUrl(String icon) =>
      'https://openweathermap.org/img/wn/$icon@2x.png';

  Future<WeatherResult> fetchAll() async {
    if (hasValidCache) {
      AppLogger.debug('Weather: returning cached result', module: 'WeatherService');
      return _cache!;
    }

    final uri = Uri.parse(
      '$_baseUrl?lat=$_lat&lon=$_lon&appid=$_apiKey'
      '&units=metric&lang=de&exclude=minutely,alerts',
    );

    AppLogger.info('Weather: fetching from OWM One Call 3.0', module: 'WeatherService');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('OWM API ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    final current = CurrentWeather.fromJson(
        json['current'] as Map<String, dynamic>);
    final hourly = (json['hourly'] as List)
        .take(24)
        .map((e) => HourlyForecast.fromJson(e as Map<String, dynamic>))
        .toList();
    final daily = (json['daily'] as List)
        .map((e) => DailyForecast.fromJson(e as Map<String, dynamic>))
        .toList();

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
