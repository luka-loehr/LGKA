// Copyright Luka Löhr 2025

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/haptic_service.dart';
import '../../theme/app_theme.dart';
import '../../services/schedule_service.dart';
// import '../../services/retry_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_footer.dart';

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
  bool _wasSchedulesLoading = true;
  bool _didShowInitialSpinner = false; // true once initial loading spinner was shown

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
      AppLogger.schedule('Schedule page initialized');
      await ref.read(scheduleProvider.notifier).loadSchedules();
      AppLogger.debug('Schedule loading complete', module: 'SchedulePage');
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
    
    if (!mounted) return;
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
        if (mounted) {
          setState(() {});
        }
        return {'schedule': schedule, 'isAvailable': isAvailable};
      });
      
      // Wait for all availability checks to complete
      final results = await Future.wait(availabilityFutures);
      
      if (!mounted) return;
      
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
        AppLogger.schedule('Second half-year available: ${results.length} schedules checked');
        _availableFirstHalbjahr.clear(); // Only show second half-year
      }

      AppLogger.success('Schedule availability check complete: ${results.where((r) => r['isAvailable'] as bool).length} available', module: 'SchedulePage');
      setState(() {});
      
      // Preload PDFs for available schedules in the background
      _preloadSchedulePDFs();
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAvailability = false;
          _lastAvailabilityCheck = DateTime.now();
        });
      }
    }
  }
  
  /// Preload PDFs for available schedules in the background
  void _preloadSchedulePDFs() {
    final allAvailableSchedules = [
      ..._availableFirstHalbjahr,
      ..._availableSecondHalbjahr,
    ];
    
    if (allAvailableSchedules.isEmpty) return;
    
    // Preload all available schedules in the background
    for (final schedule in allAvailableSchedules) {
      // Download schedule PDF in background (downloadSchedule handles caching)
      // This will download if not cached, or return cached file if it exists
      unawaited(
        ref.read(scheduleProvider.notifier).downloadSchedule(schedule).catchError((e) {
          // Silently handle errors - preloading shouldn't show errors to user
          AppLogger.debug('Failed to preload schedule PDF: ${schedule.title}', module: 'SchedulePage');
          return null; // Return null to satisfy Future<File?> return type
        })
      );
    }
    
    AppLogger.debug('Started preloading ${allAvailableSchedules.length} schedule PDF(s)', module: 'SchedulePage');
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleProvider);
    // Track if initial spinner ever appeared in this page lifetime
    if (scheduleState.isLoading) {
      _didShowInitialSpinner = true;
    }
    _wasSchedulesLoading = scheduleState.isLoading;

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
      final hasAnyButtons = _availableFirstHalbjahr.isNotEmpty || _availableSecondHalbjahr.isNotEmpty;
      if (hasAnyButtons && !_hasShownButtons) {
        _hasShownButtons = true;
        _fadeController.forward();
        AppLogger.schedule('Schedule buttons shown: ${_availableFirstHalbjahr.length + _availableSecondHalbjahr.length} available');
      }
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildScheduleList(state),
    );
  }

  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.serverConnectionHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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
      onTap: () {
        HapticService.medium();
        _openSchedule(schedule);
      },
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
    final l10n = AppLocalizations.of(context)!;
    if (gradeLevel == 'Klassen 5-10') {
      return l10n.grades5to10;
    }
    if (gradeLevel == 'J11/J12') {
      return l10n.j11j12;
    }
    return gradeLevel;
  }

  String _localizeHalbjahr(BuildContext context, String halbjahr) {
    final l10n = AppLocalizations.of(context)!;
    if (halbjahr == '1. Halbjahr') {
      return l10n.firstSemester;
    }
    if (halbjahr == '2. Halbjahr') {
      return l10n.secondSemester;
    }
    return halbjahr;
  }

  Widget _buildFooter(BuildContext context) {
    return AppFooter(bottomPadding: _getFooterPadding(context));
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

  /// Get the cached schedule file path (same logic as ScheduleService)
  Future<File?> _getCachedScheduleFile(ScheduleItem schedule) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final sanitizedGradeLevel = schedule.gradeLevel.replaceAll('/', '_');
      final sanitizedHalbjahr = schedule.halbjahr.replaceAll('.', '_');
      final filename = '${sanitizedGradeLevel}_$sanitizedHalbjahr.pdf';
      return File('${cacheDir.path}/$filename');
    } catch (e) {
      return null;
    }
  }

  void _openSchedule(ScheduleItem schedule) async {
    // Check if PDF is already downloaded (from preloading)
    final cachedFile = await _getCachedScheduleFile(schedule);
    if (cachedFile != null && await cachedFile.exists()) {
      // PDF is already cached, open immediately
      if (mounted) {
        context.push('/pdf-viewer', extra: {
          'file': cachedFile,
          'dayName': '${_localizeGradeLevel(context, schedule.gradeLevel)} - ${_localizeHalbjahr(context, schedule.halbjahr)}',
        });
      }
      return;
    }
    
    // Check mounted before using context after async operation
    if (!mounted) return;
    
    // Show loading dialog if PDF needs to be downloaded
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
              content: Text('${_localizeHalbjahr(context, schedule.halbjahr)} ${AppLocalizations.of(context)!.scheduleNotAvailable}'),
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
                content: Text(AppLocalizations.of(context)!.errorLoadingGeneric),
                backgroundColor: Colors.red,
              ),
            );
      }
    });
  }
} 