import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/models/appointment.dart';
import '../../../core/models/school_class.dart';
import '../../../core/models/subject.dart';
import '../../../core/providers/appointment_provider.dart';
import '../../../core/providers/class_provider.dart';
import '../../../core/providers/reference_data_provider.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final typeFilter = ref.watch(appointmentTypeFilterProvider);
    final auth = ref.watch(authProvider);
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
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('Alle')),
              PopupMenuItem(value: AppointmentType.exam, child: Text('Klausuren')),
              PopupMenuItem(value: AppointmentType.test, child: Text('Tests')),
              PopupMenuItem(value: AppointmentType.event, child: Text('Events')),
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
                  if (auth.isTeacher || auth.isAdmin) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _showCreateDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Termin erstellen'),
                    ),
                  ],
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
      floatingActionButton: (auth.isTeacher || auth.isAdmin)
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Termin'),
            )
          : null,
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _CreateAppointmentDialog(ref: ref),
    );
  }
}

// ── Create dialog ─────────────────────────────────────────

class _CreateAppointmentDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _CreateAppointmentDialog({required this.ref});

  @override
  ConsumerState<_CreateAppointmentDialog> createState() =>
      _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState
    extends ConsumerState<_CreateAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  AppointmentType _type = AppointmentType.exam;
  AppointmentScope _scope = AppointmentScope.class_;
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  SchoolClass? _selectedClass;
  Subject? _selectedSubject;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return AlertDialog(
      title: const Text('Termin erstellen'),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Titel *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Titel erforderlich' : null,
              ),
              const SizedBox(height: 12),

              // Type
              DropdownButtonFormField<AppointmentType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Typ'),
                items: const [
                  DropdownMenuItem(
                      value: AppointmentType.exam, child: Text('Klausur')),
                  DropdownMenuItem(
                      value: AppointmentType.test, child: Text('Test')),
                  DropdownMenuItem(
                      value: AppointmentType.event, child: Text('Event')),
                  DropdownMenuItem(
                      value: AppointmentType.other, child: Text('Sonstiges')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),

              // Scope
              DropdownButtonFormField<AppointmentScope>(
                value: _scope,
                decoration: const InputDecoration(labelText: 'Gültig für'),
                items: const [
                  DropdownMenuItem(
                      value: AppointmentScope.class_, child: Text('Klasse')),
                  DropdownMenuItem(
                      value: AppointmentScope.school, child: Text('Ganze Schule')),
                ],
                onChanged: (v) => setState(() => _scope = v!),
              ),
              const SizedBox(height: 12),

              // Class picker (only if scope == class)
              if (_scope == AppointmentScope.class_)
                classesAsync.when(
                  data: (classes) => DropdownButtonFormField<SchoolClass>(
                    value: _selectedClass,
                    decoration: const InputDecoration(labelText: 'Klasse *'),
                    items: classes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    validator: (v) => v == null ? 'Klasse wählen' : null,
                    onChanged: (v) => setState(() => _selectedClass = v),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Klassen konnten nicht geladen werden'),
                ),
              if (_scope == AppointmentScope.class_) const SizedBox(height: 12),

              // Subject picker (optional)
              subjectsAsync.when(
                data: (subjects) => DropdownButtonFormField<Subject?>(
                  value: _selectedSubject,
                  decoration:
                      const InputDecoration(labelText: 'Fach (optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('– kein Fach –')),
                    ...subjects.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedSubject = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),

              // Date picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Datum',
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(dateFormat.format(_date)),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung (optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Erstellen'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await ref.read(appointmentActionsProvider).create({
        'title': _titleCtrl.text.trim(),
        'type': _type.name,
        'scope': _scope.name,
        'date': _date.toIso8601String().substring(0, 10),
        if (_selectedClass != null) 'class_id': _selectedClass!.id,
        if (_selectedSubject != null) 'subject_id': _selectedSubject!.id,
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Termin erstellt')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }
}

// ── Card ──────────────────────────────────────────────────

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
        title: Text(
          apt.title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(apt.date), style: theme.textTheme.bodySmall),
            if (apt.description != null)
              Text(
                apt.description!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        isThreeLine: apt.description != null,
      ),
    );
  }
}
