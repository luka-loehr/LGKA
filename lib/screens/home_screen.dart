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
import 'package:connectivity_plus/connectivity_plus.dart';
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

  String? _error;
  bool _hasNoInternet = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slowConnectionController;
  late Animation<double> _slowConnectionAnimation;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
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

    // Initialize slow connection animation controller
    _slowConnectionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slowConnectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slowConnectionController, curve: Curves.easeIn),
    );

    // Preload PDFs and weather data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPlans(forceReload: false);
      // Run weather preloading in background without blocking UI
      _preloadWeatherData();
      // Check network connectivity
      _checkConnectivity();
      
      // Listen for connectivity changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
        setState(() {
          _hasNoInternet = result.contains(ConnectivityResult.none);
        });
      });
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      setState(() {
        _hasNoInternet = connectivityResult.contains(ConnectivityResult.none);
      });
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  Future<void> _refreshPlans({bool forceReload = true}) async {
    final pdfRepo = ref.read(pdfRepositoryProvider);
    await pdfRepo.preloadPdfs(forceReload: forceReload);
  }

  void _preloadWeatherData() {
    // Run in background without blocking UI
    () async {
      try {
        final weatherService = ref.read(weatherServiceProvider);
        
        // Check if we already have cached data
        final cachedData = await weatherService.getCachedData();
        if (cachedData != null && cachedData.isNotEmpty) {
          print('🌤️ [HomeScreen] Weather data already cached, no need to fetch');
          return;
        }
        
        // Fetch fresh data in background
        print('🌤️ [HomeScreen] Starting background weather data fetch');
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
    _slowConnectionController.dispose();
    _pageController.dispose();
    _connectivitySubscription.cancel();
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
      setState(() => _error = 'PDF konnte nicht geladen werden.');
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
  
  String _formatOfflineTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Minuten';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Stunden';
    } else {
      return '${time.day}.${time.month}. um ${time.hour}:${time.minute.toString().padLeft(2, '0')} Uhr';
    }
  }



  @override
  Widget build(BuildContext context) {
    final pdfRepo = ref.watch(pdfRepositoryProvider);
    
    // Trigger fade-in animation when weekdays are loaded
    if (pdfRepo.weekdaysLoaded && _fadeController.status == AnimationStatus.dismissed) {
      _fadeController.forward();
    }
    
    // Trigger slow connection animation when slow connection is detected
    if (pdfRepo.hasSlowConnection && _slowConnectionController.status == AnimationStatus.dismissed) {
      _slowConnectionController.forward();
    } else if (!pdfRepo.hasSlowConnection && _slowConnectionController.status == AnimationStatus.completed) {
      _slowConnectionController.reverse();
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
          
          // Loading bar or network notification - they replace each other at the same position
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
          else if (pdfRepo.hasSlowConnection)
            FadeTransition(
              opacity: _slowConnectionAnimation,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: pdfRepo.isNoInternet 
                            ? Colors.red.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          pdfRepo.isNoInternet 
                            ? Icons.wifi_off_outlined
                            : Icons.signal_wifi_bad_outlined,
                          color: pdfRepo.isNoInternet ? Colors.red : Colors.orange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pdfRepo.isNoInternet 
                                ? 'Hey, du hast gerade kein Internet. Deswegen zeige ich dir hier den Vertretungsplan von ${pdfRepo.offlineDataTime != null ? _formatOfflineTime(pdfRepo.offlineDataTime!) : "vorher"}. Wenn du dein WLAN oder die mobilen Daten einschaltest, kann ich dir den aktuellsten Plan anzeigen.'
                                : 'Hey, du hast gerade bisschen schlechtes Internet. Deswegen zeige ich dir hier den Vertretungsplan von ${pdfRepo.offlineDataTime != null ? _formatOfflineTime(pdfRepo.offlineDataTime!) : "vorher"}. Wenn das Internet besser wird, aktualisiere ich automatisch.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryText,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 8),
          
          if (pdfRepo.weekdaysLoaded)
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
                      ),
                      
                      // Offline mode indicator
                      if (pdfRepo.isOfflineMode && pdfRepo.offlineDataTime != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _hasNoInternet 
                              ? Colors.red.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _hasNoInternet 
                                ? Colors.red.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _hasNoInternet 
                                  ? Icons.wifi_off_outlined
                                  : Icons.signal_wifi_bad_outlined,
                                color: _hasNoInternet 
                                  ? Colors.red.shade700
                                  : Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _hasNoInternet 
                                        ? 'Hey, du hast gerade kein Internet. Deswegen zeige ich dir hier den Vertretungsplan von ${_formatOfflineTime(pdfRepo.offlineDataTime!)}. Wenn du dein WLAN oder die mobilen Daten einschaltest, kann ich dir den aktuellsten Plan anzeigen.'
                                        : 'Hey, du hast gerade bisschen schlechtes Internet. Deswegen zeige ich dir hier den Vertretungsplan von ${_formatOfflineTime(pdfRepo.offlineDataTime!)}. Wenn das Internet besser wird, aktualisiere ich automatisch.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: _hasNoInternet 
                                          ? Colors.red.shade700
                                          : Colors.orange.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
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
          if (_error != null) ...[
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
              child: Card(
                color: const Color(0xFF442727),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _error!,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFFCF6679),
                            ),
                  ),
                ),
              ),
            ),
          ],
          
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

  const _PlanOptions({
    required this.todayWeekday,
    required this.tomorrowWeekday,
    required this.onTodayClick,
    required this.onTomorrowClick,
    required this.todayDate,
    required this.tomorrowDate,
    required this.showDates,
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
        ),
        const SizedBox(height: 16),
        _PlanOptionButton(
          weekday: tomorrowWeekday,
          date: tomorrowDate,
          showDate: showDates,
          icon: Icons.calendar_today,
          onClick: onTomorrowClick,
          fallbackText: 'Morgen',
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

  const _PlanOptionButton({
    required this.weekday,
    required this.date,
    required this.showDate,
    required this.icon,
    required this.onClick,
    required this.fallbackText,
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
    // Check if this button should be disabled (empty PDF)
    final isDisabled = widget.weekday == 'weekend';
    
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
                          widget.weekday.isEmpty 
                            ? widget.fallbackText
                            : widget.weekday == 'weekend'
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