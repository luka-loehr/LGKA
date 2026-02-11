// Copyright Luka Löhr 2026

import '../../substitution/domain/substitution_models.dart';
import '../domain/schedule_models.dart';

/// Mock schedule data for class 5a
/// Based on the actual PDF schedule
class ScheduleMockData {
  /// Get mock schedule for class 5a with substitutions
  static SchoolSchedule getMockSchedule() {
    return SchoolSchedule(
      schoolYear: '2025-2026',
      lastUpdated: DateTime.now(),
      classSchedules: {
        '5a': _getClass5aSchedule(),
      },
    );
  }

  /// Get mock substitutions for class 5a (Wednesday)
  static List<SubstitutionEntry> getMockSubstitutions() {
    return [
      // Wednesday - 2nd period: Math teacher Hum is ill -> Substitution
      SubstitutionEntry(
        type: SubstitutionType.substitution,
        period: '2',
        className: '5a',
        subject: 'M',
        room: '109',
        substituteTeacher: 'Mey',
        originalTeacher: 'Hum',
        originalSubject: 'M',
        originalRoom: '109',
        text: 'Vertretung für Hum',
        rawText: '2 5a Mey M 109 M Hum 109',
      ),
      // Wednesday - 4th period: Cancelled
      SubstitutionEntry(
        type: SubstitutionType.cancellation,
        period: '4',
        className: '5a',
        subject: '',
        room: '',
        substituteTeacher: '',
        originalTeacher: 'Web',
        originalSubject: 'M',
        originalRoom: '109',
        text: 'Entfall wegen Krankheit',
        rawText: '4 5a --- --- --- M Web 109 Entfall',
      ),
      // Thursday - 1st period: Room change
      SubstitutionEntry(
        type: SubstitutionType.roomChange,
        period: '1',
        className: '5a',
        subject: 'Mus',
        room: 'AULA',
        substituteTeacher: 'Smi',
        originalTeacher: 'Smi',
        originalSubject: 'Mus',
        originalRoom: 'MUSIK',
        text: 'Raumänderung',
        rawText: '1 5a Smi Mus AULA Mus Smi MUSIK Raum-Vtr.',
      ),
      // Friday - 3rd period: Relocation
      SubstitutionEntry(
        type: SubstitutionType.relocation,
        period: '3',
        className: '5a',
        subject: 'D',
        room: '201',
        substituteTeacher: 'Hum',
        originalTeacher: 'Hum',
        originalSubject: 'E',
        originalRoom: '109',
        text: 'Verlegung von Mi 3. auf Fr 3.',
        rawText: '3 5a Hum D 201 E Hum 109 Verlegung',
      ),
    ];
  }

  /// Class 5a schedule based on PDF
  static ClassSchedule _getClass5aSchedule() {
    return ClassSchedule(
      className: '5a',
      classTeachers: ['Blum', 'Weber'],
      lessons: [
        // MONTAG
        _lesson(1, 'kR', 'Cop', '201', 0),
        _lesson(2, 'E', 'Hum', '109', 0),
        _lesson(3, 'Geo', 'Kop', '109', 0),
        _lesson(4, 'D', 'Blm', '109', 0),
        _lesson(5, 'D', 'Blm', '109', 0),
        _lesson(6, 'KL', 'Blm', '109', 0),

        // DIENSTAG
        _lesson(1, 'E', 'Hum', '109', 1),
        _lesson(2, 'D', 'Blm', '109', 1),
        _lesson(3, 'Spo', 'Bm', 'EBad1', 1),
        _lesson(4, 'M', 'Web', '109', 1),
        _lesson(5, 'M', 'Web', '109', 1),
        _lesson(6, 'KL', 'Blm', '109', 1),

        // MITTWOCH
        _lesson(1, 'E', 'Hum', '109', 2),
        _lesson(2, 'M', 'Hum', '109', 2),  // Will have substitution
        _lesson(3, 'Bio', 'Len', 'NWT1', 2),
        _lesson(4, 'M', 'Web', '109', 2),  // Will have cancellation
        _lesson(5, 'D', 'Blm', '109', 2),
        _lesson(6, 'KL', 'Blm', '109', 2),

        // DONNERSTAG
        _lesson(1, 'Mus', 'Smi', 'MUSIK', 3),  // Will have room change
        _lesson(2, 'M', 'Sir', 'BKOG', 3),
        _lesson(3, 'Bk', 'Bm', 'WB1', 3),
        _lesson(4, 'E', 'Web', '109', 3),
        _lesson(5, 'E', 'Web', '109', 3),
        _lesson(6, 'KL', 'Sir', 'BKOG', 3),

        // FREITAG
        _lesson(1, 'Spo', 'Bm', 'WB1', 4),
        _lesson(2, 'M', 'Web', '109', 4),
        _lesson(3, 'E', 'Hum', '109', 4),  // Will have relocation
        _lesson(4, 'Hum', 'Web', '109', 4),
        _lesson(5, 'M', 'Web', '109', 4),
        _lesson(6, 'KL', 'Web', '109', 4),
      ],
    );
  }

  static ScheduleLesson _lesson(int period, String subject, String teacher, String room, int dayIndex) {
    return ScheduleLesson(
      period: period,
      subject: subject,
      teacher: teacher,
      room: room,
      dayIndex: dayIndex,
      timeInfo: standardLessonTimes[period],
    );
  }
}

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
