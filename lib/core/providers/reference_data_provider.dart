import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/sync_service.dart';
import '../models/subject.dart';
import '../models/room.dart';
import '../models/time_slot.dart';

/// Subjects — offline-first.
final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncServiceProvider);

  sync.syncSubjects().ignore();

  final cached = await db.getAllSubjects();
  if (cached.isEmpty) {
    await sync.syncSubjects(force: true);
    final fresh = await db.getAllSubjects();
    return fresh
        .map((c) => Subject(
              id: c.id,
              schoolId: c.schoolId,
              name: c.name,
              abbreviation: c.abbreviation,
              color: c.color,
            ))
        .toList();
  }

  return cached
      .map((c) => Subject(
            id: c.id,
            schoolId: c.schoolId,
            name: c.name,
            abbreviation: c.abbreviation,
            color: c.color,
          ))
      .toList();
});

/// Rooms — offline-first.
final roomsProvider = FutureProvider<List<Room>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncServiceProvider);

  sync.syncRooms().ignore();

  final cached = await db.getAllRooms();
  if (cached.isEmpty) {
    await sync.syncRooms(force: true);
    final fresh = await db.getAllRooms();
    return fresh
        .map((c) => Room(id: c.id, schoolId: c.schoolId, name: c.name, building: c.building))
        .toList();
  }

  return cached
      .map((c) => Room(id: c.id, schoolId: c.schoolId, name: c.name, building: c.building))
      .toList();
});

/// Time slots — offline-first.
final timeSlotsProvider = FutureProvider<List<TimeSlot>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncServiceProvider);

  sync.syncTimeSlots().ignore();

  final cached = await db.getAllTimeSlots();
  if (cached.isEmpty) {
    await sync.syncTimeSlots(force: true);
    final fresh = await db.getAllTimeSlots();
    return fresh
        .map((c) => TimeSlot(
              id: c.id,
              schoolId: c.schoolId,
              slotNumber: c.slotNumber,
              startTime: c.startTime,
              endTime: c.endTime,
              label: c.label,
            ))
        .toList();
  }

  return cached
      .map((c) => TimeSlot(
            id: c.id,
            schoolId: c.schoolId,
            slotNumber: c.slotNumber,
            startTime: c.startTime,
            endTime: c.endTime,
            label: c.label,
          ))
      .toList();
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
