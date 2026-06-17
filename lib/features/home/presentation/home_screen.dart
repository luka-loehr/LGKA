// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_theme.dart';
import '../../substitution/application/substitution_provider.dart';
import '../../substitution/domain/substitution_models.dart';
import '../../schedule/application/schedule_provider.dart';
import '../../schedule/domain/schedule_models.dart';
import '../../settings/presentation/settings_modal.dart';
import '../../../../services/haptic_service.dart';
import '../../../../navigation/app_router.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/app_info.dart';
import '../../../../widgets/constrained_modal_bottom_sheet.dart';
import '../../../../providers/app_providers.dart';
import '../../../../l10n/app_localizations.dart';
import 'widgets/home_events_section.dart';
import 'widgets/home_weather_section.dart';
import 'widgets/skeleton_card.dart';
import 'widgets/tappable_card.dart';
import '../../events/application/events_provider.dart';
import '../../weather/application/weather_provider.dart';
import '../../../../providers/preferences_provider.dart';

/// German → English weekday translation map (used for locale-aware display)
const Map<String, String> _kDeToEn = {
  'Montag': 'Monday',
  'Dienstag': 'Tuesday',
  'Mittwoch': 'Wednesday',
  'Donnerstag': 'Thursday',
  'Freitag': 'Friday',
  'Samstag': 'Saturday',
  'Sonntag': 'Sunday',
};

/// Main home screen — scrollable dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isRefreshing = false;
  ProviderSubscription<ScheduleState>? _scheduleListener;

  @override
  void initState() {
    super.initState();
    _scheduleListener = ref.listenManual<ScheduleState>(scheduleProvider, (
      prev,
      next,
    ) {
      if (prev?.isIndexBuilt == false && next.isIndexBuilt == true) {
        if (next.availableFirstHalbjahr.isEmpty &&
            next.availableSecondHalbjahr.isEmpty) {
          ref.read(scheduleProvider.notifier).checkAvailability();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Substitutions are preloaded at app level; only recover if startup left us empty.
      final substitutionState = ref.read(substitutionProvider);
      if (!substitutionState.isInitialized ||
          (substitutionState.hasAnyError && !substitutionState.hasAnyData)) {
        await ref.read(substitutionProvider.notifier).initialize();
      }

      // 2. Load schedule list if not already loaded
      final scheduleState = ref.read(scheduleProvider);
      if (!scheduleState.hasSchedules) {
        await ref.read(scheduleProvider.notifier).loadSchedules();
      }

      // 3. Check or restore availability via provider
      final notifier = ref.read(scheduleProvider.notifier);
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
    _scheduleListener?.close();
    super.dispose();
  }



  String _localizeHalf(AppLocalizations l, String h) => h == '1. Halbjahr'
      ? l.firstSemester
      : h == '2. Halbjahr'
      ? l.secondSemester
      : h;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(substitutionProvider);
    final isSubLoading = subState.isLoading || !subState.isInitialized;

    return Scaffold(
      backgroundColor: context.appBgColor,
      appBar: _buildAppBar(),
      body: _buildBody(subState, isSubLoading, _isRefreshing),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.appBgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        AppLocalizations.of(context)!.appTitle,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: context.appPrimaryText,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            HapticService.light();
            context.push(AppRouter.news);
          },
          tooltip: AppLocalizations.of(context)!.news,
          icon: Icon(Icons.newspaper_outlined, color: context.appSecondaryText),
        ),
        IconButton(
          onPressed: () {
            HapticService.light();
            _navigateToKrankmeldung();
          },
          tooltip: AppLocalizations.of(context)!.krankmeldung,
          icon: Icon(
            Icons.medical_services_outlined,
            color: context.appSecondaryText,
          ),
        ),
        IconButton(
          onPressed: () {
            HapticService.light();
            showConstrainedModalBottomSheet(
              context: context,
              child: const SettingsModal(),
            );
          },
          tooltip: AppLocalizations.of(context)!.settings,
          icon: Icon(Icons.settings_outlined, color: context.appSecondaryText),
        ),
      ],
    );
  }

  void _navigateToKrankmeldung() {
    final prefs = ref.read(preferencesManagerProvider);
    if (prefs.krankmeldungInfoShown) {
      context.push(
        AppRouter.webview,
        extra: {
          'url': 'https://drkrankmeldung.lgka-online.de',
          'title': AppLocalizations.of(context)!.krankmeldung,
          'headers': {'User-Agent': AppInfo.userAgent},
          'fromKrankmeldungInfo': false,
        },
      );
    } else {
      context.push(AppRouter.krankmeldungInfo);
    }
  }

  Future<void> _onRefresh() async {
    HapticService.medium();
    setState(() => _isRefreshing = true);
    try {
      await Future.wait([
        ref.read(substitutionProvider.notifier).refresh(),
        ref
            .read(scheduleProvider.notifier)
            .refreshSchedules()
            .then((_) => ref.read(scheduleProvider.notifier).checkAvailability()),
        ref.read(eventsProvider.notifier).refresh(),
        ref.read(weatherDataProvider.notifier).refreshWeatherData(),
      ]);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Widget _buildBody(
    SubstitutionProviderState subState,
    bool isSubLoading,
    bool isRefreshing,
  ) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                const HomeWeatherSection(),
                const SizedBox(height: 28),
                _buildSectionHeader(
                  AppLocalizations.of(context)!.substitutionPlan,
                ),
                const SizedBox(height: 12),
                _buildSubstitution(subState, isSubLoading || isRefreshing),
                const SizedBox(height: 28),
                _buildSectionHeader(AppLocalizations.of(context)!.schedule),
                const SizedBox(height: 12),
                _buildScheduleSection(isRefreshing: isRefreshing),
                const SizedBox(height: 28),
                _buildSectionHeader(AppLocalizations.of(context)!.termine),
                const SizedBox(height: 12),
                HomeEventsSection(isRefreshing: isRefreshing),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Crossfades between states identified by [key]. Pure opacity — no scale.
  Widget _fadeSwitch(String key, Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: context.appPrimaryText,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ── Substitution ──────────────────────────────────────────────────────────

  Widget _buildSubstitution(SubstitutionProviderState state, bool isLoading) {
    final Widget child;
    final String key;

    if (isLoading) {
      key = 'sub-loading';
      child = const Column(
        children: [
          SkeletonCard(),
          SizedBox(height: 12),
          SkeletonCard(),
        ],
      );
    } else if (state.hasAnyError && !state.hasAnyData) {
      key = 'sub-error';
      child = _buildSubError();
    } else {
      key = 'sub-content';
      child = Column(
        children: [
          _buildSubCard(state.todayState, state, true),
          const SizedBox(height: 12),
          _buildSubCard(state.tomorrowState, state, false),
        ],
      );
    }

    return _fadeSwitch(key, child);
  }

  Widget _buildSubError() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: context.appSecondaryText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.serverConnectionFailed,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appPrimaryText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.serverConnectionHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.appSecondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              HapticService.light();
              ref.read(substitutionProvider.notifier).retryAll();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(AppLocalizations.of(context)!.tryAgain),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCard(
    SubstitutionState pdfState,
    SubstitutionProviderState state,
    bool isToday,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDisabled = !pdfState.canDisplay;
    final hasError = pdfState.error != null;
    final isLoading = pdfState.isLoading;

    String weekday = pdfState.weekday ?? '';
    final date = pdfState.date ?? '';
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'en' && weekday.isNotEmpty) {
      weekday = _kDeToEn[weekday] ?? weekday;
    }
    final isWeekend = weekday == 'weekend' || weekday.isEmpty;
    final l10n = AppLocalizations.of(context)!;
    final dayDisplay = isWeekend
        ? l10n.noInfoYet
        : hasError
        ? l10n.errorLoading
        : weekday;

    final row = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDisabled
                ? primary.withValues(alpha: 0.08)
                : primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      primary.withValues(alpha: isDisabled ? 0.4 : 1.0),
                    ),
                  ),
                )
              : Icon(
                  hasError ? Icons.refresh : Icons.calendar_today_outlined,
                  color: isDisabled ? primary.withValues(alpha: 0.35) : primary,
                  size: 20,
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayDisplay,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDisabled
                      ? context.appPrimaryText.withValues(alpha: 0.35)
                      : context.appPrimaryText,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              if (date.isNotEmpty && !isDisabled && !hasError) ...[
                const SizedBox(height: 2),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appSecondaryText,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!isDisabled && !hasError)
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: context.appSecondaryText.withValues(alpha: 0.5),
          ),
        if (hasError)
          Icon(Icons.refresh, size: 18, color: primary.withValues(alpha: 0.7)),
      ],
    );

    if (isDisabled) {
      return Container(
        height: kHomeCardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: context.appSurfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: row,
      );
    }

    return TappableCard(
      onTap: () {
        if (hasError) {
          HapticService.medium();
          ref.read(substitutionProvider.notifier).retryPdf(isToday);
        } else {
          HapticService.medium();
          _openPdf(state, isToday);
        }
      },
      child: row,
    );
  }

  void _openPdf(SubstitutionProviderState state, bool isToday) {
    final notifier = ref.read(substitutionProvider.notifier);
    if (!notifier.canOpenPdf(isToday)) return;
    final pdfFile = notifier.getPdfFile(isToday);
    final pdfState = isToday ? state.todayState : state.tomorrowState;
    String weekday =
        pdfState.weekday ??
        (isToday
            ? AppLocalizations.of(context)!.today
            : AppLocalizations.of(context)!.tomorrow);
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'en') {
      weekday = _kDeToEn[weekday] ?? weekday;
    }
    AppLogger.pdf('Opening PDF: $weekday (${isToday ? 'today' : 'tomorrow'})');
    if (pdfFile != null) {
      context.push(
        AppRouter.pdfViewer,
        extra: {'file': pdfFile, 'dayName': weekday},
      );
    }
  }

  // ── Schedule section ──────────────────────────────────────────────────────

  Widget _buildScheduleSection({bool isRefreshing = false}) {
    final scheduleState = ref.watch(scheduleProvider);

    if (isRefreshing ||
        scheduleState.isLoading ||
        scheduleState.isCheckingAvailability ||
        !scheduleState.isIndexBuilt) {
      return _fadeSwitch('sched-loading', const SkeletonCard());
    }

    if (scheduleState.hasError) {
      return _fadeSwitch('sched-error', _buildScheduleError(scheduleState));
    }

    if (!scheduleState.hasSchedules) {
      return _fadeSwitch('sched-empty', _buildScheduleEmpty());
    }

    if (scheduleState.availableFirstHalbjahr.isEmpty &&
        scheduleState.availableSecondHalbjahr.isEmpty) {
      return _fadeSwitch('sched-none', const SizedBox.shrink());
    }

    final activeGroup = scheduleState.availableSecondHalbjahr.isNotEmpty
        ? scheduleState.availableSecondHalbjahr
        : scheduleState.availableFirstHalbjahr;

    final l10n = AppLocalizations.of(context)!;
    final selectedClass = ref
        .watch(preferencesManagerProvider)
        .selectedScheduleClass;

    return _fadeSwitch(
      'sched-content-${selectedClass ?? 'none'}',
      _buildInlineScheduleCard(activeGroup, selectedClass, l10n),
    );
  }

  Widget _buildInlineScheduleCard(
    List<ScheduleItem> group,
    String? selectedClass,
    AppLocalizations l10n,
  ) {
    final primary = Theme.of(context).colorScheme.primary;

    if (selectedClass == null) {
      return TappableCard(
        onTap: () {
          HapticService.light();
          context.push(AppRouter.schedule);
        },
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.school_outlined, color: primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.scheduleNoClassTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: context.appPrimaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.scheduleNoClassSub,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: context.appSecondaryText.withValues(alpha: 0.5),
            ),
          ],
        ),
      );
    }

    final halbjahr = group.isNotEmpty ? group.first.halbjahr : '';
    final half = _localizeHalf(l10n, halbjahr);
    final grade = _formatClassName(selectedClass);

    return TappableCard(
      onTap: () {
        HapticService.medium();
        context.push(AppRouter.schedule);
        AppLogger.navigation('Opened schedule viewer: $grade');
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.table_chart_outlined, color: primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: context.appPrimaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  half,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appSecondaryText,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: context.appSecondaryText.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  String _formatClassName(String className) {
    final l = AppLocalizations.of(context)!;
    if (className == 'j11') return l.jahrgang11;
    if (className == 'j12') return l.jahrgang12;
    return l.klasseLabel(
      '${className[0].toUpperCase()}${className.substring(1)}',
    );
  }

  Widget _buildScheduleError(ScheduleState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_outlined,
            color: context.appSecondaryText.withValues(alpha: 0.5),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.serverConnectionFailed,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.appSecondaryText),
            ),
          ),
          IconButton(
            onPressed: () async {
              HapticService.light();
              await ref.read(scheduleProvider.notifier).refreshSchedules();
              await ref.read(scheduleProvider.notifier).checkAvailability();
            },
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleEmpty() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_outlined,
            color: context.appSecondaryText.withValues(alpha: 0.4),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.noSchedulesAvailable,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.appSecondaryText),
          ),
        ],
      ),
    );
  }
}
