// Copyright Luka Löhr 2026

/// Current weather conditions from OWM One Call 3.0
class CurrentWeather {
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windSpeed; // m/s
  final int windDeg;
  final double windGust;
  final int pressure; // hPa
  final int clouds; // %
  final int visibility; // m
  final double uvi;
  final String description;
  final String icon; // e.g. "02d"
  final String main; // e.g. "Clouds"
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime dt;

  const CurrentWeather({
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.windGust,
    required this.pressure,
    required this.clouds,
    required this.visibility,
    required this.uvi,
    required this.description,
    required this.icon,
    required this.main,
    required this.sunrise,
    required this.sunset,
    required this.dt,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    return CurrentWeather(
      temp: (json['temp'] as num).toDouble(),
      feelsLike: (json['feels_like'] as num).toDouble(),
      humidity: json['humidity'] as int,
      windSpeed: (json['wind_speed'] as num).toDouble(),
      windDeg: json['wind_deg'] as int,
      windGust: (json['wind_gust'] as num? ?? 0).toDouble(),
      pressure: json['pressure'] as int,
      clouds: json['clouds'] as int,
      visibility: json['visibility'] as int? ?? 10000,
      uvi: (json['uvi'] as num).toDouble(),
      description: weather['description'] as String,
      icon: weather['icon'] as String,
      main: weather['main'] as String,
      sunrise: DateTime.fromMillisecondsSinceEpoch(
          (json['sunrise'] as int) * 1000),
      sunset:
          DateTime.fromMillisecondsSinceEpoch((json['sunset'] as int) * 1000),
      dt: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
    );
  }
}

/// One hourly entry from OWM One Call 3.0 (48 entries available)
class HourlyForecast {
  final DateTime dt;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int windDeg;
  final double pop; // probability of precipitation 0.0–1.0
  final double? rain1h; // mm
  final double? snow1h; // mm
  final String description;
  final String icon;
  final String main;

  const HourlyForecast({
    required this.dt,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.pop,
    this.rain1h,
    this.snow1h,
    required this.description,
    required this.icon,
    required this.main,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final rain = json['rain'] as Map<String, dynamic>?;
    final snow = json['snow'] as Map<String, dynamic>?;
    return HourlyForecast(
      dt: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      temp: (json['temp'] as num).toDouble(),
      feelsLike: (json['feels_like'] as num).toDouble(),
      humidity: json['humidity'] as int,
      windSpeed: (json['wind_speed'] as num).toDouble(),
      windDeg: json['wind_deg'] as int,
      pop: (json['pop'] as num).toDouble(),
      rain1h: rain != null ? (rain['1h'] as num?)?.toDouble() : null,
      snow1h: snow != null ? (snow['1h'] as num?)?.toDouble() : null,
      description: weather['description'] as String,
      icon: weather['icon'] as String,
      main: weather['main'] as String,
    );
  }
}

/// One daily entry from OWM One Call 3.0 (8 entries available)
class DailyForecast {
  final DateTime dt;
  final DateTime sunrise;
  final DateTime sunset;
  final double tempDay;
  final double tempMin;
  final double tempMax;
  final double tempNight;
  final double feelsLikeDay;
  final int humidity;
  final double windSpeed;
  final int windDeg;
  final double pop;
  final double? rain; // mm
  final double? snow; // mm
  final double uvi;
  final String description;
  final String summary;
  final String icon;
  final String main;

  const DailyForecast({
    required this.dt,
    required this.sunrise,
    required this.sunset,
    required this.tempDay,
    required this.tempMin,
    required this.tempMax,
    required this.tempNight,
    required this.feelsLikeDay,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.pop,
    this.rain,
    this.snow,
    required this.uvi,
    required this.description,
    required this.summary,
    required this.icon,
    required this.main,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final temp = json['temp'] as Map<String, dynamic>;
    final feelsLike = json['feels_like'] as Map<String, dynamic>;
    return DailyForecast(
      dt: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      sunrise: DateTime.fromMillisecondsSinceEpoch(
          (json['sunrise'] as int) * 1000),
      sunset:
          DateTime.fromMillisecondsSinceEpoch((json['sunset'] as int) * 1000),
      tempDay: (temp['day'] as num).toDouble(),
      tempMin: (temp['min'] as num).toDouble(),
      tempMax: (temp['max'] as num).toDouble(),
      tempNight: (temp['night'] as num).toDouble(),
      feelsLikeDay: (feelsLike['day'] as num).toDouble(),
      humidity: json['humidity'] as int,
      windSpeed: (json['wind_speed'] as num).toDouble(),
      windDeg: json['wind_deg'] as int,
      pop: (json['pop'] as num).toDouble(),
      rain: (json['rain'] as num?)?.toDouble(),
      snow: (json['snow'] as num?)?.toDouble(),
      uvi: (json['uvi'] as num).toDouble(),
      description: weather['description'] as String,
      summary: json['summary'] as String? ?? '',
      icon: weather['icon'] as String,
      main: weather['main'] as String,
    );
  }
}
