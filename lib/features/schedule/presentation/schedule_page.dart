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

/// Notifier for selected class
class SelectedScheduleClassNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? className) => state = className;
}

/// Selected class provider
final selectedScheduleClassProvider = NotifierProvider<SelectedScheduleClassNotifier, String?>(
  SelectedScheduleClassNotifier.new,
);

/// Notifier for selected day
class SelectedDayIndexNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().weekday - 1;
  void select(int dayIndex) => state = dayIndex;
}

/// Selected day provider (0=Monday, etc.)
final selectedDayIndexProvider = NotifierProvider<SelectedDayIndexNotifier, int>(
  SelectedDayIndexNotifier.new,
);

/// Schedule page with week view and integrated substitutions
class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  @override
  void initState() {
    super.initState();
    // Load schedule data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await scheduleService.loadFromAssets();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedClass = ref.watch(selectedScheduleClassProvider);
    final selectedDay = ref.watch(selectedDayIndexProvider);
    
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
        
        // Day selector
        _DaySelector(
          selectedDay: selectedDay,
          onDaySelected: (dayIndex) {
            HapticService.light();
            ref.read(selectedDayIndexProvider.notifier).select(dayIndex);
          },
        ),
        
        const SizedBox(height: 12),
        
        // Schedule grid
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
              : _ScheduleGrid(
                  className: selectedClass,
                  dayIndex: selectedDay,
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

/// Day selector
class _DaySelector extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  const _DaySelector({
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['Mo', 'Di', 'Mi', 'Do', 'Fr'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(5, (index) {
          final isSelected = selectedDay == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onDaySelected(index),
              child: Container(
                margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : AppColors.appSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    days[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.secondaryText,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
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

/// Schedule grid with lessons and substitutions
class _ScheduleGrid extends StatelessWidget {
  final String className;
  final int dayIndex;
  final ClassSchedule? schedule;
  final SubstitutionProviderState substitutions;

  const _ScheduleGrid({
    required this.className,
    required this.dayIndex,
    required this.schedule,
    required this.substitutions,
  });

  @override
  Widget build(BuildContext context) {
    if (schedule == null) {
      return _MockScheduleGrid(
        className: className,
        dayIndex: dayIndex,
        substitutions: substitutions,
      );
    }

    // Get lessons for selected day
    final dayLessons = schedule!.getLessonsForDay(dayIndex);
    
    // Get substitutions for this class
    final classSubstitutions = <SubstitutionEntry>[];
    if (substitutions.todayData?.hasEntriesForClass(className) ?? false) {
      classSubstitutions.addAll(substitutions.todayData!.getEntriesForClass(className));
    }
    if (substitutions.tomorrowData?.hasEntriesForClass(className) ?? false) {
      classSubstitutions.addAll(substitutions.tomorrowData!.getEntriesForClass(className));
    }

    // Merge lessons with substitutions
    final periods = List.generate(11, (i) => i + 1);
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: periods.length,
      itemBuilder: (context, index) {
        final period = periods[index];
        final lesson = dayLessons.firstWhere(
          (l) => l.period == period,
          orElse: () => ScheduleLesson(
            period: period,
            subject: '',
            teacher: '',
            room: '',
            dayIndex: dayIndex,
            timeInfo: standardLessonTimes[period],
          ),
        );
        
        // Check for substitution
        final substitution = _findSubstitutionForPeriod(period, classSubstitutions);
        
        return _PeriodCard(
          period: period,
          lesson: lesson,
          substitution: substitution,
          timeInfo: standardLessonTimes[period],
        );
      },
    );
  }

  SubstitutionEntry? _findSubstitutionForPeriod(
    int period, 
    List<SubstitutionEntry> substitutions,
  ) {
    for (final entry in substitutions) {
      if (entry.period == period.toString() || entry.period.startsWith('$period-')) {
        return entry;
      }
    }
    return null;
  }
}

/// Mock schedule grid when no data is loaded
class _MockScheduleGrid extends StatelessWidget {
  final String className;
  final int dayIndex;
  final SubstitutionProviderState substitutions;

  const _MockScheduleGrid({
    required this.className,
    required this.dayIndex,
    required this.substitutions,
  });

  @override
  Widget build(BuildContext context) {
    // Get substitutions for this class
    final classSubstitutions = <SubstitutionEntry>[];
    if (substitutions.todayData?.hasEntriesForClass(className) ?? false) {
      classSubstitutions.addAll(substitutions.todayData!.getEntriesForClass(className));
    }
    if (substitutions.tomorrowData?.hasEntriesForClass(className) ?? false) {
      classSubstitutions.addAll(substitutions.tomorrowData!.getEntriesForClass(className));
    }

    final periods = List.generate(11, (i) => i + 1);
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: periods.length,
      itemBuilder: (context, index) {
        final period = periods[index];
        final substitution = _findSubstitutionForPeriod(period, classSubstitutions);
        
        return _PeriodCard(
          period: period,
          lesson: ScheduleLesson(
            period: period,
            subject: '',
            teacher: '',
            room: '',
            dayIndex: dayIndex,
            timeInfo: standardLessonTimes[period],
          ),
          substitution: substitution,
          timeInfo: standardLessonTimes[period],
        );
      },
    );
  }

  SubstitutionEntry? _findSubstitutionForPeriod(
    int period, 
    List<SubstitutionEntry> substitutions,
  ) {
    for (final entry in substitutions) {
      if (entry.period == period.toString() || entry.period.startsWith('$period-')) {
        return entry;
      }
    }
    return null;
  }
}

/// Period card showing lesson and substitution
class _PeriodCard extends StatelessWidget {
  final int period;
  final ScheduleLesson lesson;
  final SubstitutionEntry? substitution;
  final LessonTime? timeInfo;

  const _PeriodCard({
    required this.period,
    required this.lesson,
    this.substitution,
    this.timeInfo,
  });

  @override
  Widget build(BuildContext context) {
    final hasLesson = lesson.subject.isNotEmpty;
    final hasSubstitution = substitution != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Period number and time
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  '$period.',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (timeInfo != null)
                  Text(
                    timeInfo!.startTime,
                    style: TextStyle(
                      color: AppColors.secondaryText.withAlpha(150),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          
          // Lesson card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasSubstitution 
                    ? Color(substitution!.typeColor).withAlpha(30)
                    : hasLesson 
                        ? AppColors.appSurface 
                        : AppColors.appSurface.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
                border: hasSubstitution
                    ? Border.all(
                        color: Color(substitution!.typeColor),
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasLesson) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lesson.subject,
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              decoration: hasSubstitution && substitution!.isCancellation
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (hasSubstitution)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, 
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(substitution!.typeColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              substitution!.typeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasSubstitution && substitution!.substituteTeacher.isNotEmpty
                              ? '${substitution!.substituteTeacher} (statt ${lesson.teacher})'
                              : lesson.teacher,
                          style: TextStyle(
                            color: hasSubstitution 
                                ? Color(substitution!.typeColor)
                                : AppColors.secondaryText,
                            fontSize: 13,
                            fontWeight: hasSubstitution ? FontWeight.w600 : null,
                            decoration: hasSubstitution && substitution!.isCancellation
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.room_outlined,
                          size: 14,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasSubstitution && substitution!.room.isNotEmpty
                              ? substitution!.room
                              : lesson.room,
                          style: TextStyle(
                            color: hasSubstitution && substitution!.room != lesson.room
                                ? Color(substitution!.typeColor)
                                : AppColors.secondaryText,
                            fontSize: 13,
                            fontWeight: hasSubstitution && substitution!.room != lesson.room
                                ? FontWeight.w600 
                                : null,
                          ),
                        ),
                      ],
                    ),
                    if (hasSubstitution && substitution!.text != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                substitution!.text!,
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else if (hasSubstitution) ...[
                    // Show substitution even when no regular lesson
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(substitution!.typeColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            substitution!.typeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${substitution!.subject} - ${substitution!.substituteTeacher} - ${substitution!.room}',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Frei',
                      style: TextStyle(
                        color: AppColors.secondaryText.withAlpha(100),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
