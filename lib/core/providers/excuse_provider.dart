import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../models/excuse.dart';

/// Filter state for excuse list.
final excuseStatusFilterProvider = StateProvider<ExcuseStatus?>((ref) => null);
final excuseClassFilterProvider = StateProvider<String?>((ref) => null);

/// All excuses (filtered by current filters).
final excusesProvider =
    FutureProvider.autoDispose<List<Excuse>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final statusFilter = ref.watch(excuseStatusFilterProvider);
  final classFilter = ref.watch(excuseClassFilterProvider);

  final response = await api.getExcuses(
    status: statusFilter?.name,
    classId: classFilter,
  );

  final list = response.data as List;
  return list.map((e) => Excuse.fromJson(e as Map<String, dynamic>)).toList();
});

/// Single excuse detail.
final excuseDetailProvider =
    FutureProvider.autoDispose.family<Excuse, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.getExcuse(id);
  return Excuse.fromJson(response.data as Map<String, dynamic>);
});

class ExcuseActions {
  final Ref ref;
  ExcuseActions(this.ref);

  Future<Excuse> create({
    required String studentId,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String submissionType,
    String? reason,
    bool attestationProvided = false,
  }) async {
    final api = ref.read(apiServiceProvider);
    final response = await api.createExcuse({
      'student_id': studentId,
      'date_from': dateFrom.toIso8601String(),
      'date_to': dateTo.toIso8601String(),
      'submission_type': submissionType,
      if (reason != null) 'reason': reason,
      'attestation_provided': attestationProvided,
    });
    ref.invalidate(excusesProvider);
    return Excuse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> approve(String id, {String? note}) async {
    final api = ref.read(apiServiceProvider);
    await api.approveExcuse(id, note: note);
    ref.invalidate(excusesProvider);
    ref.invalidate(excuseDetailProvider(id));
  }

  Future<void> reject(String id, String reason) async {
    final api = ref.read(apiServiceProvider);
    await api.rejectExcuse(id, reason);
    ref.invalidate(excusesProvider);
    ref.invalidate(excuseDetailProvider(id));
  }
}

final excuseActionsProvider = Provider<ExcuseActions>((ref) {
  return ExcuseActions(ref);
});
