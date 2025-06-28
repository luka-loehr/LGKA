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
                          // Weather station explanation or waiting message
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isChartAvailable() 
                                ? AppColors.appBlueAccent.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isChartAvailable() 
                                  ? AppColors.appBlueAccent.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isChartAvailable() 
                                    ? Icons.info_outline
                                    : Icons.access_time,
                                  color: _isChartAvailable() 
                                    ? AppColors.appBlueAccent
                                    : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isChartAvailable()
                                      ? 'Diese Wetterdaten kommen direkt von der schuleigenen Wetterstation auf dem Dach. Du siehst hier live Wetterdaten von deiner Schule!'
                                      : 'Warte noch ein paar Minuten - die Wetterstation sammelt gerade neue Daten für heute. Diagramme sind ab 0:30 Uhr verfügbar.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primaryText,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Current weather data cards
                          if (_weatherData.isNotEmpty) ...[
                            // Temperature and humidity row
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
                                      height: 85,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.appSurface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: _selectedChart == ChartType.temperature
                                            ? Border.all(color: AppColors.appBlueAccent, width: 2)
                                            : Border.all(color: Colors.transparent, width: 2),
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
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Temperatur',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: _selectedChart == ChartType.temperature
                                                  ? AppColors.appBlueAccent
                                                  : AppColors.secondaryText,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_weatherData.last.temperature.toStringAsFixed(1)}°C',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                                      height: 85,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.appSurface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: _selectedChart == ChartType.humidity
                                            ? Border.all(color: AppColors.appBlueAccent, width: 2)
                                            : Border.all(color: Colors.transparent, width: 2),
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
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Luftfeuchtigkeit',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: _selectedChart == ChartType.humidity
                                                  ? AppColors.appBlueAccent
                                                  : AppColors.secondaryText,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_weatherData.last.humidity.toStringAsFixed(0)}%',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                            // Wind and pressure row
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 85,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.appSurface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.transparent, width: 2),
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Wind',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_weatherData.last.windSpeed.toStringAsFixed(1)} km/h',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppColors.primaryText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 85,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.appSurface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.transparent, width: 2),
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Luftdruck',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_weatherData.last.pressure.toStringAsFixed(0)} hPa',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          ],
                          const SizedBox(height: 20),
                          // Chart or time-based message
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.appSurface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.appBlueAccent.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isChartAvailable()
                                ? Column(
                                    children: [
                                      // Chart title
                                      Text(
                                        _getChartTitle(),
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: AppColors.primaryText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      // Professional chart
                                      Expanded(
                                        child: SfCartesianChart(
                                          backgroundColor: Colors.transparent,
                                          plotAreaBackgroundColor: Colors.transparent,
                                          primaryXAxis: DateTimeAxis(
                                            dateFormat: DateFormat.Hm(),
                                            intervalType: DateTimeIntervalType.hours,
                                            interval: 2,
                                            majorGridLines: MajorGridLines(
                                              color: AppColors.secondaryText.withOpacity(0.2),
                                              width: 0.5,
                                            ),
                                            minorGridLines: const MinorGridLines(width: 0),
                                            axisLine: AxisLine(
                                              color: AppColors.secondaryText.withOpacity(0.3),
                                              width: 1,
                                            ),
                                            majorTickLines: MajorTickLines(
                                              color: AppColors.secondaryText.withOpacity(0.3),
                                              width: 1,
                                            ),
                                            labelStyle: TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 11,
                                            ),
                                            title: AxisTitle(
                                              text: 'Uhrzeit',
                                              textStyle: TextStyle(
                                                color: AppColors.secondaryText,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          primaryYAxis: NumericAxis(
                                            title: AxisTitle(
                                              text: _getYAxisTitle(),
                                              textStyle: TextStyle(
                                                color: AppColors.secondaryText,
                                                fontSize: 12,
                                              ),
                                            ),
                                            majorGridLines: MajorGridLines(
                                              color: AppColors.secondaryText.withOpacity(0.2),
                                              width: 0.5,
                                            ),
                                            minorGridLines: const MinorGridLines(width: 0),
                                            axisLine: AxisLine(
                                              color: AppColors.secondaryText.withOpacity(0.3),
                                              width: 1,
                                            ),
                                            majorTickLines: MajorTickLines(
                                              color: AppColors.secondaryText.withOpacity(0.3),
                                              width: 1,
                                            ),
                                            labelStyle: TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 11,
                                            ),
                                          ),
                                          margin: const EdgeInsets.all(8),
                                          legend: const Legend(isVisible: false),
                                          tooltipBehavior: TooltipBehavior(
                                            enable: true,
                                            color: AppColors.appSurface,
                                            textStyle: const TextStyle(
                                              color: AppColors.primaryText,
                                              fontSize: 12,
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
                                              cardinalSplineTension: 0.7,
                                              markerSettings: const MarkerSettings(
                                                isVisible: false,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Icon(
                                        Icons.hourglass_empty,
                                        size: 48,
                                        color: AppColors.secondaryText.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _getChartUnavailableMessage(),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.primaryText,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
  }
  
  String _getChartTitle() {
    switch (_selectedChart) {
      case ChartType.temperature:
        return 'Temperaturverlauf heute';
      case ChartType.humidity:
        return 'Luftfeuchtigkeit heute';
      case ChartType.windSpeed:
      case ChartType.pressure:
        return 'Temperaturverlauf heute'; // Fallback to temperature
    }
  }
  
  String _getTooltipFormat() {
    switch (_selectedChart) {
      case ChartType.temperature:
        return 'point.x : point.y°C';
      case ChartType.humidity:
        return 'point.x : point.y%';
      case ChartType.windSpeed:
      case ChartType.pressure:
        return 'point.x : point.y°C'; // Fallback to temperature
    }
  }
  
  double _getYValue(WeatherData data) {
    switch (_selectedChart) {
      case ChartType.temperature:
        return data.temperature;
      case ChartType.humidity:
        return data.humidity;
      case ChartType.windSpeed:
      case ChartType.pressure:
        return data.temperature; // Fallback to temperature
    }
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

  bool _isChartAvailable() {
    final now = DateTime.now();
    // Charts are available after 0:30 (00:30)
    return now.hour > 0 || (now.hour == 0 && now.minute >= 30);
  }
  
  String _getChartUnavailableMessage() {
    final now = DateTime.now();
    if (now.hour == 0 && now.minute < 30) {
      final minutesLeft = 30 - now.minute;
      return 'Diagramme sind ab 0:30 Uhr verfügbar.\nNoch $minutesLeft Minute${minutesLeft == 1 ? '' : 'n'} warten.';
    }
    return 'Diagramme sind ab 0:30 Uhr verfügbar.';
  }
} 