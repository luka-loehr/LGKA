import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:convert';
import '../utils/app_logger.dart';
import '../utils/app_info.dart';

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


  Future<List<WeatherData>> fetchWeatherData() async {
    AppLogger.network('Fetching weather data');
    
    try {
      AppLogger.debug('Making HTTP request to weather service', module: 'WeatherService');
      final response = await http.get(
        Uri.parse(csvUrl),
        headers: {
          'User-Agent': AppInfo.userAgent,
        },
      ).timeout(const Duration(seconds: 10));
      
      AppLogger.debug('Response status: ${response.statusCode}', module: 'WeatherService');
      
      if (response.statusCode != 200) {
        AppLogger.error('Weather fetch failed: HTTP ${response.statusCode}', module: 'WeatherService');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }

      // Safe UTF-8 decoding with error handling
      String csvString;
      try {
        csvString = utf8.decode(response.bodyBytes, allowMalformed: true);
      } catch (e) {
        AppLogger.error('Failed to decode UTF-8 response', module: 'WeatherService', error: e);
        throw Exception('Invalid response encoding');
      }
      AppLogger.debug('Decoded ${csvString.length} characters', module: 'WeatherService');

      // Add safety check for CSV parsing to handle corrupted data
      List<List<dynamic>> csvData;
      try {
        csvData = const CsvToListConverter(
          eol: '\n',
          fieldDelimiter: ';',
        ).convert(csvString);
      } catch (e) {
        AppLogger.error('Failed to parse CSV data', module: 'WeatherService', error: e);
        throw Exception('Invalid CSV format received from weather service');
      }

      AppLogger.debug('Parsed ${csvData.length} CSV rows', module: 'WeatherService');
      
      if (csvData.isEmpty) {
        AppLogger.error('Empty weather data received', module: 'WeatherService');
        throw Exception('CSV data is empty');
      }

      // Limit data processing to prevent memory issues with massive CSVs
      // Only process the most recent 24 hours of data (1440 minutes max)
      const int maxDataPoints = 1440; // 24 hours * 60 minutes
      final int startIndex = csvData.length > maxDataPoints + 1 ? csvData.length - maxDataPoints : 1;
      final int actualRows = csvData.length - startIndex;

      AppLogger.debug('Processing ${actualRows} data points (limited to last 24h)', module: 'WeatherService');

      // Parse data with memory safety limits
      final List<WeatherData> allWeatherData = [];
      int successfulRows = 0;
      int skippedRows = 0;
      int errorRows = 0;

      // Skip header row and process limited data range
      for (int i = startIndex; i < csvData.length; i++) {
        final row = csvData[i];
        
        if (row.length < 7) {
          skippedRows++;
          continue;
        }
        
        try {
          // Safe element access with null checks
          final windSpeedValue = row.length > 0 ? row[0] : null;
          final windDirectionValue = row.length > 1 ? row[1] : null;
          final temperatureValue = row.length > 2 ? row[2] : null;
          final humidityValue = row.length > 3 ? row[3] : null;
          final precipitationValue = row.length > 4 ? row[4] : null;
          final pressureValue = row.length > 5 ? row[5] : null;
          final radiationValue = row.length > 6 ? row[6] : null;

          // Calculate minutes from midnight based on actual data position
          final dataIndex = i - startIndex;
          final minutesSinceMidnight = dataIndex;
          final now = DateTime.now();
          final time = DateTime(now.year, now.month, now.day, 0, 0)
              .add(Duration(minutes: minutesSinceMidnight));
          
          final weatherData = WeatherData(
            time: time,
            windSpeed: _parseDouble(windSpeedValue),
            windDirection: windDirectionValue?.toString() ?? '',
            temperature: _parseDouble(temperatureValue),
            humidity: _parseDouble(humidityValue),
            precipitation: _parseDouble(precipitationValue),
            pressure: _parseDouble(pressureValue),
            radiation: _parseDouble(radiationValue),
          );
          
          allWeatherData.add(weatherData);
          successfulRows++;
        } catch (e) {
          errorRows++;
        }
      }
      
      if (allWeatherData.isNotEmpty) {
        final firstTemp = allWeatherData.first.temperature;
        final lastTemp = allWeatherData.last.temperature;
        AppLogger.success('Loaded ${allWeatherData.length} points ($firstTemp°C → $lastTemp°C)', module: 'WeatherService');
      }
      
      return allWeatherData;
    } catch (e) {
      AppLogger.error('Weather fetch failed', module: 'WeatherService', error: e);
      throw Exception('Error fetching weather data: $e');
    }
  }

  /// Get the latest weather data point for real-time display
  Future<WeatherData?> getLatestWeatherData() async {
    try {
      final response = await http.get(
        Uri.parse(csvUrl),
        headers: {
          'User-Agent': AppInfo.userAgent,
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        AppLogger.error('Failed to fetch latest weather: HTTP ${response.statusCode}', module: 'WeatherService');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }

      // Safe UTF-8 decoding with error handling
      String csvString;
      try {
        csvString = utf8.decode(response.bodyBytes, allowMalformed: true);
      } catch (e) {
        AppLogger.error('Failed to decode UTF-8 response for latest weather', module: 'WeatherService', error: e);
        return null;
      }

      // Add safety check for CSV parsing to handle corrupted data
      List<List<dynamic>> csvData;
      try {
        csvData = const CsvToListConverter(
          eol: '\n',
          fieldDelimiter: ';',
        ).convert(csvString);
      } catch (e) {
        AppLogger.error('Failed to parse latest weather CSV data', module: 'WeatherService', error: e);
        return null; // Return null instead of throwing for latest data
      }
      
      if (csvData.length < 2) {
        return null;
      }

      final lastRow = csvData.last;
      
      if (lastRow.length < 7) {
        return null;
      }

      // Safe element access with null checks
      final windSpeedValue = lastRow.length > 0 ? lastRow[0] : null;
      final windDirectionValue = lastRow.length > 1 ? lastRow[1] : null;
      final temperatureValue = lastRow.length > 2 ? lastRow[2] : null;
      final humidityValue = lastRow.length > 3 ? lastRow[3] : null;
      final precipitationValue = lastRow.length > 4 ? lastRow[4] : null;
      final pressureValue = lastRow.length > 5 ? lastRow[5] : null;
      final radiationValue = lastRow.length > 6 ? lastRow[6] : null;
      
      final minutesSinceMidnight = csvData.length - 2;
      final now = DateTime.now();
      final time = DateTime(now.year, now.month, now.day, 0, 0)
          .add(Duration(minutes: minutesSinceMidnight));
      
      final weatherData = WeatherData(
        time: time,
        windSpeed: _parseDouble(windSpeedValue),
        windDirection: windDirectionValue?.toString() ?? '',
        temperature: _parseDouble(temperatureValue),
        humidity: _parseDouble(humidityValue),
        precipitation: _parseDouble(precipitationValue),
        pressure: _parseDouble(pressureValue),
        radiation: _parseDouble(radiationValue),
      );
      
      return weatherData;
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
    
    // Safe access - already checked isEmpty above
    if (fullData.isNotEmpty) {
      sampledData.add(fullData.first);
      
      for (int i = samplingRate; i < length - samplingRate; i += samplingRate) {
        if (i < fullData.length) {
          sampledData.add(fullData[i]);
        }
      }
      
      if (fullData.length > 1 && fullData.last != sampledData.last) {
        sampledData.add(fullData.last);
      }
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