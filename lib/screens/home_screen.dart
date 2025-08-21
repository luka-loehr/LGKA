// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../data/pdf_repository.dart';
import '../providers/haptic_service.dart';
import '../navigation/app_router.dart';

import 'dart:async';
import 'weather_page.dart';



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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _errorAnimationController;
  late Animation<double> _errorAnimation;
  
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Initialize error animation controller
    _errorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _errorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _errorAnimationController, curve: Curves.easeInOut),
    );

    // Preload PDFs and weather data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPlans(forceReload: false);
      // Run weather preloading in background without blocking UI
      _preloadWeatherData();
    });
  }

  Future<void> _refreshPlans({bool forceReload = true}) async {
    final pdfRepo = ref.read(pdfRepositoryProvider);
    await pdfRepo.preloadPdfs(forceReload: forceReload);
  }

  /// Retry method for global connection errors (when both PDFs fail and no weather data)
  Future<void> _retryAll() async {
    // Use unified retry service to retry both weather and PDFs simultaneously
    final retryService = ref.read(globalRetryServiceProvider);
    await retryService.retryAll();
  }

  /// Retry only today's PDF
  Future<void> _retryTodayPdf() async {
    final pdfRepo = ref.read(pdfRepositoryProvider);
    await pdfRepo.retryTodayPdf();
  }

  /// Retry only tomorrow's PDF
  Future<void> _retryTomorrowPdf() async {
    final pdfRepo = ref.read(pdfRepositoryProvider);
    await pdfRepo.retryTomorrowPdf();
  }

  void _preloadWeatherData() {
    // Run in background without blocking UI
    () async {
      try {
        // Preload weather data in background
        print('🌤️ [HomeScreen] Starting background weather data fetch');
        final weatherService = ref.read(weatherServiceProvider);
        await weatherService.fetchWeatherData();
        print('🌤️ [HomeScreen] Weather data preloaded successfully');
      } catch (e) {
        print('❌ [HomeScreen] Failed to preload weather data: $e');
        // Don't show error to user since this is background preloading
      }
    }();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _errorAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openPdf(bool isToday) async {
    // Medium vibration when opening PDF
    await HapticService.pdfLoading();
    
    final pdfRepo = ref.read(pdfRepositoryProvider);
    final file = await pdfRepo.getCachedPdfByDay(isToday);

    if (file != null && mounted) {
      // Use built-in PDF viewer
      final dayName = isToday ? pdfRepo.todayWeekday : pdfRepo.tomorrowWeekday;
      context.push(AppRouter.pdfViewer, extra: {
        'file': file,
        'dayName': dayName,
      });
    } else {
      // PDF could not be loaded - no error state needed since buttons are already greyed out
      debugPrint('PDF could not be loaded for ${isToday ? 'today' : 'tomorrow'}');
    }
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E), // Lighter than main background
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SettingsSheetContent(
        onSettingsChanged: () {
          // Force rebuild von der HomeScreen-UI
          setState(() {});
        },
      ),
    );
  }
  




  @override
  Widget build(BuildContext context) {
    final pdfRepo = ref.watch(pdfRepositoryProvider);
    
    // Trigger fade-in animation when weekdays are loaded
    if (pdfRepo.weekdaysLoaded && _fadeController.status == AnimationStatus.dismissed) {
      _fadeController.forward();
    }

    // Control error animation based on error state (keep error visible during retry)
    if (pdfRepo.shouldShowError) {
      if (_errorAnimationController.status == AnimationStatus.dismissed) {
        _errorAnimationController.forward();
      }
    } else {
      if (_errorAnimationController.status == AnimationStatus.completed) {
        _errorAnimationController.reverse();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.appSurface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegmentedButton(0, 'Vertretungsplan', Icons.calendar_today),
              _buildSegmentedButton(1, 'Wetter', Icons.wb_sunny_outlined),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              HapticService.subtle();
              _showSettingsBottomSheet();
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
          HapticService.subtle();
        },
        children: [
          // Vertretungsplan Page
          _buildVertretungsplanPage(pdfRepo),
          // Weather Page
          const WeatherPage(),
        ],
      ),
    );
  }

  Widget _buildVertretungsplanPage(PdfRepository pdfRepo) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          
          // Loading bar for PDF downloads
          if (pdfRepo.showLoadingBar)
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
              child: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 64, vertical: 24),
                height: 5,
                child: LinearProgressIndicator(
                  backgroundColor:
                      AppColors.appBlueAccent.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.appBlueAccent),
                ),
              ),
            )
          else
            const SizedBox(height: 8),

          // Error state - same format as weather page (show error even during retry)
          if (pdfRepo.shouldShowError)
            FadeTransition(
              opacity: _errorAnimation,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: AppColors.secondaryText.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Serververbindung fehlgeschlagen',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _retryAll,
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
          else if (pdfRepo.weekdaysLoaded)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Consumer(
                builder: (context, ref, child) {
                  final preferencesManager =
                      ref.watch(preferencesManagerProvider);
                  final showDates =
                      preferencesManager.showDatesWithWeekdays;

                  // Verwende die direkten Wochentage aus pdfRepo
                  final todayWeekday = pdfRepo.todayWeekday;
                  final tomorrowWeekday = pdfRepo.tomorrowWeekday;
                  final todayDate = pdfRepo.todayDate;
                  final tomorrowDate = pdfRepo.tomorrowDate;

                  return Column(
                    children: [
                      _PlanOptions(
                        todayWeekday: todayWeekday,
                        tomorrowWeekday: tomorrowWeekday,
                        todayDate: todayDate,
                        tomorrowDate: tomorrowDate,
                        showDates: showDates,
                        onTodayClick: () => _openPdf(true),
                        onTomorrowClick: () => _openPdf(false),
                        // Error states
                        todayError: pdfRepo.todayError,
                        tomorrowError: pdfRepo.tomorrowError,
                        todayLoading: pdfRepo.todayLoading,
                        tomorrowLoading: pdfRepo.tomorrowLoading,
                        // Retry functions
                        onTodayRetry: _retryTodayPdf,
                        onTomorrowRetry: _retryTomorrowPdf,
                      ),
                      

                      
                      // Debug navigation mode detection (only show if enabled in preferences)
                      if (ref.watch(preferencesManagerProvider).showNavigationDebug) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.appSurface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.appBlueAccent.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Builder(
                            builder: (context) {
                              final mediaQuery = MediaQuery.of(context);
                              final gestureInsets = mediaQuery.systemGestureInsets.bottom;
                              final viewPadding = mediaQuery.viewPadding.bottom;
                              final padding = mediaQuery.padding.bottom;
                              
                              // More robust detection logic that should work across devices
                              // Primary: systemGestureInsets.bottom - button nav usually has higher values
                              // Secondary: viewPadding.bottom - as additional indicator
                              // Fallback: Use conservative approach if values are ambiguous
                              bool isButtonNavigation;
                              String detectionMethod;
                              
                              if (gestureInsets >= 45) {
                                // Very likely button navigation
                                isButtonNavigation = true;
                                detectionMethod = "High gesture insets (≥45)";
                              } else if (gestureInsets <= 25) {
                                // Very likely gesture navigation
                                isButtonNavigation = false;
                                detectionMethod = "Low gesture insets (≤25)";
                              } else {
                                // Ambiguous range (26-44) - use viewPadding as secondary indicator
                                isButtonNavigation = viewPadding > 50;
                                detectionMethod = "Ambiguous range, using viewPadding";
                              }
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Debug: Navigation Mode Detection',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.appBlueAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'systemGestureInsets.bottom: $gestureInsets',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  Text(
                                    'viewPadding.bottom: $viewPadding',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  Text(
                                    'Detection: $detectionMethod',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondaryText.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    'Detected Mode: ${isButtonNavigation ? "Button Navigation (3 buttons)" : "Gesture Navigation (white bar)"}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isButtonNavigation ? Colors.orange : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Footer Padding: ${isButtonNavigation ? "34.0px" : "8.0px"}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

          
          // Add footer with version and copyright at bottom of home screen
          const Spacer(),
          Padding(
            padding: EdgeInsets.only(
              bottom: _isButtonNavigation(context)
                ? 34.0  // Button navigation (3 buttons) - 26px higher than gesture nav
                : 8.0,   // Gesture navigation (white bar) - perfect position
            ),
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.hasData ? snapshot.data!.version : '1.5.5';
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '© 2025 ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      'Luka Löhr',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.appBlueAccent.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' • v$version',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText.withOpacity(0.5),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedButton(int index, String title, IconData icon) {
    final isSelected = _currentPage == index;
    return GestureDetector(
      onTap: () {
        if (_currentPage != index) {
          HapticService.subtle();
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.appBlueAccent 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected 
                  ? Colors.white 
                  : AppColors.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected 
                    ? Colors.white 
                    : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanOptions extends StatelessWidget {
  final String todayWeekday;
  final String tomorrowWeekday;
  final VoidCallback onTodayClick;
  final VoidCallback onTomorrowClick;
  final String todayDate;
  final String tomorrowDate;
  final bool showDates;
  final String? todayError;
  final String? tomorrowError;
  final bool todayLoading;
  final bool tomorrowLoading;
  final VoidCallback onTodayRetry;
  final VoidCallback onTomorrowRetry;

  const _PlanOptions({
    required this.todayWeekday,
    required this.tomorrowWeekday,
    required this.onTodayClick,
    required this.onTomorrowClick,
    required this.todayDate,
    required this.tomorrowDate,
    required this.showDates,
    required this.todayError,
    required this.tomorrowError,
    required this.todayLoading,
    required this.tomorrowLoading,
    required this.onTodayRetry,
    required this.onTomorrowRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PlanOptionButton(
          weekday: todayWeekday,
          date: todayDate,
          showDate: showDates,
          icon: Icons.calendar_today,
          onClick: onTodayClick,
          fallbackText: 'Heute',
          error: todayError,
          isLoading: todayLoading,
          onRetry: onTodayRetry,
        ),
        const SizedBox(height: 16),
        _PlanOptionButton(
          weekday: tomorrowWeekday,
          date: tomorrowDate,
          showDate: showDates,
          icon: Icons.calendar_today,
          onClick: onTomorrowClick,
          fallbackText: 'Morgen',
          error: tomorrowError,
          isLoading: tomorrowLoading,
          onRetry: onTomorrowRetry,
        ),
      ],
    );
  }
}

class _PlanOptionButton extends StatefulWidget {
  final String weekday;
  final String date;
  final bool showDate;
  final IconData icon;
  final VoidCallback onClick;
  final String fallbackText;
  final String? error;
  final bool isLoading;
  final VoidCallback onRetry;

  const _PlanOptionButton({
    required this.weekday,
    required this.date,
    required this.showDate,
    required this.icon,
    required this.onClick,
    required this.fallbackText,
    required this.error,
    required this.isLoading,
    required this.onRetry,
  });

  @override
  State<_PlanOptionButton> createState() => _PlanOptionButtonState();
}

class _PlanOptionButtonState extends State<_PlanOptionButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _dateController;
  late Animation<double> _dateOpacityAnimation;
  bool _isPressed = false;
  bool _showDatePrevious = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 300), // Slower reverse animation
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _scaleController, 
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOutBack, // Nice bounce back effect
      ),
    );
    
    // Animation controller für das Ein-/Ausblenden des Datums
    _dateController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _dateOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dateController, curve: Curves.easeInOut)
    );
    
    _showDatePrevious = widget.showDate;
    if (widget.showDate) {
      _dateController.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(_PlanOptionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Wenn sich der showDate-Wert ändert, starte die Animation
    if (oldWidget.showDate != widget.showDate) {
      if (widget.showDate) {
        _dateController.forward();
      } else {
        _dateController.reverse();
      }
      _showDatePrevious = widget.showDate;
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if this button should be disabled (empty PDF, failed to load, or parser failed)
    final hasError = widget.error != null;
    final hasData = widget.weekday.isNotEmpty && widget.weekday != 'weekend';
    final isDisabled = widget.weekday.isEmpty || widget.weekday == 'weekend' || (hasError && !hasData);

    // Don't show error state anymore - treat failed PDFs like empty PDFs

    return GestureDetector(
      onTapDown: isDisabled ? null : (details) {
        setState(() => _isPressed = true);
        _scaleController.forward();
        HapticService.subtle(); // Add haptic feedback on press
      },
      onTapUp: isDisabled ? null : (details) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      onTapCancel: isDisabled ? null : () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      onTap: isDisabled ? null : () {
        widget.onClick();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: (_isPressed && !isDisabled) ? _scaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: Duration(milliseconds: _isPressed ? 150 : 300), // Slower when releasing
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: isDisabled 
                    ? AppColors.appSurface.withOpacity(0.5) // Dimmed for disabled state
                    : _isPressed 
                        ? AppColors.appSurface.withOpacity(0.8)
                        : AppColors.appSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: (_isPressed || isDisabled)
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.appBlueAccent.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDisabled 
                          ? AppColors.calendarIconBackground.withOpacity(0.5)
                          : AppColors.calendarIconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: isDisabled ? Colors.white.withOpacity(0.5) : Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          widget.weekday.isEmpty || widget.weekday == 'weekend' || (hasError && !hasData)
                            ? 'Noch keine Infos'
                            : widget.weekday,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isDisabled 
                                    ? AppColors.appOnSurface.withOpacity(0.5)
                                    : AppColors.appOnSurface,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(width: 8),
                        // Animiertes Datum
                        if (widget.date.isNotEmpty && !isDisabled)
                          FadeTransition(
                            opacity: _dateOpacityAnimation,
                            child: Text(
                              widget.date,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsSheetContent extends ConsumerStatefulWidget {
  final VoidCallback onSettingsChanged;

  const _SettingsSheetContent({
    required this.onSettingsChanged,
  });

  @override
  ConsumerState<_SettingsSheetContent> createState() => _SettingsSheetContentState();
}

class _SettingsSheetContentState extends ConsumerState<_SettingsSheetContent> {
  @override
  Widget build(BuildContext context) {
    final preferencesManager = ref.watch(preferencesManagerProvider);
    
    return Wrap(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            16, 
            16, 
            16, 
            _isButtonNavigation(context)
              ? 54.0  // Button navigation (3 buttons) - 10px higher position
              : 8.0,   // Gesture navigation (white bar) - matches footer padding
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Einstellungen',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 1),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Date Setting
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.appBlueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Datum anzeigen',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.appBlueAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Datum nach Wochentag anzeigen',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Switch(
                          value: preferencesManager.showDatesWithWeekdays,
                          onChanged: (value) async {
                            await preferencesManager.setShowDatesWithWeekdays(value);
                            HapticService.subtle();
                            setState(() {});
                            
                            // Benachrichtigung an den HomeScreen, dass sich die Einstellung geändert hat
                            widget.onSettingsChanged();
                          },
                          activeColor: AppColors.appBlueAccent,
                        ),
                      ],
                    ),
                    
                    // Divider
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    
                    // Legal Links
                    _buildLegalLinkRow(
                      context,
                      Icons.privacy_tip_outlined, 
                      'Datenschutzerklärung', 
                      'https://luka-loehr.github.io/LGKA/privacy.html'
                    ),
                    const SizedBox(height: 12),
                    _buildLegalLinkRow(
                      context,
                      Icons.info_outline, 
                      'Impressum', 
                      'https://luka-loehr.github.io/LGKA/impressum.html'
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildLegalLinkRow(BuildContext context, IconData icon, String text, String url) {
    return InkWell(
      onTap: () {
        HapticService.subtle();
        _launchURL(url);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.secondaryText,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: AppColors.secondaryText.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  void _launchURL(String url) async {
    try {
      Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }
}