import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../models/appointment.dart';

/// Filter: appointment type.
final appointmentTypeFilterProvider = StateProvider<AppointmentType?>((ref) => null);

/// Appointments list.
final appointmentsProvider =
    FutureProvider.autoDispose<List<Appointment>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final typeFilter = ref.watch(appointmentTypeFilterProvider);

  final response = await api.getAppointments(
    type: typeFilter?.name,
  );

  final list = response.data as List;
  return list.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
});

class AppointmentActions {
  final Ref ref;
  AppointmentActions(this.ref);

  Future<void> create(Map<String, dynamic> data) async {
    final api = ref.read(apiServiceProvider);
    await api.createAppointment(data);
    ref.invalidate(appointmentsProvider);
  }
}

final appointmentActionsProvider = Provider<AppointmentActions>((ref) {
  return AppointmentActions(ref);
});
