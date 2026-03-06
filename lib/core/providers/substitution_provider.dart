import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/sync_service.dart';
import '../models/substitution.dart';

/// Selected date for substitutions.
final substitutionDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Substitutions — offline-first.
final substitutionsProvider =
    FutureProvider.autoDispose<List<Substitution>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncServiceProvider);
  final date = ref.watch(substitutionDateProvider);

  // Background sync.
  sync.syncSubstitutions(date: date).ignore();

  final cached = await db.getSubstitutionsByDate(date);
  if (cached.isEmpty) {
    await sync.syncSubstitutions(date: date, force: true);
    final fresh = await db.getSubstitutionsByDate(date);
    return fresh.map(_fromCached).toList();
  }
  return cached.map(_fromCached).toList();
});

/// Substitutions for a specific date as a map: timetableEntryId → Substitution.
/// Used by timetable views to overlay substitution info on entries.
final substitutionMapByDateProvider = FutureProvider.autoDispose
    .family<Map<String, Substitution>, DateTime>((ref, date) async {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncServiceProvider);

  sync.syncSubstitutions(date: date).ignore();

  final cached = await db.getSubstitutionsByDate(date);
  if (cached.isEmpty) {
    await sync.syncSubstitutions(date: date, force: true);
    final fresh = await db.getSubstitutionsByDate(date);
    return {for (final c in fresh) c.timetableEntryId: _fromCached(c)};
  }
  return {for (final c in cached) c.timetableEntryId: _fromCached(c)};
});

Substitution _fromCached(CachedSubstitution c) => Substitution(
      id: c.id,
      timetableEntryId: c.timetableEntryId,
      date: c.date,
      type: SubstitutionType.values.firstWhere(
        (v) => v.name == c.type,
        orElse: () => SubstitutionType.substitution,
      ),
      substituteTeacherId: c.substituteTeacherId,
      substituteRoomId: c.substituteRoomId,
      substituteSubjectId: c.substituteSubjectId,
      note: c.note,
      originalSubject: c.originalSubject,
      originalTeacher: c.originalTeacher,
      originalRoom: c.originalRoom,
      substituteTeacherName: c.substituteTeacherName,
      substituteRoomName: c.substituteRoomName,
      className: c.className,
      timeSlotLabel: c.timeSlotLabel,
    );
