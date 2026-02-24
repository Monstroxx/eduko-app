import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lehrstoff')),
      body: const Center(child: Text('Lehrstoff — Coming Soon')),
      // TODO: List of lesson content entries, filterable by subject/date
    );
  }
}
