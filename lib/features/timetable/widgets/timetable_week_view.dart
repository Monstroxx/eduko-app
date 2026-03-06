import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/substitution.dart';
import '../../../core/models/timetable_entry.dart';
import '../../../core/providers/reference_data_provider.dart';
import '../../../core/providers/substitution_provider.dart';
import '../../../core/providers/timetable_provider.dart';

// ── Helpers ────────────────────────────────────────────────

int _toMinutes(String? s) {
  if (s == null) return -1;
  final p = s.split(':');
  if (p.length < 2) return -1;
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

enum _Status { past, current, upcoming }

_Status _slotStatus(String? start, String? end, int nowMin, bool isToday) {
  if (!isToday) return _Status.upcoming;
  final s = _toMinutes(start);
  final e = _toMinutes(end);
  if (s < 0) return _Status.upcoming;
  if (e >= 0 && nowMin > e) return _Status.past;
  if (nowMin >= s) return _Status.current;
  return _Status.upcoming;
}

// ── Week View ──────────────────────────────────────────────

class TimetableWeekView extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const TimetableWeekView({super.key, required this.selectedDate});

  @override
  ConsumerState<TimetableWeekView> createState() => _TimetableWeekViewState();
}

class _TimetableWeekViewState extends ConsumerState<TimetableWeekView> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30),
        (_) { if (mounted) setState(() => _now = DateTime.now()); });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(timetableByDayProvider);
    final timeSlotsAsync = ref.watch(timeSlotsProvider);
    final theme = Theme.of(context);

    final monday = widget.selectedDate
        .subtract(Duration(days: widget.selectedDate.weekday - 1));

    // Today's weekday (1–7); only 1–5 shown
    final todayWeekday = _now.weekday;
    final isCurrentWeek = monday.year == _now.year &&
        monday.month == _now.month &&
        monday.day == _now.subtract(Duration(days: _now.weekday - 1)).day;
    final nowMin = _now.hour * 60 + _now.minute;

    final dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr'];

    // Load substitution maps for all 5 days of the week
    final subMaps = <int, Map<String, Substitution>>{
      for (int d = 0; d < 5; d++)
        d + 1: ref
            .watch(substitutionMapByDateProvider(monday.add(Duration(days: d))))
            .valueOrNull ?? const {},
    };

    return timetableAsync.when(
      data: (byDay) => timeSlotsAsync.when(
        data: (timeSlots) {
          if (timeSlots.isEmpty) {
            return const Center(child: Text('Kein Stundenplan'));
          }

          final sortedSlots = [...timeSlots]
            ..sort((a, b) => a.slotNumber.compareTo(b.slotNumber));

          // Find current slot index (for the NOW row indicator)
          int currentSlotIndex = -1;
          if (isCurrentWeek) {
            for (int i = 0; i < sortedSlots.length; i++) {
              final slot = sortedSlots[i];
              final s = _toMinutes(slot.startTime.length > 4
                  ? slot.startTime : null);
              final e = _toMinutes(slot.endTime.length > 4
                  ? slot.endTime : null);
              if (s >= 0 && e >= 0 && nowMin >= s && nowMin <= e) {
                currentSlotIndex = i;
                break;
              }
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Header row ───────────────────────
                _buildHeader(
                  context, theme, monday, dayNames,
                  isCurrentWeek, todayWeekday,
                ),
                // ── Slot rows ────────────────────────
                for (int si = 0; si < sortedSlots.length; si++) ...[
                  // NOW marker row: inserted before the first upcoming slot
                  if (isCurrentWeek && currentSlotIndex == -1)
                    _maybeNowRowBefore(si, sortedSlots, nowMin, theme),

                  _buildSlotRow(
                    context, theme, sortedSlots[si], byDay,
                    si == currentSlotIndex, isCurrentWeek, todayWeekday, nowMin,
                    subMaps,
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
    );
  }

  /// Returns the NOW indicator row widget if we should insert it before slot [si].
  Widget _maybeNowRowBefore(int si, List<dynamic> slots, int nowMin,
      ThemeData theme) {
    if (si == 0) return const SizedBox.shrink();
    final prevEnd = _toMinutes(slots[si - 1].endTime);
    final nextStart = _toMinutes(slots[si].startTime);
    if (prevEnd < 0 || nextStart < 0) return const SizedBox.shrink();
    if (nowMin > prevEnd && nowMin < nextStart) {
      return _NowRowIndicator(time: _now);
    }
    return const SizedBox.shrink();
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    DateTime monday,
    List<String> dayNames,
    bool isCurrentWeek,
    int todayWeekday,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Time column header
          SizedBox(
            width: 48,
            height: 44,
            child: Center(
              child: Icon(Icons.schedule_outlined,
                  size: 16, color: theme.colorScheme.outline),
            ),
          ),
          for (int d = 0; d < 5; d++)
            Expanded(
              child: _DayHeader(
                name: dayNames[d],
                date: monday.add(Duration(days: d)),
                isToday:
                    isCurrentWeek && todayWeekday == d + 1,
                theme: theme,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlotRow(
    BuildContext context,
    ThemeData theme,
    dynamic slot,
    Map<int, List<TimetableEntry>> byDay,
    bool isCurrentSlot,
    bool isCurrentWeek,
    int todayWeekday,
    int nowMin,
    Map<int, Map<String, Substitution>> subMaps,
  ) {
    final rowBg = isCurrentSlot
        ? theme.colorScheme.primaryContainer.withAlpha(40)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(
          bottom: BorderSide(
              color: theme.colorScheme.outlineVariant, width: 0.5),
          left: isCurrentSlot
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time label
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slot.label ?? '${slot.slotNumber}',
                    style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    slot.startTime.substring(0, 5),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // One cell per day
          for (int d = 1; d <= 5; d++)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                        color: theme.colorScheme.outlineVariant, width: 0.5),
                  ),
                ),
                child: Builder(builder: (context) {
                  final cellEntries = (byDay[d] ?? [])
                      .where((e) => e.timeSlotId == slot.id)
                      .toList();
                  final sub = cellEntries.isNotEmpty
                      ? (subMaps[d] ?? {})[cellEntries.first.id]
                      : null;
                  return _WeekCell(
                    entries: cellEntries,
                    slotStatus: _slotStatus(
                      slot.startTime,
                      slot.endTime,
                      nowMin,
                      isCurrentWeek && todayWeekday == d,
                    ),
                    isCurrentDay: isCurrentWeek && todayWeekday == d,
                    substitution: sub,
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Day header ────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  final String name;
  final DateTime date;
  final bool isToday;
  final ThemeData theme;

  const _DayHeader({
    required this.name,
    required this.date,
    required this.isToday,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: isToday
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name,
              style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 1),
          isToday
              ? Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
              : Text(
                  DateFormat('d.M').format(date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
        ],
      ),
    );
  }
}

// ── NOW row indicator ──────────────────────────────────────

class _NowRowIndicator extends StatelessWidget {
  final DateTime time;
  const _NowRowIndicator({required this.time});

  @override
  Widget build(BuildContext context) {
    final hm = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Center(
            child: Text(hm,
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        Expanded(
          child: Container(height: 1.5, color: Colors.red),
        ),
      ],
    );
  }
}

// ── Week cell ─────────────────────────────────────────────

class _WeekCell extends StatelessWidget {
  final List<TimetableEntry> entries;
  final _Status slotStatus;
  final bool isCurrentDay;
  final Substitution? substitution;

  const _WeekCell({
    required this.entries,
    required this.slotStatus,
    required this.isCurrentDay,
    this.substitution,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = 52.0;

    if (entries.isEmpty) {
      return SizedBox(height: height);
    }

    final entry = entries.first;
    final sub = substitution;
    final isCancelled = sub?.type == SubstitutionType.cancellation;

    final subjectColor = entry.subjectColor != null
        ? Color(int.parse(
            'FF${entry.subjectColor!.replaceFirst('#', '')}',
            radix: 16))
        : theme.colorScheme.primaryContainer;

    final barColor = sub == null
        ? subjectColor
        : switch (sub.type) {
            SubstitutionType.cancellation => Colors.grey,
            SubstitutionType.substitution => Colors.orange,
            SubstitutionType.roomChange => Colors.teal,
            SubstitutionType.extraLesson => Colors.purple,
          };

    // Past / cancelled: reduce opacity
    final isPast = slotStatus == _Status.past;
    final isCurrent = slotStatus == _Status.current;
    final opacity = (isPast || isCancelled) ? 0.55 : 1.0;

    // Display text: substitution may override room
    final displaySubject = entry.subjectAbbreviation ??
        (entry.subjectName?.isNotEmpty == true
            ? entry.subjectName!.substring(
                0,
                entry.subjectName!.length > 3
                    ? 3
                    : entry.subjectName!.length)
            : '?');
    final displayRoom =
        sub?.substituteRoomName ?? entry.roomName;

    Widget cell = Container(
      height: height,
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: barColor.withAlpha(isPast ? 25 : 55),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isCurrent ? Colors.red : barColor,
            width: isCurrent ? 1.5 : sub != null ? 1.5 : 0.5,
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displaySubject,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: isCurrent ? Colors.red : null,
                      decoration: isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Tiny dot indicator for substitution type
                if (sub != null)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: barColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            if (displayRoom != null)
              Text(
                displayRoom,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 8,
                  color: sub?.substituteRoomName != null
                      ? Colors.teal.shade700
                      : theme.colorScheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );

    return Opacity(opacity: opacity, child: cell);
  }
}
