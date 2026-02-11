// Copyright Luka Löhr 2026

import '../domain/schedule_models.dart';

/// Mock schedule data for class 5a
/// Based on the actual PDF schedule
class ScheduleMockData {
  /// Get mock schedule for class 5a
  static SchoolSchedule getMockSchedule() {
    return SchoolSchedule(
      schoolYear: '2025-2026',
      lastUpdated: DateTime.now(),
      classSchedules: {
        '5a': _getClass5aSchedule(),
      },
    );
  }

  /// Class 5a schedule based on PDF
  static ClassSchedule _getClass5aSchedule() {
    return ClassSchedule(
      className: '5a',
      classTeachers: ['Blum', 'Weber'],
      lessons: [
        // MONTAG
        ScheduleLesson(
          period: 1,
          subject: 'kR',
          teacher: 'Cop',
          room: '201',
          dayIndex: 0,
          timeInfo: const LessonTime(startTime: '08:00', endTime: '08:45'),
        ),
        ScheduleLesson(
          period: 1,
          subject: 'eR',
          teacher: 'Zil',
          room: '211',
          dayIndex: 0,
          timeInfo: const LessonTime(startTime: '08:00', endTime: '08:45'),
        ),
        ScheduleLesson(
          period: 1,
          subject: 'eth',
          teacher: 'Shn',
          room: '110',
          dayIndex: 0,
          timeInfo: const LessonTime(startTime: '08:00', endTime: '08:45'),
        ),
        ScheduleLesson(
          period: 2,
          subject: 'E',
          teacher: 'Hum',
          room: '109',
          dayIndex: 0,
          timeInfo: const LessonTime(startTime: '08:55', endTime: '09:40'),
        ),
        ScheduleLesson(
          period: 3,
          subject: 'Geo',
          teacher: 'Kop',
          room: '109',
          dayIndex: 0,
          timeInfo: const LessonTime(startTime: '09:50', endTime: '10:35'),
        ),
        ScheduleLesson(
          period: 4,
          subject: 'D',
          teacher: 'Blm',
          room: '109',
          dayIndex: 0,
          timeInfo: const LessonTime(startTime: '10:55', endTime: '11:40'),
        ),
        ScheduleLesson(
          period: 5,
          subject: 'D',
          teacher: 'Blm',
          room: '109',
          dayIndex: 0,
          timeInfo: const LessonTime(startTime: '11:50', endTime: '12:35'),
        ),
        ScheduleLesson(
          period: 6,
          subject: 'KL',
          teacher: 'Blm',
          room: '109',
          dayIndex: 0,
          timeInfo: const LessonTime(startTime: '12:45', endTime: '13:30'),
        ),

        // DIENSTAG
        ScheduleLesson(
          period: 1,
          subject: 'E',
          teacher: 'Hum',
          room: '109',
          dayIndex: 1,
          timeInfo: const LessonTime(startTime: '08:00', endTime: '08:45'),
        ),
        ScheduleLesson(
          period: 2,
          subject: 'D',
          teacher: 'Blm',
          room: '109',
          dayIndex: 1,
          timeInfo: const LessonTime(startTime: '08:55', endTime: '09:40'),
        ),
        ScheduleLesson(
          period: 3,
          subject: 'Spo',
          teacher: 'Bm',
          room: 'EBad1',
          dayIndex: 1,
          timeInfo: const LessonTime(startTime: '09:50', endTime: '10:35'),
        ),
        ScheduleLesson(
          period: 3,
          subject: '.Swi',
          teacher: 'Bur',
          room: 'EBad2',
          dayIndex: 1,
          timeInfo: const LessonTime(startTime: '09:50', endTime: '10:35'),
        ),
        ScheduleLesson(
          period: 4,
          subject: 'M',
          teacher: 'Web',
          room: '109',
          dayIndex: 1,
          timeInfo: const LessonTime(startTime: '10:55', endTime: '11:40'),
        ),
        ScheduleLesson(
          period: 5,
          subject: 'M',
          teacher: 'Web',
          room: '109',
          dayIndex: 1,
          timeInfo: const LessonTime(startTime: '11:50', endTime: '12:35'),
        ),
        ScheduleLesson(
          period: 6,
          subject: 'KL',
          teacher: 'Blm',
          room: '109',
          dayIndex: 1,
          timeInfo: const LessonTime(startTime: '12:45', endTime: '13:30'),
        ),
        ScheduleLesson(
          period: 6,
          subject: 'KL',
          teacher: 'Web',
          room: '109',
          dayIndex: 1,
          timeInfo: const LessonTime(startTime: '12:45', endTime: '13:30'),
        ),

        // MITTWOCH
        ScheduleLesson(
          period: 1,
          subject: 'E',
          teacher: 'Hum',
          room: '109',
          dayIndex: 2,
          timeInfo: const LessonTime(startTime: '08:00', endTime: '08:45'),
        ),
        ScheduleLesson(
          period: 2,
          subject: 'Hum',
          teacher: 'Smi',
          room: '109',
          dayIndex: 2,
          timeInfo: const LessonTime(startTime: '08:55', endTime: '09:40'),
        ),
        ScheduleLesson(
          period: 3,
          subject: 'Bio',
          teacher: 'Len',
          room: 'NWT1',
          dayIndex: 2,
          timeInfo: const LessonTime(startTime: '09:50', endTime: '10:35'),
        ),
        ScheduleLesson(
          period: 4,
          subject: 'M',
          teacher: 'Web',
          room: '109',
          dayIndex: 2,
          timeInfo: const LessonTime(startTime: '10:55', endTime: '11:40'),
        ),
        ScheduleLesson(
          period: 5,
          subject: 'D',
          teacher: 'Blm',
          room: '109',
          dayIndex: 2,
          timeInfo: const LessonTime(startTime: '11:50', endTime: '12:35'),
        ),
        ScheduleLesson(
          period: 6,
          subject: 'Blm',
          teacher: '109',
          room: '',
          dayIndex: 2,
          timeInfo: const LessonTime(startTime: '12:45', endTime: '13:30'),
        ),

        // DONNERSTAG
        ScheduleLesson(
          period: 1,
          subject: 'Mus',
          teacher: 'Smi',
          room: 'MUSIK',
          dayIndex: 3,
          timeInfo: const LessonTime(startTime: '08:00', endTime: '08:45'),
        ),
        ScheduleLesson(
          period: 2,
          subject: 'M',
          teacher: 'Sir',
          room: 'BKOG',
          dayIndex: 3,
          timeInfo: const LessonTime(startTime: '08:55', endTime: '09:40'),
        ),
        ScheduleLesson(
          period: 3,
          subject: 'Bk',
          teacher: 'Bm',
          room: 'WB1',
          dayIndex: 3,
          timeInfo: const LessonTime(startTime: '09:50', endTime: '10:35'),
        ),
        ScheduleLesson(
          period: 4,
          subject: 'E',
          teacher: 'Web',
          room: '109',
          dayIndex: 3,
          timeInfo: const LessonTime(startTime: '10:55', endTime: '11:40'),
        ),
        ScheduleLesson(
          period: 5,
          subject: 'E',
          teacher: 'Web',
          room: '109',
          dayIndex: 3,
          timeInfo: const LessonTime(startTime: '11:50', endTime: '12:35'),
        ),
        ScheduleLesson(
          period: 6,
          subject: 'Sir',
          teacher: 'BKOG',
          room: '',
          dayIndex: 3,
          timeInfo: const LessonTime(startTime: '12:45', endTime: '13:30'),
        ),

        // FREITAG
        ScheduleLesson(
          period: 1,
          subject: 'Spo',
          teacher: 'Bm',
          room: 'WB1',
          dayIndex: 4,
          timeInfo: const LessonTime(startTime: '08:00', endTime: '08:45'),
        ),
        ScheduleLesson(
          period: 2,
          subject: 'M',
          teacher: 'Web',
          room: '109',
          dayIndex: 4,
          timeInfo: const LessonTime(startTime: '08:55', endTime: '09:40'),
        ),
        ScheduleLesson(
          period: 3,
          subject: 'E',
          teacher: 'Hum',
          room: '109',
          dayIndex: 4,
          timeInfo: const LessonTime(startTime: '09:50', endTime: '10:35'),
        ),
        ScheduleLesson(
          period: 4,
          subject: 'Hum',
          teacher: 'Web',
          room: '109',
          dayIndex: 4,
          timeInfo: const LessonTime(startTime: '10:55', endTime: '11:40'),
        ),
        ScheduleLesson(
          period: 5,
          subject: 'M',
          teacher: 'Web',
          room: '109',
          dayIndex: 4,
          timeInfo: const LessonTime(startTime: '11:50', endTime: '12:35'),
        ),
        ScheduleLesson(
          period: 6,
          subject: 'Web',
          teacher: '109',
          room: '',
          dayIndex: 4,
          timeInfo: const LessonTime(startTime: '12:45', endTime: '13:30'),
        ),
      ],
    );
  }
}
