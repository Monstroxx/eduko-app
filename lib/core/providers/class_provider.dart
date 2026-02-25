import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../models/school_class.dart';
import '../models/student.dart';

/// All classes for the school.
final classesProvider =
    FutureProvider.autoDispose<List<SchoolClass>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getClasses();

  final list = response.data as List;
  return list.map((e) => SchoolClass.fromJson(e as Map<String, dynamic>)).toList();
});

/// Students in a specific class.
final classStudentsProvider =
    FutureProvider.autoDispose.family<List<Student>, String>((ref, classId) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getClassStudents(classId);

  final list = response.data as List;
  return list.map((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
});
