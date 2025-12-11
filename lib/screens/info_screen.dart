// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/color_provider.dart';
import '../navigation/app_router.dart';
import '../providers/haptic_service.dart';
import '../l10n/app_localizations.dart';

class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  late AnimationController _contentController;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;
  bool _isNavigating = false;
  String _selectedColor = 'blue';

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.calendar_today,
      'titleKey': 'featureSubstitutionTitle',
      'descKey': 'featureSubstitutionDesc',
    },
    {
      'icon': Icons.schedule,
      'titleKey': 'featureScheduleTitle',
      'descKey': 'featureScheduleDesc',
    },
    {
      'icon': Icons.cloud,
      'titleKey': 'featureWeatherTitle',
      'descKey': 'featureWeatherDesc',
    },
    {
      'icon': Icons.sick,
      'titleKey': 'featureSickTitle',
      'descKey': 'featureSickDesc',
    },
  ];

  String _resolveTitle(BuildContext context, String key) {
    final l = AppLocalizations.of(context)!;
    switch (key) {
      case 'featureSubstitutionTitle':
        return l.featureSubstitutionTitle;
      case 'featureScheduleTitle':
        return l.featureScheduleTitle;
      case 'featureWeatherTitle':
        return l.featureWeatherTitle;
      case 'featureSickTitle':
        return l.featureSickTitle;
      default:
        return '';
    }
  }

  String _resolveDesc(BuildContext context, String key) {
    final l = AppLocalizations.of(context)!;
    switch (key) {
      case 'featureSubstitutionDesc':
        return l.featureSubstitutionDesc;
      case 'featureScheduleDesc':
        return l.featureScheduleDesc;
      case 'featureWeatherDesc':
        return l.featureWeatherDesc;
      case 'featureSickDesc':
        return l.featureSickDesc;
      default:
        return '';
    }
  }

  final List<Map<String, dynamic>> _accentColors = [];

  @override
  void initState() {
    super.initState();

    // Load current accent color from color provider
    _selectedColor = ref.read(colorProvider);
    
    // Populate accent colors from provider
    final allColors = ColorProvider.allColors;
    _accentColors.clear();
    _accentColors.addAll(allColors.map((palette) => {
      'name': palette.name,
      'color': palette.color,
    }));

    // Button animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Content animation
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    // Start content animation
    _contentController.forward();
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectColor(String colorName) async {
    setState(() {
      _selectedColor = colorName;
    });

    await HapticService.light();

    // Save color preference using color provider
    await ref.read(colorProvider.notifier).setColor(colorName);
  }

  Future<void> _navigateToAuth() async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    // Button press animation
    await _buttonController.forward();

    // Premium haptic feedback
    await HapticService.light();

    // Small delay for the animation to feel natural
    await Future.delayed(const Duration(milliseconds: 50));

    // Mark onboarding as completed (welcome + info) and mark first launch false
    final notifier = ref.read(preferencesManagerProvider.notifier);
    await notifier.setOnboardingCompleted(true);
    await notifier.setFirstLaunch(false);

    // Release button animation
    _buttonController.reverse();

    // Navigate to auth screen
    if (mounted) {
      context.go(AppRouter.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_contentController, _buttonController]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _contentOpacity,
              child: SlideTransition(
                position: _contentSlide,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        AppLocalizations.of(context)!.infoHeader,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Features List
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._features.map((feature) => _buildFeatureCard(feature)),
                              const SizedBox(height: 24),

                              // Accent Color Section
                              Text(
                                AppLocalizations.of(context)!.yourAccentColor,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                AppLocalizations.of(context)!.chooseFavoriteColor,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.secondaryText,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Color Selection
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _accentColors.map((colorData) =>
                                  _buildColorOption(colorData)
                                ).toList(),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),

                      // Continue Button
                      ScaleTransition(
                        scale: _buttonScale,
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: AppColors.getAccentColor(_selectedColor),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isNavigating ? null : [
                                BoxShadow(
                                  color: AppColors.getAccentColor(_selectedColor).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isNavigating ? null : _navigateToAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isNavigating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)!.letsGo,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    return Card(
      color: AppColors.appSurface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.getAccentColor(_selectedColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                feature['icon'] as IconData,
                color: AppColors.getAccentColor(_selectedColor),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _resolveTitle(context, feature['titleKey'] as String),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _resolveDesc(context, feature['descKey'] as String),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(Map<String, dynamic> colorData) {
    final isSelected = _selectedColor == colorData['name'];
    final color = colorData['color'] as Color;

    // Calculate responsive box size to fit 5 colors in one line with better constraints
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32; // Subtract padding (16px on each side)
    final spacingWidth = 4 * 12; // 4 gaps between 5 boxes × 12px spacing
    final calculatedSize = (availableWidth - spacingWidth) / 5;
    final boxSize = calculatedSize.clamp(48.0, 72.0); // Better min/max constraints

    return GestureDetector(
      onTap: () => _selectColor(colorData['name'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(boxSize * 0.32), // Scale with box size
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isSelected
              ? Icon(
                  Icons.check,
                  key: const ValueKey('check'),
                  color: Colors.white,
                  size: boxSize * 0.32, // Scale with box size
                )
              : Container(
                  key: const ValueKey('dot'),
                  width: boxSize * 0.24, // Scale with box size
                  height: boxSize * 0.24, // Scale with box size
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
