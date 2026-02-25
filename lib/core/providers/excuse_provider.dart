import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../database/app_database.dart';
import '../database/sync_service.dart';
import '../models/excuse.dart';

/// Filter state for excuse list.
final excuseStatusFilterProvider = StateProvider<ExcuseStatus?>((ref) => null);
final excuseClassFilterProvider = StateProvider<String?>((ref) => null);

/// All excuses — offline-first.
final excusesProvider =
    FutureProvider.autoDispose<List<Excuse>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncServiceProvider);
  final statusFilter = ref.watch(excuseStatusFilterProvider);

  // Background sync.
  sync.syncExcuses().ignore();

  final cached = await db.getExcusesByStatus(statusFilter?.name);
  if (cached.isEmpty) {
    await sync.syncExcuses(force: true);
    final fresh = await db.getExcusesByStatus(statusFilter?.name);
    return fresh.map(_fromCached).toList();
  }
  return cached.map(_fromCached).toList();
});

Excuse _fromCached(CachedExcuse c) => Excuse(
      id: c.id,
      studentId: c.studentId,
      dateFrom: c.dateFrom,
      dateTo: c.dateTo,
      submissionType: ExcuseSubmission.values.firstWhere(
        (v) => v.name == c.submissionType,
        orElse: () => ExcuseSubmission.digital,
      ),
      status: ExcuseStatus.values.firstWhere(
        (v) => v.name == c.status,
        orElse: () => ExcuseStatus.pending,
      ),
      reason: c.reason,
      attestationProvided: c.attestationProvided,
      submittedAt: c.submittedAt,
      approvedBy: c.approvedBy,
      approvedAt: c.approvedAt,
      studentName: c.studentName,
      linkedAbsences: c.linkedAbsences,
    );

/// Single excuse detail (always from API for freshness).
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
    // Force re-sync after mutation.
    await ref.read(syncServiceProvider).syncExcuses(force: true);
    ref.invalidate(excusesProvider);
    return Excuse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> approve(String id, {String? note}) async {
    final api = ref.read(apiServiceProvider);
    await api.approveExcuse(id, note: note);
    await ref.read(syncServiceProvider).syncExcuses(force: true);
    ref.invalidate(excusesProvider);
    ref.invalidate(excuseDetailProvider(id));
  }

  Future<void> reject(String id, String reason) async {
    final api = ref.read(apiServiceProvider);
    await api.rejectExcuse(id, reason);
    await ref.read(syncServiceProvider).syncExcuses(force: true);
    ref.invalidate(excusesProvider);
    ref.invalidate(excuseDetailProvider(id));
  }
}

final excuseActionsProvider = Provider<ExcuseActions>((ref) {
  return ExcuseActions(ref);
});
