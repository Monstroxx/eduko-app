import 'package:flutter_test/flutter_test.dart';

// ── Pure helpers (copy of logic from widgets) ──────────────
// Keeping these as standalone functions makes them trivially testable.

int toMinutes(String? s) {
  if (s == null) return -1;
  final p = s.split(':');
  if (p.length < 2) return -1;
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

enum Status { past, current, upcoming }

Status entryStatus(String? start, String? end, int nowMin) {
  final s = toMinutes(start);
  final e = toMinutes(end);
  if (s < 0) return Status.upcoming;
  if (e >= 0 && nowMin > e) return Status.past;
  if (nowMin >= s) return Status.current;
  return Status.upcoming;
}

void main() {
  group('toMinutes', () {
    test('null → -1', () => expect(toMinutes(null), -1));
    test('empty → -1', () => expect(toMinutes(''), -1));
    test('08:00:00 → 480', () => expect(toMinutes('08:00:00'), 480));
    test('08:00 → 480', () => expect(toMinutes('08:00'), 480));
    test('09:45:00 → 585', () => expect(toMinutes('09:45:00'), 585));
    test('23:59:00 → 1439', () => expect(toMinutes('23:59:00'), 1439));
    test('00:00:00 → 0', () => expect(toMinutes('00:00:00'), 0));
  });

  group('entryStatus', () {
    // Slot: 08:00–08:45
    const start = '08:00:00';
    const end = '08:45:00'; // 525

    test('before slot starts → upcoming', () {
      expect(entryStatus(start, end, 460), Status.upcoming); // 07:40
    });

    test('at start → current', () {
      expect(entryStatus(start, end, 480), Status.current); // 08:00
    });

    test('during slot → current', () {
      expect(entryStatus(start, end, 510), Status.current); // 08:30
    });

    test('at exact end → current (boundary inclusive)', () {
      expect(entryStatus(start, end, 525), Status.current); // 08:45
    });

    test('after end → past', () {
      expect(entryStatus(start, end, 526), Status.past); // 08:46
    });

    test('no start info → upcoming', () {
      expect(entryStatus(null, end, 600), Status.upcoming);
    });

    test('no end info → current if started', () {
      // Without end time, once started treat as current (not past)
      expect(entryStatus(start, null, 600), Status.current);
    });

    test('no end, not started → upcoming', () {
      expect(entryStatus(start, null, 400), Status.upcoming);
    });
  });

  group('NOW line insertion logic', () {
    // Simulates: given a list of slot statuses, find insertion point
    // (insert after last past, before first non-past)
    int findInsertAfter(List<Status> statuses) {
      int insertAfter = -1;
      for (int i = 0; i < statuses.length; i++) {
        if (statuses[i] == Status.past) insertAfter = i;
      }
      return insertAfter;
    }

    test('all upcoming → insert at -1 (before everything)', () {
      expect(
          findInsertAfter([
            Status.upcoming,
            Status.upcoming,
            Status.upcoming,
          ]),
          -1);
    });

    test('first is past, rest upcoming → insert after 0', () {
      expect(
          findInsertAfter([
            Status.past,
            Status.upcoming,
            Status.upcoming,
          ]),
          0);
    });

    test('two past, one upcoming → insert after 1', () {
      expect(
          findInsertAfter([
            Status.past,
            Status.past,
            Status.upcoming,
          ]),
          1);
    });

    test('first past, second current, third upcoming → insert after 0', () {
      expect(
          findInsertAfter([
            Status.past,
            Status.current,
            Status.upcoming,
          ]),
          0);
    });

    test('all past → insert after last (-1 means past everything)', () {
      expect(
          findInsertAfter([
            Status.past,
            Status.past,
            Status.past,
          ]),
          2);
    });
  });
}
