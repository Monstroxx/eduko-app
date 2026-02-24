import 'package:json_annotation/json_annotation.dart';

part 'subject.g.dart';

@JsonSerializable()
class Subject {
  final String id;
  @JsonKey(name: 'school_id') final String schoolId;
  final String name;
  final String abbreviation;
  final String? color;

  const Subject({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.abbreviation,
    this.color,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => _$SubjectFromJson(json);
  Map<String, dynamic> toJson() => _$SubjectToJson(this);
}
