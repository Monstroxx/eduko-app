import 'package:json_annotation/json_annotation.dart';

part 'student.g.dart';

@JsonSerializable()
class Student {
  final String id;
  @JsonKey(name: 'user_id') final String userId;
  @JsonKey(name: 'school_id') final String schoolId;
  @JsonKey(name: 'class_id') final String? classId;
  @JsonKey(name: 'date_of_birth') final DateTime dateOfBirth;
  @JsonKey(name: 'is_adult') final bool isAdult;
  @JsonKey(name: 'attestation_required') final bool attestationRequired;

  // Joined from users table
  @JsonKey(name: 'first_name') final String? firstName;
  @JsonKey(name: 'last_name') final String? lastName;
  final String? email;
  final String? username;

  const Student({
    required this.id,
    required this.userId,
    required this.schoolId,
    this.classId,
    required this.dateOfBirth,
    required this.isAdult,
    this.attestationRequired = false,
    this.firstName,
    this.lastName,
    this.email,
    this.username,
  });

  /// Human-readable display name.
  String get displayName {
    if (firstName != null && lastName != null) return '$firstName $lastName';
    if (firstName != null) return firstName!;
    return username ?? id;
  }

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);
  Map<String, dynamic> toJson() => _$StudentToJson(this);
}
