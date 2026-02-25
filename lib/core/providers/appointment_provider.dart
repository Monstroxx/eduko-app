import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../database/app_database.dart';
import '../database/sync_service.dart';
import '../models/appointment.dart';

/// Filter: appointment type.
final appointmentTypeFilterProvider = StateProvider<AppointmentType?>((ref) => null);

/// Appointments — offline-first.
final appointmentsProvider =
    FutureProvider.autoDispose<List<Appointment>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncServiceProvider);

  sync.syncAppointments().ignore();

  final cached = await db.getAllAppointments();
  if (cached.isEmpty) {
    await sync.syncAppointments(force: true);
    final fresh = await db.getAllAppointments();
    return _filterAndMap(fresh, ref.watch(appointmentTypeFilterProvider));
  }
  return _filterAndMap(cached, ref.watch(appointmentTypeFilterProvider));
});

List<Appointment> _filterAndMap(List<CachedAppointment> rows, AppointmentType? filter) {
  var list = rows.map((c) => Appointment(
        id: c.id,
        title: c.title,
        description: c.description,
        type: AppointmentType.values.firstWhere(
          (v) => v.name == c.type,
          orElse: () => AppointmentType.other,
        ),
        scope: AppointmentScope.values.firstWhere(
          (v) => v.name == c.scope,
          orElse: () => AppointmentScope.school,
        ),
        classId: c.classId,
        subjectId: c.subjectId,
        date: c.date,
        timeSlotId: c.timeSlotId,
        createdBy: c.createdBy,
      ));
  if (filter != null) {
    list = list.where((a) => a.type == filter);
  }
  return list.toList();
}

class AppointmentActions {
  final Ref ref;
  AppointmentActions(this.ref);

  Future<void> create(Map<String, dynamic> data) async {
    final api = ref.read(apiServiceProvider);
    await api.createAppointment(data);
    await ref.read(syncServiceProvider).syncAppointments(force: true);
    ref.invalidate(appointmentsProvider);
  }
}

final appointmentActionsProvider = Provider<AppointmentActions>((ref) {
  return AppointmentActions(ref);
});
