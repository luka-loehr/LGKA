// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/color_provider.dart';
import '../../providers/substitution_provider.dart';
import '../../services/haptic_service.dart';
import '../../navigation/app_router.dart';
import '../../utils/app_logger.dart';
import '../../utils/app_info.dart';
import 'weather_page.dart';
import 'schedule_page.dart';
import 'substitution_screen.dart';
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

  /// Initialize substitution provider and preload weather data
  Future<void> _initializeData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(substitutionProvider.notifier).initialize();
      
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
        // Trigger haptic feedback every time the page changes
        // This fires whenever the category in the top navbar switches
        if (_currentPage != index) {
          HapticService.medium();
        }
        setState(() => _currentPage = index);
      },
      children: [
        const SubstitutionScreen(),
        const WeatherPage(),
        const SchedulePage(),
      ],
    );
  }

  void _showSettings() {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SettingsSheet(),
    );
  }

  void _showDrawer() {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DrawerSheet(),
    );
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
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildLastDownloadedNotice(context, ref),
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

  Widget _buildLastDownloadedNotice(BuildContext context, WidgetRef ref) {
    final substitutionState = ref.watch(substitutionProvider);
    
    // Get the most recent download timestamp from both today and tomorrow
    final todayTimestamp = substitutionState.todayState.downloadTimestamp;
    final tomorrowTimestamp = substitutionState.tomorrowState.downloadTimestamp;
    
    DateTime? mostRecentTimestamp;
    if (todayTimestamp != null && tomorrowTimestamp != null) {
      mostRecentTimestamp = todayTimestamp.isAfter(tomorrowTimestamp) 
          ? todayTimestamp 
          : tomorrowTimestamp;
    } else if (todayTimestamp != null) {
      mostRecentTimestamp = todayTimestamp;
    } else if (tomorrowTimestamp != null) {
      mostRecentTimestamp = tomorrowTimestamp;
    }
    
    // Only show notice if we have a timestamp
    if (mostRecentTimestamp == null) {
      return const SizedBox.shrink();
    }
    
    // Format timestamp to show only time with seconds (HH:mm:ss)
    final dateFormat = DateFormat('HH:mm:ss', 'de_DE');
    final formattedTime = dateFormat.format(mostRecentTimestamp);
    
    return Text(
      AppLocalizations.of(context)!.lastDownloaded(formattedTime),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.secondaryText,
      ),
      textAlign: TextAlign.center,
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
