// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/schedule_provider.dart';
import '../providers/haptic_service.dart';
import '../theme/app_theme.dart';
import '../services/schedule_service.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  @override
  void initState() {
    super.initState();
    // Load schedules when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scheduleProvider.notifier).loadSchedules();
    });
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
            const Text(
              'Lade Stundenpläne...',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (state.hasError) {
      return _buildErrorState(state.error!);
    }

    if (!state.hasSchedules) {
      return _buildEmptyState();
    }

    return _buildScheduleList(state);
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
            'Serververbindung fehlgeschlagen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(scheduleProvider.notifier).loadSchedules();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
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
          const Text(
            'Keine Stundenpläne verfügbar',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Versuche es später erneut',
            style: TextStyle(
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
              // First group: 5-10 semesters
              if (state.firstHalbjahrSchedules.isNotEmpty) ...[
                ...state.firstHalbjahrSchedules
                    .where((schedule) => schedule.gradeLevel == 'Klassen 5-10')
                    .map((schedule) => _buildScheduleCard(schedule)),
                const SizedBox(height: 16), // Same spacing as substitution screen
              ],
              if (state.secondHalbjahrSchedules.isNotEmpty) ...[
                ...state.secondHalbjahrSchedules
                    .where((schedule) => schedule.gradeLevel == 'Klassen 5-10')
                    .map((schedule) => _buildScheduleCard(schedule)),
                const SizedBox(height: 24), // Bigger spacing between groups
              ],
              // Second group: J11/J12 semesters
              if (state.firstHalbjahrSchedules.isNotEmpty) ...[
                ...state.firstHalbjahrSchedules
                    .where((schedule) => schedule.gradeLevel == 'J11/J12')
                    .map((schedule) => _buildScheduleCard(schedule)),
                const SizedBox(height: 16), // Same spacing as substitution screen
              ],
              if (state.secondHalbjahrSchedules.isNotEmpty) ...[
                ...state.secondHalbjahrSchedules
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
                    schedule.gradeLevel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    schedule.halbjahr,
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
            const Text('Lade Stundenplan...'),
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
            'dayName': '${schedule.gradeLevel} - ${schedule.halbjahr}',
          });
        }
      }
    }).catchError((e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
} 