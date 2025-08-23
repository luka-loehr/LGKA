// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import '../providers/haptic_service.dart';

/// Schedule page with different grade level options
class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage>
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
    // Start animation when buttons should be visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startButtonAnimation();
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          
          // Schedule options with proper fade-in animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildScheduleOptions(),
          ),
          
          const Spacer(),
          
          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildScheduleOptions() {
    return Column(
      children: [
        _ScheduleOptionButton(
          label: 'Klassenstufe 5-7',
          onTap: () => _openSchedule('klassenstufe_5_7'),
        ),
        const SizedBox(height: 16),
        _ScheduleOptionButton(
          label: 'Klassenstufe 8-10',
          onTap: () => _openSchedule('klassenstufe_8_10'),
        ),
        const SizedBox(height: 16),
        _ScheduleOptionButton(
          label: 'Oberstufe',
          onTap: () => _openSchedule('oberstufe'),
        ),
      ],
    );
  }

  void _openSchedule(String scheduleType) {
    // TODO: Implement schedule opening logic
    // This could open a PDF viewer or navigate to a schedule screen
    HapticService.subtle();
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

/// Schedule option button
class _ScheduleOptionButton extends ConsumerStatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _ScheduleOptionButton({
    required this.label,
    required this.onTap,
  });

  @override
  ConsumerState<_ScheduleOptionButton> createState() => _ScheduleOptionButtonState();
}

class _ScheduleOptionButtonState extends ConsumerState<_ScheduleOptionButton>
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
    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: () => _onTapCancel(),
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: _isPressed 
                    ? AppColors.appSurface.withValues(alpha: 0.8)
                    : AppColors.appSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isPressed ? [] : [
                  BoxShadow(
                    color: AppColors.appBlueAccent.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.calendarIconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.appOnSurface,
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
        },
      ),
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
    HapticService.subtle();
    widget.onTap();
  }
} 