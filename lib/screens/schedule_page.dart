// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/schedule_provider.dart';
import '../providers/haptic_service.dart';
import '../theme/app_theme.dart';
import '../services/schedule_service.dart';
import '../l10n/app_localizations.dart';

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
  
  // Track available schedules
  List<ScheduleItem> _availableFirstHalbjahr = [];
  List<ScheduleItem> _availableSecondHalbjahr = [];
  bool _isCheckingAvailability = false;
  DateTime? _lastAvailabilityCheck;
  static const Duration _availabilityCheckInterval = Duration(minutes: 15);

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
    
    // Load schedules when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(scheduleProvider.notifier).loadSchedules();
      // Check availability only if it hasn't been checked recently
      if (_shouldCheckAvailability()) {
        await _checkScheduleAvailability();
      }
    });
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
  
  /// Check if availability should be checked (based on timing and cached data)
  bool _shouldCheckAvailability() {
    // If we have cached results and they're recent, don't check again
    if (_lastAvailabilityCheck != null && 
        _availableFirstHalbjahr.isNotEmpty || _availableSecondHalbjahr.isNotEmpty) {
      final timeSinceLastCheck = DateTime.now().difference(_lastAvailabilityCheck!);
      if (timeSinceLastCheck < _availabilityCheckInterval) {
        return false;
      }
    }
    return true;
  }
  
  /// Check which schedules have available PDFs
  Future<void> _checkScheduleAvailability() async {
    if (_isCheckingAvailability) return;
    
    setState(() {
      _isCheckingAvailability = true;
    });
    
    try {
      final scheduleNotifier = ref.read(scheduleProvider.notifier);
      
      // Get all schedules to check
      final allSchedules = [
        ...ref.read(scheduleProvider).firstHalbjahrSchedules,
        ...ref.read(scheduleProvider).secondHalbjahrSchedules,
      ];
      
      // Check availability concurrently instead of sequentially
      final availabilityFutures = allSchedules.map((schedule) async {
        final isAvailable = await scheduleNotifier.isScheduleAvailable(schedule);
        // Update progress after each check completes
        setState(() {
        });
        return {'schedule': schedule, 'isAvailable': isAvailable};
      });
      
      // Wait for all availability checks to complete
      final results = await Future.wait(availabilityFutures);
      
      // Separate results by halbjahr
      _availableFirstHalbjahr = [];
      _availableSecondHalbjahr = [];
      
      for (final result in results) {
        if (result['isAvailable'] as bool) {
          final schedule = result['schedule'] as ScheduleItem;
          if (schedule.halbjahr == '1. Halbjahr') {
            _availableFirstHalbjahr.add(schedule);
          } else if (schedule.halbjahr == '2. Halbjahr') {
            _availableSecondHalbjahr.add(schedule);
          }
        }
      }
      
      // EXCLUSIVE LOGIC: If second half-year is available, clear first half-year
      if (_availableSecondHalbjahr.isNotEmpty) {
        _availableFirstHalbjahr.clear(); // Only show second half-year
      }
      
      setState(() {});
    } finally {
      setState(() {
        _isCheckingAvailability = false;
        _lastAvailabilityCheck = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleProvider);

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(scheduleState),
      ),
    );
  }

  Widget _buildBody(ScheduleState state) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.checkingAvailability,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (state.hasError) {
      return Center(
        child: _buildErrorState(state.error!),
      );
    }

    if (!state.hasSchedules) {
      return Center(
        child: _buildEmptyState(),
      );
    }

    // Show availability checking state if schedules are loaded but availability is still being checked
    if (_isCheckingAvailability) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loadingSchedules,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Start animation when buttons should be visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startButtonAnimation();
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildScheduleList(state),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 64,
            color: AppColors.secondaryText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.serverConnectionFailed,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(scheduleProvider.notifier).refreshSchedules();
              await _checkScheduleAvailability();
            },
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.tryAgain),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        children: [
          const Icon(
            Icons.schedule,
            color: AppColors.secondaryText,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noSchedulesAvailable,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.tryAgainLater,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(ScheduleState state) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            children: [
              // Build all available schedules with consistent spacing
              if (_availableFirstHalbjahr.isNotEmpty || _availableSecondHalbjahr.isNotEmpty) ...[
                // Get all available schedules (either first or second half-year)
                ...(_availableFirstHalbjahr.isNotEmpty ? _availableFirstHalbjahr : _availableSecondHalbjahr)
                    .where((schedule) => schedule.gradeLevel == 'Klassen 5-10')
                    .map((schedule) => _buildScheduleCard(schedule)),
                const SizedBox(height: 16), // Consistent spacing between grade levels
                ...(_availableFirstHalbjahr.isNotEmpty ? _availableFirstHalbjahr : _availableSecondHalbjahr)
                    .where((schedule) => schedule.gradeLevel == 'J11/J12')
                    .map((schedule) => _buildScheduleCard(schedule)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildScheduleCard(ScheduleItem schedule) {
    return GestureDetector(
      onTap: () => _openSchedule(schedule),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.appSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                color: Theme.of(context).colorScheme.primary,
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
              child: Row(
                children: [
                  Text(
                    _localizeGradeLevel(context, schedule.gradeLevel),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _localizeHalbjahr(context, schedule.halbjahr),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.secondaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _localizeGradeLevel(BuildContext context, String gradeLevel) {
    if (gradeLevel == 'Klassen 5-10') {
      return 'Grades 5-10';
    }
    return gradeLevel; // J11/J12 stays the same
  }

  String _localizeHalbjahr(BuildContext context, String halbjahr) {
    if (halbjahr == '1. Halbjahr') {
      return '1st semester';
    }
    if (halbjahr == '2. Halbjahr') {
      return '2nd semester';
    }
    return halbjahr;
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
                '© ${DateTime.now().year} ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText.withValues(alpha: 0.5),
                ),
              ),
              Text(
                'Luka Löhr',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
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

  void _openSchedule(ScheduleItem schedule) {
    HapticService.subtle();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Text(AppLocalizations.of(context)!.loadingSchedule),
          ],
        ),
      ),
    );

    // Download schedule in background
    ref.read(scheduleProvider.notifier).downloadSchedule(schedule).then((file) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (file != null) {
          // Navigate to PDF viewer
          context.push('/pdf-viewer', extra: {
            'file': file,
            'dayName': '${_localizeGradeLevel(context, schedule.gradeLevel)} - ${_localizeHalbjahr(context, schedule.halbjahr)}',
          });
        } else {
          // PDF is not available yet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${schedule.halbjahr} ist noch nicht verfügbar'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }).catchError((e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorLoadingGeneric}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
} 