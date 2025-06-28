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
    try {
      final response = await http.get(Uri.parse(csvUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }

      // Decode the response body with proper encoding
      final csvString = utf8.decode(response.bodyBytes);
      
      // Parse CSV
      final List<List<dynamic>> csvData = const CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ',',
      ).convert(csvString);
      
      if (csvData.isEmpty) {
        throw Exception('CSV data is empty');
      }

      final List<WeatherData> weatherDataList = [];
      
      // Skip header row and process data
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        
        if (row.length < 7) continue; // Skip incomplete rows
        
        try {
          // Calculate time from row number (row 2 = 00:01, row 3 = 00:02, etc.)
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
          
          weatherDataList.add(weatherData);
        } catch (e) {
          // Skip malformed rows
          print('Error parsing row $i: $e');
        }
      }
      
      return weatherDataList;
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Handle German decimal format (comma as decimal separator)
      final normalizedValue = value.replaceAll(',', '.');
      return double.tryParse(normalizedValue) ?? 0.0;
    }
    return 0.0;
  }
} 