import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:convert';
import '../utils/app_logger.dart';
import '../utils/app_info.dart';
import '../utils/retry_util.dart';

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

  // JSON serialization
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
        temperature: _safeToDouble(json['temperature'], 0.0),
        humidity: _safeToDouble(json['humidity'], 0.0),
        windSpeed: _safeToDouble(json['windSpeed'], 0.0),
        windDirection: json['windDirection']?.toString() ?? '',
        precipitation: _safeToDouble(json['precipitation'], 0.0),
        pressure: _safeToDouble(json['pressure'], 0.0),
        radiation: _safeToDouble(json['radiation'], 0.0),
      );
    } catch (e) {
      // Return default WeatherData if parsing fails completely
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

  /// Safely convert a value to double with a default fallback
  static double _safeToDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    try {
      return (value as num).toDouble();
    } catch (_) {
      return defaultValue;
    }
  }
}

class WeatherService {
  static const String csvUrl = 'https://lessing-gymnasium-karlsruhe.de/wetter/lg_wetter_heute.csv';
  
  // Safety limits to prevent memory exhaustion
  static const int maxCsvSizeBytes = 10 * 1024 * 1024; // 10MB max

  Future<List<WeatherData>> fetchWeatherData() async {
    AppLogger.network('Fetching weather data');
    
    return RetryUtil.retry<List<WeatherData>>(
      operation: () async {
        // HTTP request with timeout
        final response = await http.get(
          Uri.parse(csvUrl),
          headers: {'User-Agent': AppInfo.userAgent},
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode != 200) {
          throw Exception('Failed to load weather data: ${response.statusCode}');
        }

        // Decode and validate size
        final csvString = utf8.decode(response.bodyBytes, allowMalformed: true);
        if (csvString.length > maxCsvSizeBytes) {
          throw Exception('CSV data too large (${(csvString.length / 1024 / 1024).toStringAsFixed(1)}MB). Maximum allowed: ${(maxCsvSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB');
        }

        // Parse CSV
        final csvData = const CsvToListConverter(
          eol: '\n',
          fieldDelimiter: ';',
        ).convert(csvString);
        
        if (csvData.isEmpty) {
          throw Exception('CSV data is empty');
        }

        // Limit to last 24 hours (1440 minutes) to prevent memory issues
        const int maxDataPoints = 1440;
        final int startIndex = csvData.length > maxDataPoints + 1 ? csvData.length - maxDataPoints : 1;

        // Parse data rows
        final List<WeatherData> allWeatherData = [];
        for (int i = startIndex; i < csvData.length; i++) {
          final row = csvData[i];
          if (row.length < 7) continue;
          
          try {
            final dataIndex = i - startIndex;
            final now = DateTime.now();
            final time = DateTime(now.year, now.month, now.day, 0, 0)
                .add(Duration(minutes: dataIndex));
            
            allWeatherData.add(WeatherData(
              time: time,
              windSpeed: _parseDouble(row[0]),
              windDirection: row[1]?.toString() ?? '',
              temperature: _parseDouble(row[2]),
              humidity: _parseDouble(row[3]),
              precipitation: _parseDouble(row[4]),
              pressure: _parseDouble(row[5]),
              radiation: _parseDouble(row[6]),
            ));
          } catch (e) {
            // Skip invalid rows
          }
        }
        
        if (allWeatherData.isNotEmpty) {
          AppLogger.success('Loaded ${allWeatherData.length} points (${allWeatherData.first.temperature}°C → ${allWeatherData.last.temperature}°C)', module: 'WeatherService');
        } else {
          throw Exception('No valid weather data found');
        }
        
        return allWeatherData;
      },
      maxRetries: 2,
      operationName: 'WeatherService',
      shouldRetry: RetryUtil.isRetryableError,
    ).catchError((e) {
      AppLogger.error('Weather fetch failed', module: 'WeatherService', error: e);
      throw e;
    });
  }

  /// Get the latest weather data point for real-time display
  Future<WeatherData?> getLatestWeatherData() async {
    try {
      return await RetryUtil.retry<WeatherData?>(
        operation: () async {
          final response = await http.get(
            Uri.parse(csvUrl),
            headers: {'User-Agent': AppInfo.userAgent},
          ).timeout(const Duration(seconds: 10));
          
          if (response.statusCode != 200) return null;

          final csvString = utf8.decode(response.bodyBytes, allowMalformed: true);
          final csvData = const CsvToListConverter(
            eol: '\n',
            fieldDelimiter: ';',
          ).convert(csvString);
          
          if (csvData.length < 2) return null;
          
          final lastRow = csvData.last;
          if (lastRow.length < 7) return null;
          
          final minutesSinceMidnight = csvData.length - 2;
          final now = DateTime.now();
          final time = DateTime(now.year, now.month, now.day, 0, 0)
              .add(Duration(minutes: minutesSinceMidnight));
          
          return WeatherData(
            time: time,
            windSpeed: _parseDouble(lastRow[0]),
            windDirection: lastRow[1]?.toString() ?? '',
            temperature: _parseDouble(lastRow[2]),
            humidity: _parseDouble(lastRow[3]),
            precipitation: _parseDouble(lastRow[4]),
            pressure: _parseDouble(lastRow[5]),
            radiation: _parseDouble(lastRow[6]),
          );
        },
        maxRetries: 2,
        operationName: 'WeatherService',
        shouldRetry: RetryUtil.isRetryableError,
      );
    } catch (e) {
      AppLogger.error('Error getting latest weather data', module: 'WeatherService', error: e);
      return null;
    }
  }

  /// Downsample data for chart performance while preserving latest data for display boxes
  List<WeatherData> downsampleForChart(List<WeatherData> fullData) {
    if (fullData.isEmpty) return fullData;
    
    final length = fullData.length;
    int samplingRate = 1; // Show every nth value
    
    // More aggressive downsampling for better UI performance
    if (length >= 2000) {
      samplingRate = 100; // Show every 100th value for very large datasets
    } else if (length >= 1000) {
      samplingRate = 60; // Show every 60th value
    } else if (length >= 600) {
      samplingRate = 40; // Show every 40th value  
    } else if (length >= 300) {
      samplingRate = 25; // Show every 25th value
    } else if (length >= 150) {
      samplingRate = 15; // Show every 15th value
    } else if (length >= 100) {
      samplingRate = 8; // Show every 8th value
    }
    
    if (samplingRate == 1) {
      return fullData;
    }
    
    final List<WeatherData> sampledData = [];
    
    sampledData.add(fullData.first);
    
    for (int i = samplingRate; i < length - samplingRate; i += samplingRate) {
      sampledData.add(fullData[i]);
    }
    
    if (fullData.length > 1) {
      sampledData.add(fullData.last);
    }
    
    AppLogger.debug('Downsampled $length → ${sampledData.length} points', module: 'WeatherService');
    return sampledData;
  }

  double _parseDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }
    
    if (value is double) {
      return value;
    }
    
    if (value is int) {
      return value.toDouble();
    }
    
    if (value is String) {
      // The CSV already uses dots as decimal separator, no need to replace
      return double.tryParse(value) ?? 0.0;
    }
    
    return 0.0;
  }
} 