import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../auth/auth_provider.dart';
import '../models/timetable_entry.dart';

/// Selected date for timetable views.
final timetableSelectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Timetable entries for the current user's class/teacher role.
final timetableEntriesProvider =
    FutureProvider.autoDispose<List<TimetableEntry>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final auth = ref.watch(authProvider);

  final queryParams = <String, String>{};
  if (auth.role == 'teacher') {
    queryParams['teacher_id'] = auth.userId!;
  }
  // Students and admins get all entries for their context (server filters by school).

  final response = await api.getTimetable(
    classId: queryParams['class_id'],
    teacherId: queryParams['teacher_id'],
  );

  final list = response.data as List;
  return list.map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>)).toList();
});

/// Entries grouped by day of week (1=Mon..5=Fri).
final timetableByDayProvider =
    Provider.autoDispose<AsyncValue<Map<int, List<TimetableEntry>>>>((ref) {
  return ref.watch(timetableEntriesProvider).whenData((entries) {
    final map = <int, List<TimetableEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.dayOfWeek, () => []).add(e);
    }
    // Sort each day by timeSlotId (server should return ordered, but just in case).
    for (final day in map.values) {
      day.sort((a, b) => a.timeSlotId.compareTo(b.timeSlotId));
    }
    return map;
  });
});
