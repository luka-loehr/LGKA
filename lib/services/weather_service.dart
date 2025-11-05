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
    return WeatherData(
      time: DateTime.fromMillisecondsSinceEpoch(json['time']),
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
      windSpeed: json['windSpeed'].toDouble(),
      windDirection: json['windDirection'],
      precipitation: json['precipitation'].toDouble(),
      pressure: json['pressure'].toDouble(),
      radiation: json['radiation'].toDouble(),
    );
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
      ).timeout(const Duration(seconds: 7));
      
      AppLogger.debug('Response status: ${response.statusCode}', module: 'WeatherService');
      
      if (response.statusCode != 200) {
        AppLogger.error('Weather fetch failed: HTTP ${response.statusCode}', module: 'WeatherService');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }

      final csvString = utf8.decode(response.bodyBytes);
      AppLogger.debug('Decoded ${csvString.length} characters', module: 'WeatherService');
      
      final List<List<dynamic>> csvData = const CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ';',
      ).convert(csvString);
      
      AppLogger.debug('Parsed ${csvData.length} CSV rows', module: 'WeatherService');
      
      if (csvData.isEmpty) {
        AppLogger.error('Empty weather data received', module: 'WeatherService');
        throw Exception('CSV data is empty');
      }

      // Parse all data - no sampling, use every data point for maximum accuracy
      final List<WeatherData> allWeatherData = [];
      int successfulRows = 0;
      int skippedRows = 0;
      int errorRows = 0;
      
      // Skip header row and process all data
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        
        if (row.length < 7) {
          skippedRows++;
          continue;
        }
        
        try {
          final minutesSinceMidnight = i - 1;
          final now = DateTime.now();
          final time = DateTime(now.year, now.month, now.day, 0, 0)
              .add(Duration(minutes: minutesSinceMidnight));
          
          final weatherData = WeatherData(
            time: time,
            windSpeed: _parseDouble(row[0]),
            windDirection: row[1].toString(),
            temperature: _parseDouble(row[2]),
            humidity: _parseDouble(row[3]),
            precipitation: _parseDouble(row[4]),
            pressure: _parseDouble(row[5]),
            radiation: _parseDouble(row[6]),
          );
          
          allWeatherData.add(weatherData);
          successfulRows++;
        } catch (e) {
          errorRows++;
        }
      }
      
      if (allWeatherData.isNotEmpty) {
        AppLogger.success('Loaded ${allWeatherData.length} points (${allWeatherData.first.temperature}°C → ${allWeatherData.last.temperature}°C)', module: 'WeatherService');
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
      ).timeout(const Duration(seconds: 7));
      
      if (response.statusCode != 200) {
        AppLogger.error('Failed to fetch latest weather: HTTP ${response.statusCode}', module: 'WeatherService');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }

      final csvString = utf8.decode(response.bodyBytes);
      final List<List<dynamic>> csvData = const CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ';',
      ).convert(csvString);
      
      if (csvData.length < 2) {
        return null;
      }

      final lastRow = csvData.last;
      
      if (lastRow.length < 7) {
        return null;
      }
      
      final minutesSinceMidnight = csvData.length - 2;
      final now = DateTime.now();
      final time = DateTime(now.year, now.month, now.day, 0, 0)
          .add(Duration(minutes: minutesSinceMidnight));
      
      final weatherData = WeatherData(
        time: time,
        windSpeed: _parseDouble(lastRow[0]),
        windDirection: lastRow[1].toString(),
        temperature: _parseDouble(lastRow[2]),
        humidity: _parseDouble(lastRow[3]),
        precipitation: _parseDouble(lastRow[4]),
        pressure: _parseDouble(lastRow[5]),
        radiation: _parseDouble(lastRow[6]),
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