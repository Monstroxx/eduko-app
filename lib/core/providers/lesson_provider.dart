import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../database/app_database.dart';
import '../database/sync_service.dart';
import '../models/lesson_content.dart';

/// Filter: class for lessons view.
final lessonClassFilterProvider = StateProvider<String?>((ref) => null);

/// Lesson content — offline-first.
final lessonsProvider =
    FutureProvider.autoDispose<List<LessonContent>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncServiceProvider);

  sync.syncLessons().ignore();

  final cached = await db.getAllLessons();
  if (cached.isEmpty) {
    await sync.syncLessons(force: true);
    final fresh = await db.getAllLessons();
    return fresh.map(_fromCached).toList();
  }
  return cached.map(_fromCached).toList();
});

LessonContent _fromCached(CachedLesson c) => LessonContent(
      id: c.id,
      timetableEntryId: c.timetableEntryId,
      date: c.date,
      topic: c.topic,
      homework: c.homework,
      notes: c.notes,
      recordedBy: c.recordedBy,
    );

class LessonActions {
  final Ref ref;
  LessonActions(this.ref);

  Future<void> create({
    required String timetableEntryId,
    required DateTime date,
    required String topic,
    String? homework,
    String? notes,
  }) async {
    final api = ref.read(apiServiceProvider);
    await api.createLesson({
      'timetable_entry_id': timetableEntryId,
      'date': date.toIso8601String(),
      'topic': topic,
      if (homework != null) 'homework': homework,
      if (notes != null) 'notes': notes,
    });
    await ref.read(syncServiceProvider).syncLessons(force: true);
    ref.invalidate(lessonsProvider);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final api = ref.read(apiServiceProvider);
    await api.updateLesson(id, data);
    await ref.read(syncServiceProvider).syncLessons(force: true);
    ref.invalidate(lessonsProvider);
  }
}

final lessonActionsProvider = Provider<LessonActions>((ref) {
  return LessonActions(ref);
});
