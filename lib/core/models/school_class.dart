import 'package:json_annotation/json_annotation.dart';

part 'school_class.g.dart';

@JsonSerializable()
class SchoolClass {
  final String id;
  @JsonKey(name: 'school_id') final String schoolId;
  final String name;
  @JsonKey(name: 'grade_level') final int? gradeLevel;
  @JsonKey(name: 'class_teacher_id') final String? classTeacherId;
  @JsonKey(name: 'school_year') final String schoolYear;

  const SchoolClass({
    required this.id,
    required this.schoolId,
    required this.name,
    this.gradeLevel,
    this.classTeacherId,
    required this.schoolYear,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) => _$SchoolClassFromJson(json);
  Map<String, dynamic> toJson() => _$SchoolClassToJson(this);
}
