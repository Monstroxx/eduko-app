import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/models/substitution.dart';
import '../../../core/models/excuse.dart';
import '../../../core/providers/timetable_provider.dart';
import '../../../core/providers/substitution_provider.dart';
import '../../../core/providers/excuse_provider.dart';
import '../../../core/providers/appointment_provider.dart';
import '../../../core/database/sync_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final greeting = _greeting(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eduko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Synchronisieren',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synchronisiere...'), duration: Duration(seconds: 1)),
              );
              await ref.read(syncServiceProvider).syncAll();
              ref.invalidate(timetableEntriesProvider);
              ref.invalidate(substitutionsProvider);
              ref.invalidate(excusesProvider);
              ref.invalidate(appointmentsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncServiceProvider).syncAll();
          ref.invalidate(timetableEntriesProvider);
          ref.invalidate(substitutionsProvider);
          ref.invalidate(excusesProvider);
          ref.invalidate(appointmentsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Greeting
            Text(
              '$greeting, ${auth.firstName ?? ''}!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('EEEE, d. MMMM yyyy', 'de').format(now),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 24),

            // Next lesson
            _NextLessonCard(),
            const SizedBox(height: 12),

            // Today's substitutions
            _TodaySubstitutionsCard(),
            const SizedBox(height: 12),

            // Pending excuses
            if (auth.isTeacher || auth.isAdmin) ...[
              _PendingExcusesCard(),
              const SizedBox(height: 12),
            ],

            if (auth.isStudent) ...[
              _MyExcusesCard(),
              const SizedBox(height: 12),
            ],

            // Upcoming appointments
            _UpcomingAppointmentsCard(),
          ],
        ),
      ),
    );
  }

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 10) return 'Guten Morgen';
    if (h < 14) return 'Mahlzeit';
    if (h < 18) return 'Guten Tag';
    return 'Guten Abend';
  }
}

// ── Next Lesson ─────────────────────────────────────────────

class _NextLessonCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetableAsync = ref.watch(timetableByDayProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return timetableAsync.when(
      data: (byDay) {
        final todayEntries = byDay[now.weekday] ?? [];
        if (todayEntries.isEmpty) {
          return _DashCard(
            icon: Icons.free_breakfast,
            iconColor: Colors.green,
            title: 'Kein Unterricht heute',
            subtitle: now.weekday > 5 ? 'Wochenende! 🎉' : 'Unterrichtsfrei',
          );
        }

        // Show first entry as "next" (simplified — proper version would check time)
        final next = todayEntries.first;
        final color = next.subjectColor != null
            ? Color(int.parse('FF${next.subjectColor!.replaceFirst('#', '')}', radix: 16))
            : theme.colorScheme.primary;

        return _DashCard(
          icon: Icons.schedule,
          iconColor: color,
          title: next.subjectName ?? next.subjectAbbreviation ?? 'Nächste Stunde',
          subtitle: '${next.teacherName ?? ''} · ${next.roomName ?? ''}',
          trailing: Text(
            '${todayEntries.length} Std. heute',
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
          ),
          onTap: () => GoRouter.of(context).go('/timetable'),
        );
      },
      loading: () => const _DashCardLoading(),
      error: (_, __) => const _DashCard(
        icon: Icons.error_outline, iconColor: Colors.red,
        title: 'Stundenplan nicht verfügbar', subtitle: '',
      ),
    );
  }
}

// ── Today's Substitutions ───────────────────────────────────

class _TodaySubstitutionsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(substitutionsProvider);

    return subsAsync.when(
      data: (subs) {
        if (subs.isEmpty) {
          return const _DashCard(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            title: 'Keine Vertretungen',
            subtitle: 'Regulärer Unterricht heute',
          );
        }
        return _DashCard(
          icon: Icons.swap_horiz,
          iconColor: Colors.orange,
          title: '${subs.length} Vertretung${subs.length > 1 ? 'en' : ''}',
          subtitle: subs.take(2).map((s) =>
            '${s.className ?? ''} ${s.originalSubject ?? ''}: ${_subTypeLabel(s.type)}'
          ).join('\n'),
          onTap: () => GoRouter.of(context).go('/substitutions'),
        );
      },
      loading: () => const _DashCardLoading(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _subTypeLabel(SubstitutionType t) => switch (t) {
        SubstitutionType.cancellation => 'Entfall',
        SubstitutionType.substitution => 'Vertretung',
        SubstitutionType.roomChange => 'Raumänderung',
        SubstitutionType.extraLesson => 'Zusatzstunde',
      };
}

// ── Pending Excuses (Teacher/Admin) ─────────────────────────

class _PendingExcusesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final excusesAsync = ref.watch(excusesProvider);

    return excusesAsync.when(
      data: (excuses) {
        final pending = excuses.where((e) => e.status == ExcuseStatus.pending).toList();
        if (pending.isEmpty) {
          return const _DashCard(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            title: 'Keine offenen Entschuldigungen',
            subtitle: 'Alles bearbeitet',
          );
        }
        return _DashCard(
          icon: Icons.pending_actions,
          iconColor: Colors.orange,
          title: '${pending.length} offene Entschuldigung${pending.length > 1 ? 'en' : ''}',
          subtitle: pending.take(3).map((e) => e.studentName ?? 'Schüler').join(', '),
          onTap: () => GoRouter.of(context).go('/excuses'),
        );
      },
      loading: () => const _DashCardLoading(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── My Excuses (Student) ────────────────────────────────────

class _MyExcusesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final excusesAsync = ref.watch(excusesProvider);

    return excusesAsync.when(
      data: (excuses) {
        final pending = excuses.where((e) => e.status == ExcuseStatus.pending).length;
        if (pending == 0) return const SizedBox.shrink();
        return _DashCard(
          icon: Icons.pending_outlined,
          iconColor: Colors.orange,
          title: '$pending ausstehende Entschuldigung${pending > 1 ? 'en' : ''}',
          subtitle: 'Warte auf Genehmigung',
          onTap: () => GoRouter.of(context).go('/excuses'),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Upcoming Appointments ───────────────────────────────────

class _UpcomingAppointmentsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aptAsync = ref.watch(appointmentsProvider);
    final dateFormat = DateFormat('dd.MM.');

    return aptAsync.when(
      data: (appointments) {
        final upcoming = appointments
            .where((a) => a.date.isAfter(DateTime.now().subtract(const Duration(days: 1))))
            .take(3)
            .toList();
        if (upcoming.isEmpty) return const SizedBox.shrink();

        return _DashCard(
          icon: Icons.event,
          iconColor: Colors.purple,
          title: 'Kommende Termine',
          subtitle: upcoming.map((a) =>
            '${dateFormat.format(a.date)} ${a.title}'
          ).join('\n'),
          onTap: () => GoRouter.of(context).go('/appointments'),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Reusable Card Widgets ───────────────────────────────────

class _DashCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _DashCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withAlpha(30),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      )),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (onTap != null)
                Icon(Icons.chevron_right, color: theme.colorScheme.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashCardLoading extends StatelessWidget {
  const _DashCardLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: LinearProgressIndicator()),
      ),
    );
  }
}
