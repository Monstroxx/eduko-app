import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../widgets/timetable_day_view.dart';
import '../widgets/timetable_week_view.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  bool _weekView = false;
  DateTime _selectedDate = DateTime.now();

  DateTime get _monday => _selectedDate
      .subtract(Duration(days: _selectedDate.weekday - 1));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekFormat = DateFormat('d. MMM', 'de');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stundenplan'),
        actions: [
          IconButton(
            icon: Icon(_weekView ? Icons.view_day_outlined : Icons.view_week_outlined),
            onPressed: () => setState(() => _weekView = !_weekView),
            tooltip: _weekView ? 'Tagesansicht' : 'Wochenansicht',
          ),
          IconButton(
            icon: const Icon(Icons.today_outlined),
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
            tooltip: 'Heute',
          ),
        ],
        // Week navigation bar
        bottom: _weekView
            ? PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        iconSize: 20,
                        onPressed: () => setState(() =>
                            _selectedDate = _selectedDate
                                .subtract(const Duration(days: 7))),
                      ),
                      Text(
                        '${weekFormat.format(_monday)} – '
                        '${weekFormat.format(_monday.add(const Duration(days: 4)))}',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        iconSize: 20,
                        onPressed: () => setState(() =>
                            _selectedDate =
                                _selectedDate.add(const Duration(days: 7))),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: _weekView
          ? TimetableWeekView(selectedDate: _selectedDate)
          : TimetableDayView(
              selectedDate: _selectedDate,
              onDateChanged: (d) => setState(() => _selectedDate = d),
            ),
    );
  }
}
