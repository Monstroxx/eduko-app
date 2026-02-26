import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_service.dart';
import '../../../core/providers/timetable_provider.dart';
import '../../../core/providers/substitution_provider.dart';
import '../../../core/models/timetable_entry.dart';

class CreateSubstitutionScreen extends ConsumerStatefulWidget {
  const CreateSubstitutionScreen({super.key});

  @override
  ConsumerState<CreateSubstitutionScreen> createState() =>
      _CreateSubstitutionScreenState();
}

class _CreateSubstitutionScreenState
    extends ConsumerState<CreateSubstitutionScreen> {
  DateTime _date = DateTime.now();
  String _type = 'cancellation';
  TimetableEntry? _selectedEntry;
  final _noteController = TextEditingController();
  bool _loading = false;
  final _dateFormat = DateFormat('dd.MM.yyyy');

  static const _types = {
    'cancellation': 'Entfall',
    'substitution': 'Vertretung',
    'room_change': 'Raumänderung',
    'extra_lesson': 'Zusatzstunde',
  };

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _entryLabel(TimetableEntry e) {
    final parts = <String>[
      if (e.className != null) e.className!,
      e.subjectName ?? e.subjectAbbreviation ?? e.subjectId.substring(0, 8),
      if (e.timeSlotLabel != null) e.timeSlotLabel!,
      _dayName(e.dayOfWeek),
    ];
    return parts.join(' · ');
  }

  String _dayName(int d) => const {
        1: 'Mo',
        2: 'Di',
        3: 'Mi',
        4: 'Do',
        5: 'Fr',
        6: 'Sa',
        7: 'So',
      }[d] ??
      '$d';

  Future<void> _save() async {
    if (_selectedEntry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Stunde auswählen')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final dateStr =
          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

      await api.createSubstitution({
        'timetable_entry_id': _selectedEntry!.id,
        'date': dateStr,
        'type': _type,
        if (_noteController.text.isNotEmpty) 'note': _noteController.text,
      });

      if (!mounted) return;
      // Invalidate so the list refreshes
      ref.invalidate(substitutionsProvider);
      ref.read(substitutionDateProvider.notifier).state = _date;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vertretung eingetragen ✓')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(timetableEntriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vertretung anlegen'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Speichern'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date
            Text('Datum', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_dateFormat.format(_date)),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 20),

            // Type
            Text('Art der Vertretung', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _types.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 20),

            // Timetable entry selector
            Text('Stunde', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            timetableAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Text('Kein Stundenplan vorhanden');
                }
                return DropdownButtonFormField<TimetableEntry>(
                  value: _selectedEntry,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Stunde auswählen'),
                  items: entries
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(_entryLabel(e),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedEntry = v),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Fehler: $e'),
            ),
            const SizedBox(height: 20),

            // Note
            Text('Notiz (optional)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'z.B. Krankheit, Fortbildung...',
              ),
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Vertretung speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
