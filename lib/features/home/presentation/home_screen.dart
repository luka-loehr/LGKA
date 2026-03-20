// Copyright Luka Löhr 2026

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
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
import '../../../../widgets/app_footer.dart';
import '../../../../providers/app_providers.dart';
import '../../../../l10n/app_localizations.dart';

const double _kCardHeight = 80.0;

/// Main home screen — scrollable dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  // Schedule availability — mirrors SchedulePage logic exactly
  List<ScheduleItem> _availableFirstHalbjahr = [];
  List<ScheduleItem> _availableSecondHalbjahr = [];
  bool _isCheckingAvailability = false;
  DateTime? _lastAvailabilityCheck;
  static const _availabilityCheckInterval = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Boot substitution loading
      await ref.read(substitutionProvider.notifier).initialize();

      // 2. Load schedule list (matches SchedulePage initState exactly)
      final scheduleState = ref.read(scheduleProvider);
      if (!scheduleState.hasSchedules) {
        await ref.read(scheduleProvider.notifier).loadSchedules();
      }

      // 3. Check or restore availability (mirrors SchedulePage exactly)
      if (_shouldCheckAvailability()) {
        await _checkScheduleAvailability();
      } else {
        // Already checked recently — restore from cached PDFs if lists are empty
        final allSchedules = [
          ...scheduleState.firstHalbjahrSchedules,
          ...scheduleState.secondHalbjahrSchedules,
        ];
        if (allSchedules.isNotEmpty &&
            _availableFirstHalbjahr.isEmpty &&
            _availableSecondHalbjahr.isEmpty) {
          await _restoreAvailabilityFromCache(allSchedules);
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Schedule availability (exact copy of SchedulePage logic) ──────────────

  /// Returns true if we should re-run the availability check.
  /// Mirrors the original SchedulePage._shouldCheckAvailability() including
  /// its operator-precedence quirk.
  bool _shouldCheckAvailability() {
    // ignore: dead_code — intentional: matches original precedence bug for safety
    if (_lastAvailabilityCheck != null &&
            _availableFirstHalbjahr.isNotEmpty ||
        _availableSecondHalbjahr.isNotEmpty) {
      final elapsed =
          DateTime.now().difference(_lastAvailabilityCheck ?? DateTime.now());
      if (elapsed < _availabilityCheckInterval) return false;
    }
    return true;
  }

  Future<void> _checkScheduleAvailability() async {
    if (_isCheckingAvailability) return;
    if (!mounted) return;
    setState(() => _isCheckingAvailability = true);

    try {
      final notifier = ref.read(scheduleProvider.notifier);
      final allSchedules = {
        ...ref.read(scheduleProvider).firstHalbjahrSchedules,
        ...ref.read(scheduleProvider).secondHalbjahrSchedules,
      }.toList();

      final results = await Future.wait(allSchedules.map((s) async {
        final ok = await notifier.isScheduleAvailable(s);
        if (mounted) setState(() {}); // progressive update (mirrors original)
        return {'schedule': s, 'ok': ok};
      }));

      if (!mounted) return;

      final first = <ScheduleItem>{};
      final second = <ScheduleItem>{};
      for (final r in results) {
        if (r['ok'] as bool) {
          final s = r['schedule'] as ScheduleItem;
          if (s.halbjahr == '1. Halbjahr') first.add(s);
          if (s.halbjahr == '2. Halbjahr') second.add(s);
        }
      }
      _availableFirstHalbjahr = first.toList();
      _availableSecondHalbjahr = second.toList();

      AppLogger.success(
        'Schedule availability: ${first.length + second.length} available',
        module: 'HomeScreen',
      );
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

  /// Restore availability by checking which schedules have locally cached PDFs.
  /// Mirrors SchedulePage._restoreAvailabilityFromCache().
  Future<void> _restoreAvailabilityFromCache(
      List<ScheduleItem> allSchedules) async {
    final unique = allSchedules.toSet().toList();
    for (final s in unique) {
      final cached = await _cachedScheduleFile(s);
      if (cached != null && await cached.exists()) {
        if (s.halbjahr == '1. Halbjahr') {
          if (!_availableFirstHalbjahr.contains(s)) {
            _availableFirstHalbjahr.add(s);
          }
        } else if (s.halbjahr == '2. Halbjahr') {
          if (!_availableSecondHalbjahr.contains(s)) {
            _availableSecondHalbjahr.add(s);
          }
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _preloadSchedulePDFs() {
    final all = [..._availableFirstHalbjahr, ..._availableSecondHalbjahr];
    for (final s in all) {
      unawaited(_cachedScheduleFile(s).then((cached) async {
        if (cached != null && await cached.exists()) return;
        try {
          await ref.read(scheduleProvider.notifier).downloadSchedule(s);
        } catch (_) {}
      }));
    }
  }

  Future<File?> _cachedScheduleFile(ScheduleItem s) async {
    try {
      final dir = await getTemporaryDirectory();
      final grade = s.gradeLevel.replaceAll('/', '_');
      final half = s.halbjahr.replaceAll('.', '_');
      return File('${dir.path}/${grade}_$half.pdf');
    } catch (_) {
      return null;
    }
  }

  void _openSchedule(ScheduleItem schedule) async {
    final l10n = AppLocalizations.of(context)!;
    final grade = _localizeGrade(l10n, schedule.gradeLevel);
    final half = _localizeHalf(l10n, schedule.halbjahr);
    final dayName = '$grade - $half';

    final cached = await _cachedScheduleFile(schedule);
    if (cached != null && await cached.exists()) {
      if (mounted) {
        context.push(AppRouter.pdfViewer,
            extra: {'file': cached, 'dayName': dayName});
      }
      return;
    }
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Text(l10n.loadingSchedule),
        ]),
      ),
    );

    ref.read(scheduleProvider.notifier).downloadSchedule(schedule).then((file) {
      if (!mounted) return;
      Navigator.of(context).pop();
      if (file != null) {
        context.push(AppRouter.pdfViewer,
            extra: {'file': file, 'dayName': dayName});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$half ${l10n.scheduleNotAvailable}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ));
      }
    }).catchError((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(AppLocalizations.of(context)!.errorLoadingGeneric),
        backgroundColor: Colors.red,
      ));
    });
  }

  String _localizeGrade(AppLocalizations l, String g) =>
      g == 'Klassen 5-10' ? l.grades5to10 : g == 'J11/J12' ? l.j11j12 : g;

  String _localizeHalf(AppLocalizations l, String h) =>
      h == '1. Halbjahr'
          ? l.firstSemester
          : h == '2. Halbjahr'
              ? l.secondSemester
              : h;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(substitutionProvider);
    final isSubLoading = subState.isLoading || !subState.isInitialized;

    // When main.dart finishes preloading the class index (which also downloads
    // the schedule PDF), re-run availability so we find the newly cached file.
    ref.listen<ScheduleState>(scheduleProvider, (prev, next) {
      if (prev?.isIndexBuilt == false && next.isIndexBuilt == true) {
        if (_availableFirstHalbjahr.isEmpty &&
            _availableSecondHalbjahr.isEmpty) {
          _checkScheduleAvailability();
        }
      }
    });

    return Scaffold(
      backgroundColor: context.appBgColor,
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildPinnedFooter(),
      body: _buildBody(subState, isSubLoading),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.appBgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        _greeting(context),
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
          icon:
              Icon(Icons.newspaper_outlined, color: context.appSecondaryText),
        ),
        IconButton(
          onPressed: () {
            HapticService.light();
            _navigateToKrankmeldung();
          },
          tooltip: AppLocalizations.of(context)!.krankmeldung,
          icon: Icon(Icons.medical_services_outlined,
              color: context.appSecondaryText),
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
          icon:
              Icon(Icons.settings_outlined, color: context.appSecondaryText),
        ),
      ],
    );
  }

  Widget _buildPinnedFooter() {
    final mq = MediaQuery.of(context);
    final gi = mq.systemGestureInsets.bottom;
    final bottomPadding = gi >= 45
        ? 34.0
        : gi <= 25
            ? 8.0
            : mq.viewPadding.bottom > 50
                ? 34.0
                : 8.0;
    return AppFooter(bottomPadding: bottomPadding);
  }

  void _navigateToKrankmeldung() {
    final prefs = ref.read(preferencesManagerProvider);
    if (prefs.krankmeldungInfoShown) {
      context.push(AppRouter.webview, extra: {
        'url': 'https://drkrankmeldung.lgka-online.de',
        'title': AppLocalizations.of(context)!.krankmeldung,
        'headers': {'User-Agent': AppInfo.userAgent},
        'fromKrankmeldungInfo': false,
      });
    } else {
      context.push(AppRouter.krankmeldungInfo);
    }
  }

  Widget _buildBody(SubstitutionProviderState subState, bool isSubLoading) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 4),
              _buildDateLine(),
              const SizedBox(height: 24),
              _buildSectionHeader(
                  AppLocalizations.of(context)!.substitutionPlan),
              const SizedBox(height: 12),
              _buildSubstitution(subState, isSubLoading),
              const SizedBox(height: 28),
              _buildSectionHeader(AppLocalizations.of(context)!.schedule),
              const SizedBox(height: 12),
              _buildScheduleSection(),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Greeting ──────────────────────────────────────────────────────────────

  String _greeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 11) return l10n.greetingMorning;
    if (hour < 18) return l10n.greetingDay;
    return l10n.greetingEvening;
  }

  Widget _buildDateLine() {
    final locale = Localizations.localeOf(context).languageCode;
    final date = DateFormat('EEEE, d. MMMM', locale == 'de' ? 'de_DE' : 'en_US')
        .format(DateTime.now());
    return Text(
      date,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.appSecondaryText,
            fontWeight: FontWeight.w500,
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
      child = Column(children: [
        _SkeletonCard(),
        const SizedBox(height: 12),
        _SkeletonCard(),
      ]);
    } else if (state.hasAnyError && !state.hasAnyData) {
      key = 'sub-error';
      child = _buildSubError();
    } else {
      key = 'sub-content';
      child = Column(children: [
        _buildSubCard(state.todayState, state, true),
        const SizedBox(height: 12),
        _buildSubCard(state.tomorrowState, state, false),
      ]);
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
      child: Column(children: [
        Icon(Icons.cloud_off_outlined,
            size: 40, color: context.appSecondaryText.withValues(alpha: 0.5)),
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
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: context.appSecondaryText),
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
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ]),
    );
  }

  Widget _buildSubCard(
      SubstitutionState pdfState, SubstitutionProviderState state, bool isToday) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDisabled = !pdfState.canDisplay;
    final hasError = pdfState.error != null;
    final isLoading = pdfState.isLoading;

    String weekday = pdfState.weekday ?? '';
    final date = pdfState.date ?? '';
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'en' && weekday.isNotEmpty) {
      const de2en = {
        'Montag': 'Monday',
        'Dienstag': 'Tuesday',
        'Mittwoch': 'Wednesday',
        'Donnerstag': 'Thursday',
        'Freitag': 'Friday',
        'Samstag': 'Saturday',
        'Sonntag': 'Sunday',
      };
      weekday = de2en[weekday] ?? weekday;
    }
    final isWeekend = weekday == 'weekend' || weekday.isEmpty;
    final l10n = AppLocalizations.of(context)!;
    final dayDisplay = isWeekend
        ? l10n.noInfoYet
        : hasError
            ? l10n.errorLoading
            : weekday;

    final row = Row(children: [
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
                      primary.withValues(alpha: isDisabled ? 0.4 : 1.0)),
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
        Icon(Icons.arrow_forward_ios,
            size: 14, color: context.appSecondaryText.withValues(alpha: 0.5)),
      if (hasError)
        Icon(Icons.refresh, size: 18, color: primary.withValues(alpha: 0.7)),
    ]);

    if (isDisabled) {
      return Container(
        height: _kCardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: context.appSurfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: row,
      );
    }

    return _TappableCard(
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
    String weekday = pdfState.weekday ??
        (isToday
            ? AppLocalizations.of(context)!.today
            : AppLocalizations.of(context)!.tomorrow);
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'en') {
      const de2en = {
        'Montag': 'Monday',
        'Dienstag': 'Tuesday',
        'Mittwoch': 'Wednesday',
        'Donnerstag': 'Thursday',
        'Freitag': 'Friday',
        'Samstag': 'Saturday',
        'Sonntag': 'Sunday',
      };
      weekday = de2en[weekday] ?? weekday;
    }
    AppLogger.pdf(
        'Opening PDF: $weekday (${isToday ? 'today' : 'tomorrow'})');
    if (pdfFile != null) {
      context.push(AppRouter.pdfViewer,
          extra: {'file': pdfFile, 'dayName': weekday});
    }
  }

  // ── Schedule section ──────────────────────────────────────────────────────

  Widget _buildScheduleSection() {
    final scheduleState = ref.watch(scheduleProvider);

    if (scheduleState.isLoading ||
        _isCheckingAvailability ||
        !scheduleState.isIndexBuilt) {
      return _fadeSwitch(
        'sched-loading',
        Column(children: [
          const _SkeletonCard(),
          const SizedBox(height: 12),
          const _SkeletonCard(),
        ]),
      );
    }

    if (scheduleState.hasError) {
      return _fadeSwitch('sched-error', _buildScheduleError(scheduleState));
    }

    if (!scheduleState.hasSchedules) {
      return _fadeSwitch('sched-empty', _buildScheduleEmpty());
    }

    if (_availableFirstHalbjahr.isEmpty && _availableSecondHalbjahr.isEmpty) {
      return _fadeSwitch('sched-none', const SizedBox.shrink());
    }

    final activeGroup = _availableSecondHalbjahr.isNotEmpty
        ? _availableSecondHalbjahr
        : _availableFirstHalbjahr;

    final l10n = AppLocalizations.of(context)!;
    final items = <Widget>[];
    final g5 = activeGroup.where((s) => s.gradeLevel == 'Klassen 5-10').toList();
    final gJ = activeGroup.where((s) => s.gradeLevel == 'J11/J12').toList();
    for (final s in [...g5, ...gJ]) {
      items.add(_buildInlineScheduleCard(s, l10n));
      items.add(const SizedBox(height: 12));
    }
    if (items.isNotEmpty && items.last is SizedBox) items.removeLast();

    return _fadeSwitch(
      'sched-content',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: items),
    );
  }

  Widget _buildInlineScheduleCard(
      ScheduleItem schedule, AppLocalizations l10n) {
    final primary = Theme.of(context).colorScheme.primary;
    final grade = _localizeGrade(l10n, schedule.gradeLevel);
    final half = _localizeHalf(l10n, schedule.halbjahr);

    return _TappableCard(
      onTap: () {
        HapticService.medium();
        _openSchedule(schedule);
        AppLogger.navigation('Opened schedule: $grade $half');
      },
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Icon(Icons.table_chart_outlined, color: primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
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
        Icon(Icons.arrow_forward_ios,
            size: 14,
            color: context.appSecondaryText.withValues(alpha: 0.5)),
      ]),
    );
  }

  Widget _buildScheduleError(ScheduleState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(Icons.schedule_outlined,
            color: context.appSecondaryText.withValues(alpha: 0.5),
            size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.serverConnectionFailed,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appSecondaryText,
                ),
          ),
        ),
        IconButton(
          onPressed: () async {
            HapticService.light();
            await ref.read(scheduleProvider.notifier).refreshSchedules();
            await _checkScheduleAvailability();
          },
          icon: Icon(Icons.refresh,
              color: Theme.of(context).colorScheme.primary, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  Widget _buildScheduleEmpty() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(Icons.schedule_outlined,
            color: context.appSecondaryText.withValues(alpha: 0.4),
            size: 28),
        const SizedBox(width: 12),
        Text(
          AppLocalizations.of(context)!.noSchedulesAvailable,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appSecondaryText,
              ),
        ),
      ]),
    );
  }
}


// ── Skeleton ───────────────────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _opacity = Tween(begin: 0.3, end: 0.7).animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Container(
          height: _kCardHeight,
          decoration: BoxDecoration(
            color: context.appSurfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ── Generic tappable card ──────────────────────────────────────────────────────

class _TappableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TappableCard({required this.child, required this.onTap});

  @override
  State<_TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<_TappableCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
        lowerBound: 0.97,
        upperBound: 1.0,
        value: 1.0);
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _scale.reverse();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _scale.forward();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _scale.forward();
      },
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _pressed ? _scale.value : 1.0,
          child: Container(
            height: _kCardHeight,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: context.appSurfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _pressed
                  ? null
                  : [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
