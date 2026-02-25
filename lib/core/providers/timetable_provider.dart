import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/sync_service.dart';
import '../models/timetable_entry.dart';

/// Selected date for timetable views.
final timetableSelectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Timetable entries — offline-first: reads from local DB, syncs in background.
final timetableEntriesProvider =
    FutureProvider.autoDispose<List<TimetableEntry>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncServiceProvider);

  // Trigger background sync (non-blocking).
  sync.syncTimetable().ignore();

  // Read from local DB.
  final cached = await db.getAllTimetableEntries();

  if (cached.isEmpty) {
    // First load — wait for sync.
    await sync.syncTimetable(force: true);
    final fresh = await db.getAllTimetableEntries();
    return fresh.map(_fromCached).toList();
  }

  return cached.map(_fromCached).toList();
});

TimetableEntry _fromCached(CachedTimetableEntry c) => TimetableEntry(
      id: c.id,
      classId: c.classId,
      subjectId: c.subjectId,
      teacherId: c.teacherId,
      roomId: c.roomId,
      timeSlotId: c.timeSlotId,
      dayOfWeek: c.dayOfWeek,
      weekType: WeekType.values.firstWhere(
        (w) => w.name == c.weekType,
        orElse: () => WeekType.all,
      ),
      subjectName: c.subjectName,
      subjectAbbreviation: c.subjectAbbreviation,
      subjectColor: c.subjectColor,
      teacherName: c.teacherName,
      teacherAbbreviation: c.teacherAbbreviation,
      roomName: c.roomName,
      className: c.className,
    );

/// Entries grouped by day of week (1=Mon..5=Fri).
final timetableByDayProvider =
    Provider.autoDispose<AsyncValue<Map<int, List<TimetableEntry>>>>((ref) {
  return ref.watch(timetableEntriesProvider).whenData((entries) {
    final map = <int, List<TimetableEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.dayOfWeek, () => []).add(e);
    }
    for (final day in map.values) {
      day.sort((a, b) => a.timeSlotId.compareTo(b.timeSlotId));
    }
    return map;
  });
});
