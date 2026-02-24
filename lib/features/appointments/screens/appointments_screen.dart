import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termine')),
      body: const Center(child: Text('Termine — Coming Soon')),
      // TODO: Calendar view with exams, events, etc.
    );
  }
}
