import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/attendance.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/class_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  // Overrides: studentId → chosen status (null = not changed)
  final _overrides = <String, AttendanceStatus>{};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final classId = ref.watch(attendanceClassIdProvider);
    final periodId = ref.watch(attendancePeriodIdProvider);
    final date = ref.watch(attendanceDateProvider);
    final classesAsync = ref.watch(classesProvider);
    final periodsAsync = ref.watch(classDayTimetableProvider);
    final theme = Theme.of(context);
    final dateStr = DateFormat('EEEE, d. MMMM', 'de').format(date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anwesenheit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Heute',
            onPressed: () {
              ref.read(attendanceDateProvider.notifier).state = DateTime.now();
              ref.read(attendancePeriodIdProvider.notifier).state = null;
              setState(() => _overrides.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Date navigator ─────────────────────────────────
          Card(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeDate(date.subtract(const Duration(days: 1))),
                  ),
                  Expanded(
                    child: Text(
                      dateStr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDate(date.add(const Duration(days: 1))),
                  ),
                ],
              ),
            ),
          ),

          // ── Class selector ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: classesAsync.when(
              data: (classes) => DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Klasse',
                  prefixIcon: Icon(Icons.group),
                  isDense: true,
                ),
                value: classId,
                items: classes
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) {
                  ref.read(attendanceClassIdProvider.notifier).state = v;
                  ref.read(attendancePeriodIdProvider.notifier).state = null;
                  setState(() => _overrides.clear());
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Fehler beim Laden der Klassen'),
            ),
          ),

          // ── Period selector ────────────────────────────────
          if (classId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: periodsAsync.when(
                data: (periods) {
                  if (periods.isEmpty) {
                    return Text(
                      'Keine Stunden an diesem Tag',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Stunde',
                      prefixIcon: Icon(Icons.access_time),
                      isDense: true,
                    ),
                    value: periodId,
                    items: periods
                        .map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(
                                '${e.timeSlotLabel ?? e.timeSlotStart ?? ''} — ${e.subjectName ?? 'Stunde'}',
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      ref.read(attendancePeriodIdProvider.notifier).state = v;
                      setState(() => _overrides.clear());
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) =>
                    const Text('Fehler beim Laden der Stunden'),
              ),
            ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // ── Student list ───────────────────────────────────
          Expanded(
            child: _buildStudentList(classId, periodId, date),
          ),
        ],
      ),
      floatingActionButton: _overrides.isNotEmpty && periodId != null
          ? FloatingActionButton.extended(
              onPressed: _saving ? null : _saveAttendance,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text('Speichern (${_overrides.length})'),
            )
          : null,
    );
  }

  Widget _buildStudentList(String? classId, String? periodId, DateTime date) {
    if (classId == null) {
      return Center(
        child: Text(
          'Bitte Klasse und Stunde wählen',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }
    if (periodId == null) {
      return Center(
        child: Text(
          'Bitte eine Stunde wählen',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }

    // Show existing attendance merged with all class students
    final attendanceAsync = ref.watch(classAttendanceProvider);
    final studentsAsync = ref.watch(classStudentsProvider(classId));

    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Fehler: $err')),
      data: (students) {
        if (students.isEmpty) {
          return const Center(child: Text('Keine Schüler in dieser Klasse'));
        }

        // Build a map studentId → existing attendance record (filtered by periodId)
        final existing = <String, Attendance>{};
        attendanceAsync.whenData((records) {
          for (final r in records) {
            if (r.timetableEntryId == periodId) {
              existing[r.studentId] = r;
            }
          }
        });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          itemCount: students.length,
          itemBuilder: (context, i) {
            final student = students[i];
            final rec = existing[student.id];
            final currentStatus =
                _overrides[student.id] ?? rec?.status ?? AttendanceStatus.present;
            final isChanged = _overrides.containsKey(student.id);

            return _AttendanceRow(
              studentName: student.displayName,
              status: currentStatus,
              isChanged: isChanged,
              onStatusChanged: (s) => setState(() => _overrides[student.id] = s),
            );
          },
        );
      },
    );
  }

  void _changeDate(DateTime d) {
    ref.read(attendanceDateProvider.notifier).state = d;
    ref.read(attendancePeriodIdProvider.notifier).state = null;
    setState(() => _overrides.clear());
  }

  Future<void> _saveAttendance() async {
    final periodId = ref.read(attendancePeriodIdProvider);
    final date = ref.read(attendanceDateProvider);
    if (periodId == null || _overrides.isEmpty) return;

    setState(() => _saving = true);
    try {
      final entries = _overrides.entries.map((e) {
        // 'late_' is Dart enum name; backend expects 'late'
        final statusStr =
            e.value == AttendanceStatus.late_ ? 'late' : e.value.name;
        return {'student_id': e.key, 'status': statusStr};
      }).toList();

      final count = await ref.read(attendanceActionsProvider).recordBatch(
            timetableEntryId: periodId,
            date: date,
            entries: entries,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count Einträge gespeichert')),
      );
      setState(() => _overrides.clear());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Row widget ──────────────────────────────────────────────────────────────

class _AttendanceRow extends StatelessWidget {
  final String studentName;
  final AttendanceStatus status;
  final bool isChanged;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  const _AttendanceRow({
    required this.studentName,
    required this.status,
    required this.isChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: isChanged ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isChanged
            ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _statusColor(status, theme),
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                studentName,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Wrap(
              spacing: 4,
              children: AttendanceStatus.values
                  .map((s) => _StatusChip(
                        statusValue: s,
                        selected: status == s,
                        onTap: () => onStatusChanged(s),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(AttendanceStatus s, ThemeData theme) => switch (s) {
        AttendanceStatus.present => Colors.green.shade100,
        AttendanceStatus.absent => Colors.red.shade100,
        AttendanceStatus.late_ => Colors.orange.shade100,
        AttendanceStatus.excusedLeave => Colors.blue.shade100,
      };
}

class _StatusChip extends StatelessWidget {
  final AttendanceStatus statusValue;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.statusValue,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (statusValue) {
      AttendanceStatus.present => ('✓', Colors.green),
      AttendanceStatus.absent => ('✗', Colors.red),
      AttendanceStatus.late_ => ('⏰', Colors.orange),
      AttendanceStatus.excusedLeave => ('E', Colors.blue),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? color.shade100 : Colors.transparent,
          border: Border.all(
            color: selected ? color.shade400 : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? color.shade700 : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
