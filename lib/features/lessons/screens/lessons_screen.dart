import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/models/timetable_entry.dart';
import '../../../core/providers/lesson_provider.dart';
import '../../../core/providers/timetable_provider.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final lessonsAsync = ref.watch(lessonsProvider);
    final isTeacher = auth.role == 'teacher' || auth.role == 'admin';
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Lehrstoff')),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Eintrag erstellen'),
            )
          : null,
      body: lessonsAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Kein Lehrstoff eingetragen',
                      style: theme.textTheme.bodyLarge),
                  if (isTeacher) ...[
                    const SizedBox(height: 8),
                    Text('Tippe auf + um einen Eintrag zu erstellen',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(lessonsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: theme.colorScheme.outline),
                            const SizedBox(width: 4),
                            Text(dateFormat.format(lesson.date),
                                style: theme.textTheme.labelSmall),
                            const Spacer(),
                            if (isTeacher)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () =>
                                    _showEditDialog(context, ref, lesson.id, lesson),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(lesson.topic,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        if (lesson.homework != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.assignment,
                                  size: 16, color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  lesson.homework!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (lesson.notes != null) ...[
                          const SizedBox(height: 4),
                          Text(lesson.notes!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.outline)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Fehler: $err')),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LessonFormSheet(ref: ref),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, String lessonId, dynamic lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LessonFormSheet(
        ref: ref,
        lessonId: lessonId,
        initialTopic: lesson.topic,
        initialHomework: lesson.homework,
        initialNotes: lesson.notes,
      ),
    );
  }
}

// ── Form sheet ──────────────────────────────────────────────────────────────

class _LessonFormSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final String? lessonId;
  final String? initialTopic;
  final String? initialHomework;
  final String? initialNotes;

  const _LessonFormSheet({
    required this.ref,
    this.lessonId,
    this.initialTopic,
    this.initialHomework,
    this.initialNotes,
  });

  @override
  ConsumerState<_LessonFormSheet> createState() => _LessonFormSheetState();
}

class _LessonFormSheetState extends ConsumerState<_LessonFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _topicCtrl;
  late final TextEditingController _homeworkCtrl;
  late final TextEditingController _notesCtrl;

  DateTime _date = DateTime.now();
  TimetableEntry? _selectedEntry;
  bool _saving = false;

  bool get _isEdit => widget.lessonId != null;

  @override
  void initState() {
    super.initState();
    _topicCtrl = TextEditingController(text: widget.initialTopic ?? '');
    _homeworkCtrl = TextEditingController(text: widget.initialHomework ?? '');
    _notesCtrl = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _homeworkCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(timetableEntriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  _isEdit ? 'Eintrag bearbeiten' : 'Lehrstoff eintragen',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Datum',
                  prefixIcon: Icon(Icons.calendar_today),
                  isDense: true,
                ),
                child: Text(DateFormat('dd.MM.yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 12),

            // Timetable entry picker (required for create)
            if (!_isEdit)
              entriesAsync.when(
                data: (entries) {
                  // Filter by weekday of selected date, fall back to all if none
                  final dayEntries = entries
                      .where((e) => e.dayOfWeek == _date.weekday)
                      .toList();
                  final items = dayEntries.isNotEmpty ? dayEntries : entries;
                  if (items.isEmpty) {
                    return const Text(
                      'Keine Stunden im Stundenplan',
                      style: TextStyle(color: Colors.grey),
                    );
                  }
                  return DropdownButtonFormField<TimetableEntry>(
                    decoration: const InputDecoration(
                      labelText: 'Stunde *',
                      prefixIcon: Icon(Icons.access_time),
                      isDense: true,
                    ),
                    value: _selectedEntry,
                    items: items.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            '${e.timeSlotLabel ?? ''} ${e.subjectName ?? ''}'
                                .trim(),
                          ),
                        )).toList(),
                    onChanged: (v) => setState(() => _selectedEntry = v),
                    validator: (v) =>
                        v == null ? 'Bitte eine Stunde wählen' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),

            const SizedBox(height: 12),

            // Topic
            TextFormField(
              controller: _topicCtrl,
              decoration: const InputDecoration(
                labelText: 'Thema / Inhalt *',
                prefixIcon: Icon(Icons.menu_book),
              ),
              maxLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Thema ist Pflicht' : null,
            ),
            const SizedBox(height: 12),

            // Homework
            TextFormField(
              controller: _homeworkCtrl,
              decoration: const InputDecoration(
                labelText: 'Hausaufgaben (optional)',
                prefixIcon: Icon(Icons.assignment),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notizen (optional)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(_isEdit ? 'Speichern' : 'Eintragen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final actions = ref.read(lessonActionsProvider);
      final topic = _topicCtrl.text.trim();
      final homework =
          _homeworkCtrl.text.trim().isEmpty ? null : _homeworkCtrl.text.trim();
      final notes =
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

      if (_isEdit) {
        await actions.update(widget.lessonId!, {
          'topic': topic,
          if (homework != null) 'homework': homework,
          if (notes != null) 'notes': notes,
        });
      } else {
        if (_selectedEntry == null) return; // Validator catches this above
        await actions.create(
          timetableEntryId: _selectedEntry!.id,
          date: _date,
          topic: topic,
          homework: homework,
          notes: notes,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Eintrag aktualisiert' : 'Lehrstoff eingetragen')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
