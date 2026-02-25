import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/models/excuse.dart';
import '../../../core/providers/excuse_provider.dart';

class ExcusesScreen extends ConsumerWidget {
  const ExcusesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return DefaultTabController(
      length: auth.isStudent ? 1 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entschuldigungen'),
          bottom: auth.isStudent
              ? null
              : const TabBar(
                  tabs: [
                    Tab(text: 'Ausstehend'),
                    Tab(text: 'Entschuldigt'),
                    Tab(text: 'Abgelehnt'),
                  ],
                ),
        ),
        body: auth.isStudent
            ? const _ExcuseList(status: null)
            : const TabBarView(
                children: [
                  _ExcuseList(status: ExcuseStatus.pending),
                  _ExcuseList(status: ExcuseStatus.approved),
                  _ExcuseList(status: ExcuseStatus.rejected),
                ],
              ),
        floatingActionButton: auth.isStudent
            ? FloatingActionButton.extended(
                onPressed: () => context.go('/excuses/create'),
                icon: const Icon(Icons.add),
                label: const Text('Neue Entschuldigung'),
              )
            : null,
      ),
    );
  }
}

class _ExcuseList extends ConsumerWidget {
  final ExcuseStatus? status;

  const _ExcuseList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Set filter before watching.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(excuseStatusFilterProvider.notifier).state = status;
    });

    final excusesAsync = ref.watch(excusesProvider);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return excusesAsync.when(
      data: (excuses) {
        if (excuses.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  status == ExcuseStatus.pending
                      ? 'Keine ausstehenden Entschuldigungen'
                      : 'Keine Entschuldigungen',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(excusesProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: excuses.length,
            itemBuilder: (context, index) {
              final excuse = excuses[index];
              return _ExcuseCard(excuse: excuse, dateFormat: dateFormat);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Fehler: $err'),
            TextButton(
              onPressed: () => ref.invalidate(excusesProvider),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExcuseCard extends ConsumerWidget {
  final Excuse excuse;
  final DateFormat dateFormat;

  const _ExcuseCard({required this.excuse, required this.dateFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = switch (excuse.status) {
      ExcuseStatus.pending => Colors.orange,
      ExcuseStatus.approved => Colors.green,
      ExcuseStatus.rejected => Colors.red,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/excuses/${excuse.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      excuse.studentName ?? 'Schüler',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Chip(
                    label: Text(
                      excuse.submissionType == ExcuseSubmission.digital
                          ? 'Digital'
                          : 'Papier',
                      style: theme.textTheme.labelSmall,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(excuse.dateFrom)} – ${dateFormat.format(excuse.dateTo)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (excuse.reason != null) ...[
                const SizedBox(height: 4),
                Text(
                  excuse.reason!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (excuse.linkedAbsences != null && excuse.linkedAbsences! > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${excuse.linkedAbsences} verknüpfte Fehlstunden',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
