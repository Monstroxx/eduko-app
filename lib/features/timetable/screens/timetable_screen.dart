import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stundenplan'),
        actions: [
          IconButton(
            icon: Icon(_weekView ? Icons.view_day : Icons.view_week),
            onPressed: () => setState(() => _weekView = !_weekView),
            tooltip: _weekView ? 'Tagesansicht' : 'Wochenansicht',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
            tooltip: 'Heute',
          ),
        ],
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
