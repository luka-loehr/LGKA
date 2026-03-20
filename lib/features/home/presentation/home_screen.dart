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
import '../../news/application/news_provider.dart';
import '../../news/domain/news_models.dart';
import '../../settings/presentation/settings_modal.dart';
import '../../../../services/haptic_service.dart';
import '../../../../navigation/app_router.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/app_info.dart';
import '../../../../widgets/constrained_modal_bottom_sheet.dart';
import '../../../../widgets/app_footer.dart';
import '../../../../providers/app_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Main home screen — scrollable dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _subFadeController;
  late Animation<double> _subFadeAnimation;
  bool _subAnimated = false;

  // Schedule availability
  List<ScheduleItem> _availableFirstHalbjahr = [];
  List<ScheduleItem> _availableSecondHalbjahr = [];
  bool _scheduleChecking = false;
  DateTime? _lastScheduleCheck;
  static const _scheduleCheckInterval = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    _subFadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _subFadeAnimation = CurvedAnimation(
      parent: _subFadeController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(substitutionProvider.notifier).initialize();
      final scheduleState = ref.read(scheduleProvider);
      if (!scheduleState.hasSchedules) {
        await ref.read(scheduleProvider.notifier).loadSchedules();
      }
      await _checkScheduleAvailability();
      ref.read(newsProvider.notifier).loadNews();
    });
  }

  @override
  void dispose() {
    _subFadeController.dispose();
    super.dispose();
  }

  // ── Schedule availability ─────────────────────────────────────────────────

  bool _shouldCheckSchedule() {
    if (_lastScheduleCheck != null &&
        DateTime.now().difference(_lastScheduleCheck!) < _scheduleCheckInterval) {
      return false;
    }
    return true;
  }

  Future<void> _checkScheduleAvailability() async {
    if (_scheduleChecking || !_shouldCheckSchedule()) return;
    if (!mounted) return;
    setState(() => _scheduleChecking = true);
    try {
      final notifier = ref.read(scheduleProvider.notifier);
      final state = ref.read(scheduleProvider);
      final allSchedules = {
        ...state.firstHalbjahrSchedules,
        ...state.secondHalbjahrSchedules,
      }.toList();

      final results = await Future.wait(allSchedules.map((s) async {
        final ok = await notifier.isScheduleAvailable(s);
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

      // Fallback: if availability check returned nothing, check for locally cached PDFs
      if (_availableFirstHalbjahr.isEmpty && _availableSecondHalbjahr.isEmpty) {
        await _restoreFromCachedFiles(allSchedules);
      }
      _lastScheduleCheck = DateTime.now();
    } finally {
      if (mounted) setState(() => _scheduleChecking = false);
    }
  }

  Future<void> _restoreFromCachedFiles(List<ScheduleItem> schedules) async {
    final first = <ScheduleItem>{};
    final second = <ScheduleItem>{};
    for (final s in schedules.toSet()) {
      final cached = await _cachedScheduleFile(s);
      if (cached != null && await cached.exists()) {
        final size = await cached.length();
        if (size > 1000) {
          if (s.halbjahr == '1. Halbjahr') first.add(s);
          if (s.halbjahr == '2. Halbjahr') second.add(s);
        }
      }
    }
    if (mounted) {
      _availableFirstHalbjahr = first.toList();
      _availableSecondHalbjahr = second.toList();
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
        context.push(AppRouter.pdfViewer, extra: {'file': cached, 'dayName': dayName});
      }
      return;
    }
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Text(l10n.loadingSchedule),
          ],
        ),
      ),
    );

    ref.read(scheduleProvider.notifier).downloadSchedule(schedule).then((file) {
      if (!mounted) return;
      Navigator.of(context).pop();
      if (file != null) {
        context.push(AppRouter.pdfViewer, extra: {'file': file, 'dayName': dayName});
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
        content: Text(AppLocalizations.of(context)!.errorLoadingGeneric),
        backgroundColor: Colors.red,
      ));
    });
  }

  String _localizeGrade(AppLocalizations l, String g) =>
      g == 'Klassen 5-10' ? l.grades5to10 : g == 'J11/J12' ? l.j11j12 : g;

  String _localizeHalf(AppLocalizations l, String h) =>
      h == '1. Halbjahr' ? l.firstSemester : h == '2. Halbjahr' ? l.secondSemester : h;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(substitutionProvider);
    final isSubLoading = subState.isLoading || !subState.isInitialized;

    if (!isSubLoading && !_subAnimated) {
      _subAnimated = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _subFadeController.forward());
    }

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
        'LGKA+',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.appPrimaryText,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
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
          icon: Icon(Icons.settings_outlined, color: context.appSecondaryText),
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
              const SizedBox(height: 8),
              _buildGreeting(),
              const SizedBox(height: 24),
              _buildNewsTeaser(),
              const SizedBox(height: 28),
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

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Guten Morgen'
        : hour < 18
            ? 'Guten Tag'
            : 'Guten Abend';
    final date = DateFormat('EEEE, d. MMMM', 'de_DE').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: context.appPrimaryText,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appSecondaryText,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
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
    if (isLoading) {
      return Column(children: [
        _SkeletonCard(),
        const SizedBox(height: 12),
        _SkeletonCard(),
      ]);
    }
    if (state.hasAnyError && !state.hasAnyData) {
      return _buildSubError(state);
    }
    return FadeTransition(
      opacity: _subFadeAnimation,
      child: Column(children: [
        _SubstitutionCard(
          pdfState: state.todayState,
          label: AppLocalizations.of(context)!.today,
          onTap: () => _openPdf(state, true),
          onRetry: () => ref.read(substitutionProvider.notifier).retryPdf(true),
        ),
        const SizedBox(height: 12),
        _SubstitutionCard(
          pdfState: state.tomorrowState,
          label: AppLocalizations.of(context)!.tomorrow,
          onTap: () => _openPdf(state, false),
          onRetry: () =>
              ref.read(substitutionProvider.notifier).retryPdf(false),
        ),
      ]),
    );
  }

  Widget _buildSubError(SubstitutionProviderState state) {
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ]),
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
        'Montag': 'Monday', 'Dienstag': 'Tuesday', 'Mittwoch': 'Wednesday',
        'Donnerstag': 'Thursday', 'Freitag': 'Friday',
        'Samstag': 'Saturday', 'Sonntag': 'Sunday',
      };
      weekday = de2en[weekday] ?? weekday;
    }
    AppLogger.pdf('Opening PDF: $weekday (${isToday ? 'today' : 'tomorrow'})');
    if (pdfFile != null) {
      context.push(AppRouter.pdfViewer, extra: {'file': pdfFile, 'dayName': weekday});
    }
  }

  // ── News teaser ───────────────────────────────────────────────────────────

  Widget _buildNewsTeaser() {
    final newsState = ref.watch(newsProvider);
    final events = newsState.events.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.news,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.appPrimaryText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticService.light();
                context.push(AppRouter.news);
              },
              child: Row(
                children: [
                  Text(
                    'Alle',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 11,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (newsState.isLoading)
          Column(children: [_SkeletonCard(), const SizedBox(height: 12), _SkeletonCard()])
        else if (events.isEmpty)
          const SizedBox.shrink()
        else
          Column(
            children: events.asMap().entries.map((entry) {
              final i = entry.key;
              final article = entry.value;
              return Column(
                children: [
                  _buildNewsCard(article),
                  if (i < events.length - 1) const SizedBox(height: 10),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildNewsCard(NewsEvent article) {
    final primary = Theme.of(context).colorScheme.primary;
    return _TappableCard(
      onTap: () {
        HapticService.light();
        context.push(AppRouter.newsDetail, extra: article);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.article_outlined, color: primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.appPrimaryText,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  article.createdDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appSecondaryText,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios,
              size: 14,
              color: context.appSecondaryText.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  // ── Schedule section ──────────────────────────────────────────────────────

  Widget _buildScheduleSection() {
    final scheduleState = ref.watch(scheduleProvider);

    if (scheduleState.isLoading || _scheduleChecking) {
      return _SkeletonCard();
    }

    if (scheduleState.hasError) {
      return _buildScheduleError(scheduleState);
    }

    final allAvailable = [
      ..._availableFirstHalbjahr,
      ..._availableSecondHalbjahr,
    ];

    if (allAvailable.isEmpty) {
      return _buildScheduleEmpty();
    }

    final l10n = AppLocalizations.of(context)!;
    final hasBoth = _availableFirstHalbjahr.isNotEmpty &&
        _availableSecondHalbjahr.isNotEmpty;
    final items = <Widget>[];

    void addGroup(List<ScheduleItem> group) {
      final g5 = group.where((s) => s.gradeLevel == 'Klassen 5-10').toList();
      final gJ = group.where((s) => s.gradeLevel == 'J11/J12').toList();
      for (final s in [...g5, ...gJ]) {
        items.add(_buildInlineScheduleCard(s, l10n));
        items.add(const SizedBox(height: 12));
      }
    }

    addGroup(_availableFirstHalbjahr);
    if (hasBoth) {
      items.add(Divider(
          height: 24, color: context.appSecondaryText.withValues(alpha: 0.2)));
    }
    addGroup(_availableSecondHalbjahr);
    if (items.isNotEmpty && items.last is SizedBox) items.removeLast();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }

  Widget _buildInlineScheduleCard(ScheduleItem schedule, AppLocalizations l10n) {
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
          child: Icon(Icons.table_chart_outlined, color: primary, size: 20),
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
            color: context.appSecondaryText.withValues(alpha: 0.5), size: 28),
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
            color: context.appSecondaryText.withValues(alpha: 0.4), size: 28),
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

// ── Substitution card ──────────────────────────────────────────────────────────

class _SubstitutionCard extends ConsumerStatefulWidget {
  final SubstitutionState pdfState;
  final String label; // "Heute" / "Morgen" — kept for tap logic, not shown
  final VoidCallback onTap;
  final VoidCallback onRetry;

  const _SubstitutionCard({
    required this.pdfState,
    required this.label,
    required this.onTap,
    required this.onRetry,
  });

  @override
  ConsumerState<_SubstitutionCard> createState() => _SubstitutionCardState();
}

class _SubstitutionCardState extends ConsumerState<_SubstitutionCard>
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
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.pdfState.canDisplay;
    final hasError = widget.pdfState.error != null;
    final isLoading = widget.pdfState.isLoading;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _onDown(),
      onTapUp: isDisabled ? null : (_) => _onUp(),
      onTapCancel: isDisabled ? null : _onCancel,
      onTap: isDisabled
          ? null
          : () {
              if (hasError) {
                HapticService.medium();
                widget.onRetry();
              } else {
                HapticService.medium();
                widget.onTap();
              }
            },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _pressed ? _scale.value : 1.0,
          child: _buildCard(context, isDisabled, hasError, isLoading),
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, bool isDisabled, bool hasError, bool isLoading) {
    final primary = Theme.of(context).colorScheme.primary;

    String weekday = widget.pdfState.weekday ?? '';
    final date = widget.pdfState.date ?? '';
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'en' && weekday.isNotEmpty) {
      const de2en = {
        'Montag': 'Monday', 'Dienstag': 'Tuesday', 'Mittwoch': 'Wednesday',
        'Donnerstag': 'Thursday', 'Freitag': 'Friday',
        'Samstag': 'Saturday', 'Sonntag': 'Sunday',
      };
      weekday = de2en[weekday] ?? weekday;
    }
    final isWeekend = weekday == 'weekend' || weekday.isEmpty;
    final dayDisplay = isWeekend
        ? AppLocalizations.of(context)!.noInfoYet
        : hasError
            ? AppLocalizations.of(context)!.errorLoading
            : weekday;

    return Container(
      decoration: BoxDecoration(
        color: isDisabled
            ? context.appSurfaceColor.withValues(alpha: 0.5)
            : context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDisabled || _pressed
            ? null
            : [
                BoxShadow(
                  color: primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(children: [
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
                size: 14,
                color: context.appSecondaryText.withValues(alpha: 0.5)),
          if (hasError)
            Icon(Icons.refresh,
                size: 18, color: primary.withValues(alpha: 0.7)),
        ]),
      ),
    );
  }

  void _onDown() {
    setState(() => _pressed = true);
    _scale.reverse();
  }

  void _onUp() {
    setState(() => _pressed = false);
    _scale.forward();
  }

  void _onCancel() {
    setState(() => _pressed = false);
    _scale.forward();
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
          height: 80,
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
