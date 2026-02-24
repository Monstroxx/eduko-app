import 'package:json_annotation/json_annotation.dart';

part 'teacher.g.dart';

@JsonSerializable()
class Teacher {
  final String id;
  @JsonKey(name: 'user_id') final String userId;
  @JsonKey(name: 'school_id') final String schoolId;
  final String abbreviation;

  const Teacher({
    required this.id,
    required this.userId,
    required this.schoolId,
    required this.abbreviation,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) => _$TeacherFromJson(json);
  Map<String, dynamic> toJson() => _$TeacherToJson(this);
}
