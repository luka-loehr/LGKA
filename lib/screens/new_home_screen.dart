// Copyright Luka Löhr 2025

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/color_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/news_provider.dart';
import '../services/schedule_service.dart';
import '../data/pdf_repository.dart';
import '../providers/haptic_service.dart';
import '../navigation/app_router.dart';
import '../services/retry_service.dart';
import '../utils/app_logger.dart';
import '../utils/app_info.dart';
import '../widgets/app_footer.dart';
import '../l10n/app_localizations.dart';

/// New card-based home screen
class NewHomeScreen extends ConsumerStatefulWidget {
  const NewHomeScreen({super.key});

  @override
  ConsumerState<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends ConsumerState<NewHomeScreen> {
  bool _pdfLoadingPreviously = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Initialize PDF repository and preload weather data
  Future<void> _initializeData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(pdfRepositoryProvider.notifier).initialize();
      
      // Preload weather data in background
      _preloadWeatherData();
      
      // Preload news in background
      ref.read(newsProvider.notifier).loadNews();
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

    // Trigger light haptic when PDFs finish loading and data is available
    final becameAvailable = _pdfLoadingPreviously && !pdfRepo.isLoading && pdfRepo.hasAnyData;
    if (becameAvailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await HapticService.light();
      });
    }
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
        onPressed: _onKrankmeldungPressed,
        icon: const Icon(
          Icons.medical_services_outlined,
          color: AppColors.secondaryText,
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.appTitle,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
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

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          
          // Primary Card: Vertretungsplan
          _VertretungsplanCard(),
          
          const SizedBox(height: 16),
          
          // Grid: Stundenplan & Wetter
          Row(
            children: [
              Expanded(child: _StundenplanCard()),
              const SizedBox(width: 16),
              Expanded(child: _WetterCard()),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // News Card
          _NeuigkeitenCard(),
          
          const SizedBox(height: 32),
          
          // Footer
          _buildFooter(context),
        ],
      ),
    );
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

  void _onKrankmeldungPressed() {
    HapticService.subtle();
    
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

  void _navigateToSubstitutions() {
    HapticService.subtle();
    final pdfRepo = ref.read(pdfRepositoryProvider);
    
    // Navigate to a page that shows substitution options
    // For now, we'll show a bottom sheet with options
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SubstitutionOptionsSheet(pdfRepo: pdfRepo),
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
}

/// Primary Card: Vertretungsplan
class _VertretungsplanCard extends ConsumerWidget {
  const _VertretungsplanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfRepo = ref.watch(pdfRepositoryProvider);
    
    return _HomeCard(
      height: 180,
      onTap: () {
        HapticService.subtle();
        final pdfRepoState = ref.read(pdfRepositoryProvider);
        
        // Show substitution options
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1E1E1E),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _SubstitutionOptionsSheet(pdfRepo: pdfRepoState),
        );
      },
      child: Row(
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.substitutionPlan,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppLocalizations.of(context)!.today} & ${AppLocalizations.of(context)!.tomorrow}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                if (pdfRepo.hasAnyData) ...[
                  const SizedBox(height: 8),
                  _buildStatusIndicator(context, pdfRepo),
                ],
              ],
            ),
          ),
          
          // Arrow
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.secondaryText.withValues(alpha: 0.6),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, PdfRepositoryState pdfRepo) {
    final todayAvailable = pdfRepo.todayState.canDisplay;
    final tomorrowAvailable = pdfRepo.tomorrowState.canDisplay;
    
    String status;
    Color statusColor;
    
    if (todayAvailable && tomorrowAvailable) {
      status = '${AppLocalizations.of(context)!.today} & ${AppLocalizations.of(context)!.tomorrow} verfügbar';
      statusColor = Colors.green;
    } else if (todayAvailable) {
      status = '${AppLocalizations.of(context)!.today} verfügbar';
      statusColor = Colors.green;
    } else if (tomorrowAvailable) {
      status = '${AppLocalizations.of(context)!.tomorrow} verfügbar';
      statusColor = Colors.orange;
    } else {
      status = AppLocalizations.of(context)!.noInfoYet;
      statusColor = AppColors.secondaryText;
    }
    
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          status,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.secondaryText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Grid Card: Stundenplan
class _StundenplanCard extends ConsumerWidget {
  const _StundenplanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _HomeCard(
      height: 140,
      onTap: () {
        HapticService.subtle();
        context.push(AppRouter.schedule);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule, color: Colors.white, size: 24),
          ),
          const Spacer(),
          
          // Title
          Text(
            AppLocalizations.of(context)!.schedule,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          
          // Subtitle
          Text(
            '${AppLocalizations.of(context)!.grades5to10} & ${AppLocalizations.of(context)!.j11j12}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Arrow (bottom right)
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.secondaryText.withValues(alpha: 0.6),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid Card: Wetter
class _WetterCard extends ConsumerWidget {
  const _WetterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(weatherDataProvider);
    final currentTemp = weatherState.latestData?.temperature;
    
    return _HomeCard(
      height: 140,
      onTap: () {
        HapticService.subtle();
        context.push(AppRouter.weather);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 24),
          ),
          const Spacer(),
          
          // Title
          Text(
            AppLocalizations.of(context)!.weather,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          
          // Subtitle with temperature
          Text(
            currentTemp != null 
              ? '${currentTemp.toStringAsFixed(1)}°C'
              : 'Live Daten',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          
          // Arrow (bottom right)
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.secondaryText.withValues(alpha: 0.6),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// News Card
class _NeuigkeitenCard extends ConsumerWidget {
  const _NeuigkeitenCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsState = ref.watch(newsProvider);
    final eventCount = newsState.events.length;
    
    return _HomeCard(
      height: 140,
      onTap: () {
        HapticService.subtle();
        context.push(AppRouter.news);
      },
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.newspaper_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.news,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    if (eventCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$eventCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Aktuelle Nachrichten',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          
          // Arrow
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.secondaryText.withValues(alpha: 0.6),
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Reusable Card Widget
class _HomeCard extends StatefulWidget {
  final double height;
  final VoidCallback onTap;
  final Widget child;

  const _HomeCard({
    required this.height,
    required this.onTap,
    required this.child,
  });

  @override
  State<_HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<_HomeCard> 
    with SingleTickerProviderStateMixin {
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
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
        widget.onTap();
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
              height: widget.height,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.appSurface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _isPressed ? [] : [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Substitution Options Bottom Sheet
class _SubstitutionOptionsSheet extends ConsumerWidget {
  final PdfRepositoryState pdfRepo;

  const _SubstitutionOptionsSheet({required this.pdfRepo});

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
                AppLocalizations.of(context)!.substitutionPlan,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPlanOption(
                context,
                ref,
                pdfRepo.todayState,
                AppLocalizations.of(context)!.today,
                true,
              ),
              const SizedBox(height: 12),
              _buildPlanOption(
                context,
                ref,
                pdfRepo.tomorrowState,
                AppLocalizations.of(context)!.tomorrow,
                false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanOption(
    BuildContext context,
    WidgetRef ref,
    PdfState pdfState,
    String label,
    bool isToday,
  ) {
    final isDisabled = !pdfState.canDisplay;
    final hasError = pdfState.error != null;

    return InkWell(
      onTap: isDisabled ? null : () {
        HapticService.subtle();
        Navigator.of(context).pop();
        final pdfRepoNotifier = ref.read(pdfRepositoryProvider.notifier);
        if (!pdfRepoNotifier.canOpenPdf(isToday)) return;

        final pdfFile = pdfRepoNotifier.getPdfFile(isToday);
        final weekday = pdfState.weekday ?? label;
        
        if (pdfFile != null) {
          context.push(AppRouter.pdfViewer, extra: {
            'file': pdfFile,
            'dayName': weekday,
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.appSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled 
              ? AppColors.secondaryText.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
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
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDisabled 
                        ? AppColors.appOnSurface.withValues(alpha: 0.5)
                        : AppColors.appOnSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (pdfState.weekday != null && !isDisabled) ...[
                    const SizedBox(height: 4),
                    Text(
                      pdfState.weekday!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                  if (hasError && !isDisabled) ...[
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.errorLoading,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isDisabled)
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

/// Settings Bottom Sheet (reused from original)
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
                ref.read(colorProvider.notifier).setColor(colorPalette.name);
                HapticService.subtle();
              },
              child: Container(
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
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            );
          }).toList(),
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
        _buildNewsLink(context),
        const SizedBox(height: 12),
        _buildBugReportLink(context),
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

  Widget _buildNewsLink(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.subtle();
        Navigator.of(context).pop();
        context.push(AppRouter.news);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.newspaper_outlined,
              color: AppColors.secondaryText,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.news,
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

  Widget _buildBugReportLink(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.subtle();
        Navigator.of(context).pop();
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

