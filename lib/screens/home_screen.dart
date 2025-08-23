// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../data/pdf_repository.dart';
import '../data/preferences_manager.dart';
import '../providers/haptic_service.dart';
import '../navigation/app_router.dart';
import 'weather_page.dart';

/// Main home screen with substitution plan and weather tabs
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
      final pdfRepo = ref.read(pdfRepositoryProvider);
      await pdfRepo.initialize();
      
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
      title: _buildSegmentedControl(),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _showSettings,
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
          _buildSegmentedButton(0, 'Vertretungsplan', Icons.calendar_today),
          _buildSegmentedButton(1, 'Wetter', Icons.wb_sunny_outlined),
        ],
      ),
    );
  }

  Widget _buildSegmentedButton(int index, String title, IconData icon) {
    final isSelected = _currentPage == index;
    
    return GestureDetector(
      onTap: () => _switchToPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.appBlueAccent : Colors.transparent,
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
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchToPage(int index) {
    if (_currentPage != index) {
      HapticService.subtle();
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage = index);
    }
  }

  Widget _buildBody() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
        // Add haptic feedback when switching tabs
        HapticService.subtle();
      },
      children: [
        const _SubstitutionPlanPage(),
        const WeatherPage(),
      ],
    );
  }

  void _showSettings() {
    HapticService.subtle();
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
    
    if (!pdfRepo.isInitialized || pdfRepo.isLoading) {
      return const _LoadingView();
    }

    if (pdfRepo.hasAnyError && !pdfRepo.hasAnyData) {
      return _ErrorView(
        onRetry: () => pdfRepo.retryAll(),
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
            child: _buildPlanOptions(pdfRepo),
          ),
          
          const Spacer(),
          
          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildPlanOptions(PdfRepository pdfRepo) {
    return Column(
      children: [
        _PlanOptionButton(
          pdfState: pdfRepo.todayState,
          label: 'Heute',
          onTap: () => _openPdf(pdfRepo, true),
          onRetry: () => pdfRepo.retryPdf(true),
        ),
        const SizedBox(height: 16),
        _PlanOptionButton(
          pdfState: pdfRepo.tomorrowState,
          label: 'Morgen',
          onTap: () => _openPdf(pdfRepo, false),
          onRetry: () => pdfRepo.retryPdf(false),
        ),
      ],
    );
  }

  void _openPdf(PdfRepository pdfRepo, bool isToday) {
    if (!pdfRepo.canOpenPdf(isToday)) return;
    
    // Get the PDF file and actual weekday from the PDF state
    final pdfFile = pdfRepo.getPdfFile(isToday);
    final pdfState = isToday ? pdfRepo.todayState : pdfRepo.tomorrowState;
    final weekday = pdfState.weekday ?? (isToday ? 'Heute' : 'Morgen');
    
    if (pdfFile != null) {
      // Navigate to PDF viewer screen
      context.push(AppRouter.pdfViewer, extra: {
        'file': pdfFile,
        'dayName': weekday,
      });
    }
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: _getFooterPadding(context),
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
                  color: AppColors.secondaryText.withValues(alpha: 0.5),
                ),
              ),
              Text(
                'Luka Löhr',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.appBlueAccent.withValues(alpha: 0.7),
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

/// Loading view while PDFs are being initialized
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.appBlueAccent),
          ),
          SizedBox(height: 16),
          Text(
            'Lade Vertretungspläne...',
            style: TextStyle(color: AppColors.secondaryText),
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
            Icons.description_outlined,
            size: 64,
            color: AppColors.secondaryText.withValues(alpha: 0.5),
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
            onPressed: onRetry,
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
    final preferencesManager = ref.watch(preferencesManagerProvider);
    final showDates = preferencesManager.showDatesWithWeekdays;
    
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
                    child: _buildContent(showDates, isDisabled, hasError, isLoading),
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
        color: AppColors.appBlueAccent.withValues(alpha: 0.1),
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
            ? AppColors.calendarIconBackground.withValues(alpha: 0.5)
            : AppColors.calendarIconBackground,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.calendar_today,
        color: isDisabled ? Colors.white.withValues(alpha: 0.5) : Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildContent(bool showDates, bool isDisabled, bool hasError, bool isLoading) {
    final weekday = widget.pdfState.weekday ?? '';
    final date = widget.pdfState.date ?? '';
    
    String displayText;
    if (hasError) {
      displayText = 'Fehler beim Laden';
    } else if (weekday.isEmpty || weekday == 'weekend') {
      displayText = 'Noch keine Infos';
    } else {
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
          AnimatedOpacity(
            opacity: showDates ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              date,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRetryButton() {
    return IconButton(
      onPressed: widget.onRetry,
      icon: const Icon(
        Icons.refresh,
        color: AppColors.appBlueAccent,
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
    // Add haptic feedback when button is tapped
    HapticService.subtle();
    
    if (widget.pdfState.error != null) {
      widget.onRetry();
    } else {
      widget.onTap();
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
                'Einstellungen',
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
                    _buildDateSetting(context, preferencesManager),
                    const SizedBox(height: 16),
                    _buildDivider(),
                    const SizedBox(height: 16),
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

  Widget _buildDateSetting(BuildContext context, PreferencesManager preferencesManager) {
    return Row(
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
          },
          activeColor: AppColors.appBlueAccent,
        ),
      ],
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
        _buildLegalLink(
          context,
          Icons.privacy_tip_outlined, 
          'Datenschutzerklärung', 
          'https://luka-loehr.github.io/LGKA/privacy.html'
        ),
        const SizedBox(height: 12),
        _buildLegalLink(
          context,
          Icons.info_outline, 
          'Impressum', 
          'https://luka-loehr.github.io/LGKA/impressum.html'
        ),
      ],
    );
  }

  Widget _buildLegalLink(BuildContext context, IconData icon, String text, String url) {
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