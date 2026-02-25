import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/class_provider.dart';
import '../../../core/models/attendance.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final _statusOverrides = <String, AttendanceStatus>{};

  @override
  Widget build(BuildContext context) {
    final classId = ref.watch(attendanceClassIdProvider);
    final date = ref.watch(attendanceDateProvider);
    final classesAsync = ref.watch(classesProvider);
    final attendanceAsync = ref.watch(classAttendanceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anwesenheit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () =>
                ref.read(attendanceDateProvider.notifier).state = DateTime.now(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref.read(attendanceDateProvider.notifier).state =
                      date.subtract(const Duration(days: 1)),
                ),
                Text(
                  DateFormat('EEEE, d. MMMM', 'de').format(date),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => ref.read(attendanceDateProvider.notifier).state =
                      date.add(const Duration(days: 1)),
                ),
              ],
            ),
          ),

          // Class selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: classesAsync.when(
              data: (classes) => DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Klasse',
                  prefixIcon: Icon(Icons.group),
                ),
                value: classId,
                items: classes
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (v) =>
                    ref.read(attendanceClassIdProvider.notifier).state = v,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Fehler beim Laden der Klassen'),
            ),
          ),

          const SizedBox(height: 16),

          // Student list with attendance toggles
          Expanded(
            child: classId == null
                ? Center(
                    child: Text('Bitte Klasse wählen',
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline)),
                  )
                : attendanceAsync.when(
                    data: (records) {
                      if (records.isEmpty) {
                        return const Center(
                            child: Text('Keine Einträge für diesen Tag'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final currentStatus =
                              _statusOverrides[record.id] ?? record.status;
                          return _AttendanceRow(
                            studentName: record.studentName ?? record.studentId,
                            status: currentStatus,
                            onStatusChanged: (status) {
                              setState(() {
                                _statusOverrides[record.id] = status;
                              });
                            },
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Fehler: $err')),
                  ),
          ),
        ],
      ),
      floatingActionButton: classId != null && _statusOverrides.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _saveAttendance,
              icon: const Icon(Icons.check),
              label: Text('Speichern (${_statusOverrides.length})'),
            )
          : null,
    );
  }

  Future<void> _saveAttendance() async {
    // TODO: batch save via attendanceActionsProvider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anwesenheit gespeichert')),
    );
    setState(() => _statusOverrides.clear());
    ref.invalidate(classAttendanceProvider);
  }
}

class _AttendanceRow extends StatelessWidget {
  final String studentName;
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  const _AttendanceRow({
    required this.studentName,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(studentName, style: theme.textTheme.bodyMedium),
            ),
            for (final s in AttendanceStatus.values)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ChoiceChip(
                  label: Text(_statusLabel(s)),
                  selected: status == s,
                  selectedColor: _statusColor(s),
                  onSelected: (_) => onStatusChanged(s),
                  visualDensity: VisualDensity.compact,
                  labelStyle: theme.textTheme.labelSmall,
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => '✓',
        AttendanceStatus.absent => '✗',
        AttendanceStatus.late_ => '⏰',
        AttendanceStatus.excusedLeave => 'E',
      };

  Color _statusColor(AttendanceStatus s) => switch (s) {
        AttendanceStatus.present => Colors.green.shade100,
        AttendanceStatus.absent => Colors.red.shade100,
        AttendanceStatus.late_ => Colors.orange.shade100,
        AttendanceStatus.excusedLeave => Colors.blue.shade100,
      };
}
