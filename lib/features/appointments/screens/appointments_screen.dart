import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/appointment_provider.dart';
import '../../../core/models/appointment.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final typeFilter = ref.watch(appointmentTypeFilterProvider);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Termine'),
        actions: [
          PopupMenuButton<AppointmentType?>(
            icon: Icon(
              Icons.filter_list,
              color: typeFilter != null ? theme.colorScheme.primary : null,
            ),
            onSelected: (v) =>
                ref.read(appointmentTypeFilterProvider.notifier).state = v,
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Alle')),
              const PopupMenuItem(
                  value: AppointmentType.exam, child: Text('Klausuren')),
              const PopupMenuItem(
                  value: AppointmentType.test, child: Text('Tests')),
              const PopupMenuItem(
                  value: AppointmentType.event, child: Text('Events')),
            ],
          ),
        ],
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_available,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Keine Termine', style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(appointmentsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final apt = appointments[index];
                return _AppointmentCard(apt: apt, dateFormat: dateFormat);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Fehler: $err')),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment apt;
  final DateFormat dateFormat;

  const _AppointmentCard({required this.apt, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, color) = switch (apt.type) {
      AppointmentType.exam => (Icons.school, Colors.red),
      AppointmentType.test => (Icons.quiz, Colors.orange),
      AppointmentType.event => (Icons.celebration, Colors.purple),
      AppointmentType.other => (Icons.event, Colors.grey),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(40),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(apt.title,
            style:
                theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(apt.date), style: theme.textTheme.bodySmall),
            if (apt.description != null)
              Text(apt.description!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        isThreeLine: apt.description != null,
      ),
    );
  }
}
