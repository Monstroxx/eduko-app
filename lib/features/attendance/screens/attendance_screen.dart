import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anwesenheit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Class selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Klasse',
                prefixIcon: Icon(Icons.group),
              ),
              items: const [], // TODO: populate from classes provider
              onChanged: (v) {},
            ),
          ),

          // Period selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Stunde',
                prefixIcon: Icon(Icons.access_time),
              ),
              items: const [], // TODO: populate from timetable
              onChanged: (v) {},
            ),
          ),

          const SizedBox(height: 16),

          // Student list with attendance toggles
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 0, // TODO: populate from students provider
              itemBuilder: (context, index) {
                // TODO: AttendanceStudentRow with status toggles
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: submit attendance batch
        },
        icon: const Icon(Icons.check),
        label: const Text('Speichern'),
      ),
    );
  }
}
