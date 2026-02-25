import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../models/lesson_content.dart';

/// Filter: class for lessons view.
final lessonClassFilterProvider = StateProvider<String?>((ref) => null);

/// Lesson content entries.
final lessonsProvider =
    FutureProvider.autoDispose<List<LessonContent>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final classId = ref.watch(lessonClassFilterProvider);

  final response = await api.getLessons(classId: classId);

  final list = response.data as List;
  return list.map((e) => LessonContent.fromJson(e as Map<String, dynamic>)).toList();
});

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
    ref.invalidate(lessonsProvider);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final api = ref.read(apiServiceProvider);
    await api.updateLesson(id, data);
    ref.invalidate(lessonsProvider);
  }
}

final lessonActionsProvider = Provider<LessonActions>((ref) {
  return LessonActions(ref);
});
