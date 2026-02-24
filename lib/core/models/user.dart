import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

enum UserRole {
  @JsonValue('student') student,
  @JsonValue('teacher') teacher,
  @JsonValue('admin') admin,
}

@JsonSerializable()
class User {
  final String id;
  @JsonKey(name: 'school_id') final String schoolId;
  final String? email;
  final String username;
  final UserRole role;
  @JsonKey(name: 'first_name') final String firstName;
  @JsonKey(name: 'last_name') final String lastName;
  final String? locale;
  @JsonKey(name: 'is_active') final bool isActive;

  const User({
    required this.id,
    required this.schoolId,
    this.email,
    required this.username,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.locale,
    this.isActive = true,
  });

  String get displayName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
