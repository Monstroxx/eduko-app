import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/timetable_provider.dart';
import '../../../core/providers/reference_data_provider.dart';
import '../../../core/models/timetable_entry.dart';

class TimetableWeekView extends ConsumerWidget {
  final DateTime selectedDate;

  const TimetableWeekView({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetableAsync = ref.watch(timetableByDayProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final theme = Theme.of(context);

    // Calculate Monday of the selected week.
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr'];

    return timetableAsync.when(
      data: (byDay) => timeSlotsAsync.when(
        data: (timeSlots) {
          final sortedSlots = [...timeSlots]
            ..sort((a, b) => a.slotNumber.compareTo(b.slotNumber));

          return SingleChildScrollView(
            child: Table(
              border: TableBorder.all(
                color: theme.colorScheme.outlineVariant,
                width: 0.5,
              ),
              columnWidths: const {
                0: FixedColumnWidth(48),
              },
              children: [
                // Header row
                TableRow(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  children: [
                    const SizedBox(height: 40), // Time column header
                    for (int d = 0; d < 5; d++)
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          children: [
                            Text(dayNames[d],
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              DateFormat('d.M')
                                  .format(monday.add(Duration(days: d))),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                // One row per time slot
                for (final slot in sortedSlots)
                  TableRow(
                    children: [
                      // Time label
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          children: [
                            Text(
                              slot.label ?? '${slot.slotNumber}',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              slot.startTime.substring(0, 5),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Days
                      for (int d = 1; d <= 5; d++)
                        _WeekCell(
                          entries: (byDay[d] ?? [])
                              .where((e) => e.timeSlotId == slot.id)
                              .toList(),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Fehler: $err')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Fehler: $err')),
    );
  }
}

class _WeekCell extends StatelessWidget {
  final List<TimetableEntry> entries;

  const _WeekCell({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return const SizedBox(height: 48);
    }

    final entry = entries.first;
    final color = entry.subjectColor != null
        ? Color(int.parse('FF${entry.subjectColor!.replaceFirst('#', '')}', radix: 16))
        : theme.colorScheme.primaryContainer;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(60),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 0.5),
        ),
        padding: const EdgeInsets.all(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              entry.subjectAbbreviation ?? entry.subjectName?.substring(0, 3) ?? '?',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (entry.roomName != null)
              Text(
                entry.roomName!,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 8,
                  color: theme.colorScheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
