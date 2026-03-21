// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/schedule_provider.dart';
import '../../../../services/haptic_service.dart';
import '../../../../theme/app_theme.dart';
import '../domain/schedule_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_logger.dart';
import '../../../../widgets/app_footer.dart';
import '../../../../services/loading_spinner_tracker_service.dart';

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
  final _spinnerTracker = LoadingSpinnerTracker();

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(scheduleProvider.notifier);
      final scheduleState = ref.read(scheduleProvider);
      if (!scheduleState.hasSchedules) {
        await notifier.loadSchedules();
      }

      if (ref.read(scheduleProvider).shouldCheckAvailability) {
        await notifier.checkAvailability();
      } else if (ref.read(scheduleProvider).availableFirstHalbjahr.isEmpty &&
          ref.read(scheduleProvider).availableSecondHalbjahr.isEmpty) {
        await notifier.restoreAvailabilityFromCache();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleProvider);

    final isShowingSpinner = scheduleState.isLoading || scheduleState.isCheckingAvailability || !scheduleState.isIndexBuilt;
    final hasData = scheduleState.hasSchedules && !scheduleState.hasError && scheduleState.isIndexBuilt;

    // Track spinner visibility and trigger haptic feedback when spinner disappears
    _spinnerTracker.trackState(
      isSpinnerVisible: isShowingSpinner,
      hasData: hasData,
      hasError: scheduleState.hasError,
      mounted: mounted,
    );

    return Scaffold(
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
              style: TextStyle(
                color: context.appSecondaryText,
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

    // Show availability checking state if schedules are loaded but availability or class index is still being checked
    if (state.isCheckingAvailability || !state.isIndexBuilt) {
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
              style: TextStyle(
                color: context.appSecondaryText,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Start animation when buttons should be visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasAnyButtons = state.availableFirstHalbjahr.isNotEmpty ||
          state.availableSecondHalbjahr.isNotEmpty;
      if (hasAnyButtons && !_hasShownButtons) {
        _hasShownButtons = true;
        _fadeController.forward();
        AppLogger.schedule(
            'Schedule buttons shown: ${state.availableFirstHalbjahr.length + state.availableSecondHalbjahr.length} available');
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
              color: context.appSecondaryText.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.serverConnectionFailed,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.appPrimaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.serverConnectionHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.appSecondaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                HapticService.medium();
                await ref.read(scheduleProvider.notifier).refreshSchedules();
                await ref.read(scheduleProvider.notifier).checkAvailability();
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
          Icon(
            Icons.schedule,
            color: context.appSecondaryText,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noSchedulesAvailable,
            style: TextStyle(
              color: context.appPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.tryAgainLater,
            style: TextStyle(
              color: context.appSecondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(ScheduleState state) {
    final firstSemesterSchedules = state.availableFirstHalbjahr;
    final secondSemesterSchedules = state.availableSecondHalbjahr;
    final hasBothSemesters = firstSemesterSchedules.isNotEmpty && 
                             secondSemesterSchedules.isNotEmpty;
    
    return Column(
      children: [
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            children: [
              // First Semester (if available)
              if (firstSemesterSchedules.isNotEmpty) ...[
                ...firstSemesterSchedules
                    .where((s) => s.gradeLevel == 'Klassen 5-10')
                    .map((schedule) => _buildScheduleCard(schedule)),
                const SizedBox(height: 16),
                ...firstSemesterSchedules
                    .where((s) => s.gradeLevel == 'J11/J12')
                    .map((schedule) => _buildScheduleCard(schedule)),
              ],
              
              // Separator if both semesters exist
              if (hasBothSemesters) ...[
                const SizedBox(height: 24),
                Divider(height: 1, color: context.appSecondaryText.withValues(alpha: 0.2)),
                const SizedBox(height: 24),
              ],
              
              // Second Semester (if available)
              if (secondSemesterSchedules.isNotEmpty) ...[
                ...secondSemesterSchedules
                    .where((s) => s.gradeLevel == 'Klassen 5-10')
                    .map((schedule) => _buildScheduleCard(schedule)),
                const SizedBox(height: 16),
                ...secondSemesterSchedules
                    .where((s) => s.gradeLevel == 'J11/J12')
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
          color: context.appSurfaceColor,
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
                      color: context.appPrimaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _localizeHalbjahr(context, schedule.halbjahr),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: context.appSecondaryText,
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

  void _openSchedule(ScheduleItem schedule) async {
    final cachedFile = await ref.read(scheduleProvider.notifier).getCachedScheduleFile(schedule);
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