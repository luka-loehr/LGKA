// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_theme.dart';
import '../../../../providers/color_provider.dart';
import '../../../../providers/preferences_provider.dart';
import '../../../../navigation/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/haptic_service.dart';

class AppearanceScreen extends ConsumerStatefulWidget {
  const AppearanceScreen({super.key});

  @override
  ConsumerState<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends ConsumerState<AppearanceScreen>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  late AnimationController _contentController;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

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

    _contentController.forward();
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _navigateToAuth() async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    HapticService.medium();
    await _buttonController.forward();
    await Future.delayed(const Duration(milliseconds: 50));
    _buttonController.reverse();

    if (mounted) {
      context.go(AppRouter.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(preferencesManagerProvider).themeMode;
    final selectedColor = ref.watch(colorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final l = AppLocalizations.of(context)!;
    final modes = [
      (mode: 'dark', icon: Icons.dark_mode_rounded, label: l.themeDark),
      (mode: 'system', icon: Icons.brightness_auto_rounded, label: l.themeAuto),
      (mode: 'light', icon: Icons.light_mode_rounded, label: l.themeLight),
    ];

    return Scaffold(
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
                    children: [
                      const Spacer(),

                      // Title
                      Text(
                        AppLocalizations.of(context)!.appearanceTitle,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Segmented theme picker
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: modes.map((m) {
                            final isSelected = currentMode == m.mode;
                            return GestureDetector(
                              onTap: () {
                                HapticService.light();
                                ref
                                    .read(preferencesManagerProvider.notifier)
                                    .setThemeMode(m.mode);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                                alpha: isDark ? 0.3 : 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      m.icon,
                                      size: 18,
                                      color: isSelected
                                          ? AppColors.getAccentColor(selectedColor)
                                          : context.appSecondaryText,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      m.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: isSelected
                                                ? AppColors.getAccentColor(selectedColor)
                                                : context.appSecondaryText,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const Spacer(),

                      // Los geht's button
                      ScaleTransition(
                        scale: _buttonScale,
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: AppColors.getAccentColor(selectedColor),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isNavigating
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: AppColors.getAccentColor(selectedColor)
                                            .withValues(alpha: 0.3),
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
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    )
                                  : Text(
                                      AppLocalizations.of(context)!.letsGo,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
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
}
