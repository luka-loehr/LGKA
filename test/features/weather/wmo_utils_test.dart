import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather_bg_null_safety/flutter_weather_bg.dart';
import 'package:lgka_flutter/features/weather/domain/weather_models.dart';
import 'package:weather_icons/weather_icons.dart';

void main() {
  test('returns german weather description for known and unknown codes', () {
    expect(WmoUtils.description(0), 'Klarer Himmel');
    expect(WmoUtils.description(999), 'Unbekannt');
  });

  test('maps day-night weather types for clear and fallback codes', () {
    expect(WmoUtils.weatherType(0, true), WeatherType.sunny);
    expect(WmoUtils.weatherType(0, false), WeatherType.sunnyNight);
    expect(WmoUtils.weatherType(999, true), WeatherType.cloudy);
  });

  test('maps icons for rainy and unknown weather codes', () {
    expect(WmoUtils.icon(61, true), WeatherIcons.day_rain);
    expect(WmoUtils.icon(999, false), WeatherIcons.cloudy);
  });
}
