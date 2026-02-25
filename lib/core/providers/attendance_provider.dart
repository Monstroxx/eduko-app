import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../models/attendance.dart';

/// Currently selected class for attendance recording.
final attendanceClassIdProvider = StateProvider<String?>((ref) => null);

/// Currently selected date for attendance.
final attendanceDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Class attendance records for the selected class + date.
final classAttendanceProvider =
    FutureProvider.autoDispose<List<Attendance>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final classId = ref.watch(attendanceClassIdProvider);
  final date = ref.watch(attendanceDateProvider);

  if (classId == null) return [];

  final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final response = await api.getClassAttendance(classId, date: dateStr);

  final list = response.data as List;
  return list.map((e) => Attendance.fromJson(e as Map<String, dynamic>)).toList();
});

/// Record or update attendance. Returns updated list via invalidation.
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
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await api.recordAttendance({
      'student_id': studentId,
      'timetable_entry_id': timetableEntryId,
      'date': dateStr,
      'status': status.name,
      if (note != null) 'note': note,
    });
    ref.invalidate(classAttendanceProvider);
  }

  Future<void> recordBatch({
    required String timetableEntryId,
    required DateTime date,
    required List<Map<String, dynamic>> records,
  }) async {
    final api = ref.read(apiServiceProvider);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await api.recordAttendanceBatch({
      'timetable_entry_id': timetableEntryId,
      'date': dateStr,
      'records': records,
    });
    ref.invalidate(classAttendanceProvider);
  }
}

final attendanceActionsProvider = Provider<AttendanceActions>((ref) {
  return AttendanceActions(ref);
});
