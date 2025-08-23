// Copyright Luka Löhr 2025

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(
        title: Text(
          'Stundenpläne',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
        ),
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        actions: [
          IconButton(
            onPressed: () async {
              await HapticService.subtle();
              ref.read(scheduleProvider.notifier).refreshSchedules();
            },
            icon: const Icon(
              Icons.refresh,
              color: AppColors.secondaryText,
            ),
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: _buildBody(scheduleState),
    );
  }

  Widget _buildBody(ScheduleState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.appBlueAccent,
            ),
            SizedBox(height: 16),
            Text(
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryText,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(scheduleProvider.notifier).loadSchedules();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appBlueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            color: AppColors.secondaryText,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'Keine Stundenpläne verfügbar',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
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
    return RefreshIndicator(
      onRefresh: () => ref.read(scheduleProvider.notifier).refreshSchedules(),
      color: AppColors.appBlueAccent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.firstSemesterSchedules.isNotEmpty) ...[
            _buildSemesterSection('1. Halbjahr', state.firstSemesterSchedules),
            const SizedBox(height: 24),
          ],
          if (state.secondSemesterSchedules.isNotEmpty) ...[
            _buildSemesterSection('2. Halbjahr', state.secondSemesterSchedules),
          ],
          if (state.lastUpdated != null) ...[
            const SizedBox(height: 24),
            _buildLastUpdatedInfo(state.lastUpdated!),
          ],
        ],
      ),
    );
  }

  Widget _buildSemesterSection(String semester, List<ScheduleItem> schedules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          semester,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.appBlueAccent,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...schedules.map((schedule) => _buildScheduleCard(schedule)),
      ],
    );
  }

  Widget _buildScheduleCard(ScheduleItem schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.appSurface,
      elevation: 2,
      child: InkWell(
        onTap: () => _openSchedule(schedule),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.appBlueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: AppColors.appBlueAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.gradeLevel,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schedule.title,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
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
      ),
    );
  }

  Widget _buildLastUpdatedInfo(DateTime lastUpdated) {
    return Center(
      child: Text(
        'Zuletzt aktualisiert: ${_formatDateTime(lastUpdated)}',
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Gerade eben';
    } else if (difference.inMinutes < 60) {
      return 'Vor ${difference.inMinutes} Minuten';
    } else if (difference.inHours < 24) {
      return 'Vor ${difference.inHours} Stunden';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }
  }

  void _openSchedule(ScheduleItem schedule) {
    HapticService.subtle();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(
              color: AppColors.appBlueAccent,
            ),
            SizedBox(width: 16),
            Text('Lade Stundenplan...'),
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
            'dayName': '${schedule.gradeLevel} - ${schedule.semester}',
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