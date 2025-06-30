// Copyright Luka Löhr 2025

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';

class OfflineCache {
  static const String _weatherDataKey = 'offline_weather_data';
  static const String _weatherTimeKey = 'offline_weather_time';
  static const String _pdfInfoKey = 'offline_pdf_info';
  static const String _offlineDir = 'offline_cache';
  
  // Save weather data to offline cache
  static Future<void> saveWeatherData(List<WeatherData> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = data.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_weatherDataKey, jsonString);
      await prefs.setInt(_weatherTimeKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('💾 [OfflineCache] Weather data saved to offline cache');
    } catch (e) {
      debugPrint('❌ [OfflineCache] Error saving weather data: $e');
    }
  }
  
  // Get weather data from offline cache
  static Future<List<WeatherData>?> getWeatherData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_weatherDataKey);
      
      if (cachedJson != null) {
        final List<dynamic> jsonList = jsonDecode(cachedJson);
        final weatherData = jsonList.map((json) => WeatherData.fromJson(json)).toList();
        debugPrint('💾 [OfflineCache] Weather data loaded from offline cache');
        return weatherData;
      }
    } catch (e) {
      debugPrint('❌ [OfflineCache] Error loading weather data: $e');
    }
    return null;
  }
  
  // Get weather data last update time
  static Future<DateTime?> getWeatherLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeMs = prefs.getInt(_weatherTimeKey);
      if (timeMs != null) {
        return DateTime.fromMillisecondsSinceEpoch(timeMs);
      }
    } catch (e) {
      debugPrint('❌ [OfflineCache] Error getting weather update time: $e');
    }
    return null;
  }
  
  // Save PDF to offline cache
  static Future<void> savePdf(File sourceFile, String weekday, String date, bool isToday) async {
    try {
      final dir = await _getOfflineDirectory();
      final filename = isToday ? 'offline_today.pdf' : 'offline_tomorrow.pdf';
      final targetFile = File('${dir.path}/$filename');
      
      // Copy file to offline cache
      await sourceFile.copy(targetFile.path);
      
      // Save metadata
      final prefs = await SharedPreferences.getInstance();
      final info = await _getPdfInfo() ?? {};
      
      info[isToday ? 'today' : 'tomorrow'] = {
        'weekday': weekday,
        'date': date,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_pdfInfoKey, jsonEncode(info));
      
      debugPrint('💾 [OfflineCache] PDF saved to offline cache: $weekday $date');
    } catch (e) {
      debugPrint('❌ [OfflineCache] Error saving PDF: $e');
    }
  }
  
  // Get PDF from offline cache
  static Future<File?> getPdf(bool isToday) async {
    try {
      final dir = await _getOfflineDirectory();
      final filename = isToday ? 'offline_today.pdf' : 'offline_tomorrow.pdf';
      final file = File('${dir.path}/$filename');
      
      if (await file.exists()) {
        debugPrint('💾 [OfflineCache] PDF loaded from offline cache');
        return file;
      }
    } catch (e) {
      debugPrint('❌ [OfflineCache] Error loading PDF: $e');
    }
    return null;
  }
  
  // Get PDF metadata
  static Future<Map<String, dynamic>?> getPdfInfo(bool isToday) async {
    try {
      final info = await _getPdfInfo();
      return info?[isToday ? 'today' : 'tomorrow'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ [OfflineCache] Error getting PDF info: $e');
    }
    return null;
  }
  
  // Get all PDF info
  static Future<Map<String, dynamic>?> _getPdfInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final infoJson = prefs.getString(_pdfInfoKey);
      if (infoJson != null) {
        return jsonDecode(infoJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('❌ [OfflineCache] Error loading PDF info: $e');
    }
    return null;
  }
  
  // Get offline cache directory
  static Future<Directory> _getOfflineDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${appDir.path}/$_offlineDir');
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    return offlineDir;
  }
  
  // Clear all offline cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_weatherDataKey);
      await prefs.remove(_weatherTimeKey);
      await prefs.remove(_pdfInfoKey);
      
      final dir = await _getOfflineDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      
      debugPrint('💾 [OfflineCache] All offline cache cleared');
    } catch (e) {
      debugPrint('❌ [OfflineCache] Error clearing cache: $e');
    }
  }
} 