// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/color_provider.dart';
import '../navigation/app_router.dart';
import '../providers/haptic_service.dart';
import '../l10n/app_localizations.dart';

class WhatYouCanDoScreen extends ConsumerStatefulWidget {
  const WhatYouCanDoScreen({super.key});

  @override
  ConsumerState<WhatYouCanDoScreen> createState() => _WhatYouCanDoScreenState();
}

class _WhatYouCanDoScreenState extends ConsumerState<WhatYouCanDoScreen>
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
      'icon': Icons.newspaper_outlined,
      'titleKey': 'featureNewsTitle',
      'descKey': 'featureNewsDesc',
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
      case 'featureNewsTitle':
        return l.featureNewsTitle;
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
      case 'featureNewsDesc':
        return l.featureNewsDesc;
      case 'featureSickDesc':
        return l.featureSickDesc;
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();

    // Load current accent color from color provider for feature icons
    _selectedColor = ref.read(colorProvider);

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

  Future<void> _navigateToAccentColor() async {
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

    // Release button animation
    _buttonController.reverse();

    // Navigate to accent color screen
    if (mounted) {
      context.go(AppRouter.accentColor);
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
                              onPressed: _isNavigating ? null : _navigateToAccentColor,
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
                                    AppLocalizations.of(context)!.continueLabel,
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
}

