import 'package:json_annotation/json_annotation.dart';

part 'substitution.g.dart';

enum SubstitutionType {
  @JsonValue('substitution') substitution,
  @JsonValue('cancellation') cancellation,
  @JsonValue('room_change') roomChange,
  @JsonValue('extra_lesson') extraLesson,
}

@JsonSerializable()
class Substitution {
  final String id;
  @JsonKey(name: 'timetable_entry_id') final String timetableEntryId;
  final DateTime date;
  final SubstitutionType type;
  @JsonKey(name: 'substitute_teacher_id') final String? substituteTeacherId;
  @JsonKey(name: 'substitute_room_id') final String? substituteRoomId;
  @JsonKey(name: 'substitute_subject_id') final String? substituteSubjectId;
  final String? note;

  // Enriched
  final String? originalSubject;
  final String? originalTeacher;
  final String? originalRoom;
  final String? substituteTeacherName;
  final String? substituteRoomName;
  final String? className;
  @JsonKey(name: 'time_slot_label') final String? timeSlotLabel;

  const Substitution({
    required this.id,
    required this.timetableEntryId,
    required this.date,
    required this.type,
    this.substituteTeacherId,
    this.substituteRoomId,
    this.substituteSubjectId,
    this.note,
    this.originalSubject,
    this.originalTeacher,
    this.originalRoom,
    this.substituteTeacherName,
    this.substituteRoomName,
    this.className,
    this.timeSlotLabel,
  });

  factory Substitution.fromJson(Map<String, dynamic> json) =>
      _$SubstitutionFromJson(json);
  Map<String, dynamic> toJson() => _$SubstitutionToJson(this);
}
