// Copyright Luka Löhr 2026

/// Represents weather data at a specific point in time
class WeatherData {
  final DateTime time;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String windDirection;
  final double precipitation;
  final double pressure;
  final double radiation;

  WeatherData({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.precipitation,
    required this.pressure,
    required this.radiation,
  });

  /// JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'time': time.millisecondsSinceEpoch,
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'precipitation': precipitation,
      'pressure': pressure,
      'radiation': radiation,
    };
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    try {
      // Safe parsing with defaults for all fields
      final timeValue = json['time'];
      final time = timeValue != null
          ? DateTime.fromMillisecondsSinceEpoch(
              timeValue is int ? timeValue : int.tryParse(timeValue.toString()) ?? 0)
          : DateTime.now();

      return WeatherData(
        time: time,
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
        humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
        windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 0.0,
        windDirection: json['windDirection'] as String? ?? '',
        precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
        pressure: (json['pressure'] as num?)?.toDouble() ?? 0.0,
        radiation: (json['radiation'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      // Return default data if parsing fails
      return WeatherData(
        time: DateTime.now(),
        temperature: 0.0,
        humidity: 0.0,
        windSpeed: 0.0,
        windDirection: '',
        precipitation: 0.0,
        pressure: 0.0,
        radiation: 0.0,
      );
    }
  }
}
