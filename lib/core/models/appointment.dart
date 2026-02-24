import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

enum AppointmentType {
  @JsonValue('exam') exam,
  @JsonValue('test') test,
  @JsonValue('event') event,
  @JsonValue('other') other,
}

enum AppointmentScope {
  @JsonValue('school') school,
  @JsonValue('class') class_,
  @JsonValue('subject') subject,
}

@JsonSerializable()
class Appointment {
  final String id;
  final String title;
  final String? description;
  final AppointmentType type;
  final AppointmentScope scope;
  @JsonKey(name: 'class_id') final String? classId;
  @JsonKey(name: 'subject_id') final String? subjectId;
  final DateTime date;
  @JsonKey(name: 'time_slot_id') final String? timeSlotId;
  @JsonKey(name: 'created_by') final String createdBy;

  const Appointment({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.scope,
    this.classId,
    this.subjectId,
    required this.date,
    this.timeSlotId,
    required this.createdBy,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentToJson(this);
}
