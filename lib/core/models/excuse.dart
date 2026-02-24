import 'package:json_annotation/json_annotation.dart';

part 'excuse.g.dart';

enum ExcuseStatus {
  @JsonValue('pending') pending,
  @JsonValue('approved') approved,
  @JsonValue('rejected') rejected,
}

enum ExcuseSubmission {
  @JsonValue('digital') digital,
  @JsonValue('paper') paper,
}

@JsonSerializable()
class Excuse {
  final String id;
  @JsonKey(name: 'student_id') final String studentId;
  @JsonKey(name: 'date_from') final DateTime dateFrom;
  @JsonKey(name: 'date_to') final DateTime dateTo;
  @JsonKey(name: 'submission_type') final ExcuseSubmission submissionType;
  final ExcuseStatus status;
  final String? reason;
  @JsonKey(name: 'attestation_provided') final bool attestationProvided;
  @JsonKey(name: 'file_path') final String? filePath;
  @JsonKey(name: 'submitted_at') final DateTime submittedAt;
  @JsonKey(name: 'approved_by') final String? approvedBy;
  @JsonKey(name: 'approved_at') final DateTime? approvedAt;

  // Enriched
  final String? studentName;
  @JsonKey(name: 'linked_absences') final int? linkedAbsences;

  const Excuse({
    required this.id,
    required this.studentId,
    required this.dateFrom,
    required this.dateTo,
    required this.submissionType,
    required this.status,
    this.reason,
    this.attestationProvided = false,
    this.filePath,
    required this.submittedAt,
    this.approvedBy,
    this.approvedAt,
    this.studentName,
    this.linkedAbsences,
  });

  factory Excuse.fromJson(Map<String, dynamic> json) => _$ExcuseFromJson(json);
  Map<String, dynamic> toJson() => _$ExcuseToJson(this);
}
