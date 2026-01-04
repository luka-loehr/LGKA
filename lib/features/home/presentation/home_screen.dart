// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../substitution/application/substitution_provider.dart';
import '../../substitution/presentation/substitution_screen.dart';
import '../../weather/application/weather_provider.dart';
import '../../weather/presentation/weather_page.dart';
import '../../schedule/presentation/schedule_page.dart';
import '../../settings/presentation/settings_modal.dart';
import '../../../../services/haptic_service.dart';
import '../../../../utils/app_logger.dart';
import '../../../../widgets/constrained_modal_bottom_sheet.dart';
import 'drawer_modal.dart';
import '../../../../l10n/app_localizations.dart';

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
    showConstrainedModalBottomSheet(
      context: context,
      child: const SettingsModal(),
    );
  }

  void _showDrawer() {
    showConstrainedModalBottomSheet(
      context: context,
      child: const DrawerModal(),
    );
  }


}

