import 'package:json_annotation/json_annotation.dart';

part 'timetable_entry.g.dart';

enum WeekType {
  @JsonValue('all') all,
  @JsonValue('A') a,
  @JsonValue('B') b,
}

@JsonSerializable()
class TimetableEntry {
  final String id;
  @JsonKey(name: 'class_id') final String classId;
  @JsonKey(name: 'subject_id') final String subjectId;
  @JsonKey(name: 'teacher_id') final String teacherId;
  @JsonKey(name: 'room_id') final String? roomId;
  @JsonKey(name: 'time_slot_id') final String timeSlotId;
  @JsonKey(name: 'day_of_week') final int dayOfWeek;
  @JsonKey(name: 'week_type') final WeekType weekType;

  // Enriched fields (joined in by the API — all snake_case from backend)
  @JsonKey(name: 'subject_name')        final String? subjectName;
  @JsonKey(name: 'subject_abbreviation') final String? subjectAbbreviation;
  @JsonKey(name: 'subject_color')       final String? subjectColor;
  @JsonKey(name: 'teacher_name')        final String? teacherName;
  @JsonKey(name: 'teacher_abbreviation') final String? teacherAbbreviation;
  @JsonKey(name: 'room_name')           final String? roomName;
  @JsonKey(name: 'class_name')          final String? className;
  @JsonKey(name: 'time_slot_label')     final String? timeSlotLabel;
  @JsonKey(name: 'time_slot_start')     final String? timeSlotStart;
  @JsonKey(name: 'time_slot_end')       final String? timeSlotEnd;

  const TimetableEntry({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    this.roomId,
    required this.timeSlotId,
    required this.dayOfWeek,
    this.weekType = WeekType.all,
    this.subjectName,
    this.subjectAbbreviation,
    this.subjectColor,
    this.teacherName,
    this.teacherAbbreviation,
    this.roomName,
    this.className,
    this.timeSlotLabel,
    this.timeSlotStart,
    this.timeSlotEnd,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) =>
      _$TimetableEntryFromJson(json);
  Map<String, dynamic> toJson() => _$TimetableEntryToJson(this);
}
