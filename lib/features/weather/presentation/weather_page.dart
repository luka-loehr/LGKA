import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:timezone/timezone.dart' as tz;
import '../domain/weather_models.dart';
import '../../../../theme/app_theme.dart';
import '../application/weather_provider.dart';
import '../../../../services/haptic_service.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_logger.dart';

import '../../../../widgets/app_footer.dart';
import 'package:intl/intl.dart';
import '../../../../services/loading_spinner_tracker_service.dart';


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
  radiation,
}

class _WeatherPageState extends ConsumerState<WeatherPage> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  ChartType _selectedChart = ChartType.temperature;
  bool _isChartRendered = false;
  bool _isInitialRenderComplete = false;
  bool _forceShowErrorUntilSuccess = false; // Keep error UI visible during retries until data arrives

  late AnimationController _errorAnimationController;
  late Animation<double> _errorAnimation;

  // Fade-in animation for weather components
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasShownComponents = false;

  // Chart animation completion detection

  Timer? _animationTimer;

  // Loading spinner tracker for haptic feedback
  final _spinnerTracker = LoadingSpinnerTracker();
  
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
      if (!mounted) return;
      
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
          // Start chart animation completion detection
          _startChartAnimation();
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

  void _startChartAnimation() {

    
    // Cancel any existing timer
    _animationTimer?.cancel();
    
    // Start timer to detect when chart animation completes (800ms)
    _animationTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {

        
        // Chart animation completed! Do something here
        _onChartAnimationComplete();
      }
    });
  }

  void _onChartAnimationComplete() {
    AppLogger.chart('Chart animation completed for ${_getChartTitle().toLowerCase()}');
  }

  @override
  void dispose() {
    _errorAnimationController.dispose();
    _fadeController.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }

  void _refreshData() async {
    AppLogger.chart('Manual refresh requested');
    // Ensure error UI stays visible while retrying, until data successfully loads
    if (mounted) {
      setState(() {
        _forceShowErrorUntilSuccess = true;
      });
    }
    try {
      await ref.read(weatherDataProvider.notifier).refreshWeatherData();
      AppLogger.success('Weather data refreshed successfully', module: 'WeatherPage');
    } catch (e) {
      AppLogger.error('Weather refresh failed', module: 'WeatherPage', error: e);
    }
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
            AppLocalizations.of(context)!.chartLoading,
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
    final hasNoChartData = weatherState.chartData.isEmpty;
    final shouldShowWeatherError = weatherState.error != null && hasNoChartData;
    final shouldShowStaleDataError = _isDataStale() && weatherState.chartData.isNotEmpty;
    final shouldShowRepairError = _isWeatherStationRepair();
    // Keep showing the error placeholder while retrying until data loads
    final shouldShowAnyError = _forceShowErrorUntilSuccess || shouldShowWeatherError || shouldShowStaleDataError || shouldShowRepairError;

    // Track spinner visibility and trigger haptic feedback when spinner disappears
    final isSpinnerVisible = weatherState.isLoading && weatherState.chartData.isEmpty;
    final hasData = weatherState.chartData.isNotEmpty;
    final hasError = shouldShowAnyError;

    final hapticTriggered = _spinnerTracker.trackState(
      isSpinnerVisible: isSpinnerVisible,
      hasData: hasData,
      hasError: hasError,
      mounted: mounted,
    );

    // Log successful load when haptic is triggered
    if (hapticTriggered) {
      AppLogger.success('Weather data load complete: ${weatherState.chartData.length} data points', module: 'WeatherPage');
    }
    
    if (shouldShowAnyError) {
      if (_errorAnimationController.status == AnimationStatus.dismissed) {
        _errorAnimationController.forward();
      }
    } else {
      if (_errorAnimationController.status == AnimationStatus.completed) {
        _errorAnimationController.reverse();
      }
    }

    // Reset forced error once we have data
    if (_forceShowErrorUntilSuccess && weatherState.chartData.isNotEmpty) {
      if (mounted) {
        setState(() {
          _forceShowErrorUntilSuccess = false;
        });
      }
      AppLogger.chart('Weather data loaded successfully');
    }

    // Trigger chart rendering when data becomes available
    if (!_isChartRendered && weatherState.chartData.isNotEmpty && _isInitialRenderComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isChartRendered = true;
          });
          AppLogger.chart('Chart rendering started');
          // Start chart animation completion detection
          _startChartAnimation();
        }
      });
    }
    
    // Check if chart is not available (data collection window or repair)
    final isChartUnavailable = !_isChartAvailable();
    
    return weatherState.isLoading && weatherState.chartData.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.loadingWeather,
                    style: const TextStyle(color: AppColors.secondaryText),
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
                        Icon(
                          shouldShowRepairError
                            ? Icons.build_outlined
                            : Icons.wb_sunny_outlined,
                          size: 64,
                          color: shouldShowRepairError
                            ? Theme.of(context).colorScheme.primary
                            : AppColors.secondaryText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          shouldShowRepairError
                            ? AppLocalizations.of(context)!.weatherStationRepair
                            : shouldShowStaleDataError 
                              ? AppLocalizations.of(context)!.serverMaintenance
                              : AppLocalizations.of(context)!.serverConnectionFailed,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          shouldShowRepairError
                            ? AppLocalizations.of(context)!.weatherStationRepairFooter
                            : AppLocalizations.of(context)!.serverConnectionHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (!shouldShowRepairError) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticService.medium();
                              _refreshData();
                            },
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
                      ],
                    ),
                  ),
                )
              : isChartUnavailable
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_empty_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.dataBeingCollected,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.dataCollectionDescription,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
              : weatherState.chartData.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.noWeatherData,
                        style: const TextStyle(color: AppColors.secondaryText),
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
                                // Weather station explanation - only show when chart is available
                                if (_isChartAvailable()) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.appSurface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.liveWeatherData,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(context)!.liveWeatherDescription,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.secondaryText,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Current weather data cards - only show when chart is available
                                if (weatherState.latestData != null && _isChartAvailable()) ...[
                                  // Temperature and humidity row - responsive layout
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isSmallScreen = constraints.maxWidth < 400;
                                      final cardHeight = isSmallScreen ? 75.0 : 85.0;
                                      final padding = isSmallScreen ? 12.0 : 16.0;
                                      
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                HapticService.medium();
                                                setState(() {
                                                  _selectedChart = ChartType.temperature;
                                                  _isChartRendered = false; // Force chart re-render
                                                });
                                                // Re-render chart after a short delay
                                                Future.delayed(const Duration(milliseconds: 50), () {
                                                  if (mounted) {
                                                    setState(() {
                                                      _isChartRendered = true;
                                                    });
                                                    // Start chart animation completion detection
                                                    _startChartAnimation();
                                                  }
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                height: cardHeight,
                                                padding: EdgeInsets.all(padding),
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
                                                      AppLocalizations.of(context)!.temperatureLabel,
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: _selectedChart == ChartType.temperature
                                                            ? Theme.of(context).colorScheme.primary
                                                            : AppColors.secondaryText,
                                                        fontWeight: _selectedChart == ChartType.temperature
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                        fontSize: isSmallScreen ? 11 : 12,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: isSmallScreen ? 2 : 4),
                                                    Text(
                                                      '${weatherState.latestData!.temperature.toStringAsFixed(1)}°C',
                                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        color: _selectedChart == ChartType.temperature
                                                            ? Theme.of(context).colorScheme.primary
                                                            : AppColors.primaryText,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: isSmallScreen ? 18 : 20,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: isSmallScreen ? 8 : 12),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                HapticService.medium();
                                                setState(() {
                                                  _selectedChart = ChartType.humidity;
                                                  _isChartRendered = false; // Force chart re-render
                                                });
                                                // Re-render chart after a short delay
                                                Future.delayed(const Duration(milliseconds: 50), () {
                                                  if (mounted) {
                                                    setState(() {
                                                      _isChartRendered = true;
                                                    });
                                                    // Start chart animation completion detection
                                                    _startChartAnimation();
                                                  }
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                height: cardHeight,
                                                padding: EdgeInsets.all(padding),
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
                                                      AppLocalizations.of(context)!.humidityLabel,
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: _selectedChart == ChartType.humidity
                                                            ? Theme.of(context).colorScheme.primary
                                                            : AppColors.secondaryText,
                                                        fontWeight: _selectedChart == ChartType.humidity
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                        fontSize: isSmallScreen ? 11 : 12,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: isSmallScreen ? 2 : 4),
                                                    Text(
                                                      '${weatherState.latestData!.humidity.toStringAsFixed(0)}%',
                                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        color: _selectedChart == ChartType.humidity
                                                            ? Theme.of(context).colorScheme.primary
                                                            : AppColors.primaryText,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: isSmallScreen ? 18 : 20,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // Wind speed and pressure row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            HapticService.medium();
                                            setState(() {
                                              _selectedChart = ChartType.windSpeed;
                                              _isChartRendered = false; // Force chart re-render
                                            });
                                            // Re-render chart after a short delay
                                            Future.delayed(const Duration(milliseconds: 50), () {
                                              if (mounted) {
                                                setState(() {
                                                  _isChartRendered = true;
                                                });
                                                // Start chart animation completion detection
                                                _startChartAnimation();
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
                                                  AppLocalizations.of(context)!.windSpeedLabel,
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
                                            HapticService.medium();
                                            setState(() {
                                              _selectedChart = ChartType.radiation;
                                              _isChartRendered = false; // Force chart re-render
                                            });
                                            // Re-render chart after a short delay
                                            Future.delayed(const Duration(milliseconds: 50), () {
                                              if (mounted) {
                                                setState(() {
                                                  _isChartRendered = true;
                                                });
                                                // Start chart animation completion detection
                                                _startChartAnimation();
                                              }
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            height: 85,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: _selectedChart == ChartType.radiation
                                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                                  : AppColors.appSurface,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: _selectedChart == ChartType.radiation
                                                    ? Theme.of(context).colorScheme.primary
                                                    : AppColors.secondaryText.withValues(alpha: 0.2),
                                                width: _selectedChart == ChartType.radiation ? 2 : 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  AppLocalizations.of(context)!.pressureLabel,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: _selectedChart == ChartType.radiation
                                                        ? Theme.of(context).colorScheme.primary
                                                        : AppColors.secondaryText,
                                                    fontWeight: _selectedChart == ChartType.radiation
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${weatherState.latestData!.radiation.toStringAsFixed(0)} W/m²',
                                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    color: _selectedChart == ChartType.radiation
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
                                // Chart - only show when chart is available
                                if (_isChartAvailable()) ...[
                                  const SizedBox(height: 16),
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
                                      child: Column(
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
                                                      text: AppLocalizations.of(context)!.timeLabel,
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
                                      ),
                                    ),
                                  ),
                                ],
                                // Add spacer when chart is not available to push footer down
                                if (!_isChartAvailable()) const Spacer(),
                                if (_isChartAvailable()) const SizedBox(height: 16),
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
      return {'min': 0.0, 'max': 100.0};
    }
    
    // Get all Y values for the selected chart type
    final yValues = chartData.map((data) => _getYValue(data)).toList();
    
    // Filter out any invalid values
    final validYValues = yValues.where((value) => value.isFinite && !value.isNaN).toList();
    
    if (validYValues.isEmpty) {
      return {'min': 0.0, 'max': 100.0};
    }
    
    // Find min and max values
    final minValue = validYValues.reduce((a, b) => a < b ? a : b);
    final maxValue = validYValues.reduce((a, b) => a > b ? a : b);
    
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
      case ChartType.radiation:
        // Radiation: round to nearest 1 W/m²
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
    
    return {
      'min': niceMin,
      'max': niceMax,
    };
  }
  
  String _getChartTitle() {
    switch (_selectedChart) {
      case ChartType.temperature:
        return AppLocalizations.of(context)!.temperatureTodayTitle;
      case ChartType.humidity:
        return AppLocalizations.of(context)!.humidityTodayTitle;
      case ChartType.windSpeed:
        return AppLocalizations.of(context)!.windSpeedTodayTitle;
      case ChartType.radiation:
        return AppLocalizations.of(context)!.pressureTodayTitle;
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
      case ChartType.radiation:
        return 'point.x : point.y W/m²';
    }

  }
  
  String _getYAxisTitle() {
    switch (_selectedChart) {
      case ChartType.temperature:
        return AppLocalizations.of(context)!.yAxisTemperature;
      case ChartType.humidity:
        return AppLocalizations.of(context)!.yAxisHumidity;
      case ChartType.windSpeed:
        return AppLocalizations.of(context)!.yAxisWindSpeed;
      case ChartType.radiation:
        return AppLocalizations.of(context)!.yAxisPressure;
    }

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
      case ChartType.radiation:
        value = data.radiation;
        break;
    }

    // Final safety check: ensure value is valid for chart rendering
    if (!value.isFinite || value.isNaN) {
      return 0.0; // Return safe default for corrupted data
    }

    return value;
  }

  bool _isChartAvailable() {
    final weatherState = ref.read(weatherDataProvider);
    
    // Check if we're in the data collection window (0:00 - 1:00 AM German time)
    try {
      final berlin = tz.getLocation('Europe/Berlin');
      final now = tz.TZDateTime.now(berlin);
      final isDataCollectionWindow = now.hour == 0; // Between 0:00 and 0:59
      
      // If we're in the data collection window, chart is not available
      if (isDataCollectionWindow) {
        return false;
      }
    } catch (e) {
      // If timezone initialization fails, fall back to checking data count
      AppLogger.error('Timezone check failed', module: 'WeatherPage', error: e);
    }
    
    // Charts are available when we have at least 1 data point in the full dataset
    // (before downsampling for chart rendering)
    return weatherState.fullDataCount >= 1;
  }
  
  /// Check if weather station is in repair mode (after 1 AM and less than 50 data points)
  bool _isWeatherStationRepair() {
    final weatherState = ref.read(weatherDataProvider);
    
    // Don't show repair error if there's a network/connection error
    // Network errors should be shown instead of repair messages
    if (weatherState.error != null) {
      return false;
    }
    
    try {
      final berlin = tz.getLocation('Europe/Berlin');
      final now = tz.TZDateTime.now(berlin);
      final isAfter1AM = now.hour >= 1; // After 1:00 AM (not during 0:00-0:59 data collection window)
      
      // After 1 AM, if we have less than 50 data points, show repair error
      // This indicates the weather station should have collected enough data by now
      // Only show this if there's no error (meaning fetch succeeded but data is insufficient)
      if (isAfter1AM && weatherState.fullDataCount < 50) {
        return true;
      }
    } catch (e) {
      // If timezone check fails, don't show repair error to avoid false positives
      AppLogger.error('Timezone check failed for repair mode', module: 'WeatherPage', error: e);
    }
    
    return false;
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
        data.radiation == firstData.radiation);
    
    return allSame;
  }
  
  /// Calculate optimal x-axis interval to prevent overlapping time labels
  /// Ensures at least 2 time labels are always shown
  double _calculateOptimalInterval(List<WeatherData> chartData, BuildContext context) {
    if (chartData.isEmpty) return 2.0;
    
    // Get the time range of the data
    final firstTime = chartData.first.time;
    final lastTime = chartData.last.time;
    final totalDuration = lastTime.difference(firstTime);
    final totalHours = totalDuration.inHours.toDouble();
    
    // Handle edge case: if all data points are at the same time or very close
    // Use a minimum interval to ensure at least 2 labels
    if (totalHours < 0.5) {
      // For very short time ranges (< 30 min), use 15-minute intervals
      // This ensures we show at least 2 labels
      return 0.25; // 15 minutes in hours
    }
    
    // Ensure we always have at least 2 labels by limiting interval to half the range
    final maxIntervalForTwoLabels = totalHours / 2.0;
    
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
    double interval;
    if (minInterval <= 1.0) {
      interval = 1.0; // Show every hour
    } else if (minInterval <= 2.0) {
      interval = 2.0; // Show every 2 hours
    } else if (minInterval <= 3.0) {
      interval = 3.0; // Show every 3 hours
    } else if (minInterval <= 4.0) {
      interval = 4.0; // Show every 4 hours
    } else if (minInterval <= 6.0) {
      interval = 6.0; // Show every 6 hours
    } else {
      interval = 12.0; // Show every 12 hours for very long ranges
    }
    
    // Ensure we always have at least 2 labels by capping the interval
    // But never return 0 or negative - use a minimum of 0.25 hours (15 minutes)
    final finalInterval = interval > maxIntervalForTwoLabels ? maxIntervalForTwoLabels : interval;
    return finalInterval > 0 ? finalInterval : 0.25;
  }
  


  Widget _buildFooter(BuildContext context) {
    return AppFooter(
      bottomPadding: _isButtonNavigation(context) ? 34.0 : 8.0,
    );
  }
} 