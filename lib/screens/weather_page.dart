import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import 'package:intl/intl.dart';
import '../services/offline_cache_service.dart';

// Helper function for robust navigation bar detection across all Android devices
bool _isButtonNavigation(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final gestureInsets = mediaQuery.systemGestureInsets.bottom;
  final viewPadding = mediaQuery.viewPadding.bottom;
  
  if (gestureInsets >= 45) {
    // Very likely button navigation - high confidence
    return true;
  } else if (gestureInsets <= 25) {
    // Very likely gesture navigation - high confidence
    return false;
  } else {
    // Ambiguous range (26-44) - use viewPadding as secondary indicator
    // Button navigation typically has higher viewPadding
    return viewPadding > 50;
  }
}

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
  ChartType _selectedChart = ChartType.temperature;
  bool _isChartRendered = false;
  bool _isInitialRenderComplete = false;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    // Check if data needs to be loaded (fallback for edge cases)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final weatherState = ref.read(weatherDataProvider);
      if (!weatherState.isPreloaded && weatherState.chartData.isEmpty && !weatherState.isLoading) {
        ref.read(weatherDataProvider.notifier).preloadWeatherData();
      }
      
      // Start progressive rendering after first frame
      _startProgressiveRendering();
    });
  }

  void _startProgressiveRendering() {
    // Step 1: Mark initial render as complete
    if (mounted) {
      setState(() {
        _isInitialRenderComplete = true;
      });
    }
    
    // Step 2: Render chart after a short delay to prevent UI freeze
    // Only render if we have data to avoid unnecessary work
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        final weatherState = ref.read(weatherDataProvider);
        if (weatherState.chartData.isNotEmpty) {
          setState(() {
            _isChartRendered = true;
          });
        }
      }
    });
  }

  void _refreshData() {
    ref.read(weatherDataProvider.notifier).refreshWeatherData();
  }

  void _updateDataInBackground() {
    ref.read(weatherDataProvider.notifier).updateDataInBackground();
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

  Widget _buildChartPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.appSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondaryText.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.appBlueAccent),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Diagramm wird geladen...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final weatherState = ref.watch(weatherDataProvider);
    final pdfRepo = ref.watch(pdfRepositoryProvider);
    
    // Trigger chart rendering when data becomes available
    if (!_isChartRendered && weatherState.chartData.isNotEmpty && _isInitialRenderComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isChartRendered = true;
          });
        }
      });
    }
    
    return weatherState.isLoading && weatherState.chartData.isEmpty
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
          : weatherState.error != null && weatherState.chartData.isEmpty && !weatherState.isOfflineMode && !pdfRepo.isOfflineMode
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
                          onPressed: _refreshData,
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
              : weatherState.chartData.isEmpty && (weatherState.isOfflineMode || pdfRepo.isOfflineMode)
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 64,
                              color: Colors.orange.withOpacity(0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Offline-Modus',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primaryText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                DateTime? offlineTime;
                                if (weatherState.isOfflineMode && weatherState.offlineDataTime != null) {
                                  offlineTime = weatherState.offlineDataTime;
                                } else if (pdfRepo.isOfflineMode && pdfRepo.offlineDataTime != null) {
                                  offlineTime = pdfRepo.offlineDataTime;
                                }
                                
                                return Column(
                                  children: [
                                    Text(
                                      'Um die aktuellsten Daten zu erhalten, schalte bitte dein Internet an.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.secondaryText,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (offlineTime != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Zuletzt aktualisiert ${_formatUpdateTime(offlineTime)}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.secondaryText.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                );
                              }
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _refreshData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Erneut versuchen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
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
              : weatherState.chartData.isEmpty
                  ? const Center(
                      child: Text(
                        'Keine Wetterdaten verfügbar',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 16.0,
                        bottom: _isButtonNavigation(context)
                          ? 50.0  // Button navigation (3 buttons) - more space needed
                          : 24.0, // Gesture navigation (white bar) - less space needed
                      ),
                      child: Column(
                        children: [
                          // Offline notification (if applicable)
                          FutureBuilder<DateTime?>(
                            future: OfflineCache.getWeatherLastUpdateTime(),
                            builder: (context, snapshot) {
                              // Check for offline mode - either weather system or PDF system
                              final isWeatherOffline = weatherState.isOfflineMode && weatherState.offlineDataTime != null;
                              final isPdfOffline = pdfRepo.isOfflineMode && pdfRepo.offlineDataTime != null;
                              final isOffline = isWeatherOffline || isPdfOffline;
                              
                              // Check for slow connection
                              final hasSlowConnection = pdfRepo.hasSlowConnection;
                              final isNoInternet = pdfRepo.isNoInternet;
                              
                              if (!isOffline && !hasSlowConnection) {
                                return const SizedBox.shrink();
                              }
                              
                              // Use the most recent offline time for display
                              DateTime? offlineTime;
                              if (isWeatherOffline && isPdfOffline) {
                                // Use the more recent of the two
                                offlineTime = weatherState.offlineDataTime!.isAfter(pdfRepo.offlineDataTime!) 
                                  ? weatherState.offlineDataTime 
                                  : pdfRepo.offlineDataTime;
                              } else if (isWeatherOffline) {
                                offlineTime = weatherState.offlineDataTime;
                              } else if (isPdfOffline) {
                                offlineTime = pdfRepo.offlineDataTime;
                              }
                              
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isNoInternet ? Icons.wifi_off_outlined : Icons.signal_wifi_bad_outlined,
                                      color: Colors.orange.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isNoInternet
                                              ? 'Um die aktuellsten Daten zu erhalten, schalte bitte dein Internet an.'
                                              : 'Du hast gerade schlechtes Internet, um die aktuellsten Daten zu erhalten, warte bitte noch einen Moment...',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.orange.shade700,
                                              height: 1.3,
                                            ),
                                          ),
                                          if (offlineTime != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Zuletzt aktualisiert ${_formatUpdateTime(offlineTime)}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.orange.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
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
                          if (weatherState.latestData != null) ...[
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
                                        border: Border.all(color: Colors.transparent, width: 2),
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
                                            '${weatherState.latestData!.temperature.toStringAsFixed(1)}°C',
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
                                          'Luftfeuchtigkeit',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${weatherState.latestData!.humidity.toStringAsFixed(0)}%',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: AppColors.primaryText,
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
                                          '${weatherState.latestData!.windSpeed.toStringAsFixed(1)} km/h',
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
                                          '${weatherState.latestData!.pressure.toStringAsFixed(0)} hPa',
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
                                      // Progressive chart rendering
                                      Expanded(
                                        child: _isChartRendered
                                          ? SfCartesianChart(
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
                                                  dataSource: weatherState.chartData,
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
                                            )
                                          : _buildChartPlaceholder(),
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
      case ChartType.windSpeed:
      case ChartType.pressure:
        return 'Temperaturverlauf heute'; // Always fallback to temperature
    }
  }
  
  String _getTooltipFormat() {
    switch (_selectedChart) {
      case ChartType.temperature:
        return 'point.x : point.y°C';
      case ChartType.humidity:
      case ChartType.windSpeed:
      case ChartType.pressure:
        return 'point.x : point.y°C'; // Always fallback to temperature
    }
  }
  
  String _getYAxisTitle() {
    switch (_selectedChart) {
      case ChartType.temperature:
        return 'Temperatur (°C)';
      case ChartType.humidity:
      case ChartType.windSpeed:
      case ChartType.pressure:
        return 'Temperatur (°C)'; // Always fallback to temperature
    }
  }
  
  double _getYValue(WeatherData data) {
    switch (_selectedChart) {
      case ChartType.temperature:
        return data.temperature;
      case ChartType.humidity:
      case ChartType.windSpeed:
      case ChartType.pressure:
        return data.temperature; // Always fallback to temperature
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