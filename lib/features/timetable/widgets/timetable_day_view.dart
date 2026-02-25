import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/timetable_provider.dart';
import '../../../core/providers/reference_data_provider.dart';
import '../../../core/models/timetable_entry.dart';

class TimetableDayView extends ConsumerWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const TimetableDayView({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayFormat = DateFormat('EEEE, d. MMMM', 'de');
    final timetableAsync = ref.watch(timetableByDayProvider);
    final dayOfWeek = selectedDate.weekday; // 1=Mon..7=Sun

    return Column(
      children: [
        // Date navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    onDateChanged(selectedDate.subtract(const Duration(days: 1))),
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) onDateChanged(picked);
                },
                child: Text(
                  dayFormat.format(selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () =>
                    onDateChanged(selectedDate.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),

        // Timetable entries
        Expanded(
          child: timetableAsync.when(
            data: (byDay) {
              final entries = byDay[dayOfWeek] ?? [];
              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.free_breakfast,
                          size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        dayOfWeek > 5 ? 'Wochenende 🎉' : 'Kein Unterricht',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: entries.length,
                itemBuilder: (context, index) =>
                    _TimetableEntryCard(entry: entries[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Fehler: $err'),
                  TextButton(
                    onPressed: () => ref.invalidate(timetableEntriesProvider),
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimetableEntryCard extends ConsumerWidget {
  final TimetableEntry entry;

  const _TimetableEntryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeSlotAsync = ref.watch(timeSlotByIdProvider(entry.timeSlotId));
    final theme = Theme.of(context);

    // Parse subject color or use default.
    final subjectColor = entry.subjectColor != null
        ? Color(int.parse('FF${entry.subjectColor!.replaceFirst('#', '')}', radix: 16))
        : theme.colorScheme.primaryContainer;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color bar
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: subjectColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Time column
            SizedBox(
              width: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: timeSlotAsync.when(
                  data: (slot) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        slot?.label ?? '${slot?.slotNumber ?? '?'}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (slot != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          slot.startTime.substring(0, 5),
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          slot.endTime.substring(0, 5),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const Text('?'),
                ),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.subjectName ?? entry.subjectAbbreviation ?? 'Fach',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          entry.teacherName ?? entry.teacherAbbreviation ?? '–',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.room_outlined,
                            size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          entry.roomName ?? '–',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (entry.weekType != WeekType.all)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Chip(
                          label: Text('Woche ${entry.weekType.name.toUpperCase()}'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelStyle: theme.textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
