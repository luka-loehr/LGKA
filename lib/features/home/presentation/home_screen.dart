// Copyright Luka Löhr 2026

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
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildSegmentedControl(),
            const SizedBox(height: 8),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.appBackground,
      elevation: 0,
      toolbarHeight: 56,
      leading: IconButton(
        onPressed: () {
          HapticService.light();
          _showDrawer();
        },
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.appSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.menu,
            color: AppColors.primaryText,
            size: 20,
          ),
        ),
      ),
      title: Text(
        'LGKA+',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            HapticService.light();
            _showSettings();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.appSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: AppColors.primaryText,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    final tabs = [
      _TabData(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: AppLocalizations.of(context)!.substitutionPlan,
      ),
      _TabData(
        icon: Icons.wb_sunny_outlined,
        activeIcon: Icons.wb_sunny,
        label: AppLocalizations.of(context)!.weather,
      ),
      _TabData(
        icon: Icons.schedule_outlined,
        activeIcon: Icons.schedule,
        label: AppLocalizations.of(context)!.schedule,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.appSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          return Expanded(
            child: _buildSegmentedButton(index, tabs[index]),
          );
        }),
      ),
    );
  }

  Widget _buildSegmentedButton(int index, _TabData tab) {
    final isSelected = _currentPage == index;

    return GestureDetector(
      onTap: () => _switchToPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? tab.activeIcon : tab.icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.secondaryText,
            ),
            const SizedBox(width: 8),
            Text(
              tab.label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
          HapticService.medium();
        }
        setState(() => _currentPage = index);
      },
      children: const [
        SubstitutionScreen(),
        WeatherPage(),
        SchedulePage(),
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

/// Tab data helper class
class _TabData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _TabData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
