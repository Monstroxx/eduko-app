import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../models/models.dart';
import 'app_database.dart';

/// How stale data can be before we force a re-sync (5 minutes).
const _staleDuration = Duration(minutes: 5);

/// Handles API → local SQLite sync for offline-first data.
class SyncService {
  final AppDatabase _db;
  final ApiService _api;

  SyncService(this._db, this._api);

  /// Sync everything (called on login / pull-to-refresh).
  Future<void> syncAll() async {
    await Future.wait([
      syncTimetable(),
      syncSubstitutions(),
      syncSubjects(),
      syncRooms(),
      syncTimeSlots(),
      syncExcuses(),
      syncAppointments(),
      syncLessons(),
    ]);
  }

  /// Returns true if table needs sync.
  Future<bool> _needsSync(String table) async {
    final last = await _db.getLastSynced(table);
    if (last == null) return true;
    return DateTime.now().difference(last) > _staleDuration;
  }

  // ── Timetable ──

  Future<void> syncTimetable({bool force = false}) async {
    if (!force && !await _needsSync('timetable')) return;
    final response = await _api.getTimetable();
    final list = (response.data as List)
        .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    await _db.replaceTimetableEntries(list.map((e) => CachedTimetableEntriesCompanion(
      id: Value(e.id),
      classId: Value(e.classId),
      subjectId: Value(e.subjectId),
      teacherId: Value(e.teacherId),
      roomId: Value(e.roomId),
      timeSlotId: Value(e.timeSlotId),
      dayOfWeek: Value(e.dayOfWeek),
      weekType: Value(e.weekType.name),
      subjectName: Value(e.subjectName),
      subjectAbbreviation: Value(e.subjectAbbreviation),
      subjectColor: Value(e.subjectColor),
      teacherName: Value(e.teacherName),
      teacherAbbreviation: Value(e.teacherAbbreviation),
      roomName: Value(e.roomName),
      className: Value(e.className),
      timeSlotLabel: Value(e.timeSlotLabel),
      timeSlotStart: Value(e.timeSlotStart),
      timeSlotEnd: Value(e.timeSlotEnd),
    )).toList());
  }

  // ── Substitutions ──

  Future<void> syncSubstitutions({DateTime? date, bool force = false}) async {
    if (!force && !await _needsSync('substitutions')) return;
    final d = date ?? DateTime.now();
    final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final response = await _api.getSubstitutions(date: dateStr);
    final data = response.data;
    final list = data is List
        ? data.map((e) => Substitution.fromJson(e as Map<String, dynamic>)).toList()
        : <Substitution>[];

    await _db.replaceSubstitutions(list.map((e) => CachedSubstitutionsCompanion(
      id: Value(e.id),
      timetableEntryId: Value(e.timetableEntryId),
      date: Value(e.date),
      type: Value(e.type.name),
      substituteTeacherId: Value(e.substituteTeacherId),
      substituteRoomId: Value(e.substituteRoomId),
      substituteSubjectId: Value(e.substituteSubjectId),
      note: Value(e.note),
      originalSubject: Value(e.originalSubject),
      originalTeacher: Value(e.originalTeacher),
      originalRoom: Value(e.originalRoom),
      substituteTeacherName: Value(e.substituteTeacherName),
      substituteRoomName: Value(e.substituteRoomName),
      className: Value(e.className),
      timeSlotLabel: Value(e.timeSlotLabel),
    )).toList());
  }

  // ── Excuses ──

  Future<void> syncExcuses({bool force = false}) async {
    if (!force && !await _needsSync('excuses')) return;
    final response = await _api.getExcuses();
    final list = (response.data as List)
        .map((e) => Excuse.fromJson(e as Map<String, dynamic>))
        .toList();

    await _db.replaceExcuses(list.map((e) => CachedExcusesCompanion(
      id: Value(e.id),
      studentId: Value(e.studentId),
      dateFrom: Value(e.dateFrom),
      dateTo: Value(e.dateTo),
      submissionType: Value(e.submissionType.name),
      status: Value(e.status.name),
      reason: Value(e.reason),
      attestationProvided: Value(e.attestationProvided),
      submittedAt: Value(e.submittedAt),
      approvedBy: Value(e.approvedBy),
      approvedAt: Value(e.approvedAt),
      studentName: Value(e.studentName),
      linkedAbsences: Value(e.linkedAbsences),
    )).toList());
  }

  // ── Appointments ──

  Future<void> syncAppointments({bool force = false}) async {
    if (!force && !await _needsSync('appointments')) return;
    final response = await _api.getAppointments();
    final list = (response.data as List)
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();

    await _db.replaceAppointments(list.map((e) => CachedAppointmentsCompanion(
      id: Value(e.id),
      title: Value(e.title),
      description: Value(e.description),
      type: Value(e.type.name),
      scope: Value(e.scope.name),
      classId: Value(e.classId),
      subjectId: Value(e.subjectId),
      date: Value(e.date),
      timeSlotId: Value(e.timeSlotId),
      createdBy: Value(e.createdBy),
    )).toList());
  }

  // ── Lessons ──

  Future<void> syncLessons({bool force = false}) async {
    if (!force && !await _needsSync('lessons')) return;
    final response = await _api.getLessons();
    final list = (response.data as List)
        .map((e) => LessonContent.fromJson(e as Map<String, dynamic>))
        .toList();

    await _db.replaceLessons(list.map((e) => CachedLessonsCompanion(
      id: Value(e.id),
      timetableEntryId: Value(e.timetableEntryId),
      date: Value(e.date),
      topic: Value(e.topic),
      homework: Value(e.homework),
      notes: Value(e.notes),
      recordedBy: Value(e.recordedBy),
    )).toList());
  }

  // ── Reference data ──

  Future<void> syncSubjects({bool force = false}) async {
    if (!force && !await _needsSync('subjects')) return;
    final response = await _api.getSubjects();
    final list = (response.data as List)
        .map((e) => Subject.fromJson(e as Map<String, dynamic>))
        .toList();

    await _db.replaceSubjects(list.map((e) => CachedSubjectsCompanion(
      id: Value(e.id),
      schoolId: Value(e.schoolId),
      name: Value(e.name),
      abbreviation: Value(e.abbreviation),
      color: Value(e.color),
    )).toList());
  }

  Future<void> syncRooms({bool force = false}) async {
    if (!force && !await _needsSync('rooms')) return;
    final response = await _api.getRooms();
    final list = (response.data as List)
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();

    await _db.replaceRooms(list.map((e) => CachedRoomsCompanion(
      id: Value(e.id),
      schoolId: Value(e.schoolId),
      name: Value(e.name),
      building: Value(e.building),
    )).toList());
  }

  Future<void> syncTimeSlots({bool force = false}) async {
    if (!force && !await _needsSync('time_slots')) return;
    final response = await _api.getTimeSlots();
    final list = (response.data as List)
        .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
        .toList();

    await _db.replaceTimeSlots(list.map((e) => CachedTimeSlotsCompanion(
      id: Value(e.id),
      schoolId: Value(e.schoolId),
      slotNumber: Value(e.slotNumber),
      startTime: Value(e.startTime),
      endTime: Value(e.endTime),
      label: Value(e.label),
    )).toList());
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(apiServiceProvider),
  );
});
