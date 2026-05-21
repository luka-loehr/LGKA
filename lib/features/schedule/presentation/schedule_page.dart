// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/schedule_provider.dart';
import '../application/schedule_navigation_helper.dart';
import '../../../../providers/preferences_provider.dart';
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
  bool _isPromptingForClass = false;
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

    // If data is already cached, start fully visible — no fade-in on resume.
    final cached = ref.read(scheduleProvider);
    if (cached.availableFirstHalbjahr.isNotEmpty ||
        cached.availableSecondHalbjahr.isNotEmpty) {
      _fadeController.value = 1.0;
      _hasShownButtons = true;
    }

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

    final isShowingSpinner = scheduleState.isLoading ||
        scheduleState.isCheckingAvailability ||
        !scheduleState.isIndexBuilt;
    final hasData = scheduleState.hasSchedules &&
        !scheduleState.hasError &&
        scheduleState.isIndexBuilt;

    _spinnerTracker.trackState(
      isSpinnerVisible: isShowingSpinner,
      hasData: hasData,
      hasError: scheduleState.hasError,
      mounted: mounted,
    );

    final selectedClass =
        ref.watch(preferencesManagerProvider).selectedScheduleClass;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            HapticService.light();
            context.pop();
          },
          icon: Icon(
            Icons.arrow_back,
            color: context.appSecondaryText,
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.schedule,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: context.appPrimaryText,
                fontWeight: FontWeight.bold,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          if (selectedClass != null)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: context.appSecondaryText),
              tooltip: AppLocalizations.of(context)!.setClassTitle,
              onPressed: () {
                HapticService.light();
                _showSetClassDialog();
              },
            ),
        ],
      ),
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
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.checkingAvailability,
              style: TextStyle(color: context.appSecondaryText, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (state.hasError) {
      return Center(child: _buildErrorState(state.error!));
    }

    if (!state.hasSchedules) {
      return Center(child: _buildEmptyState());
    }

    // Only block with a spinner on first load — if buttons are already visible,
    // let the re-check run silently in the background.
    final hasButtons = state.availableFirstHalbjahr.isNotEmpty ||
        state.availableSecondHalbjahr.isNotEmpty;
    if ((state.isCheckingAvailability || !state.isIndexBuilt) && !hasButtons) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loadingSchedules,
              style: TextStyle(color: context.appSecondaryText, fontSize: 16),
            ),
          ],
        ),
      );
    }

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
            Icon(Icons.schedule_outlined,
                size: 64,
                color: context.appSecondaryText.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.serverConnectionFailed,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: context.appPrimaryText),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.serverConnectionHint,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.appSecondaryText),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
          Icon(Icons.schedule, color: context.appSecondaryText, size: 64),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noSchedulesAvailable,
            style: TextStyle(
                color: context.appPrimaryText,
                fontSize: 18,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.tryAgainLater,
            style: TextStyle(color: context.appSecondaryText, fontSize: 14),
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

    // Determine if user has a class selected
    final selectedClass =
        ref.watch(preferencesManagerProvider).selectedScheduleClass;

    if (selectedClass == null && !_isPromptingForClass) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isPromptingForClass) return;
        _showSetClassDialog();
      });
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        Expanded(
          child: selectedClass == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                  children: [
                    // First Semester
                    if (firstSemesterSchedules.isNotEmpty) ...[
                      _buildHalbjahrCard(
                        schedules: firstSemesterSchedules,
                        selectedClass: selectedClass,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (hasBothSemesters) ...[
                      const SizedBox(height: 8),
                      Divider(
                          height: 1,
                          color: context.appSecondaryText.withValues(alpha: 0.2)),
                      const SizedBox(height: 24),
                    ],

                    // Second Semester
                    if (secondSemesterSchedules.isNotEmpty) ...[
                      _buildHalbjahrCard(
                        schedules: secondSemesterSchedules,
                        selectedClass: selectedClass,
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 20),
        AppFooter(bottomPadding: _getFooterPadding(context)),
      ],
    );
  }

  void _showSetClassDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    
    final currentClass = ref.read(preferencesManagerProvider).selectedScheduleClass;
    if (currentClass != null) {
      controller.text = currentClass.toUpperCase();
    }
    
    _isPromptingForClass = true;

    showDialog<void>(
      context: context,
      barrierDismissible: currentClass != null,
      builder: (ctx) {
        return AlertDialog(
          title: Text(currentClass == null ? l10n.scheduleNoClassTitle : l10n.setClassTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: Icon(
                Icons.school_outlined,
                color: context.appSecondaryText,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '',
            ),
            onSubmitted: (_) => _submitSelectedClass(ctx, controller),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (currentClass == null && mounted) {
                  context.pop();
                }
              },
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () => _submitSelectedClass(ctx, controller),
              child: Text(l10n.setClassButton),
            ),
          ],
        );
      },
    ).then((_) {
      controller.dispose();
      _isPromptingForClass = false;
    });
  }

  void _submitSelectedClass(BuildContext dialogContext, TextEditingController controller) {
    final cls = controller.text.trim().toLowerCase();
    if (cls.isEmpty) {
      return;
    }

    Navigator.of(dialogContext).pop();
    ref.read(preferencesManagerProvider.notifier).setSelectedScheduleClass(cls);
  }

  /// ONE card per halbjahr group. Title is the user's class if selected.
  Widget _buildHalbjahrCard({
    required List<ScheduleItem> schedules,
    required String? selectedClass,
  }) {
    final halbjahr = schedules.isNotEmpty ? schedules.first.halbjahr : '';
    final halfLabel = _localizeHalbjahr(context, halbjahr);

    final title = selectedClass != null
        ? _formatClassName(selectedClass)
        : _localizeGradeLevel(context, schedules.first.gradeLevel);

    return GestureDetector(
      onTap: () {
        HapticService.medium();
        context.openScheduleForClass(ref, schedules, selectedClass);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: context.appSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
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
              child: const Icon(Icons.table_chart_outlined,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: context.appPrimaryText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    halfLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appSecondaryText,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: context.appSecondaryText, size: 16),
          ],
        ),
      ),
    );
  }

  String _formatClassName(String className) {
    final l = AppLocalizations.of(context)!;
    if (className == 'j11') return l.jahrgang11;
    if (className == 'j12') return l.jahrgang12;
    return l.klasseLabel('${className[0].toUpperCase()}${className.substring(1)}');
  }

  String _localizeGradeLevel(BuildContext context, String gradeLevel) {
    final l10n = AppLocalizations.of(context)!;
    if (gradeLevel == 'Klassen 5-10') return l10n.grades5to10;
    if (gradeLevel == 'J11/J12') return l10n.j11j12;
    return gradeLevel;
  }

  String _localizeHalbjahr(BuildContext context, String halbjahr) {
    final l10n = AppLocalizations.of(context)!;
    if (halbjahr == '1. Halbjahr') return l10n.firstSemester;
    if (halbjahr == '2. Halbjahr') return l10n.secondSemester;
    return halbjahr;
  }

  double _getFooterPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final gestureInsets = mediaQuery.systemGestureInsets.bottom;
    final viewPadding = mediaQuery.viewPadding.bottom;

    if (gestureInsets >= 45) return 34.0;
    if (gestureInsets <= 25) return 8.0;
    return viewPadding > 50 ? 34.0 : 8.0;
  }

}
