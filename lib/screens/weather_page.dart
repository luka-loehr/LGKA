import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import 'package:intl/intl.dart';

class WeatherPage extends ConsumerStatefulWidget {
  const WeatherPage({super.key});

  @override
  ConsumerState<WeatherPage> createState() => _WeatherPageState();
}

enum ChartType {
  temperature,
  humidity,
  windSpeed,
  pressure,
}

class _WeatherPageState extends ConsumerState<WeatherPage> with AutomaticKeepAliveClientMixin {
  List<WeatherData> _weatherData = [];
  bool _isLoading = true;
  bool _isUpdating = false; // Track if we're updating in background
  DateTime? _lastUpdateTime;
  String? _error;
  ChartType _selectedChart = ChartType.temperature;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    print('📱 [WeatherPage] Starting _loadWeatherData()');
    
    final weatherService = ref.read(weatherServiceProvider);
    
    // First, try to load cached data
    final cachedData = await weatherService.getCachedData();
    final cacheTime = await weatherService.getLastCacheTime();
    
    if (cachedData != null && cachedData.isNotEmpty) {
      print('📱 [WeatherPage] Using cached data');
      setState(() {
        _weatherData = cachedData;
        _lastUpdateTime = cacheTime;
        _isLoading = false;
        _error = null;
      });
      
      // Update data in background
      _updateDataInBackground();
    } else {
      // No cache, need to fetch fresh data
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      try {
        print('📱 [WeatherPage] No cache, fetching fresh data');
        final data = await weatherService.fetchWeatherData();
        
        if (mounted) {
          setState(() {
            _weatherData = data;
            _lastUpdateTime = DateTime.now();
            _isLoading = false;
          });
        }
      } catch (e) {
        print('❌ [WeatherPage] Error loading data: $e');
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  void _updateDataInBackground() {
    print('📱 [WeatherPage] Starting background update');
    setState(() {
      _isUpdating = true;
    });
    
    () async {
      try {
        final weatherService = ref.read(weatherServiceProvider);
        final freshData = await weatherService.fetchWeatherData();
        
        if (mounted && freshData.isNotEmpty) {
          print('📱 [WeatherPage] Background update successful');
          setState(() {
            _weatherData = freshData;
            _lastUpdateTime = DateTime.now();
            _isUpdating = false;
          });
        }
      } catch (e) {
        print('❌ [WeatherPage] Background update failed: $e');
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        }
      }
    }();
  }



  String _formatUpdateTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Gerade eben';
    } else if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Minute${difference.inMinutes == 1 ? '' : 'n'}';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Stunde${difference.inHours == 1 ? '' : 'n'}';
    } else {
      return DateFormat('dd.MM. HH:mm').format(time);
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
                          // Last update indicator
                          if (_lastUpdateTime != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.appSurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isUpdating) ...[
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.appBlueAccent.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    _isUpdating 
                                      ? 'Aktualisiere...'
                                      : 'Letzte Aktualisierung: ${_formatUpdateTime(_lastUpdateTime!)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Current weather data cards
                          if (_weatherData.isNotEmpty) ...[
                            // Temperature and time header
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedChart = ChartType.temperature;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.appSurface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: _selectedChart == ChartType.temperature
                                            ? Border.all(color: AppColors.appBlueAccent, width: 2)
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _selectedChart == ChartType.temperature
                                                ? AppColors.appBlueAccent.withOpacity(0.3)
                                                : AppColors.appBlueAccent.withOpacity(0.1),
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
                                              color: _selectedChart == ChartType.temperature
                                                  ? AppColors.appBlueAccent
                                                  : AppColors.secondaryText,
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
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedChart = ChartType.humidity;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.appSurface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: _selectedChart == ChartType.humidity
                                            ? Border.all(color: AppColors.appBlueAccent, width: 2)
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _selectedChart == ChartType.humidity
                                                ? AppColors.appBlueAccent.withOpacity(0.3)
                                                : AppColors.appBlueAccent.withOpacity(0.1),
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
                                              color: _selectedChart == ChartType.humidity
                                                  ? AppColors.appBlueAccent
                                                  : AppColors.secondaryText,
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Wind and pressure
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedChart = ChartType.windSpeed;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.appSurface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: _selectedChart == ChartType.windSpeed
                                            ? Border.all(color: AppColors.appBlueAccent, width: 2)
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _selectedChart == ChartType.windSpeed
                                                ? AppColors.appBlueAccent.withOpacity(0.3)
                                                : AppColors.appBlueAccent.withOpacity(0.1),
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
                                              color: _selectedChart == ChartType.windSpeed
                                                  ? AppColors.appBlueAccent
                                                  : AppColors.secondaryText,
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
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedChart = ChartType.pressure;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.appSurface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: _selectedChart == ChartType.pressure
                                            ? Border.all(color: AppColors.appBlueAccent, width: 2)
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _selectedChart == ChartType.pressure
                                                ? AppColors.appBlueAccent.withOpacity(0.3)
                                                : AppColors.appBlueAccent.withOpacity(0.1),
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
                                              color: _selectedChart == ChartType.pressure
                                                  ? AppColors.appBlueAccent
                                                  : AppColors.secondaryText,
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
                                    text: _getYAxisTitle(),
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
                                  text: _getChartTitle(),
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
                                  format: _getTooltipFormat(),
                                ),
                                series: <CartesianSeries<dynamic, dynamic>>[
                                  SplineSeries<WeatherData, DateTime>(
                                    dataSource: _weatherData,
                                    xValueMapper: (WeatherData data, _) => data.time,
                                    yValueMapper: (WeatherData data, _) => _getYValue(data),
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
  
  String _getYAxisTitle() {
    switch (_selectedChart) {
      case ChartType.temperature:
        return 'Temperatur (°C)';
      case ChartType.humidity:
        return 'Luftfeuchtigkeit (%)';
      case ChartType.windSpeed:
        return 'Windgeschwindigkeit (km/h)';
      case ChartType.pressure:
        return 'Luftdruck (hPa)';
    }
  }
  
  String _getChartTitle() {
    switch (_selectedChart) {
      case ChartType.temperature:
        return 'Temperaturverlauf heute';
      case ChartType.humidity:
        return 'Luftfeuchtigkeit heute';
      case ChartType.windSpeed:
        return 'Windgeschwindigkeit heute';
      case ChartType.pressure:
        return 'Luftdruckverlauf heute';
    }
  }
  
  String _getTooltipFormat() {
    switch (_selectedChart) {
      case ChartType.temperature:
        return 'point.x : point.y°C';
      case ChartType.humidity:
        return 'point.x : point.y%';
      case ChartType.windSpeed:
        return 'point.x : point.y km/h';
      case ChartType.pressure:
        return 'point.x : point.y hPa';
    }
  }
  
  double _getYValue(WeatherData data) {
    switch (_selectedChart) {
      case ChartType.temperature:
        return data.temperature;
      case ChartType.humidity:
        return data.humidity;
      case ChartType.windSpeed:
        return data.windSpeed;
      case ChartType.pressure:
        return data.pressure;
    }
  }
} 