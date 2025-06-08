// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../data/pdf_repository.dart';
import '../providers/haptic_service.dart';
import '../services/file_opener_service.dart';
import '../navigation/app_router.dart';
import 'package:open_filex/open_filex.dart';

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

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isTodayLoading = false;
  bool _isTomorrowLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Preload PDFs when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPlans(forceReload: false);
    });
  }

  Future<void> _refreshPlans({bool forceReload = true}) async {
    final pdfRepo = ref.read(pdfRepositoryProvider);
    await pdfRepo.preloadPdfs(forceReload: forceReload);
  }

  Future<void> _openPdf(bool isToday) async {
    // Medium vibration when opening PDF
    await HapticService.pdfLoading();
    
    final pdfRepo = ref.read(pdfRepositoryProvider);
    final file = await pdfRepo.getCachedPdfByDay(isToday);

    if (file != null && mounted) {
      final dayName = isToday ? pdfRepo.todayWeekday : pdfRepo.tomorrowWeekday;
      context.push(AppRouter.pdfViewer, extra: {
        'file': file,
        'dayName': dayName,
      });
      
      // Track plan opening and possibly trigger review
      final reviewService = ref.read(reviewServiceProvider);
      await reviewService.trackPlanOpenAndRequestReviewIfNeeded();
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

  void _showAboutBottomSheet() {
    final pdfRepo = ref.read(pdfRepositoryProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E), // Lighter than main background
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AboutSheetContent(
        todayPdfTimestamp: pdfRepo.todayLastUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdfRepo = ref.watch(pdfRepositoryProvider);
    
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        title: Text(
          'Vertretungsplan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        backgroundColor: AppColors.appBackground,
        elevation: 0,
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
          IconButton(
            onPressed: () {
              HapticService.subtle();
              _showAboutBottomSheet();
            },
            icon: const Icon(
              Icons.info_outline,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshPlans(forceReload: true),
        backgroundColor: AppColors.appSurface,
        color: AppColors.appBlueAccent,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    if (!pdfRepo.weekdaysLoaded)
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 64, vertical: 32),
                        height: 5,
                        child: LinearProgressIndicator(
                          backgroundColor:
                              AppColors.appBlueAccent.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.appBlueAccent),
                        ),
                      )
                    else
                      Consumer(
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
                              
                              // Debug navigation mode detection
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
                                          'Footer Padding: ${isButtonNavigation ? "32.0px" : "12.0px"}',
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
                          );
                        },
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Card(
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
                    ],
                    
                    // Add footer with version and copyright at bottom of home screen
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: _isButtonNavigation(context)
                          ? 32.0  // Button navigation (3 buttons) - 20px higher than gesture nav
                          : 12.0,  // Gesture navigation (white bar) - closer to bottom
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
        ),
        const SizedBox(height: 16),
        _PlanOptionButton(
          weekday: tomorrowWeekday,
          date: tomorrowDate,
          showDate: showDates,
          icon: Icons.calendar_today,
          onClick: onTomorrowClick,
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

  const _PlanOptionButton({
    required this.weekday,
    required this.date,
    required this.showDate,
    required this.icon,
    required this.onClick,
  });

  @override
  State<_PlanOptionButton> createState() => _PlanOptionButtonState();
}

class _PlanOptionButtonState extends State<_PlanOptionButton>
    with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    // Animation controller für das Ein-/Ausblenden des Datums
    _dateController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
        widget.onClick();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.appSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.calendarIconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          widget.weekday,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.appOnSurface,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(width: 8),
                        // Animiertes Datum
                        if (widget.date.isNotEmpty)
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
              
              const SizedBox(height: 20),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Datum anzeigen',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.appOnSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Zeigt das Datum nach dem Wochentag an',
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutSheetContent extends StatelessWidget {
  final String todayPdfTimestamp;

  const _AboutSheetContent({
    required this.todayPdfTimestamp,
  });

  void _launchURL(String url) async {
    try {
      Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }

  void _triggerReview() async {
    final InAppReview inAppReview = InAppReview.instance;
    
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    } else {
      // Fallback: Öffne Play Store Seite
      inAppReview.openStoreListing();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LGKA+',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 24),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    _buildLinkRow(
                      context,
                      Icons.shield_outlined, 
                      'Datenschutzerklärung', 
                      'https://luka-loehr.github.io/LGKA/privacy.html'
                    ),
                    const SizedBox(height: 8),
                    _buildLinkRow(
                      context,
                      Icons.description_outlined, 
                      'Lizenz', 
                      'https://github.com/luka-loehr/LGKA/blob/main/LICENSE'
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
  
  Widget _buildLinkRow(BuildContext context, IconData icon, String text, String url) {
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
              color: AppColors.appBlueAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.appBlueAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF78A5F9),
          size: 18,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
} 