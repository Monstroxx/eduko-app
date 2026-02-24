import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';


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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 0, // TODO: populate from provider
            itemBuilder: (context, index) {
              // TODO: TimetableEntryCard
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
