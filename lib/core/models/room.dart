import 'package:json_annotation/json_annotation.dart';

part 'room.g.dart';

@JsonSerializable()
class Room {
  final String id;
  @JsonKey(name: 'school_id') final String schoolId;
  final String name;
  final String? building;

  const Room({
    required this.id,
    required this.schoolId,
    required this.name,
    this.building,
  });

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
  Map<String, dynamic> toJson() => _$RoomToJson(this);
}
