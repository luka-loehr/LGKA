import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> with AutomaticKeepAliveClientMixin {
  final WeatherService _weatherService = WeatherService();
  List<WeatherData> _weatherData = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _weatherService.fetchWeatherData();
      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.appBlueAccent),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Lade Wetterdaten...',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: AppColors.secondaryText.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Wetterdaten konnten nicht geladen werden',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Überprüfe deine Internetverbindung',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadWeatherData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Erneut versuchen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.appBlueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _weatherData.isEmpty
                  ? const Center(
                      child: Text(
                        'Keine Wetterdaten verfügbar',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Current weather data cards
                          if (_weatherData.isNotEmpty) ...[
                            // Temperature and time header
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.appSurface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.appBlueAccent.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Temperatur',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${_weatherData.last.temperature.toStringAsFixed(1)}°C',
                                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            color: AppColors.appBlueAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.appSurface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.appBlueAccent.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Luftfeuchtigkeit',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${_weatherData.last.humidity.toStringAsFixed(0)}%',
                                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            color: AppColors.appBlueAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Wind and pressure
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.appSurface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.appBlueAccent.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Wind',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${_weatherData.last.windSpeed.toStringAsFixed(1)} km/h',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: AppColors.primaryText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _weatherData.last.windDirection,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.appSurface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.appBlueAccent.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Luftdruck',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${_weatherData.last.pressure.toStringAsFixed(0)} hPa',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: AppColors.primaryText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Last update info
                            Text(
                              'Letzte Aktualisierung: ${DateFormat('HH:mm').format(_weatherData.last.time)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.secondaryText.withOpacity(0.7),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          // Temperature chart
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.appSurface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.appBlueAccent.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: SfCartesianChart(
                                primaryXAxis: DateTimeAxis(
                                  dateFormat: DateFormat.Hm(),
                                  intervalType: DateTimeIntervalType.hours,
                                  interval: 2,
                                  majorGridLines: const MajorGridLines(width: 0),
                                  labelStyle: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                primaryYAxis: NumericAxis(
                                  title: AxisTitle(
                                    text: 'Temperatur (°C)',
                                    textStyle: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                  majorGridLines: MajorGridLines(
                                    color: AppColors.secondaryText.withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                  labelStyle: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                title: ChartTitle(
                                  text: 'Temperaturverlauf heute',
                                  textStyle: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                legend: const Legend(isVisible: false),
                                tooltipBehavior: TooltipBehavior(
                                  enable: true,
                                  color: AppColors.appSurface,
                                  textStyle: const TextStyle(
                                    color: AppColors.primaryText,
                                  ),
                                  borderColor: AppColors.appBlueAccent,
                                  borderWidth: 1,
                                  format: 'point.x : point.y°C',
                                ),
                                series: <CartesianSeries<dynamic, dynamic>>[
                                  SplineSeries<WeatherData, DateTime>(
                                    dataSource: _weatherData,
                                    xValueMapper: (WeatherData data, _) => data.time,
                                    yValueMapper: (WeatherData data, _) => data.temperature,
                                    color: AppColors.appBlueAccent,
                                    width: 3,
                                    splineType: SplineType.cardinal,
                                    cardinalSplineTension: 0.8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
  }
} 