// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';
import '../../substitution/application/substitution_provider.dart';
import '../../substitution/domain/substitution_models.dart';
import '../../settings/presentation/settings_modal.dart';
import '../../../../services/haptic_service.dart';
import '../../../../navigation/app_router.dart';
import '../../../../utils/app_logger.dart';
import '../../../../widgets/constrained_modal_bottom_sheet.dart';
import '../../../../widgets/app_footer.dart';
import '../../../../providers/app_providers.dart';
import '../../../../utils/app_info.dart';
import '../../../../l10n/app_localizations.dart';

/// Main home screen — scrollable dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(substitutionProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final substitutionState = ref.watch(substitutionProvider);
    final isLoading =
        substitutionState.isLoading || !substitutionState.isInitialized;

    // Trigger fade-in once data (or error) is ready
    if (!isLoading && !_hasAnimated) {
      _hasAnimated = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _fadeController.forward());
    }

    return Scaffold(
      backgroundColor: context.appBgColor,
      appBar: _buildAppBar(context),
      body: _buildBody(context, substitutionState, isLoading),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.appBgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        'LGKA',
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
            _navigateToKrankmeldung(context);
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

  void _navigateToKrankmeldung(BuildContext context) {
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

  Widget _buildBody(BuildContext context, SubstitutionProviderState state,
      bool isLoading) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              _buildGreeting(context),
              const SizedBox(height: 28),
              _buildSectionHeader(
                  context, AppLocalizations.of(context)!.substitutionPlan),
              const SizedBox(height: 12),
              _buildSubstitutionContent(context, state, isLoading),
              const SizedBox(height: 28),
              _buildSectionHeader(
                  context, AppLocalizations.of(context)!.schedule),
              const SizedBox(height: 12),
              _buildScheduleCard(context),
              const SizedBox(height: 32),
              AppFooter(bottomPadding: _footerPadding(context)),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Greeting ────────────────────────────────────────────────────────────────

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final String greeting;
    if (hour < 11) {
      greeting = 'Guten Morgen';
    } else if (hour < 18) {
      greeting = 'Guten Tag';
    } else {
      greeting = 'Guten Abend';
    }
    final dateStr =
        DateFormat('EEEE, d. MMMM', 'de_DE').format(DateTime.now());

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
          dateStr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appSecondaryText,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  // ── Section header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.appPrimaryText,
            fontWeight: FontWeight.w700,
          ),
    );
  }

  // ── Substitution content ───────────────────────────────────────────────────

  Widget _buildSubstitutionContent(BuildContext context,
      SubstitutionProviderState state, bool isLoading) {
    if (isLoading) {
      return _buildSubstitutionLoading(context);
    }
    if (state.hasAnyError && !state.hasAnyData) {
      return _buildSubstitutionError(context, state);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _SubstitutionCard(
            pdfState: state.todayState,
            label: AppLocalizations.of(context)!.today,
            onTap: () => _openPdf(state, true),
            onRetry: () =>
                ref.read(substitutionProvider.notifier).retryPdf(true),
          ),
          const SizedBox(height: 12),
          _SubstitutionCard(
            pdfState: state.tomorrowState,
            label: AppLocalizations.of(context)!.tomorrow,
            onTap: () => _openPdf(state, false),
            onRetry: () =>
                ref.read(substitutionProvider.notifier).retryPdf(false),
          ),
        ],
      ),
    );
  }

  Widget _buildSubstitutionLoading(BuildContext context) {
    return Column(
      children: [
        _SkeletonCard(),
        const SizedBox(height: 12),
        _SkeletonCard(),
      ],
    );
  }

  Widget _buildSubstitutionError(
      BuildContext context, SubstitutionProviderState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appSecondaryText,
                ),
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
        ],
      ),
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
    final localeCode = Localizations.localeOf(context).languageCode;
    if (localeCode == 'en') {
      const Map<String, String> de2en = {
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
    AppLogger.pdf('Opening PDF: $weekday (${isToday ? 'today' : 'tomorrow'})');
    if (pdfFile != null) {
      context.push(AppRouter.pdfViewer, extra: {
        'file': pdfFile,
        'dayName': weekday,
      });
    }
  }

  // ── Schedule card ──────────────────────────────────────────────────────────

  Widget _buildScheduleCard(BuildContext context) {
    return _TappableCard(
      onTap: () {
        HapticService.medium();
        context.push(AppRouter.schedule);
        AppLogger.navigation('Opened schedule from home');
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.table_chart_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.schedule,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.appPrimaryText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Klassen 5–10 & Jahrgänge 11/12',
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  double _footerPadding(BuildContext context) {
    final mq = MediaQuery.of(context);
    final gi = mq.systemGestureInsets.bottom;
    if (gi >= 45) return 34.0;
    if (gi <= 25) return 8.0;
    return mq.viewPadding.bottom > 50 ? 34.0 : 8.0;
  }
}

// ── Substitution Card ──────────────────────────────────────────────────────────

class _SubstitutionCard extends ConsumerStatefulWidget {
  final SubstitutionState pdfState;
  final String label;
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
        builder: (context, _) => Transform.scale(
          scale: _pressed ? _scale.value : 1.0,
          child: _buildCard(context, isDisabled, hasError, isLoading),
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, bool isDisabled, bool hasError, bool isLoading) {
    final primary = Theme.of(context).colorScheme.primary;

    // Day name + date from state
    String weekday = widget.pdfState.weekday ?? '';
    final date = widget.pdfState.date ?? '';
    final localeCode = Localizations.localeOf(context).languageCode;
    if (localeCode == 'en' && weekday.isNotEmpty) {
      const Map<String, String> de2en = {
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

    final bool isWeekend = weekday == 'weekend' || weekday.isEmpty;
    final String dayDisplay = isWeekend
        ? AppLocalizations.of(context)!.noInfoYet
        : (hasError
            ? AppLocalizations.of(context)!.errorLoading
            : weekday);

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
        child: Row(
          children: [
            // Icon circle
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                            primary.withValues(alpha: isDisabled ? 0.4 : 1.0)),
                      ),
                    )
                  : Icon(
                      hasError ? Icons.refresh : Icons.calendar_today_outlined,
                      color: isDisabled
                          ? primary.withValues(alpha: 0.35)
                          : primary,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 14),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "Heute" / "Morgen" tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primary.withValues(
                          alpha: isDisabled ? 0.06 : 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.label,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isDisabled
                                    ? primary.withValues(alpha: 0.4)
                                    : primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Day name
                  Text(
                    dayDisplay,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isDisabled
                                  ? context.appPrimaryText
                                      .withValues(alpha: 0.35)
                                  : context.appPrimaryText,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                  ),
                  if (date.isNotEmpty && !isDisabled && !hasError) ...[
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.appSecondaryText,
                              ),
                    ),
                  ],
                ],
              ),
            ),
            // Arrow
            if (!isDisabled && !hasError)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: context.appSecondaryText.withValues(alpha: 0.5),
              ),
            if (hasError)
              Icon(Icons.refresh,
                  size: 18, color: primary.withValues(alpha: 0.7)),
          ],
        ),
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

// ── Skeleton placeholder card ──────────────────────────────────────────────────

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
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: Container(
          height: 88,
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
        builder: (context, _) => Transform.scale(
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
