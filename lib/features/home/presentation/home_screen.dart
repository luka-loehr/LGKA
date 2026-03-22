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
import 'widgets/skeleton_card.dart';
import 'widgets/tappable_card.dart';
import '../../events/application/events_provider.dart';
import '../../events/domain/event_model.dart';
import '../../weather/application/weather_provider.dart';
import '../../weather/domain/weather_models.dart';
import '../../../../providers/preferences_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_weather_bg_null_safety/flutter_weather_bg.dart' hide WeatherDataState;
import 'package:weather_icons/weather_icons.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Boot substitution loading
      await ref.read(substitutionProvider.notifier).initialize();

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

  void _openScheduleForClass(
      List<ScheduleItem> group, String? selectedClass) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(scheduleProvider.notifier);
    final scheduleState = ref.read(scheduleProvider);

    // Pick the correct PDF based on selected class
    final isJahrgang = selectedClass != null && selectedClass.startsWith('j');
    ScheduleItem? target;
    if (isJahrgang) {
      target = group.where((s) => s.gradeLevel == 'J11/J12').firstOrNull;
    }
    target ??= group.where((s) => s.gradeLevel == 'Klassen 5-10').firstOrNull;
    target ??= group.firstOrNull;
    if (target == null) return;

    final half = _localizeHalf(l10n, target.halbjahr);
    final title = selectedClass != null
        ? _formatClassName(selectedClass)
        : _localizeGrade(l10n, target.gradeLevel);
    final dayName = '$title – $half';

    // Look up target page from the appropriate index
    List<int>? targetPages;
    if (selectedClass != null && scheduleState.isIndexBuilt) {
      final page = isJahrgang
          ? notifier.getClassPageJ(selectedClass)
          : notifier.getClassPage(selectedClass);
      if (page != null) targetPages = [page];
    }

    final cached = await notifier.getCachedScheduleFile(target);
    if (cached != null && await cached.exists()) {
      if (mounted) {
        context.push(AppRouter.pdfViewer, extra: {
          'file': cached,
          'dayName': dayName,
          if (targetPages != null) 'targetPages': targetPages,
        });
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

    notifier.downloadSchedule(target).then((file) {
      if (!mounted) return;
      Navigator.of(context).pop();
      if (file != null) {
        if (selectedClass != null && scheduleState.isIndexBuilt) {
          final page = isJahrgang
              ? notifier.getClassPageJ(selectedClass)
              : notifier.getClassPage(selectedClass);
          if (page != null) targetPages = [page];
        }
        context.push(AppRouter.pdfViewer, extra: {
          'file': file,
          'dayName': dayName,
          if (targetPages != null) 'targetPages': targetPages,
        });
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
        if (next.availableFirstHalbjahr.isEmpty &&
            next.availableSecondHalbjahr.isEmpty) {
          ref.read(scheduleProvider.notifier).checkAvailability();
        }
      }
    });

    return Scaffold(
      backgroundColor: context.appBgColor,
      appBar: _buildAppBar(),
      body: _buildBody(subState, isSubLoading),
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
              const SizedBox(height: 16),
              _buildWeatherSection(),
              const SizedBox(height: 28),
              _buildSectionHeader(
                  AppLocalizations.of(context)!.substitutionPlan),
              const SizedBox(height: 12),
              _buildSubstitution(subState, isSubLoading),
              const SizedBox(height: 28),
              _buildSectionHeader(AppLocalizations.of(context)!.schedule),
              const SizedBox(height: 12),
              _buildScheduleSection(),
              const SizedBox(height: 28),
              _buildSectionHeader(AppLocalizations.of(context)!.termine),
              const SizedBox(height: 12),
              _buildTermineSection(),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
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

  // ── Weather ────────────────────────────────────────────────────────────────

  Widget _buildWeatherSection() {
    final weatherState = ref.watch(weatherDataProvider);

    final Widget child;
    final String key;

    if (weatherState.isLoading && weatherState.current == null) {
      key = 'weather-loading';
      child = const SkeletonCard();
    } else if (weatherState.hasError && weatherState.current == null) {
      key = 'weather-error';
      child = _buildWeatherError();
    } else if (weatherState.current != null) {
      key = 'weather-content';
      child = _buildWeatherCard(weatherState.current!, weatherState.daily);
    } else {
      return const SizedBox.shrink();
    }

    return _fadeSwitch(key, child);
  }

  Widget _buildWeatherCard(CurrentWeather current, List<DailyForecast> daily) {
    final today = daily.isNotEmpty ? daily.first : null;
    final scene = WmoUtils.weatherType(current.weatherCode, current.isDay);

    const textShadows = [Shadow(color: Colors.black38, blurRadius: 6)];

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          BoxedIcon(
            WmoUtils.icon(current.weatherCode, current.isDay),
            size: 36,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${current.temp.round()}°',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            shadows: textShadows,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _capitalize(WmoUtils.localizedDescription(current.weatherCode, AppLocalizations.of(context)!)),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              shadows: textShadows,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  today != null
                      ? AppLocalizations.of(context)!.weatherFeelsLikeHighLow(current.feelsLike.round(), today.tempMax.round(), today.tempMin.round())
                      : AppLocalizations.of(context)!.weatherFeelsLikeHumidity(current.feelsLike.round(), current.humidity),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        shadows: textShadows,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios,
              size: 14, color: Colors.white.withValues(alpha: 0.7)),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: kHomeCardHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticService.medium();
              context.push(AppRouter.weather);
            },
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) => WeatherBg(
                      weatherType: scene,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black12, Colors.black26],
                      ),
                    ),
                  ),
                ),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherError() {
    return Container(
      height: kHomeCardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(Icons.cloud_off_outlined,
            size: 20, color: context.appSecondaryText.withValues(alpha: 0.4)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.weatherDataNotAvailable,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appSecondaryText,
                ),
          ),
        ),
        IconButton(
          onPressed: () {
            HapticService.light();
            ref.read(weatherDataProvider.notifier).updateDataInBackground();
          },
          icon: Icon(Icons.refresh,
              color: Theme.of(context).colorScheme.primary, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ── Substitution ──────────────────────────────────────────────────────────

  Widget _buildSubstitution(SubstitutionProviderState state, bool isLoading) {
    final Widget child;
    final String key;

    if (isLoading) {
      key = 'sub-loading';
      child = Column(children: [
        const SkeletonCard(),
        const SizedBox(height: 12),
        const SkeletonCard(),
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
      weekday = _kDeToEn[weekday] ?? weekday;
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
        Icon(Icons.arrow_forward_ios,
            size: 14, color: context.appSecondaryText.withValues(alpha: 0.5)),
      if (hasError)
        Icon(Icons.refresh, size: 18, color: primary.withValues(alpha: 0.7)),
    ]);

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
    String weekday = pdfState.weekday ??
        (isToday
            ? AppLocalizations.of(context)!.today
            : AppLocalizations.of(context)!.tomorrow);
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'en') {
      weekday = _kDeToEn[weekday] ?? weekday;
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
    final selectedClass =
        ref.watch(preferencesManagerProvider).selectedScheduleClass;

    return _fadeSwitch(
      'sched-content-${selectedClass ?? 'none'}',
      _buildInlineScheduleCard(activeGroup, selectedClass, l10n),
    );
  }

  Widget _buildInlineScheduleCard(
      List<ScheduleItem> group, String? selectedClass, AppLocalizations l10n) {
    final primary = Theme.of(context).colorScheme.primary;

    if (selectedClass == null) {
      return TappableCard(
        onTap: () {
          HapticService.light();
          _showSetClassDialog(group);
        },
        child: Row(children: [
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
          Icon(Icons.arrow_forward_ios,
              size: 14,
              color: context.appSecondaryText.withValues(alpha: 0.5)),
        ]),
      );
    }

    final halbjahr = group.isNotEmpty ? group.first.halbjahr : '';
    final half = _localizeHalf(l10n, halbjahr);
    final grade = _formatClassName(selectedClass);

    return TappableCard(
      onTap: () {
        HapticService.medium();
        _openScheduleForClass(group, selectedClass);
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
        Icon(Icons.arrow_forward_ios,
            size: 14,
            color: context.appSecondaryText.withValues(alpha: 0.5)),
      ]),
    );
  }

  void _showSetClassDialog(List<ScheduleItem> group) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.setClassTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: Icon(Icons.school_outlined,
                  color: context.appSecondaryText),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '',
            ),
            onSubmitted: (_) {
              final cls = controller.text.trim().toLowerCase();
              if (cls.isNotEmpty) {
                Navigator.of(ctx).pop();
                ref
                    .read(preferencesManagerProvider.notifier)
                    .setSelectedScheduleClass(cls);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                final cls = controller.text.trim().toLowerCase();
                if (cls.isNotEmpty) {
                  Navigator.of(ctx).pop();
                  ref
                      .read(preferencesManagerProvider.notifier)
                      .setSelectedScheduleClass(cls);
                }
              },
              child: Text(l10n.setClassButton),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }

  String _formatClassName(String className) {
    final l = AppLocalizations.of(context)!;
    if (className == 'j11') return l.jahrgang11;
    if (className == 'j12') return l.jahrgang12;
    return l.klasseLabel('${className[0].toUpperCase()}${className.substring(1)}');
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
            await ref.read(scheduleProvider.notifier).checkAvailability();
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

  // ── Termine (events) section ───────────────────────────────────────────────

  Widget _buildTermineSection() {
    final eventsState = ref.watch(eventsProvider);

    final Widget child;
    final String key;

    if (eventsState.isLoading) {
      key = 'events-loading';
      child = const Column(children: [
        SkeletonCard(),
        SizedBox(height: 12),
        SkeletonCard(),
        SizedBox(height: 12),
        SkeletonCard(),
        SizedBox(height: 12),
        SkeletonCard(),
      ]);
    } else if (eventsState.hasError && eventsState.events.isEmpty) {
      key = 'events-error';
      child = _buildEventsError();
    } else if (eventsState.events.isEmpty) {
      key = 'events-empty';
      child = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appSurfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Icon(Icons.event_outlined,
              color: context.appSecondaryText.withValues(alpha: 0.4),
              size: 28),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.noEventsAvailable,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appSecondaryText,
                ),
          ),
        ]),
      );
    } else {
      key = 'events-content';
      final displayEvents = eventsState.events.take(4).toList();
      final items = <Widget>[];
      for (final event in displayEvents) {
        items.add(_buildEventCard(event));
        items.add(const SizedBox(height: 12));
      }
      if (items.isNotEmpty && items.last is SizedBox) items.removeLast();
      child = Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: items);
    }

    return _fadeSwitch(key, child);
  }

  Widget _buildEventCard(SchoolEvent event) {
    final primary = Theme.of(context).colorScheme.primary;
    final locale = Localizations.localeOf(context).languageCode;

    // Format the date: short weekday + day + month name
    // Use German locale for German, otherwise default
    final dateLocale = locale == 'de' ? 'de_DE' : 'en_US';
    final weekdayFormat = DateFormat('EEE', dateLocale);
    final dayMonthFormat = DateFormat('d. MMMM', dateLocale);

    final weekday = weekdayFormat.format(event.date);
    final dayMonth = dayMonthFormat.format(event.date);

    String subtitle;
    if (event.time != null) {
      subtitle = '$weekday, $dayMonth · ${event.time}';
    } else {
      subtitle = '$weekday, $dayMonth';
    }

    return Container(
      height: kHomeCardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.event_outlined, color: primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: context.appPrimaryText,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appSecondaryText,
                    ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildEventsError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(Icons.event_outlined,
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
            await ref.read(eventsProvider.notifier).refresh();
          },
          icon: Icon(Icons.refresh,
              color: Theme.of(context).colorScheme.primary, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}
