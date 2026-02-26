import 'package:flutter_test/flutter_test.dart';
import 'package:eduko/core/models/timetable_entry.dart';

// Extract the next-lesson logic into a pure testable function
// (mirrors the logic in dashboard_screen.dart _NextLessonCard)
TimetableEntry? findNextLesson(
    List<TimetableEntry> entries, DateTime now) {
  final nowMinutes = now.hour * 60 + now.minute;

  for (final e in entries) {
    if (e.timeSlotStart != null) {
      final parts = e.timeSlotStart!.split(':');
      final slotMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (slotMinutes >= nowMinutes - 30) return e;
    }
  }
  return entries.isEmpty ? null : entries.last;
}

bool allLessonsDone(List<TimetableEntry> entries, DateTime now) {
  final nowMinutes = now.hour * 60 + now.minute;
  return entries.isNotEmpty &&
      entries.every((e) {
        if (e.timeSlotStart == null) return false;
        final parts = e.timeSlotStart!.split(':');
        final slotMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        return slotMinutes < nowMinutes - 30;
      });
}

TimetableEntry _entry(String id, String start) => TimetableEntry(
      id: id,
      classId: 'c1',
      subjectId: 's1',
      teacherId: 't1',
      timeSlotId: 'ts1',
      dayOfWeek: 1,
      subjectName: 'Mathe',
      timeSlotStart: start,
    );

void main() {
  group('findNextLesson', () {
    final entries = [
      _entry('1', '08:00:00'),
      _entry('2', '09:45:00'),
      _entry('3', '11:30:00'),
    ];

    test('before school: returns first lesson', () {
      final now = DateTime(2026, 2, 26, 7, 30);
      expect(findNextLesson(entries, now)?.id, '1');
    });

    test('during first lesson: returns first lesson (within 30 min)', () {
      final now = DateTime(2026, 2, 26, 8, 15);
      expect(findNextLesson(entries, now)?.id, '1');
    });

    test('between lessons: returns next upcoming', () {
      final now = DateTime(2026, 2, 26, 9, 0);
      // 08:00 started >30min ago (60min), 09:45 starts in 45min → return 09:45
      expect(findNextLesson(entries, now)?.id, '2');
    });

    test('during second lesson: returns second lesson', () {
      final now = DateTime(2026, 2, 26, 10, 0);
      // 09:45 is 15min ago → within 30min window
      expect(findNextLesson(entries, now)?.id, '2');
    });

    test('after all lessons: fallback to last', () {
      final now = DateTime(2026, 2, 26, 14, 0);
      // All started >30min ago → fallback
      expect(findNextLesson(entries, now)?.id, '3');
    });

    test('empty list: returns null', () {
      expect(findNextLesson([], DateTime.now()), isNull);
    });
  });

  group('allLessonsDone', () {
    final entries = [
      _entry('1', '08:00:00'),
      _entry('2', '09:45:00'),
    ];

    test('before school: not done', () {
      expect(allLessonsDone(entries, DateTime(2026, 2, 26, 7, 0)), false);
    });

    test('after last lesson ends: done', () {
      // 09:45 + 30min grace = 10:15 → at 14:00 all done
      expect(allLessonsDone(entries, DateTime(2026, 2, 26, 14, 0)), true);
    });

    test('during last lesson: not done', () {
      expect(allLessonsDone(entries, DateTime(2026, 2, 26, 10, 0)), false);
    });

    test('empty list: not done (no lessons to be done)', () {
      expect(allLessonsDone([], DateTime.now()), false);
    });
  });
}
