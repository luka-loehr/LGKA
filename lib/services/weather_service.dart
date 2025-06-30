import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_cache_service.dart';

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
  static const String _cacheKey = 'weather_data_cache';
  static const String _cacheTimeKey = 'weather_data_cache_time';
  static const Duration _cacheValidDuration = Duration(minutes: 10);
  
  // In-memory cache
  List<WeatherData>? _cachedWeatherData;
  DateTime? _lastFetchTime;

  /// Get the last cache update time
  Future<DateTime?> getLastCacheTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimeMs = prefs.getInt(_cacheTimeKey);
      if (cacheTimeMs != null) {
        return DateTime.fromMillisecondsSinceEpoch(cacheTimeMs);
      }
    } catch (e) {
      print('❌ [WeatherService] Error getting cache time: $e');
    }
    return null;
  }



  /// Returns cached data if available and valid, null otherwise
  Future<List<WeatherData>?> getCachedData() async {
    // First check in-memory cache
    if (_cachedWeatherData != null && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheValidDuration) {
        print('🌤️ [WeatherService] Returning in-memory cached data');
        return _cachedWeatherData;
      }
    }
    
    // Check persistent cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final cacheTimeMs = prefs.getInt(_cacheTimeKey);
      
      if (cachedJson != null && cacheTimeMs != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimeMs);
        final timeSinceCache = DateTime.now().difference(cacheTime);
        
        if (timeSinceCache < _cacheValidDuration) {
          print('🌤️ [WeatherService] Loading data from persistent cache');
          final List<dynamic> jsonList = jsonDecode(cachedJson);
          final weatherData = jsonList.map((json) => WeatherData.fromJson(json)).toList();
          
          // Update in-memory cache
          _cachedWeatherData = weatherData;
          _lastFetchTime = cacheTime;
          
          return weatherData;
        } else {
          print('🌤️ [WeatherService] Persistent cache expired');
        }
      }
    } catch (e) {
      print('❌ [WeatherService] Error loading from persistent cache: $e');
    }
    
    return null;
  }

  /// Save data to persistent cache
  Future<void> _saveToCache(List<WeatherData> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = data.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      
      print('🌤️ [WeatherService] Data saved to persistent cache');
    } catch (e) {
      print('❌ [WeatherService] Error saving to persistent cache: $e');
    }
  }



  Future<List<WeatherData>> fetchWeatherData() async {
    print('🌤️ [WeatherService] Starting fetchWeatherData()');
    
    // Check cache first
    final cachedData = await getCachedData();
    if (cachedData != null) {
      print('🌤️ [WeatherService] Returning cached data (${cachedData.length} items)');
      return cachedData;
    }
    
    print('🌤️ [WeatherService] No valid cache, fetching fresh data');
    
    print('🌤️ [WeatherService] URL: $csvUrl');
    
    try {
      print('🌤️ [WeatherService] Making HTTP request...');
      final response = await http.get(Uri.parse(csvUrl));
      
      print('🌤️ [WeatherService] Response status code: ${response.statusCode}');
      print('🌤️ [WeatherService] Response headers: ${response.headers}');
      print('🌤️ [WeatherService] Response body length: ${response.bodyBytes.length} bytes');
      
      if (response.statusCode != 200) {
        print('❌ [WeatherService] HTTP error: ${response.statusCode}');
        print('❌ [WeatherService] Response body: ${response.body}');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }

      // Decode the response body with proper encoding
      final csvString = utf8.decode(response.bodyBytes);
      print('🌤️ [WeatherService] Decoded CSV string length: ${csvString.length} characters');
      print('🌤️ [WeatherService] First 500 characters of CSV:');
      print(csvString.length > 500 ? csvString.substring(0, 500) + '...' : csvString);
      
      // Parse CSV
      print('🌤️ [WeatherService] Parsing CSV data...');
      final List<List<dynamic>> csvData = const CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ';',  // Changed from comma to semicolon!
      ).convert(csvString);
      
      print('🌤️ [WeatherService] CSV parsed. Total rows: ${csvData.length}');
      
      if (csvData.isEmpty) {
        print('❌ [WeatherService] CSV data is empty');
        throw Exception('CSV data is empty');
      }

      // Print header row for debugging
      if (csvData.isNotEmpty) {
        print('🌤️ [WeatherService] Header row: ${csvData[0]}');
        print('🌤️ [WeatherService] Header row length: ${csvData[0].length}');
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
          if (skippedRows == 0) {
            print('⚠️ [WeatherService] Skipping incomplete rows...');
          }
          skippedRows++;
          continue; // Skip incomplete rows
        }
        
        try {
          // Calculate time from row number (row 2 = 00:01, row 3 = 00:02, etc.)
          final minutesSinceMidnight = i - 1;
          final now = DateTime.now();
          final time = DateTime(now.year, now.month, now.day, 0, 0)
              .add(Duration(minutes: minutesSinceMidnight));
          
          final windSpeed = _parseDouble(row[0]);
          final windDirection = row[1].toString();
          final temperature = _parseDouble(row[2]);
          final humidity = _parseDouble(row[3]);
          final precipitation = _parseDouble(row[4]);
          final pressure = _parseDouble(row[5]);
          final radiation = _parseDouble(row[6]);
          
          final weatherData = WeatherData(
            time: time,
            windSpeed: windSpeed,
            windDirection: windDirection,
            temperature: temperature,
            humidity: humidity,
            precipitation: precipitation,
            pressure: pressure,
            radiation: radiation,
          );
          
          allWeatherData.add(weatherData);
          successfulRows++;
          
          // Only log first 3 successful rows to avoid spam
          if (successfulRows <= 3) {
            print('✅ [WeatherService] Successfully added weather data for $time');
          }
        } catch (e) {
          // Skip malformed rows
          print('❌ [WeatherService] Error parsing row $i: $e');
          print('❌ [WeatherService] Problematic row data: $row');
          errorRows++;
        }
      }
      
      print('🌤️ [WeatherService] Processing complete:');
      print('    Total rows in CSV: ${csvData.length - 1}');
      print('    Successful rows: $successfulRows');
      print('    Skipped rows: $skippedRows');
      print('    Error rows: $errorRows');
      print('    Final weather data points: ${allWeatherData.length}');
      
      if (allWeatherData.isNotEmpty) {
        print('🌤️ [WeatherService] First data point: ${allWeatherData.first.time} - ${allWeatherData.first.temperature}°C');
        print('🌤️ [WeatherService] Last data point: ${allWeatherData.last.time} - ${allWeatherData.last.temperature}°C');
      }
      
      // Cache all data in memory and persistent storage
      _cachedWeatherData = allWeatherData;
      _lastFetchTime = DateTime.now();
      await _saveToCache(allWeatherData);
      
      // Also save to offline cache
      await OfflineCache.saveWeatherData(allWeatherData);
      
      print('🌤️ [WeatherService] Data cached successfully');
      
      return allWeatherData;
    } catch (e) {
      print('❌ [WeatherService] Fatal error in fetchWeatherData: $e');
      print('❌ [WeatherService] Stack trace: ${StackTrace.current}');
      
      // Try to load from offline cache if network fails
      print('🌤️ [WeatherService] Attempting to load from offline cache');
      final offlineData = await OfflineCache.getWeatherData();
      if (offlineData != null && offlineData.isNotEmpty) {
        print('🌤️ [WeatherService] Loaded ${offlineData.length} items from offline cache');
        return offlineData;
      }
      
      throw Exception('Error fetching weather data: $e');
    }
  }

  /// Get the latest weather data point for real-time display
  Future<WeatherData?> getLatestWeatherData() async {
    print('🌤️ [WeatherService] Getting latest weather data');
    
    try {
      print('🌤️ [WeatherService] Making HTTP request for latest data...');
      final response = await http.get(Uri.parse(csvUrl));
      
      if (response.statusCode != 200) {
        print('❌ [WeatherService] HTTP error: ${response.statusCode}');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }

      final csvString = utf8.decode(response.bodyBytes);
      final List<List<dynamic>> csvData = const CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ';',
      ).convert(csvString);
      
      if (csvData.length < 2) {
        print('❌ [WeatherService] Not enough data in CSV');
        return null;
      }

      // Get the last row (most recent data)
      final lastRow = csvData.last;
      
      if (lastRow.length < 7) {
        print('❌ [WeatherService] Last row incomplete');
        return null;
      }
      
      // Calculate time for the last row
      final minutesSinceMidnight = csvData.length - 2; // -1 for header, -1 for 0-based index
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
      
      print('🌤️ [WeatherService] Latest data: ${weatherData.time} - ${weatherData.temperature}°C');
      return weatherData;
    } catch (e) {
      print('❌ [WeatherService] Error getting latest weather data: $e');
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
      print('📊 [WeatherService] No downsampling needed for ${length} data points');
      return fullData;
    }
    
    final List<WeatherData> sampledData = [];
    
    // Always include the first data point
    sampledData.add(fullData.first);
    
    // Sample intermediate points with better distribution
    for (int i = samplingRate; i < length - samplingRate; i += samplingRate) {
      sampledData.add(fullData[i]);
    }
    
    // Always include the last data point (most recent)
    if (fullData.length > 1) {
      sampledData.add(fullData.last);
    }
    
    print('📊 [WeatherService] Downsampled ${length} points to ${sampledData.length} (every ${samplingRate}th value)');
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