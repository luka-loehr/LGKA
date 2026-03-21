// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_weather_bg_null_safety/flutter_weather_bg.dart'
    hide WeatherDataState;
import 'package:weather_icons/weather_icons.dart';

// ── WMO utility ──────────────────────────────────────────────────────────────

class WmoUtils {
  WmoUtils._();

  /// German description for a WMO weather code.
  static String description(int code) {
    switch (code) {
      case 0:  return 'Klarer Himmel';
      case 1:  return 'Überwiegend klar';
      case 2:  return 'Teilweise bewölkt';
      case 3:  return 'Bedeckt';
      case 45: return 'Nebel';
      case 48: return 'Gefrierender Nebel';
      case 51: return 'Leichter Nieselregen';
      case 53: return 'Mäßiger Nieselregen';
      case 55: return 'Dichter Nieselregen';
      case 56: return 'Leichter gefrierender Nieselregen';
      case 57: return 'Gefrierender Nieselregen';
      case 61: return 'Leichter Regen';
      case 63: return 'Mäßiger Regen';
      case 65: return 'Starker Regen';
      case 66: return 'Leichter gefrierender Regen';
      case 67: return 'Gefrierender Regen';
      case 71: return 'Leichter Schneefall';
      case 73: return 'Mäßiger Schneefall';
      case 75: return 'Starker Schneefall';
      case 77: return 'Schneekörner';
      case 80: return 'Leichte Regenschauer';
      case 81: return 'Mäßige Regenschauer';
      case 82: return 'Starke Regenschauer';
      case 85: return 'Leichte Schneeschauer';
      case 86: return 'Starke Schneeschauer';
      case 95: return 'Gewitter';
      case 96: return 'Gewitter mit Hagel';
      case 99: return 'Gewitter mit schwerem Hagel';
      default: return 'Unbekannt';
    }
  }

  /// Maps a WMO code + day/night flag to a [WeatherType] animation.
  static WeatherType weatherType(int code, bool isDay) {
    if (code == 0 || code == 1) return isDay ? WeatherType.sunny : WeatherType.sunnyNight;
    if (code == 2)              return isDay ? WeatherType.cloudy : WeatherType.cloudyNight;
    if (code == 3)              return isDay ? WeatherType.overcast : WeatherType.cloudyNight;
    if (code == 45 || code == 48) return WeatherType.foggy;
    if (code == 51 || code == 53 || code == 56) return WeatherType.lightRainy;
    if (code == 55 || code == 57 || code == 66 || code == 67) return WeatherType.middleRainy;
    if (code == 61 || code == 80) return WeatherType.lightRainy;
    if (code == 63 || code == 81) return WeatherType.middleRainy;
    if (code == 65 || code == 82) return WeatherType.heavyRainy;
    if (code == 71 || code == 77 || code == 85) return WeatherType.lightSnow;
    if (code == 73) return WeatherType.middleSnow;
    if (code == 75 || code == 86) return WeatherType.heavySnow;
    if (code == 95 || code == 96 || code == 99) return WeatherType.thunder;
    return isDay ? WeatherType.cloudy : WeatherType.cloudyNight;
  }

  /// Returns the best [IconData] from the weather_icons package for a WMO code.
  static IconData icon(int code, bool isDay) {
    switch (code) {
      case 0:
      case 1:  return isDay ? WeatherIcons.day_sunny : WeatherIcons.night_clear;
      case 2:  return isDay ? WeatherIcons.day_cloudy : WeatherIcons.night_alt_cloudy;
      case 3:  return WeatherIcons.cloudy;
      case 45:
      case 48: return WeatherIcons.fog;
      case 51:
      case 53: return isDay ? WeatherIcons.day_sprinkle : WeatherIcons.night_alt_sprinkle;
      case 55: return WeatherIcons.sprinkle;
      case 56:
      case 57: return WeatherIcons.sleet;
      case 61: return isDay ? WeatherIcons.day_rain : WeatherIcons.night_alt_rain;
      case 63: return WeatherIcons.rain;
      case 65: return WeatherIcons.rain_wind;
      case 66:
      case 67: return WeatherIcons.sleet;
      case 71: return isDay ? WeatherIcons.day_snow : WeatherIcons.night_alt_snow;
      case 73: return WeatherIcons.snow;
      case 75: return WeatherIcons.snow_wind;
      case 77: return WeatherIcons.snowflake_cold;
      case 80: return isDay ? WeatherIcons.day_showers : WeatherIcons.night_alt_showers;
      case 81: return WeatherIcons.showers;
      case 82: return WeatherIcons.storm_showers;
      case 85: return isDay ? WeatherIcons.day_snow : WeatherIcons.night_alt_snow;
      case 86: return WeatherIcons.snow_wind;
      case 95: return isDay ? WeatherIcons.day_thunderstorm : WeatherIcons.night_alt_thunderstorm;
      case 96:
      case 99: return WeatherIcons.thunderstorm;
      default: return WeatherIcons.cloudy;
    }
  }
}

// ── Models ───────────────────────────────────────────────────────────────────

/// Current weather conditions from Open-Meteo.
class CurrentWeather {
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windSpeed; // km/h
  final int windDeg;
  final double windGust; // km/h
  final int pressure; // hPa (mean sea level)
  final int clouds; // %
  final double visibility; // m
  final double uvi;
  final int weatherCode; // WMO code
  final bool isDay;
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
    required this.weatherCode,
    required this.isDay,
    required this.dt,
  });

  String get description => WmoUtils.description(weatherCode);
}

/// One hourly entry from Open-Meteo.
class HourlyForecast {
  final DateTime dt;
  final double temp;
  final int humidity;
  final double windSpeed; // km/h
  final int windDeg;
  final double pop; // 0.0–1.0
  final int weatherCode; // WMO code
  final bool isDay;

  const HourlyForecast({
    required this.dt,
    required this.temp,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.pop,
    required this.weatherCode,
    required this.isDay,
  });
}

/// One daily entry from Open-Meteo.
class DailyForecast {
  final DateTime dt;
  final DateTime sunrise;
  final DateTime sunset;
  final double tempMax;
  final double tempMin;
  final double pop; // 0.0–1.0
  final double uvi;
  final double windSpeed; // km/h max
  final int weatherCode; // WMO code

  const DailyForecast({
    required this.dt,
    required this.sunrise,
    required this.sunset,
    required this.tempMax,
    required this.tempMin,
    required this.pop,
    required this.uvi,
    required this.windSpeed,
    required this.weatherCode,
  });

  String get description => WmoUtils.description(weatherCode);
}
