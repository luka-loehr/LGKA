import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:convert';

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
}

class WeatherService {
  static const String csvUrl = 'https://lessing-gymnasium-karlsruhe.de/wetter/lg_wetter_heute.csv';

  Future<List<WeatherData>> fetchWeatherData() async {
    print('🌤️ [WeatherService] Starting fetchWeatherData()');
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

      final List<WeatherData> weatherDataList = [];
      int successfulRows = 0;
      int skippedRows = 0;
      int errorRows = 0;
      
      // Skip header row and process data
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
          
          weatherDataList.add(weatherData);
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
      print('    Total rows processed: ${csvData.length - 1}');
      print('    Successful rows: $successfulRows');
      print('    Skipped rows: $skippedRows');
      print('    Error rows: $errorRows');
      print('    Final weather data list size: ${weatherDataList.length}');
      
      if (weatherDataList.isNotEmpty) {
        print('🌤️ [WeatherService] First data point: ${weatherDataList.first.time} - ${weatherDataList.first.temperature}°C');
        print('🌤️ [WeatherService] Last data point: ${weatherDataList.last.time} - ${weatherDataList.last.temperature}°C');
      }
      
      return weatherDataList;
    } catch (e) {
      print('❌ [WeatherService] Fatal error in fetchWeatherData: $e');
      print('❌ [WeatherService] Stack trace: ${StackTrace.current}');
      throw Exception('Error fetching weather data: $e');
    }
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