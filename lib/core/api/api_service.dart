import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

/// Central API service — thin wrapper around Dio for all Eduko endpoints.
class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  // ── Auth ────────────────────────────────────────────────

  Future<Response> login(String username, String password, String schoolId) =>
      _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
        'school_id': schoolId,
      });

  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register', data: data);

  // ── Timetable ──────────────────────────────────────────

  Future<Response> getTimetable({String? classId, String? teacherId, String? date}) =>
      _dio.get('/timetable', queryParameters: {
        if (classId != null) 'class_id': classId,
        if (teacherId != null) 'teacher_id': teacherId,
        if (date != null) 'date': date,
      });

  // ── Substitutions ──────────────────────────────────────

  Future<Response> getSubstitutions({String? date, String? from, String? to}) =>
      _dio.get('/substitutions', queryParameters: {
        if (date != null) 'date': date,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      });

  // ── Attendance ─────────────────────────────────────────

  Future<Response> recordAttendance(Map<String, dynamic> data) =>
      _dio.post('/attendance', data: data);

  Future<Response> recordAttendanceBatch(Map<String, dynamic> data) =>
      _dio.post('/attendance', data: data);

  Future<Response> updateAttendance(String id, Map<String, dynamic> data) =>
      _dio.put('/attendance/$id', data: data);

  Future<Response> getClassAttendance(String classId, {String? date}) =>
      _dio.get('/attendance/class/$classId', queryParameters: {
        if (date != null) 'date': date,
      });

  // ── Excuses ────────────────────────────────────────────

  Future<Response> createExcuse(Map<String, dynamic> data) =>
      _dio.post('/excuses', data: data);

  Future<Response> getExcuses({String? status, String? studentId, String? classId}) =>
      _dio.get('/excuses', queryParameters: {
        if (status != null) 'status': status,
        if (studentId != null) 'student_id': studentId,
        if (classId != null) 'class_id': classId,
      });

  Future<Response> getExcuse(String id) => _dio.get('/excuses/$id');

  Future<Response> approveExcuse(String id, {String? note}) =>
      _dio.patch('/excuses/$id/approve', data: {if (note != null) 'note': note});

  Future<Response> rejectExcuse(String id, String reason) =>
      _dio.patch('/excuses/$id/reject', data: {'reason': reason});

  Future<Response> uploadExcuseForm(String excuseId, String filePath) {
    final formData = FormData.fromMap({
      'excuse_id': excuseId,
      'file': MultipartFile.fromFileSync(filePath),
    });
    return _dio.post('/excuses/upload', data: formData);
  }

  Future<Response> downloadExcusePdf(String id) =>
      _dio.get('/excuses/$id/pdf', options: Options(responseType: ResponseType.bytes));

  // ── Lessons ────────────────────────────────────────────

  Future<Response> createLesson(Map<String, dynamic> data) =>
      _dio.post('/lessons', data: data);

  Future<Response> updateLesson(String id, Map<String, dynamic> data) =>
      _dio.put('/lessons/$id', data: data);

  Future<Response> getLessons({String? classId, String? subjectId, String? from, String? to}) =>
      _dio.get('/lessons', queryParameters: {
        if (classId != null) 'class_id': classId,
        if (subjectId != null) 'subject_id': subjectId,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      });

  // ── Appointments ───────────────────────────────────────

  Future<Response> getAppointments({String? type, String? classId, String? from, String? to}) =>
      _dio.get('/appointments', queryParameters: {
        if (type != null) 'type': type,
        if (classId != null) 'class_id': classId,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      });

  Future<Response> createAppointment(Map<String, dynamic> data) =>
      _dio.post('/appointments', data: data);

  // ── Students ───────────────────────────────────────────

  Future<Response> getStudents({String? classId}) =>
      _dio.get('/students', queryParameters: {
        if (classId != null) 'class_id': classId,
      });

  Future<Response> getStudent(String id) => _dio.get('/students/$id');

  Future<Response> getStudentAbsences(String id, {String? from, String? to}) =>
      _dio.get('/students/$id/absences', queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      });

  // ── Classes ────────────────────────────────────────────

  Future<Response> getClasses({String? schoolYear}) =>
      _dio.get('/classes', queryParameters: {
        if (schoolYear != null) 'school_year': schoolYear,
      });

  Future<Response> getClassStudents(String classId) =>
      _dio.get('/classes/$classId/students');

  // ── Subjects, Rooms, TimeSlots ─────────────────────────

  Future<Response> getSubjects() => _dio.get('/subjects');
  Future<Response> getRooms() => _dio.get('/rooms');
  Future<Response> getTimeSlots() => _dio.get('/timeslots');

  // ── School Settings ────────────────────────────────────

  Future<Response> getSchoolSettings() => _dio.get('/school/settings');
}
