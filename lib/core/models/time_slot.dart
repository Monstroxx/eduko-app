import 'package:json_annotation/json_annotation.dart';

part 'time_slot.g.dart';

@JsonSerializable()
class TimeSlot {
  final String id;
  @JsonKey(name: 'school_id') final String schoolId;
  @JsonKey(name: 'slot_number') final int slotNumber;
  @JsonKey(name: 'start_time') final String startTime;
  @JsonKey(name: 'end_time') final String endTime;
  final String? label;

  const TimeSlot({
    required this.id,
    required this.schoolId,
    required this.slotNumber,
    required this.startTime,
    required this.endTime,
    this.label,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) => _$TimeSlotFromJson(json);
  Map<String, dynamic> toJson() => _$TimeSlotToJson(this);
}
