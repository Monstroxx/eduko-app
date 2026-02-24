import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimetableWeekView extends ConsumerWidget {
  final DateTime selectedDate;

  const TimetableWeekView({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement week grid view
    return const Center(
      child: Text('Wochenansicht — Coming Soon'),
    );
  }
}
