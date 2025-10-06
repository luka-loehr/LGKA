import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../services/retry_service.dart';
import '../providers/haptic_service.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';


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

class _WeatherPageState extends ConsumerState<WeatherPage> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  ChartType _selectedChart = ChartType.temperature;
  bool _isChartRendered = false;
  bool _isInitialRenderComplete = false;
  int _debugCounter = 0; // Debug counter for logging

  late AnimationController _errorAnimationController;
  late Animation<double> _errorAnimation;
  
  // Fade-in animation for weather components
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasShownComponents = false;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();

    // Initialize error animation controller
    _errorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _errorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _errorAnimationController, curve: Curves.easeInOut),
    );

    // Initialize fade-in animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

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

  void _startComponentAnimation() {
    if (!_hasShownComponents) {
      _hasShownComponents = true;
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _errorAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _refreshData() {
    // Retry all data sources for better user experience
    ref.read(retryServiceProvider).retryAllDataSources();
  }

  Widget _buildChartPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.appSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondaryText.withValues(alpha: 0.1),
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
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
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

    // Control error animation based on weather error state or stale data
    final shouldShowWeatherError = weatherState.error != null && weatherState.chartData.isEmpty;
    final shouldShowStaleDataError = _isDataStale() && weatherState.chartData.isNotEmpty;
    final shouldShowAnyError = shouldShowWeatherError || shouldShowStaleDataError;
    
    if (shouldShowAnyError) {
      if (_errorAnimationController.status == AnimationStatus.dismissed) {
        _errorAnimationController.forward();
      }
    } else {
      if (_errorAnimationController.status == AnimationStatus.completed) {
        _errorAnimationController.reverse();
      }
    }

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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lade Wetterdaten...',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ],
              ),
            )
          : shouldShowAnyError
              ? FadeTransition(
                  opacity: _errorAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          shouldShowStaleDataError 
                            ? AppLocalizations.of(context)!.serverMaintenance
                            : AppLocalizations.of(context)!.serverConnectionFailed,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _refreshData,
                          icon: const Icon(Icons.refresh),
                          label: Text(AppLocalizations.of(context)!.tryAgain),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
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
                  ? Center(
                      child: const Text(
                        'Keine Wetterdaten verfügbar',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        // Start animation when weather components should be visible
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _startComponentAnimation();
                        });
                        
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Weather station explanation or waiting message
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: _isChartAvailable() 
                                      ? AppColors.appSurface
                                      : AppColors.appSurface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _isChartAvailable() 
                                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                                        : Colors.orange.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isChartAvailable()
                                          ? AppLocalizations.of(context)!.liveWeatherData
                                          : AppLocalizations.of(context)!.dataBeingCollected,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: _isChartAvailable() 
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.orange,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _isChartAvailable()
                                          ? AppLocalizations.of(context)!.liveWeatherDescription
                                          : AppLocalizations.of(context)!.dataCollectionDescription,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.secondaryText,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                                              _isChartRendered = false; // Force chart re-render
                                            });
                                            HapticService.subtle();
                                            // Re-render chart after a short delay
                                            Future.delayed(const Duration(milliseconds: 50), () {
                                              if (mounted) {
                                                setState(() {
                                                  _isChartRendered = true;
                                                });
                                              }
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            height: 85,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: _selectedChart == ChartType.temperature
                                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                                  : AppColors.appSurface,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: _selectedChart == ChartType.temperature
                                                    ? Theme.of(context).colorScheme.primary
                                                    : AppColors.secondaryText.withValues(alpha: 0.2),
                                                width: _selectedChart == ChartType.temperature ? 2 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Temperatur',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: _selectedChart == ChartType.temperature
                                                        ? Theme.of(context).colorScheme.primary
                                                        : AppColors.secondaryText,
                                                    fontWeight: _selectedChart == ChartType.temperature
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${weatherState.latestData!.temperature.toStringAsFixed(1)}°C',
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    color: _selectedChart == ChartType.temperature
                                                        ? Theme.of(context).colorScheme.primary
                                                        : AppColors.primaryText,
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
                                              _isChartRendered = false; // Force chart re-render
                                            });
                                            HapticService.subtle();
                                            // Re-render chart after a short delay
                                            Future.delayed(const Duration(milliseconds: 50), () {
                                              if (mounted) {
                                                setState(() {
                                                  _isChartRendered = true;
                                                });
                                              }
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            height: 85,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: _selectedChart == ChartType.humidity
                                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                                  : AppColors.appSurface,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: _selectedChart == ChartType.humidity
                                                    ? Theme.of(context).colorScheme.primary
                                                    : AppColors.secondaryText.withValues(alpha: 0.2),
                                                width: _selectedChart == ChartType.humidity ? 2 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Luftfeuchtigkeit',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: _selectedChart == ChartType.humidity
                                                        ? Theme.of(context).colorScheme.primary
                                                        : AppColors.secondaryText,
                                                    fontWeight: _selectedChart == ChartType.humidity
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${weatherState.latestData!.humidity.toStringAsFixed(0)}%',
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    color: _selectedChart == ChartType.humidity
                                                        ? Theme.of(context).colorScheme.primary
                                                        : AppColors.primaryText,
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
                                  // Wind speed and pressure row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedChart = ChartType.windSpeed;
                                              _isChartRendered = false; // Force chart re-render
                                            });
                                            HapticService.subtle();
                                            // Re-render chart after a short delay
                                            Future.delayed(const Duration(milliseconds: 50), () {
                                              if (mounted) {
                                                setState(() {
                                                  _isChartRendered = true;
                                                });
                                              }
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            height: 85,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: _selectedChart == ChartType.windSpeed
                                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                                  : AppColors.appSurface,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: _selectedChart == ChartType.windSpeed
                                                    ? Theme.of(context).colorScheme.primary
                                                    : AppColors.secondaryText.withValues(alpha: 0.2),
                                                width: _selectedChart == ChartType.windSpeed ? 2 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Windgeschwindigkeit',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: _selectedChart == ChartType.windSpeed
                                                        ? Theme.of(context).colorScheme.primary
                                                        : AppColors.secondaryText,
                                                    fontWeight: _selectedChart == ChartType.windSpeed
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${weatherState.latestData!.windSpeed.toStringAsFixed(1)} km/h',
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    color: _selectedChart == ChartType.windSpeed
                                                        ? Theme.of(context).colorScheme.primary
                                                        : AppColors.primaryText,
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
                                              _selectedChart = ChartType.pressure;
                                              _isChartRendered = false; // Force chart re-render
                                            });
                                            HapticService.subtle();
                                            // Re-render chart after a short delay
                                            Future.delayed(const Duration(milliseconds: 50), () {
                                              if (mounted) {
                                                setState(() {
                                                  _isChartRendered = true;
                                                });
                                              }
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            height: 85,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: _selectedChart == ChartType.pressure
                                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                                  : AppColors.appSurface,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: _selectedChart == ChartType.pressure
                                                    ? Theme.of(context).colorScheme.primary
                                                    : AppColors.secondaryText.withValues(alpha: 0.2),
                                                width: _selectedChart == ChartType.pressure ? 2 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Luftdruck',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: _selectedChart == ChartType.pressure
                                                        ? Theme.of(context).colorScheme.primary
                                                        : AppColors.secondaryText,
                                                    fontWeight: _selectedChart == ChartType.pressure
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${weatherState.latestData!.pressure.toStringAsFixed(0)} hPa',
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    color: _selectedChart == ChartType.pressure
                                                        ? Theme.of(context).colorScheme.primary
                                                        : AppColors.primaryText,
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
                                ],
                                const SizedBox(height: 16),
                                // Chart or time-based message
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.appSurface,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                                                      interval: _calculateOptimalInterval(weatherState.chartData, context),
                                                      majorGridLines: MajorGridLines(
                                                        color: AppColors.secondaryText.withValues(alpha: 0.2),
                                                        width: 0.5,
                                                        ),
                                                      minorGridLines: const MinorGridLines(width: 0),
                                                      axisLine: AxisLine(
                                                        color: AppColors.secondaryText.withValues(alpha: 0.3),
                                                        width: 1,
                                                      ),
                                                      majorTickLines: MajorTickLines(
                                                        color: AppColors.secondaryText.withValues(alpha: 0.2),
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
                                                      minimum: _calculateOptimalYAxisRange(weatherState.chartData)['min'],
                                                      maximum: _calculateOptimalYAxisRange(weatherState.chartData)['max'],
                                                      majorGridLines: MajorGridLines(
                                                        color: AppColors.secondaryText.withValues(alpha: 0.2),
                                                        width: 0.5,
                                                      ),
                                                      minorGridLines: const MinorGridLines(width: 0),
                                                      axisLine: AxisLine(
                                                        color: AppColors.secondaryText.withValues(alpha: 0.3),
                                                        width: 1,
                                                      ),
                                                      majorTickLines: MajorTickLines(
                                                        color: AppColors.secondaryText.withValues(alpha: 0.3),
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
                                                      borderColor: Theme.of(context).colorScheme.primary,
                                                      borderWidth: 1,
                                                      format: _getTooltipFormat(),
                                                    ),
                                                    series: <CartesianSeries<dynamic, dynamic>>[
                                                      SplineSeries<WeatherData, DateTime>(
                                                        dataSource: weatherState.chartData,
                                                        xValueMapper: (WeatherData data, _) => data.time,
                                                        yValueMapper: (WeatherData data, _) => _getYValue(data),
                                                        color: Theme.of(context).colorScheme.primary,
                                                        width: 3,
                                                        splineType: SplineType.cardinal,
                                                        cardinalSplineTension: 0.7,
                                                        animationDuration: 1000, // 1 second animation for dramatic effect
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
                                              color: AppColors.secondaryText.withValues(alpha: 0.5),
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
                                const SizedBox(height: 16),
                                _buildFooter(context),
                              ],
                            ),
                          ),
                        );
                      },
                    );
  }
  
  /// Calculate optimal Y-axis range to prevent data cutoff
  Map<String, double> _calculateOptimalYAxisRange(List<WeatherData> chartData) {
    if (chartData.isEmpty) {
      print('📊 [WeatherPage] No chart data available for Y-axis calculation');
      return {'min': 0.0, 'max': 100.0};
    }
    
    // Get all Y values for the selected chart type
    final yValues = chartData.map((data) => _getYValue(data)).toList();
    
    // Filter out any invalid values
    final validYValues = yValues.where((value) => value.isFinite && !value.isNaN).toList();
    
    if (validYValues.isEmpty) {
      print('📊 [WeatherPage] No valid Y values found for chart type: $_selectedChart');
      return {'min': 0.0, 'max': 100.0};
    }
    
    // Find min and max values
    final minValue = validYValues.reduce((a, b) => a < b ? a : b);
    final maxValue = validYValues.reduce((a, b) => a > b ? a : b);
    
    print('📊 [WeatherPage] Chart type: $_selectedChart');
    print('📊 [WeatherPage] Y values range: $minValue to $maxValue');
    print('📊 [WeatherPage] Sample Y values: ${validYValues.take(5).toList()}');
    
    // Calculate range and add padding
    final range = maxValue - minValue;
    final padding = range * 0.1; // 10% padding on each side
    
    // Handle edge cases where range is very small
    final adjustedPadding = padding < 0.1 ? 0.1 : padding;
    
    // Round to nice values based on the data type
    double niceMin, niceMax;
    
    switch (_selectedChart) {
      case ChartType.temperature:
        // Temperature: round to nearest 0.5°C
        niceMin = (minValue - adjustedPadding).floorToDouble();
        niceMax = (maxValue + adjustedPadding).ceilToDouble();
        break;
      case ChartType.humidity:
        // Humidity: round to nearest 5%
        niceMin = ((minValue - adjustedPadding) / 5).floor() * 5;
        niceMax = ((maxValue + adjustedPadding) / 5).ceil() * 5;
        break;
      case ChartType.windSpeed:
        // Wind speed: round to nearest 1 km/h
        niceMin = (minValue - adjustedPadding).floorToDouble();
        niceMax = (maxValue + adjustedPadding).ceilToDouble();
        break;
      case ChartType.pressure:
        // Pressure: round to nearest 1 hPa
        niceMin = (minValue - adjustedPadding).floorToDouble();
        niceMax = (maxValue + adjustedPadding).ceilToDouble();
        break;
    }
    
    // Ensure minimum range for very small datasets
    if (niceMax - niceMin < 1.0) {
      final center = (niceMin + niceMax) / 2;
      niceMin = center - 0.5;
      niceMax = center + 0.5;
    }
    
    print('📊 [WeatherPage] Final Y-axis range: $niceMin to $niceMax');
    
    return {
      'min': niceMin,
      'max': niceMax,
    };
  }
  
  String _getChartTitle() {
    switch (_selectedChart) {
      case ChartType.temperature:
        return 'Temperaturverlauf heute';
      case ChartType.humidity:
        return 'Luftfeuchtigkeitsverlauf heute';
      case ChartType.windSpeed:
        return 'Windgeschwindigkeitsverlauf heute';
      case ChartType.pressure:
        return 'Luftdruckverlauf heute';
    }
    return 'Wetterverlauf heute'; // Default fallback
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
    return 'point.x : point.y'; // Default fallback
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
    return 'Wert'; // Default fallback
  }
  
  double _getYValue(WeatherData data) {
    double value;
    switch (_selectedChart) {
      case ChartType.temperature:
        value = data.temperature;
        break;
      case ChartType.humidity:
        value = data.humidity;
        break;
      case ChartType.windSpeed:
        value = data.windSpeed;
        break;
      case ChartType.pressure:
        value = data.pressure;
        break;
    }
    
    // Debug logging for first few data points
    if (_debugCounter < 3) {
      print('📊 [WeatherPage] _getYValue: ChartType.$_selectedChart = $value (from data: ${data.time})');
      _debugCounter++;
    }
    
    return value;
  }

  bool _isChartAvailable() {
    final now = DateTime.now();
    // Charts are available after 0:30 (00:30)
    return now.hour > 0 || (now.hour == 0 && now.minute >= 30);
  }
  
  /// Check if weather data values have been the same for more than 60 minutes
  bool _isDataStale() {
    final weatherState = ref.read(weatherDataProvider);
    if (weatherState.chartData.length < 2) return false;
    
    // Get the last 60 minutes of data (assuming 1-minute intervals)
    final now = DateTime.now();
    final sixtyMinutesAgo = now.subtract(const Duration(minutes: 60));
    
    // Filter data from last 60 minutes
    final recentData = weatherState.chartData
        .where((data) => data.time.isAfter(sixtyMinutesAgo))
        .toList();
    
    if (recentData.length < 2) return false;
    
    // Check if all values are exactly the same
    final firstData = recentData.first;
    final allSame = recentData.every((data) =>
        data.temperature == firstData.temperature &&
        data.humidity == firstData.humidity &&
        data.windSpeed == firstData.windSpeed &&
        data.pressure == firstData.pressure &&
        data.radiation == firstData.radiation);
    
    return allSame;
  }
  
  /// Calculate optimal x-axis interval to prevent overlapping time labels
  double _calculateOptimalInterval(List<WeatherData> chartData, BuildContext context) {
    if (chartData.isEmpty) return 2.0;
    
    // Get the time range of the data
    final firstTime = chartData.first.time;
    final lastTime = chartData.last.time;
    final totalHours = lastTime.difference(firstTime).inHours;
    
    // Get the actual chart width from MediaQuery
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final availableWidth = screenWidth - 64.0; // Account for padding (32px on each side)
    
    // Calculate how many labels we can comfortably fit
    // We want to show enough labels to be useful but not so many that they overlap
    final labelWidth = 70.0; // Approximate width of a time label (HH:MM) with some spacing
    final maxLabels = (availableWidth / labelWidth).floor();
    
    // Ensure we have at least 2 labels and at most 8 labels
    final targetLabels = maxLabels.clamp(2, 8);
    
    // Calculate the minimum interval needed
    double minInterval = totalHours / targetLabels;
    
    // Round up to the nearest "nice" interval
    if (minInterval <= 1.0) {
      return 1.0; // Show every hour
    } else if (minInterval <= 2.0) {
      return 2.0; // Show every 2 hours
    } else if (minInterval <= 3.0) {
      return 3.0; // Show every 3 hours
    } else if (minInterval <= 4.0) {
      return 4.0; // Show every 4 hours
    } else if (minInterval <= 6.0) {
      return 6.0; // Show every 6 hours
    } else {
      return 12.0; // Show every 12 hours for very long ranges
    }
  }
  
  String _getChartUnavailableMessage() {
    final now = DateTime.now();
    if (now.hour == 0 && now.minute < 30) {
      final minutesLeft = 30 - now.minute;
      return 'Diagramme sind ab 0:30 Uhr verfügbar.\nNoch $minutesLeft Minute${minutesLeft == 1 ? '' : 'n'} warten.';
    }
    return 'Diagramme sind ab 0:30 Uhr verfügbar.';
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: _isButtonNavigation(context) ? 34.0 : 8.0,
      ),
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.hasData ? snapshot.data!.version : '1.5.5';
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '© ${DateTime.now().year} ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText.withValues(alpha: 0.5),
                ),
              ),
              Text(
                'Luka Löhr',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ' • v$version',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText.withValues(alpha: 0.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 