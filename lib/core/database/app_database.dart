import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ── Tables ─────────────────────────────────────────────────

class CachedTimetableEntries extends Table {
  TextColumn get id => text()();
  TextColumn get classId => text().named('class_id')();
  TextColumn get subjectId => text().named('subject_id')();
  TextColumn get teacherId => text().named('teacher_id')();
  TextColumn get roomId => text().named('room_id').nullable()();
  TextColumn get timeSlotId => text().named('time_slot_id')();
  IntColumn get dayOfWeek => integer().named('day_of_week')();
  TextColumn get weekType => text().named('week_type').withDefault(const Constant('all'))();
  // Enriched
  TextColumn get subjectName => text().named('subject_name').nullable()();
  TextColumn get subjectAbbreviation => text().named('subject_abbreviation').nullable()();
  TextColumn get subjectColor => text().named('subject_color').nullable()();
  TextColumn get teacherName => text().named('teacher_name').nullable()();
  TextColumn get teacherAbbreviation => text().named('teacher_abbreviation').nullable()();
  TextColumn get roomName => text().named('room_name').nullable()();
  TextColumn get className => text().named('class_name').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedSubstitutions extends Table {
  TextColumn get id => text()();
  TextColumn get timetableEntryId => text().named('timetable_entry_id')();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text()();
  TextColumn get substituteTeacherId => text().named('substitute_teacher_id').nullable()();
  TextColumn get substituteRoomId => text().named('substitute_room_id').nullable()();
  TextColumn get substituteSubjectId => text().named('substitute_subject_id').nullable()();
  TextColumn get note => text().nullable()();
  // Enriched
  TextColumn get originalSubject => text().named('original_subject').nullable()();
  TextColumn get originalTeacher => text().named('original_teacher').nullable()();
  TextColumn get originalRoom => text().named('original_room').nullable()();
  TextColumn get substituteTeacherName => text().named('substitute_teacher_name').nullable()();
  TextColumn get substituteRoomName => text().named('substitute_room_name').nullable()();
  TextColumn get className => text().named('class_name').nullable()();
  TextColumn get timeSlotLabel => text().named('time_slot_label').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedExcuses extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text().named('student_id')();
  DateTimeColumn get dateFrom => dateTime().named('date_from')();
  DateTimeColumn get dateTo => dateTime().named('date_to')();
  TextColumn get submissionType => text().named('submission_type')();
  TextColumn get status => text()();
  TextColumn get reason => text().nullable()();
  BoolColumn get attestationProvided => boolean().named('attestation_provided').withDefault(const Constant(false))();
  DateTimeColumn get submittedAt => dateTime().named('submitted_at')();
  TextColumn get approvedBy => text().named('approved_by').nullable()();
  DateTimeColumn get approvedAt => dateTime().named('approved_at').nullable()();
  TextColumn get studentName => text().named('student_name').nullable()();
  IntColumn get linkedAbsences => integer().named('linked_absences').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedAppointments extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get type => text()();
  TextColumn get scope => text()();
  TextColumn get classId => text().named('class_id').nullable()();
  TextColumn get subjectId => text().named('subject_id').nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get timeSlotId => text().named('time_slot_id').nullable()();
  TextColumn get createdBy => text().named('created_by')();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedLessons extends Table {
  TextColumn get id => text()();
  TextColumn get timetableEntryId => text().named('timetable_entry_id')();
  DateTimeColumn get date => dateTime()();
  TextColumn get topic => text()();
  TextColumn get homework => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get recordedBy => text().named('recorded_by')();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedSubjects extends Table {
  TextColumn get id => text()();
  TextColumn get schoolId => text().named('school_id')();
  TextColumn get name => text()();
  TextColumn get abbreviation => text()();
  TextColumn get color => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedRooms extends Table {
  TextColumn get id => text()();
  TextColumn get schoolId => text().named('school_id')();
  TextColumn get name => text()();
  TextColumn get building => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedTimeSlots extends Table {
  TextColumn get id => text()();
  TextColumn get schoolId => text().named('school_id')();
  IntColumn get slotNumber => integer().named('slot_number')();
  TextColumn get startTime => text().named('start_time')();
  TextColumn get endTime => text().named('end_time')();
  TextColumn get label => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tracks when each table was last synced.
class SyncMeta extends Table {
  TextColumn get syncTable => text().named('table_name')();
  DateTimeColumn get lastSynced => dateTime().named('last_synced')();

  @override
  Set<Column> get primaryKey => {syncTable};
}

// ── Database ───────────────────────────────────────────────

@DriftDatabase(tables: [
  CachedTimetableEntries,
  CachedSubstitutions,
  CachedExcuses,
  CachedAppointments,
  CachedLessons,
  CachedSubjects,
  CachedRooms,
  CachedTimeSlots,
  SyncMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Sync metadata ──

  Future<DateTime?> getLastSynced(String table) async {
    final row = await (select(syncMeta)
          ..where((t) => t.syncTable.equals(table)))
        .getSingleOrNull();
    return row?.lastSynced;
  }

  Future<void> setLastSynced(String table) async {
    await into(syncMeta).insertOnConflictUpdate(SyncMetaCompanion(
      syncTable: Value(table),
      lastSynced: Value(DateTime.now()),
    ));
  }

  // ── Timetable ──

  Future<List<CachedTimetableEntry>> getAllTimetableEntries() =>
      select(cachedTimetableEntries).get();

  Future<void> replaceTimetableEntries(List<CachedTimetableEntriesCompanion> rows) async {
    await transaction(() async {
      await delete(cachedTimetableEntries).go();
      await batch((b) => b.insertAll(cachedTimetableEntries, rows));
      await setLastSynced('timetable');
    });
  }

  // ── Substitutions ──

  Future<List<CachedSubstitution>> getSubstitutionsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(cachedSubstitutions)
          ..where((t) => t.date.isBetweenValues(start, end)))
        .get();
  }

  Future<void> replaceSubstitutions(List<CachedSubstitutionsCompanion> rows) async {
    await transaction(() async {
      await delete(cachedSubstitutions).go();
      await batch((b) => b.insertAll(cachedSubstitutions, rows));
      await setLastSynced('substitutions');
    });
  }

  // ── Excuses ──

  Future<List<CachedExcuse>> getExcusesByStatus(String? status) {
    final q = select(cachedExcuses);
    if (status != null) {
      q.where((t) => t.status.equals(status));
    }
    return q.get();
  }

  Future<void> replaceExcuses(List<CachedExcusesCompanion> rows) async {
    await transaction(() async {
      await delete(cachedExcuses).go();
      await batch((b) => b.insertAll(cachedExcuses, rows));
      await setLastSynced('excuses');
    });
  }

  // ── Appointments ──

  Future<List<CachedAppointment>> getAllAppointments() =>
      select(cachedAppointments).get();

  Future<void> replaceAppointments(List<CachedAppointmentsCompanion> rows) async {
    await transaction(() async {
      await delete(cachedAppointments).go();
      await batch((b) => b.insertAll(cachedAppointments, rows));
      await setLastSynced('appointments');
    });
  }

  // ── Lessons ──

  Future<List<CachedLesson>> getAllLessons() =>
      select(cachedLessons).get();

  Future<void> replaceLessons(List<CachedLessonsCompanion> rows) async {
    await transaction(() async {
      await delete(cachedLessons).go();
      await batch((b) => b.insertAll(cachedLessons, rows));
      await setLastSynced('lessons');
    });
  }

  // ── Reference data ──

  Future<void> replaceSubjects(List<CachedSubjectsCompanion> rows) async {
    await transaction(() async {
      await delete(cachedSubjects).go();
      await batch((b) => b.insertAll(cachedSubjects, rows));
      await setLastSynced('subjects');
    });
  }

  Future<void> replaceRooms(List<CachedRoomsCompanion> rows) async {
    await transaction(() async {
      await delete(cachedRooms).go();
      await batch((b) => b.insertAll(cachedRooms, rows));
      await setLastSynced('rooms');
    });
  }

  Future<void> replaceTimeSlots(List<CachedTimeSlotsCompanion> rows) async {
    await transaction(() async {
      await delete(cachedTimeSlots).go();
      await batch((b) => b.insertAll(cachedTimeSlots, rows));
      await setLastSynced('time_slots');
    });
  }

  Future<List<CachedSubject>> getAllSubjects() => select(cachedSubjects).get();
  Future<List<CachedRoom>> getAllRooms() => select(cachedRooms).get();
  Future<List<CachedTimeSlot>> getAllTimeSlots() => select(cachedTimeSlots).get();

  // ── Clear all ──

  Future<void> clearAll() async {
    await transaction(() async {
      await delete(cachedTimetableEntries).go();
      await delete(cachedSubstitutions).go();
      await delete(cachedExcuses).go();
      await delete(cachedAppointments).go();
      await delete(cachedLessons).go();
      await delete(cachedSubjects).go();
      await delete(cachedRooms).go();
      await delete(cachedTimeSlots).go();
      await delete(syncMeta).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'eduko.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
