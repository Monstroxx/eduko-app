import 'package:json_annotation/json_annotation.dart';

part 'lesson_content.g.dart';

@JsonSerializable()
class LessonContent {
  final String id;
  @JsonKey(name: 'timetable_entry_id') final String timetableEntryId;
  final DateTime date;
  final String topic;
  final String? homework;
  final String? notes;
  @JsonKey(name: 'recorded_by') final String recordedBy;

  const LessonContent({
    required this.id,
    required this.timetableEntryId,
    required this.date,
    required this.topic,
    this.homework,
    this.notes,
    required this.recordedBy,
  });

  factory LessonContent.fromJson(Map<String, dynamic> json) =>
      _$LessonContentFromJson(json);
  Map<String, dynamic> toJson() => _$LessonContentToJson(this);
}
