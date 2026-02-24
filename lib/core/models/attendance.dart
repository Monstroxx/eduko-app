import 'package:json_annotation/json_annotation.dart';

part 'attendance.g.dart';

enum AttendanceStatus {
  @JsonValue('present') present,
  @JsonValue('absent') absent,
  @JsonValue('late') late_,
  @JsonValue('excused_leave') excusedLeave,
}

@JsonSerializable()
class Attendance {
  final String id;
  @JsonKey(name: 'student_id') final String studentId;
  @JsonKey(name: 'timetable_entry_id') final String timetableEntryId;
  final DateTime date;
  final AttendanceStatus status;
  @JsonKey(name: 'recorded_by') final String recordedBy;
  final String? note;

  // Enriched
  final String? studentName;

  const Attendance({
    required this.id,
    required this.studentId,
    required this.timetableEntryId,
    required this.date,
    required this.status,
    required this.recordedBy,
    this.note,
    this.studentName,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => _$AttendanceFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceToJson(this);
}
