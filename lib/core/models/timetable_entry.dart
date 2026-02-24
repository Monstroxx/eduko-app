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

  // Enriched fields (populated by API joins)
  final String? subjectName;
  final String? subjectAbbreviation;
  final String? subjectColor;
  final String? teacherName;
  final String? teacherAbbreviation;
  final String? roomName;
  final String? className;

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
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) =>
      _$TimetableEntryFromJson(json);
  Map<String, dynamic> toJson() => _$TimetableEntryToJson(this);
}
