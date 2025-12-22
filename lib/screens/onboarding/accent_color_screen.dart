// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/color_provider.dart';
import '../../navigation/app_router.dart';
import '../../providers/haptic_service.dart';
import '../../l10n/app_localizations.dart';

class AccentColorScreen extends ConsumerStatefulWidget {
  const AccentColorScreen({super.key});

  @override
  ConsumerState<AccentColorScreen> createState() => _AccentColorScreenState();
}

class _AccentColorScreenState extends ConsumerState<AccentColorScreen>
    with TickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;
  late AnimationController _contentController;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;
  bool _isNavigating = false;
  String _selectedColor = 'blue';

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

    // Release button animation
    _buttonController.reverse();

    // Navigate to auth screen
    // Note: Onboarding will be marked as completed only after successful authentication
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
                    children: [
                      const Spacer(),
                      
                      // Header
                      Text(
                        AppLocalizations.of(context)!.accentColorTitle,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        AppLocalizations.of(context)!.accentColorDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Color Selection
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: _accentColors.map((colorData) =>
                          _buildColorOption(colorData)
                        ).toList(),
                      ),

                      const Spacer(),

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

