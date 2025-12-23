// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/color_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../data/pdf_repository.dart';
import '../../data/preferences_manager.dart';
import '../../providers/haptic_service.dart';
import '../../navigation/app_router.dart';
import '../../services/retry_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/app_info.dart';
import '../../widgets/app_footer.dart';
import 'weather_page.dart';
import 'schedule_page.dart';
import '../../l10n/app_localizations.dart';

/// Main home screen with substitution plan and weather tabs
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _pdfLoadingPreviously = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Initialize PDF repository and preload weather data
  Future<void> _initializeData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(pdfRepositoryProvider.notifier).initialize();
      
      // Preload weather data in background
      _preloadWeatherData();
    });
  }

  /// Preload weather data without blocking UI
  void _preloadWeatherData() {
    Future(() async {
      try {
        final weatherService = ref.read(weatherServiceProvider);
        await weatherService.fetchWeatherData();
      } catch (e) {
        // Silent failure for background preloading
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pdfRepo = ref.watch(pdfRepositoryProvider);

    // Track PDF loading state
    final becameAvailable = _pdfLoadingPreviously && !pdfRepo.isLoading && pdfRepo.hasAnyData;
    _pdfLoadingPreviously = pdfRepo.isLoading;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.appBackground,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          HapticService.light();
          _showDrawer();
        },
        icon: const Icon(
          Icons.menu,
          color: AppColors.secondaryText,
        ),
      ),
      title: _buildSegmentedControl(),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            HapticService.light();
            _showSettings();
          },
          icon: const Icon(
            Icons.settings_outlined,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.appSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentedButton(0, AppLocalizations.of(context)!.substitutionPlan, Icons.calendar_today),
          _buildSegmentedButton(1, AppLocalizations.of(context)!.weather, Icons.wb_sunny_outlined),
          _buildSegmentedButton(2, AppLocalizations.of(context)!.schedule, Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildSegmentedButton(int index, String title, IconData icon) {
    final isSelected = _currentPage == index;
    final shouldShowText = _shouldShowTextForTab(index);
    
    return GestureDetector(
      onTap: () => _switchToPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: shouldShowText ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.secondaryText,
            ),
            if (shouldShowText) ...[
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.secondaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Determine if text should be shown for a specific tab based on current page
  bool _shouldShowTextForTab(int tabIndex) {
    // Only show text for the current page
    return tabIndex == _currentPage;
  }

  void _switchToPage(int index) {
    if (_currentPage != index) {
      _pageController.jumpToPage(index);
      setState(() => _currentPage = index);

      final tabNames = [
        AppLocalizations.of(context)!.substitutionPlan,
        AppLocalizations.of(context)!.weather,
        AppLocalizations.of(context)!.schedule,
      ];
      AppLogger.navigation('Switched to ${tabNames[index]} tab');
    }
  }

  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        if (_currentPage != index) {
          HapticService.light();
        }
        setState(() => _currentPage = index);
      },
      children: [
        const _SubstitutionPlanPage(),
        const WeatherPage(),
        const SchedulePage(),
      ],
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SettingsSheet(),
    );
  }

  void _showDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DrawerSheet(),
    );
  }

  void _onKrankmeldungPressed() {
    final preferencesManager = ref.read(preferencesManagerProvider);
    
    // Check if krankmeldung info has been shown before
    if (preferencesManager.krankmeldungInfoShown) {
      // Navigate directly to webview
      context.push(AppRouter.webview, extra: {
        'url': 'https://apps.lgka-online.de/apps/krankmeldung/',
        'title': AppLocalizations.of(context)!.krankmeldung,
        'headers': {
          'User-Agent': AppInfo.userAgent,
        },
        'fromKrankmeldungInfo': false,
      });
    } else {
      // Navigate to the info screen first
      context.push(AppRouter.krankmeldungInfo);
    }
  }

}

/// Substitution plan page with today and tomorrow options
class _SubstitutionPlanPage extends ConsumerStatefulWidget {
  const _SubstitutionPlanPage();

  @override
  ConsumerState<_SubstitutionPlanPage> createState() => _SubstitutionPlanPageState();
}

class _SubstitutionPlanPageState extends ConsumerState<_SubstitutionPlanPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasShownButtons = false;
  bool _wasLoading = true;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _startButtonAnimation() {
    if (!_hasShownButtons) {
      _hasShownButtons = true;
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfRepo = ref.watch(pdfRepositoryProvider);
    
    _wasLoading = pdfRepo.isLoading || !pdfRepo.isInitialized;
    
    if (!pdfRepo.isInitialized || pdfRepo.isLoading) {
      return _LoadingView();
    }

    if (pdfRepo.hasAnyError && !pdfRepo.hasAnyData) {
      return _ErrorView(
        onRetry: () {
          HapticService.light();
          ref.read(retryServiceProvider).retryAllDataSources();
        },
      );
    }

    // Start animation when buttons should be visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startButtonAnimation();
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          
          // Plan options with proper fade-in animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildPlanOptions(pdfRepo, ref),
          ),
          
          const Spacer(),
          
          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildPlanOptions(PdfRepositoryState pdfRepoState, WidgetRef ref) {
    return Column(
      children: [
        _PlanOptionButton(
          pdfState: pdfRepoState.todayState,
          label: AppLocalizations.of(context)!.today,
          onTap: () => _openPdf(pdfRepoState, ref, true),
          onRetry: () {
            ref.read(retryServiceProvider).retryAllDataSources();
          },
        ),
        const SizedBox(height: 16),
        _PlanOptionButton(
          pdfState: pdfRepoState.tomorrowState,
          label: AppLocalizations.of(context)!.tomorrow,
          onTap: () => _openPdf(pdfRepoState, ref, false),
          onRetry: () {
            ref.read(retryServiceProvider).retryAllDataSources();
          },
        ),
      ],
    );
  }

  void _openPdf(PdfRepositoryState pdfRepoState, WidgetRef ref, bool isToday) {
    final pdfRepoNotifier = ref.read(pdfRepositoryProvider.notifier);
    if (!pdfRepoNotifier.canOpenPdf(isToday)) return;

    // Get the PDF file and actual weekday from the PDF state
    final pdfFile = pdfRepoNotifier.getPdfFile(isToday);
    final pdfState = isToday ? pdfRepoState.todayState : pdfRepoState.tomorrowState;
    String weekday = pdfState.weekday ?? (isToday ? AppLocalizations.of(context)!.today : AppLocalizations.of(context)!.tomorrow);
    // Translate German weekdays to English for display when locale is English
    final localeCode = Localizations.localeOf(context).languageCode;
    if (localeCode == 'en') {
      const Map<String, String> germanToEnglishWeekday = {
        'Montag': 'Monday',
        'Dienstag': 'Tuesday',
        'Mittwoch': 'Wednesday',
        'Donnerstag': 'Thursday',
        'Freitag': 'Friday',
        'Samstag': 'Saturday',
        'Sonntag': 'Sunday',
      };
      if (germanToEnglishWeekday.containsKey(weekday)) {
        weekday = germanToEnglishWeekday[weekday]!;
      }
    }

    AppLogger.pdf('Opening PDF: $weekday (${isToday ? 'today' : 'tomorrow'})');

    if (pdfFile != null) {
      // Navigate to PDF viewer screen
      context.push(AppRouter.pdfViewer, extra: {
        'file': pdfFile,
        'dayName': weekday,
      });
    }
  }

  Widget _buildFooter(BuildContext context) {
    return AppFooter(bottomPadding: _getFooterPadding(context));
  }

  double _getFooterPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final gestureInsets = mediaQuery.systemGestureInsets.bottom;
    final viewPadding = mediaQuery.viewPadding.bottom;
    
    // Determine navigation mode based on gesture insets
    if (gestureInsets >= 45) {
      return 34.0; // Button navigation
    } else if (gestureInsets <= 25) {
      return 8.0; // Gesture navigation
    } else {
      // Ambiguous range - use viewPadding as secondary indicator
      return viewPadding > 50 ? 34.0 : 8.0;
    }
  }
}

/// Stundenplan page with schedule options
class _StundenplanPage extends ConsumerStatefulWidget {
  const _StundenplanPage();

  @override
  ConsumerState<_StundenplanPage> createState() => _StundenplanPageState();
}

class _StundenplanPageState extends ConsumerState<_StundenplanPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasShownButtons = false;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _startButtonAnimation() {
    if (!_hasShownButtons) {
      _hasShownButtons = true;
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start animation when buttons should be visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startButtonAnimation();
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          
          // Schedule options with proper fade-in animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildScheduleOptions(),
          ),
          
          const Spacer(),
          
          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildScheduleOptions() {
    return Column(
      children: [
        _ScheduleOptionButton(
          label: AppLocalizations.of(context)!.classes5to7,
          onTap: () => _openSchedule('klassenstufe_5_7'),
        ),
        const SizedBox(height: 16),
        _ScheduleOptionButton(
          label: AppLocalizations.of(context)!.classes8to10,
          onTap: () => _openSchedule('klassenstufe_8_10'),
        ),
        const SizedBox(height: 16),
        _ScheduleOptionButton(
          label: AppLocalizations.of(context)!.upperSchool,
          onTap: () => _openSchedule('oberstufe'),
        ),
      ],
    );
  }

  void _openSchedule(String scheduleType) {
    // Navigate to schedule page - implementation handled in SchedulePage
  }

  Widget _buildFooter(BuildContext context) {
    return AppFooter(bottomPadding: _getFooterPadding(context));
  }

  double _getFooterPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final gestureInsets = mediaQuery.systemGestureInsets.bottom;
    final viewPadding = mediaQuery.viewPadding.bottom;
    
    // Determine navigation mode based on gesture insets
    if (gestureInsets >= 45) {
      return 34.0; // Button navigation
    } else if (gestureInsets <= 25) {
      return 8.0; // Gesture navigation
    } else {
      // Ambiguous range - use viewPadding as secondary indicator
      return viewPadding > 50 ? 34.0 : 8.0;
    }
  }
}

/// Schedule option button
class _ScheduleOptionButton extends ConsumerStatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _ScheduleOptionButton({
    required this.label,
    required this.onTap,
  });

  @override
  ConsumerState<_ScheduleOptionButton> createState() => _ScheduleOptionButtonState();
}

class _ScheduleOptionButtonState extends ConsumerState<_ScheduleOptionButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: () => _onTapCancel(),
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: _isPressed 
                    ? AppColors.appSurface.withValues(alpha: 0.8)
                    : AppColors.appSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isPressed ? [] : [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                      color: AppColors.calendarIconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.appOnSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.secondaryText.withValues(alpha: 0.6),
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTap() {
    HapticService.medium();
    widget.onTap();
  }
}

/// Loading view while PDFs are being initialized
class _LoadingView extends StatelessWidget {
  _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.loadingSubstitutions,
            style: const TextStyle(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

/// Error view when all PDFs fail to load
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: AppColors.secondaryText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.serverConnectionFailed,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.serverConnectionHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              HapticService.light();
              onRetry();
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
      ),
    );
  }
}

/// Individual plan option button
class _PlanOptionButton extends ConsumerStatefulWidget {
  final PdfState pdfState;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  const _PlanOptionButton({
    required this.pdfState,
    required this.label,
    required this.onTap,
    required this.onRetry,
  });

  @override
  ConsumerState<_PlanOptionButton> createState() => _PlanOptionButtonState();
}

class _PlanOptionButtonState extends ConsumerState<_PlanOptionButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.pdfState.canDisplay;
    final hasError = widget.pdfState.error != null;
    final isLoading = widget.pdfState.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _onTapDown(),
      onTapUp: isDisabled ? null : (_) => _onTapUp(),
      onTapCancel: isDisabled ? null : () => _onTapCancel(),
      onTap: isDisabled ? null : _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: _getBackgroundColor(isDisabled),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _getBoxShadow(isDisabled),
              ),
              child: Row(
                children: [
                  _buildIcon(isDisabled),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildContent(isDisabled, hasError, isLoading),
                  ),
                  if (hasError) _buildRetryButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBackgroundColor(bool isDisabled) {
    if (isDisabled) {
      return AppColors.appSurface.withValues(alpha: 0.5);
    }
    if (_isPressed) {
      return AppColors.appSurface.withValues(alpha: 0.8);
    }
    return AppColors.appSurface;
  }

  List<BoxShadow> _getBoxShadow(bool isDisabled) {
    if (_isPressed || isDisabled) return [];
    return [
      BoxShadow(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  Widget _buildIcon(bool isDisabled) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDisabled 
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.calendar_today,
        color: isDisabled ? Colors.white.withValues(alpha: 0.5) : Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildContent(bool isDisabled, bool hasError, bool isLoading) {
    String weekday = widget.pdfState.weekday ?? '';
    final date = widget.pdfState.date ?? '';
    
    String displayText;
    if (hasError) {
      displayText = AppLocalizations.of(context)!.errorLoading;
    } else if (weekday.isEmpty || weekday == 'weekend') {
      displayText = AppLocalizations.of(context)!.noInfoYet;
    } else {
      // Translate German weekday names to English for display if needed
      final localeCode = Localizations.localeOf(context).languageCode;
      if (localeCode == 'en') {
        const Map<String, String> germanToEnglishWeekday = {
          'Montag': 'Monday',
          'Dienstag': 'Tuesday',
          'Mittwoch': 'Wednesday',
          'Donnerstag': 'Thursday',
          'Freitag': 'Friday',
          'Samstag': 'Saturday',
          'Sonntag': 'Sunday',
        };
        if (germanToEnglishWeekday.containsKey(weekday)) {
          weekday = germanToEnglishWeekday[weekday]!;
        }
      }
      displayText = weekday;
    }

    return Row(
      children: [
        Text(
          displayText,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isDisabled 
                ? AppColors.appOnSurface.withValues(alpha: 0.5)
                : AppColors.appOnSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (date.isNotEmpty && !isDisabled) ...[
          const SizedBox(width: 8),
          Text(
            date,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRetryButton() {
    return IconButton(
      onPressed: widget.onRetry,
      icon: Icon(
        Icons.refresh,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTap() {
    HapticService.medium();
    if (widget.pdfState.error != null) {
      widget.onRetry();
    } else {
      widget.onTap();
    }
  }
}

/// Drawer bottom sheet
class _DrawerSheet extends ConsumerWidget {
  const _DrawerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            16, 
            16, 
            16, 
            _getBottomPadding(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.more,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildKrankmeldungOption(context, ref),
                    const SizedBox(height: 4),
                    _buildDivider(),
                    const SizedBox(height: 4),
                    _buildNeuigkeitenOption(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKrankmeldungOption(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          Navigator.of(context).pop();
          
          final preferencesManager = ref.read(preferencesManagerProvider);
          
          // Check if krankmeldung info has been shown before
          if (preferencesManager.krankmeldungInfoShown) {
            // Navigate directly to webview
            context.push(AppRouter.webview, extra: {
              'url': 'https://apps.lgka-online.de/apps/krankmeldung/',
              'title': AppLocalizations.of(context)!.krankmeldung,
              'headers': {
                'User-Agent': AppInfo.userAgent,
              },
              'fromKrankmeldungInfo': false,
            });
          } else {
            // Navigate to the info screen first
            context.push(AppRouter.krankmeldungInfo);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.medical_services_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.krankmeldung,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.secondaryText.withValues(alpha: 0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeuigkeitenOption(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          Navigator.of(context).pop();
          context.push(AppRouter.news);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.newspaper_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.news,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.secondaryText.withValues(alpha: 0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  double _getBottomPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final gestureInsets = mediaQuery.systemGestureInsets.bottom;

    if (gestureInsets >= 45) {
      return 54.0; // Button navigation
    } else if (gestureInsets <= 25) {
      return 8.0; // Gesture navigation
    } else {
      return mediaQuery.viewPadding.bottom > 50 ? 54.0 : 8.0;
    }
  }
}

/// Settings bottom sheet
class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesManager = ref.watch(preferencesManagerProvider);
    
    return Wrap(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            16, 
            16, 
            16, 
            _getBottomPadding(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.settings,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildAccentColorSetting(context, ref),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildHapticTestSection(context),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildLegalLinks(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccentColorSetting(BuildContext context, WidgetRef ref) {
    final choosableColors = ref.watch(choosableColorsProvider);
    final currentColorName = ref.watch(colorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.accentColor,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.chooseAccentColor,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: choosableColors.map((colorPalette) {
            final isSelected = currentColorName == colorPalette.name;
            return GestureDetector(
              onTap: () {
                HapticService.light();
                ref.read(colorProvider.notifier).setColor(colorPalette.name);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                curve: Curves.easeInOut,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorPalette.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorPalette.color.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 60),
                  curve: Curves.easeInOut,
                  opacity: isSelected ? 1.0 : 0.0,
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHapticTestSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haptic Feedback Test',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Test haptic feedback levels',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildHapticTestButton(
                context,
                'Light',
                () => HapticService.light(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHapticTestButton(
                context,
                'Medium',
                () => HapticService.medium(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHapticTestButton(
                context,
                'Intense',
                () => HapticService.intense(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHapticTestButton(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.appSurface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.secondaryText.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildLegalLinks(BuildContext context) {
    return Column(
      children: [
        _buildBugReportLink(context),
        const SizedBox(height: 12),
        _buildSupportLink(context),
        const SizedBox(height: 12),
        _buildLegalLink(
          context,
          Icons.privacy_tip_outlined, 
          AppLocalizations.of(context)!.privacyLabel, 
          'https://luka-loehr.github.io/LGKA/privacy.html'
        ),
        const SizedBox(height: 12),
        _buildLegalLink(
          context,
          Icons.info_outline, 
          AppLocalizations.of(context)!.legalLabel, 
          'https://luka-loehr.github.io/LGKA/impressum.html'
        ),
      ],
    );
  }


  Widget _buildBugReportLink(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push(AppRouter.bugReport);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.bug_report_outlined,
              color: AppColors.secondaryText,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.bugReport,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.secondaryText.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportLink(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.intense();
        _launchURL('https://buymeacoffee.com/lukaloehr');
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.favorite_outline,
              color: AppColors.secondaryText,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.supportProject,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: AppColors.secondaryText.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalLink(BuildContext context, IconData icon, String text, String url) {
    return InkWell(
      onTap: () {
        HapticService.light();
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
              color: AppColors.secondaryText.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }

  double _getBottomPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final gestureInsets = mediaQuery.systemGestureInsets.bottom;

    if (gestureInsets >= 45) {
      return 54.0; // Button navigation
    } else if (gestureInsets <= 25) {
      return 8.0; // Gesture navigation
    } else {
      return mediaQuery.viewPadding.bottom > 50 ? 54.0 : 8.0;
    }
  }
}
