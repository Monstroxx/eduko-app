import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../models/subject.dart';
import '../models/room.dart';
import '../models/time_slot.dart';

/// Subjects list (cached, rarely changes).
final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getSubjects();
  final list = response.data as List;
  return list.map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList();
});

/// Rooms list.
final roomsProvider = FutureProvider<List<Room>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getRooms();
  final list = response.data as List;
  return list.map((e) => Room.fromJson(e as Map<String, dynamic>)).toList();
});

/// Time slots.
final timeSlotsProvider = FutureProvider<List<TimeSlot>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getTimeSlots();
  final list = response.data as List;
  return list.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>)).toList();
});

/// Lookup helpers.
final subjectByIdProvider = Provider.family<AsyncValue<Subject?>, String>((ref, id) {
  return ref.watch(subjectsProvider).whenData(
    (subjects) => subjects.where((s) => s.id == id).firstOrNull,
  );
});

final roomByIdProvider = Provider.family<AsyncValue<Room?>, String>((ref, id) {
  return ref.watch(roomsProvider).whenData(
    (rooms) => rooms.where((r) => r.id == id).firstOrNull,
  );
});

final timeSlotByIdProvider = Provider.family<AsyncValue<TimeSlot?>, String>((ref, id) {
  return ref.watch(timeSlotsProvider).whenData(
    (slots) => slots.where((s) => s.id == id).firstOrNull,
  );
});
