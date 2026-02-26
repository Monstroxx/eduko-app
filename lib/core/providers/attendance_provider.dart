import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../models/attendance.dart';
import '../models/timetable_entry.dart';
import 'timetable_provider.dart';

/// Currently selected class for attendance recording.
final attendanceClassIdProvider = StateProvider<String?>((ref) => null);

/// Currently selected date for attendance.
final attendanceDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Currently selected timetable entry (period) for attendance recording.
final attendancePeriodIdProvider = StateProvider<String?>((ref) => null);

/// Timetable entries for a given classId filtered by weekday of the selected date.
final classDayTimetableProvider =
    FutureProvider.autoDispose<List<TimetableEntry>>((ref) async {
  final classId = ref.watch(attendanceClassIdProvider);
  final date = ref.watch(attendanceDateProvider);
  if (classId == null) return [];

  final all = await ref.watch(timetableEntriesProvider.future);
  return all
      .where((e) => e.classId == classId && e.dayOfWeek == date.weekday)
      .toList();
});

/// Existing attendance records for the selected class + date (may be empty on first run).
final classAttendanceProvider =
    FutureProvider.autoDispose<List<Attendance>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final classId = ref.watch(attendanceClassIdProvider);
  final date = ref.watch(attendanceDateProvider);

  if (classId == null) return [];

  final dateStr =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final response =
      await api.getClassAttendance(classId, date: dateStr);

  final list = response.data as List;
  return list
      .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Record or update attendance for a class period.
class AttendanceActions {
  final Ref ref;
  AttendanceActions(this.ref);

  Future<void> record({
    required String studentId,
    required String timetableEntryId,
    required DateTime date,
    required AttendanceStatus status,
    String? note,
  }) async {
    final api = ref.read(apiServiceProvider);
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await api.recordAttendance({
      'student_id': studentId,
      'timetable_entry_id': timetableEntryId,
      'date': dateStr,
      'status': status.name == 'late_' ? 'late' : status.name,
      if (note != null) 'note': note,
    });
    ref.invalidate(classAttendanceProvider);
  }

  /// Batch-record attendance for a full class period.
  /// Backend expects: { timetable_entry_id, date, entries: [{student_id, status}] }
  Future<int> recordBatch({
    required String timetableEntryId,
    required DateTime date,
    required List<Map<String, dynamic>> entries,
  }) async {
    final api = ref.read(apiServiceProvider);
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await api.recordAttendanceBatch({
      'timetable_entry_id': timetableEntryId,
      'date': dateStr,
      'entries': entries, // key is 'entries', not 'records'
    });
    ref.invalidate(classAttendanceProvider);
    return (response.data as Map<String, dynamic>)['recorded'] as int? ?? 0;
  }
}

final attendanceActionsProvider = Provider<AttendanceActions>((ref) {
  return AttendanceActions(ref);
});
