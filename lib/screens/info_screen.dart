// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../navigation/app_router.dart';
import '../providers/haptic_service.dart';

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
      'title': 'Vertretungsplan',
      'description': 'Aktueller Vertretungsplan für heute/morgen',
    },
    {
      'icon': Icons.schedule,
      'title': 'Stundenplan',
      'description': 'Stundenplan fürs 1./2. Halbjahr',
    },
    {
      'icon': Icons.cloud,
      'title': 'Wetterdaten',
      'description': 'Zugriff auf die eigene Wetterstation der Schule',
    },
    {
      'icon': Icons.sick,
      'title': 'Krankmeldung',
      'description': 'Krankmeldung direkt über die App einreichen',
    },
  ];

  final List<Map<String, dynamic>> _accentColors = [
    {'name': 'blue', 'color': AppColors.getAccentColor('blue')},
    {'name': 'lavender', 'color': AppColors.getAccentColor('lavender')},
    {'name': 'mint', 'color': AppColors.getAccentColor('mint')},
    {'name': 'peach', 'color': AppColors.getAccentColor('peach')},
    {'name': 'rose', 'color': AppColors.getAccentColor('rose')},
  ];

  @override
  void initState() {
    super.initState();

    // Load current accent color
    final prefsManager = ref.read(preferencesManagerProvider);
    _selectedColor = prefsManager.accentColor;

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

    // Save color preference
    final prefsManager = ref.read(preferencesManagerProvider);
    await prefsManager.setAccentColor(colorName);
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
                        'Was kannst du mit der App machen?',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Features List
                      Expanded(
                        child: ListView(
                          children: [
                            ..._features.map((feature) => _buildFeatureCard(feature)),
                            const SizedBox(height: 20),

                            // Accent Color Section
                            Text(
                              'Deine Akzentfarbe',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Wähle deine Lieblingsfarbe aus. Diese wird überall in der App verwendet.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Color Selection
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _accentColors.map((colorData) =>
                                _buildColorOption(colorData)
                              ).toList(),
                            ),

                            const SizedBox(height: 32),
                          ],
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
                                    'Los geht\'s!',
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
    // Calculate responsive card height based on screen size - medium cards
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.10; // 10% of screen height (medium size)
    final minHeight = 70.0; // Medium size
    final maxHeight = 100.0; // Medium size
    final finalHeight = cardHeight.clamp(minHeight, maxHeight);
    
    return Card(
      color: AppColors.appSurface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 7), // Medium spacing
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14), // Medium border radius
      ),
      child: SizedBox(
        height: finalHeight,
        child: Padding(
          padding: const EdgeInsets.all(14), // Medium padding
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, // Medium size
                height: 44, // Medium size
                decoration: BoxDecoration(
                  color: AppColors.getAccentColor(_selectedColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11), // Medium border radius
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppColors.getAccentColor(_selectedColor),
                  size: 22, // Medium icon size
                ),
              ),
              const SizedBox(width: 14), // Medium spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith( // Back to titleMedium
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3), // Medium spacing
                    Text(
                      feature['description'] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith( // Back to bodyMedium
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(Map<String, dynamic> colorData) {
    final isSelected = _selectedColor == colorData['name'];
    final color = colorData['color'] as Color;

    // Calculate responsive box size to fit 5 colors in one line
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32; // Subtract padding (16px on each side)
    final spacingWidth = 4 * 12; // 4 gaps between 5 boxes × 12px spacing
    final boxSize = (availableWidth - spacingWidth) / 5;

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
