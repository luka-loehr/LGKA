// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_theme.dart';
import '../domain/substitution_models.dart';
import '../application/substitution_provider.dart';
import '../../../../services/haptic_service.dart';
import '../../../../navigation/app_router.dart';
import '../../../../utils/app_logger.dart';
import '../../../../widgets/app_footer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/loading_spinner_tracker_service.dart';

/// Selected day provider (today/tomorrow) - true = today, false = tomorrow
final selectedDayProvider = NotifierProvider<_SelectedDayNotifier, bool>(
  _SelectedDayNotifier.new,
);

class _SelectedDayNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void setToday() => state = true;
  void setTomorrow() => state = false;
}

/// Selected class provider
final selectedClassProvider = NotifierProvider<_SelectedClassNotifier, String?>(
  _SelectedClassNotifier.new,
);

class _SelectedClassNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? className) => state = className;
  void clear() => state = null;
}

/// Substitution plan screen with class grid view
class SubstitutionScreen extends ConsumerStatefulWidget {
  const SubstitutionScreen({super.key});

  @override
  ConsumerState<SubstitutionScreen> createState() => _SubstitutionScreenState();
}

class _SubstitutionScreenState extends ConsumerState<SubstitutionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final _spinnerTracker = LoadingSpinnerTracker();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final substitutionState = ref.watch(substitutionProvider);
    final isLoading = substitutionState.isLoading || !substitutionState.isInitialized;
    final isError = substitutionState.hasAnyError && !substitutionState.hasAnyData;
    final hasData = substitutionState.hasAnyData;

    // Track spinner visibility
    _spinnerTracker.trackState(
      isSpinnerVisible: isLoading,
      hasData: hasData,
      hasError: isError,
      mounted: mounted,
    );
    
    if (!substitutionState.isInitialized || substitutionState.isLoading) {
      return const _LoadingView();
    }

    if (substitutionState.hasAnyError && !substitutionState.hasAnyData) {
      return _ErrorView(
        onRetry: () {
          ref.read(substitutionProvider.notifier).retryAll();
        },
      );
    }

    // Start animation when content is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_fadeController.isCompleted) {
        _fadeController.forward();
      }
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Day selector header
          _DaySelectorHeader(
            todayState: substitutionState.todayState,
            tomorrowState: substitutionState.tomorrowState,
          ),
          
          const SizedBox(height: 16),
          
          // Main content
          Expanded(
            child: _MainContent(
              substitutionState: substitutionState,
            ),
          ),
          
          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return AppFooter(bottomPadding: _getFooterPadding(context));
  }

  double _getFooterPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final gestureInsets = mediaQuery.systemGestureInsets.bottom;
    final viewPadding = mediaQuery.viewPadding.bottom;
    
    if (gestureInsets >= 45) {
      return 34.0;
    } else if (gestureInsets <= 25) {
      return 8.0;
    } else {
      return viewPadding > 50 ? 34.0 : 8.0;
    }
  }
}

/// Day selector header with today/tomorrow tabs
class _DaySelectorHeader extends ConsumerWidget {
  final SubstitutionState todayState;
  final SubstitutionState tomorrowState;

  const _DaySelectorHeader({
    required this.todayState,
    required this.tomorrowState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isToday = ref.watch(selectedDayProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.appSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DayTab(
              label: AppLocalizations.of(context)!.today,
              date: todayState.date ?? '',
              weekday: todayState.weekday ?? '',
              isSelected: isToday,
              hasData: todayState.canDisplay,
              onTap: () {
                HapticService.light();
                ref.read(selectedDayProvider.notifier).setToday();
                ref.read(selectedClassProvider.notifier).clear();
              },
            ),
          ),
          Expanded(
            child: _DayTab(
              label: AppLocalizations.of(context)!.tomorrow,
              date: tomorrowState.date ?? '',
              weekday: tomorrowState.weekday ?? '',
              isSelected: !isToday,
              hasData: tomorrowState.canDisplay,
              onTap: () {
                HapticService.light();
                ref.read(selectedDayProvider.notifier).setTomorrow();
                ref.read(selectedClassProvider.notifier).clear();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual day tab
class _DayTab extends StatelessWidget {
  final String label;
  final String date;
  final String weekday;
  final bool isSelected;
  final bool hasData;
  final VoidCallback onTap;

  const _DayTab({
    required this.label,
    required this.date,
    required this.weekday,
    required this.isSelected,
    required this.hasData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: hasData ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              weekday.isNotEmpty ? weekday : label,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : hasData 
                        ? AppColors.primaryText 
                        : AppColors.secondaryText,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (date.isNotEmpty && hasData)
              Text(
                date,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white.withAlpha(180) 
                      : AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Main content area - shows either class grid or class detail
class _MainContent extends ConsumerWidget {
  final SubstitutionProviderState substitutionState;

  const _MainContent({required this.substitutionState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isToday = ref.watch(selectedDayProvider);
    final selectedClass = ref.watch(selectedClassProvider);
    
    final data = isToday 
        ? substitutionState.todayData 
        : substitutionState.tomorrowData;

    if (data == null || !data.isValid) {
      return _EmptyDayView(
        isToday: isToday,
        hasError: isToday 
            ? substitutionState.todayState.error != null
            : substitutionState.tomorrowState.error != null,
        onRetry: () {
          ref.read(substitutionProvider.notifier).retryPdf(isToday);
        },
      );
    }

    // If a class is selected, show its details
    if (selectedClass != null) {
      return _ClassDetailView(
        className: selectedClass,
        entries: data.getEntriesForClass(selectedClass),
        weekday: data.weekday,
        date: data.date,
        onBack: () {
          HapticService.light();
          ref.read(selectedClassProvider.notifier).clear();
        },
      );
    }

    // Show class grid
    return _ClassGridView(
      classes: data.uniqueClasses,
      data: data,
      onClassSelected: (className) {
        HapticService.medium();
        ref.read(selectedClassProvider.notifier).select(className);
        AppLogger.navigation('Selected class: $className');
      },
    );
  }
}

/// Grid view of all classes
class _ClassGridView extends StatelessWidget {
  final List<String> classes;
  final ParsedSubstitutionData data;
  final ValueChanged<String> onClassSelected;

  const _ClassGridView({
    required this.classes,
    required this.data,
    required this.onClassSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Klassen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${classes.length} Klassen',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final className = classes[index];
                final entryCount = data.getEntriesForClass(className).length;
                
                return _ClassCard(
                  className: className,
                  entryCount: entryCount,
                  onTap: () => onClassSelected(className),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual class card
class _ClassCard extends StatefulWidget {
  final String className;
  final int entryCount;
  final VoidCallback onTap;

  const _ClassCard({
    required this.className,
    required this.entryCount,
    required this.onTap,
  });

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasEntries = widget.entryCount > 0;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? 0.95 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: hasEntries 
                    ? colorScheme.primary.withAlpha(30)
                    : AppColors.appSurface,
                borderRadius: BorderRadius.circular(16),
                border: hasEntries
                    ? Border.all(
                        color: colorScheme.primary.withAlpha(100),
                        width: 1,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.className,
                    style: TextStyle(
                      color: hasEntries 
                          ? colorScheme.primary 
                          : AppColors.primaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                  if (hasEntries) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, 
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.entryCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Detail view for a selected class
class _ClassDetailView extends StatelessWidget {
  final String className;
  final List<SubstitutionEntry> entries;
  final String weekday;
  final String date;
  final VoidCallback onBack;

  const _ClassDetailView({
    required this.className,
    required this.entries,
    required this.weekday,
    required this.date,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.appSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.primaryText,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Klasse $className',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$weekday, $date',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, 
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: entries.any((e) => e.isCancellation)
                      ? const Color(0xFFEF4444).withAlpha(30)
                      : Theme.of(context).colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${entries.length} Einträge',
                  style: TextStyle(
                    color: entries.any((e) => e.isCancellation)
                        ? const Color(0xFFEF4444)
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Entries list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                return _EntryCard(
                  entry: entries[index],
                  isFirst: index == 0,
                  isLast: index == entries.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual substitution entry card
class _EntryCard extends StatelessWidget {
  final SubstitutionEntry entry;
  final bool isFirst;
  final bool isLast;

  const _EntryCard({
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = Color(entry.typeColor);

    return Container(
      margin: EdgeInsets.only(
        bottom: isLast ? 0 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.appSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type and period
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: typeColor.withAlpha(30),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, 
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.typeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: typeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.period}. Stunde',
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (entry.text != null && entry.text!.isNotEmpty) ...[
                  const Spacer(),
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.secondaryText,
                  ),
                ],
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject info
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.book_outlined,
                        label: 'Fach',
                        value: entry.subject.isNotEmpty 
                            ? entry.subject 
                            : '-',
                      ),
                    ),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.room_outlined,
                        label: 'Raum',
                        value: entry.room.isNotEmpty 
                            ? entry.room 
                            : '-',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Teacher info
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.person_outline,
                        label: 'Vertretung',
                        value: entry.substituteTeacher.isNotEmpty 
                            ? entry.substituteTeacher 
                            : '-',
                      ),
                    ),
                    if (entry.originalTeacher != null) ...[
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.person_outline,
                          label: 'Lehrer',
                          value: entry.originalTeacher!,
                          isStrikethrough: entry.isCancellation,
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Additional text
                if (entry.text != null && entry.text!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0x1AFFFFFF)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.text!,
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Info item widget for entry cards
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isStrikethrough;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isStrikethrough = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.secondaryText,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration: isStrikethrough 
                    ? TextDecoration.lineThrough 
                    : null,
                decorationColor: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Empty day view (weekend or no data)
class _EmptyDayView extends StatelessWidget {
  final bool isToday;
  final bool hasError;
  final VoidCallback onRetry;

  const _EmptyDayView({
    required this.isToday,
    required this.hasError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final label = isToday 
        ? AppLocalizations.of(context)!.today 
        : AppLocalizations.of(context)!.tomorrow;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasError ? Icons.error_outline : Icons.weekend,
              size: 64,
              color: AppColors.secondaryText.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              hasError 
                  ? AppLocalizations.of(context)!.errorLoading
                  : AppLocalizations.of(context)!.noInfoYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasError
                  ? AppLocalizations.of(context)!.serverConnectionHint
                  : 'Für $label sind keine Vertretungen eingetragen.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasError) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  HapticService.light();
                  onRetry();
                },
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading view
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.loadingSubstitutions,
            style: const TextStyle(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

/// Error view
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: AppColors.secondaryText.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.serverConnectionFailed,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.serverConnectionHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              HapticService.light();
              onRetry();
            },
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.tryAgain),
          ),
        ],
      ),
    );
  }
}
