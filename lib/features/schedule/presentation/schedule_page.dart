// Copyright Luka Löhr 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../substitution/application/substitution_provider.dart';
import '../../substitution/domain/substitution_models.dart';
import '../domain/schedule_models.dart';
import '../data/schedule_service.dart';
import '../../../../services/haptic_service.dart';
import '../../../../utils/app_logger.dart';

/// Standard lesson times
const Map<int, LessonTime> standardLessonTimes = {
  1: LessonTime(startTime: '08:00', endTime: '08:45'),
  2: LessonTime(startTime: '08:55', endTime: '09:40'),
  3: LessonTime(startTime: '09:50', endTime: '10:35'),
  4: LessonTime(startTime: '10:55', endTime: '11:40'),
  5: LessonTime(startTime: '11:50', endTime: '12:35'),
  6: LessonTime(startTime: '12:45', endTime: '13:30'),
  7: LessonTime(startTime: '13:35', endTime: '14:20'),
  8: LessonTime(startTime: '14:25', endTime: '15:10'),
  9: LessonTime(startTime: '15:15', endTime: '16:00'),
  10: LessonTime(startTime: '16:05', endTime: '16:50'),
  11: LessonTime(startTime: '16:55', endTime: '17:40'),
};

/// Selected class notifier
class SelectedScheduleClassNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? className) => state = className;
}

/// Selected class provider
final selectedScheduleClassProvider = NotifierProvider<SelectedScheduleClassNotifier, String?>(
  SelectedScheduleClassNotifier.new,
);

/// Schedule page with full week grid view
class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  @override
  void initState() {
    super.initState();
    // Load mock data and auto-select 5a
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      scheduleService.loadMockData();
      // Auto-select class 5a
      ref.read(selectedScheduleClassProvider.notifier).select('5a');
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedClass = ref.watch(selectedScheduleClassProvider);
    
    return Column(
      children: [
        // Class selector
        _ClassSelector(
          classes: scheduleService.classNames.isEmpty 
              ? ['5a', '5b', '5c', '6a', '6b', '6c', '7a', '7b', '7c', '7d', 
                 '8a', '8b', '8c', '8d', '9a', '9b', '9c', '9d',
                 '10a', '10b', '10c', '10d', '10e']
              : scheduleService.classNames,
          selectedClass: selectedClass,
          onClassSelected: (className) {
            HapticService.light();
            ref.read(selectedScheduleClassProvider.notifier).select(className);
            AppLogger.navigation('Selected class: $className');
          },
        ),
        
        const SizedBox(height: 12),
        
        // Week grid header (days)
        _WeekHeader(),
        
        const SizedBox(height: 8),
        
        // Full week schedule grid
        Expanded(
          child: selectedClass == null
              ? _EmptyClassView(
                  onSelectClass: () => _showClassPicker(context, 
                    scheduleService.classNames.isEmpty 
                        ? ['5a', '5b', '5c', '6a', '6b', '6c', '7a', '7b', '7c', '7d',
                           '8a', '8b', '8c', '8d', '9a', '9b', '9c', '9d',
                           '10a', '10b', '10c', '10d', '10e']
                        : scheduleService.classNames),
                )
              : _WeekScheduleGrid(
                  className: selectedClass,
                  schedule: scheduleService.getScheduleForClass(selectedClass),
                  substitutions: ref.watch(substitutionProvider),
                ),
        ),
      ],
    );
  }

  void _showClassPicker(BuildContext context, List<String> classes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Klasse auswählen',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final className = classes[index];
                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedScheduleClassProvider.notifier).select(className);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withAlpha(100),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            className,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Class selector widget
class _ClassSelector extends StatelessWidget {
  final List<String> classes;
  final String? selectedClass;
  final ValueChanged<String> onClassSelected;

  const _ClassSelector({
    required this.classes,
    required this.selectedClass,
    required this.onClassSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.appSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            'Klasse:',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: selectedClass == null
                ? GestureDetector(
                    onTap: () => _showClassDropdown(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Auswählen',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () => _showClassDropdown(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedClass!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showClassDropdown(BuildContext context) {
    onClassSelected(selectedClass ?? classes.first);
  }
}

/// Week header with day names
class _WeekHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final days = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag'];
    final dayShort = ['Mo', 'Di', 'Mi', 'Do', 'Fr'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Time column header
          Container(
            width: 45,
            alignment: Alignment.center,
            child: Text(
              '',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Day columns
          ...List.generate(5, (index) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(left: index > 0 ? 4 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.appSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      dayShort[index],
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      days[index].substring(2),
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Empty class view
class _EmptyClassView extends StatelessWidget {
  final VoidCallback onSelectClass;

  const _EmptyClassView({required this.onSelectClass});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppColors.secondaryText.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'Stundenplan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wähle eine Klasse aus, um den Stundenplan zu sehen',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onSelectClass,
            child: const Text('Klasse auswählen'),
          ),
        ],
      ),
    );
  }
}

/// Week schedule grid showing all 5 days
class _WeekScheduleGrid extends StatelessWidget {
  final String className;
  final ClassSchedule? schedule;
  final SubstitutionProviderState substitutions;

  const _WeekScheduleGrid({
    required this.className,
    required this.schedule,
    required this.substitutions,
  });

  @override
  Widget build(BuildContext context) {
    // Get all substitutions for this class organized by period
    final substitutionMap = <String, SubstitutionEntry>{};
    
    // Helper to add substitutions to map
    void addSubstitutions(ParsedSubstitutionData? data) {
      if (data == null) return;
      final entries = data.getEntriesForClass(className);
      for (final entry in entries) {
        // Key format: "period" (just the period number)
        // Handle period ranges like "1-2"
        final periodParts = entry.period.split('-');
        final startPeriod = int.tryParse(periodParts[0]) ?? 0;
        final endPeriod = periodParts.length > 1 
            ? int.tryParse(periodParts[1]) ?? startPeriod
            : startPeriod;
        
        for (int p = startPeriod; p <= endPeriod; p++) {
          final key = '$p';
          substitutionMap[key] = entry;
        }
      }
    }
    
    addSubstitutions(substitutions.todayData);
    addSubstitutions(substitutions.tomorrowData);

    final periods = List.generate(11, (i) => i + 1);
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: periods.length,
      itemBuilder: (context, index) {
        final period = periods[index];
        return _PeriodRow(
          period: period,
          schedule: schedule,
          substitutionMap: substitutionMap,
          timeInfo: standardLessonTimes[period],
        );
      },
    );
  }
}

/// Single period row with all 5 days
class _PeriodRow extends StatelessWidget {
  final int period;
  final ClassSchedule? schedule;
  final Map<String, SubstitutionEntry> substitutionMap;
  final LessonTime? timeInfo;

  const _PeriodRow({
    required this.period,
    required this.schedule,
    required this.substitutionMap,
    this.timeInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Period number and time
          Container(
            width: 45,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$period.',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (timeInfo != null)
                  Text(
                    timeInfo!.startTime,
                    style: TextStyle(
                      color: AppColors.secondaryText.withAlpha(150),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          // Day cells
          ...List.generate(5, (dayIndex) {
            // Get lesson for this period/day
            ScheduleLesson? lesson;
            if (schedule != null) {
              final dayLessons = schedule!.getLessonsForDay(dayIndex);
              for (final l in dayLessons) {
                if (l.period == period) {
                  lesson = l;
                  break;
                }
              }
            }
            
            // Find substitution using just the period number
            final substitution = substitutionMap['$period'];
            
            return Expanded(
              child: _DayCell(
                lesson: lesson,
                substitution: substitution,
                margin: EdgeInsets.only(left: dayIndex > 0 ? 4 : 0),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Single day cell in the grid
class _DayCell extends StatelessWidget {
  final ScheduleLesson? lesson;
  final SubstitutionEntry? substitution;
  final EdgeInsets margin;

  const _DayCell({
    this.lesson,
    this.substitution,
    required this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final hasLesson = lesson != null && lesson!.subject.isNotEmpty;
    final hasSubstitution = substitution != null && substitution!.period.isNotEmpty;
    
    // Determine display values
    final displaySubject = hasSubstitution && substitution!.subject.isNotEmpty
        ? substitution!.subject
        : (lesson?.subject ?? '');
    final displayTeacher = hasSubstitution && substitution!.substituteTeacher.isNotEmpty
        ? substitution!.substituteTeacher
        : (lesson?.teacher ?? '');
    final displayRoom = hasSubstitution && substitution!.room.isNotEmpty
        ? substitution!.room
        : (lesson?.room ?? '');
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: hasSubstitution 
            ? Color(substitution!.typeColor).withAlpha(40)
            : hasLesson 
                ? AppColors.appSurface 
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: hasSubstitution
            ? Border.all(
                color: Color(substitution!.typeColor),
                width: 1.5,
              )
            : (hasLesson ? Border.all(
                color: AppColors.appSurface.withAlpha(100),
                width: 1,
              ) : null),
      ),
      child: hasLesson || hasSubstitution
          ? Padding(
              padding: const EdgeInsets.all(3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Substitution badge (only if there's actually a substitution)
                  if (hasSubstitution)
                    Container(
                      margin: const EdgeInsets.only(bottom: 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4, 
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Color(substitution!.typeColor),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        _getShortTypeLabel(substitution!.type),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 7,
                        ),
                      ),
                    ),
                  
                  // Subject
                  if (displaySubject.isNotEmpty)
                    Text(
                      displaySubject,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        decoration: hasSubstitution && substitution!.isCancellation
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  
                  // Teacher & Room
                  if (displayTeacher.isNotEmpty || displayRoom.isNotEmpty)
                    Text(
                      '$displayTeacher ${displayRoom.isNotEmpty ? "· $displayRoom" : ""}',
                      style: TextStyle(
                        color: hasSubstitution 
                            ? Color(substitution!.typeColor)
                            : AppColors.secondaryText,
                        fontSize: 8,
                        fontWeight: hasSubstitution ? FontWeight.w500 : null,
                        decoration: hasSubstitution && substitution!.isCancellation
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            )
          : null,
    );
  }
  
  String _getShortTypeLabel(SubstitutionType type) {
    switch (type) {
      case SubstitutionType.substitution:
        return 'Ver';
      case SubstitutionType.cancellation:
        return 'Ent';
      case SubstitutionType.roomChange:
        return 'Raum';
      case SubstitutionType.exchange:
        return 'Tausch';
      case SubstitutionType.relocation:
        return 'Verl';
      case SubstitutionType.supervision:
        return 'Bet';
      case SubstitutionType.specialUnit:
        return 'Sond';
      case SubstitutionType.teacherObservation:
        return 'Lehr';
      case SubstitutionType.unknown:
        return 'Sonst';
    }
  }
}
