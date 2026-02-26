import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/timetable_entry.dart';
import '../../../core/providers/reference_data_provider.dart';
import '../../../core/providers/timetable_provider.dart';

// ── Helpers ────────────────────────────────────────────────

int _toMinutes(String? s) {
  if (s == null) return -1;
  final p = s.split(':');
  if (p.length < 2) return -1;
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

enum _Status { past, current, upcoming }

_Status _entryStatus(TimetableEntry e, int nowMin) {
  final start = _toMinutes(e.timeSlotStart);
  final end = _toMinutes(e.timeSlotEnd);
  if (start < 0) return _Status.upcoming;
  if (end >= 0 && nowMin > end) return _Status.past;
  if (nowMin >= start) return _Status.current;
  return _Status.upcoming;
}

// ── Day View ───────────────────────────────────────────────

class TimetableDayView extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const TimetableDayView({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  ConsumerState<TimetableDayView> createState() => _TimetableDayViewState();
}

class _TimetableDayViewState extends ConsumerState<TimetableDayView> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Refresh every 30 s so NOW line stays accurate.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _isToday =>
      widget.selectedDate.year == _now.year &&
      widget.selectedDate.month == _now.month &&
      widget.selectedDate.day == _now.day;

  @override
  Widget build(BuildContext context) {
    final dayFormat = DateFormat('EEEE, d. MMMM', 'de');
    final timetableAsync = ref.watch(timetableByDayProvider);
    final dayOfWeek = widget.selectedDate.weekday;

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
                onPressed: () => widget.onDateChanged(
                    widget.selectedDate.subtract(const Duration(days: 1))),
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) widget.onDateChanged(picked);
                },
                child: Text(
                  dayFormat.format(widget.selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => widget.onDateChanged(
                    widget.selectedDate.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),

        Expanded(
          child: timetableAsync.when(
            data: (byDay) {
              final entries = byDay[dayOfWeek] ?? [];
              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.free_breakfast,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        dayOfWeek > 5 ? 'Wochenende 🎉' : 'Kein Unterricht',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              }
              return _buildList(entries);
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Fehler: $err'),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(timetableEntriesProvider),
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<TimetableEntry> entries) {
    if (!_isToday) {
      // Not today: plain list, no NOW line, no graying.
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: entries.length,
        itemBuilder: (_, i) =>
            _TimetableEntryCard(entry: entries[i], status: _Status.upcoming),
      );
    }

    final nowMin = _now.hour * 60 + _now.minute;
    final statuses = entries.map((e) => _entryStatus(e, nowMin)).toList();

    // Find insertion point for NOW line:
    // Insert after the last 'past' entry and before the first 'current'/'upcoming'.
    int nowInsertAfter = -1; // insert before index 0 if all upcoming
    for (int i = 0; i < statuses.length; i++) {
      if (statuses[i] == _Status.past) nowInsertAfter = i;
    }
    // Only show line if there's at least one past AND one non-past entry,
    // OR if school hasn't started yet (nowInsertAfter == -1 and time < first start).
    final hasNonPast = statuses.any((s) => s != _Status.past);
    final showNowLine = hasNonPast &&
        (nowInsertAfter >= 0 ||
            nowMin < _toMinutes(entries.first.timeSlotStart));

    // Build flat items list: entries interleaved with optional NOW marker.
    final items = <Widget>[];

    // Now line before everything (school hasn't started yet)
    if (showNowLine && nowInsertAfter == -1) {
      items.add(_NowLine(time: _now));
    }

    for (int i = 0; i < entries.length; i++) {
      items.add(_TimetableEntryCard(
          entry: entries[i], status: statuses[i]));
      // Insert NOW line after last past entry
      if (showNowLine && i == nowInsertAfter) {
        items.add(_NowLine(time: _now));
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: items,
    );
  }
}

// ── NOW indicator ─────────────────────────────────────────

class _NowLine extends StatelessWidget {
  final DateTime time;
  const _NowLine({required this.time});

  @override
  Widget build(BuildContext context) {
    final hm = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(height: 1.5, color: Colors.red),
          ),
          const SizedBox(width: 4),
          Text(
            hm,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Entry card ────────────────────────────────────────────

class _TimetableEntryCard extends ConsumerWidget {
  final TimetableEntry entry;
  final _Status status;

  const _TimetableEntryCard({required this.entry, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeSlotAsync = ref.watch(timeSlotByIdProvider(entry.timeSlotId));
    final theme = Theme.of(context);

    final subjectColor = entry.subjectColor != null
        ? Color(int.parse(
            'FF${entry.subjectColor!.replaceFirst('#', '')}',
            radix: 16))
        : theme.colorScheme.primaryContainer;

    // Past: reduce opacity to ~55% — colors remain but look faded.
    final opacity = status == _Status.past ? 0.55 : 1.0;

    Widget card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      // Current lesson: subtle elevation + outline for emphasis.
      elevation: status == _Status.current ? 4 : 1,
      shape: status == _Status.current
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: subjectColor, width: 1.5),
            )
          : null,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color bar
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: subjectColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Time column
            SizedBox(
              width: 64,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: timeSlotAsync.when(
                  data: (slot) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        slot?.label ?? '${slot?.slotNumber ?? '?'}',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (slot != null) ...[
                        const SizedBox(height: 2),
                        Text(slot.startTime.substring(0, 5),
                            style: theme.textTheme.bodySmall),
                        Text(slot.endTime.substring(0, 5),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            )),
                      ],
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const Text('?'),
                ),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.subjectName ??
                                entry.subjectAbbreviation ??
                                'Fach',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (status == _Status.current)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Jetzt',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14,
                            color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          entry.teacherName ??
                              entry.teacherAbbreviation ??
                              '–',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.room_outlined,
                            size: 14,
                            color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(entry.roomName ?? '–',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                    if (entry.weekType != WeekType.all)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Chip(
                          label: Text(
                              'Woche ${entry.weekType.name.toUpperCase()}'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelStyle: theme.textTheme.labelSmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Opacity(opacity: opacity, child: card);
  }
}
