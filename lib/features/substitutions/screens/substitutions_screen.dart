import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/substitution_provider.dart';
import '../../../core/models/substitution.dart';

class SubstitutionsScreen extends ConsumerWidget {
  const SubstitutionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(substitutionDateProvider);
    final subsAsync = ref.watch(substitutionsProvider);
    final theme = Theme.of(context);
    final dayFormat = DateFormat('EEEE, d. MMMM', 'de');

    return Scaffold(
      appBar: AppBar(title: const Text('Vertretungsplan')),
      body: Column(
        children: [
          // Date selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref
                      .read(substitutionDateProvider.notifier)
                      .state = date.subtract(const Duration(days: 1)),
                ),
                Text(
                  dayFormat.format(date),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => ref
                      .read(substitutionDateProvider.notifier)
                      .state = date.add(const Duration(days: 1)),
                ),
              ],
            ),
          ),

          // Substitution list
          Expanded(
            child: subsAsync.when(
              data: (subs) {
                if (subs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('Keine Vertretungen',
                            style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(substitutionsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: subs.length,
                    itemBuilder: (context, index) =>
                        _SubstitutionCard(sub: subs[index]),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Fehler: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubstitutionCard extends StatelessWidget {
  final Substitution sub;

  const _SubstitutionCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, color, label) = switch (sub.type) {
      SubstitutionType.cancellation => (
          Icons.cancel_outlined,
          Colors.red,
          'Entfall'
        ),
      SubstitutionType.substitution => (
          Icons.swap_horiz,
          Colors.orange,
          'Vertretung'
        ),
      SubstitutionType.roomChange => (
          Icons.room_outlined,
          Colors.blue,
          'Raumänderung'
        ),
      SubstitutionType.extraLesson => (
          Icons.add_circle_outline,
          Colors.green,
          'Zusatzstunde'
        ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(40),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Row(
          children: [
            if (sub.className != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(sub.className!),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  labelStyle: theme.textTheme.labelSmall,
                ),
              ),
            Text(
              sub.originalSubject ?? '–',
              style: theme.textTheme.titleSmall,
            ),
            if (sub.timeSlotLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                sub.timeSlotLabel!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12)),
            if (sub.type == SubstitutionType.substitution &&
                sub.substituteTeacherName != null)
              Text('→ ${sub.substituteTeacherName}',
                  style: theme.textTheme.bodySmall),
            if (sub.type == SubstitutionType.roomChange &&
                sub.substituteRoomName != null)
              Text('→ ${sub.substituteRoomName}',
                  style: theme.textTheme.bodySmall),
            if (sub.note != null)
              Text(sub.note!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
