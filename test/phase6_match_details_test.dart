import 'package:flutter_test/flutter_test.dart';

import 'package:pickletrack/utils/match_date_format.dart';

void main() {
  group('formatMatchDate', () {
    // Pin "now" so tests are deterministic — DateTime.now() would
    // drift across CI runs / timezones.
    // Anchor the fixedNow to a clock time that puts the 12-month
    // test dates fully in the "older than a week" branch — this
    // is the 2024 set so 2024-01-03 is 615+ days before 2025-10-10.
    final fixedNow = DateTime(2025, 10, 10, 14, 30);

    test('returns Today plus time for same calendar day', () {
      final dt = DateTime(2025, 10, 10, 11, 15);
      expect(formatMatchDate(dt, now: fixedNow), 'Today, 11:15');
    });

    test('returns Yesterday plus time for previous calendar day', () {
      final dt = DateTime(2025, 10, 9, 19, 5);
      expect(formatMatchDate(dt, now: fixedNow), 'Yesterday, 19:05');
    });

    test('returns N days ago plus time for last 7 days', () {
      final dt = DateTime(2025, 10, 7, 9, 0);
      expect(formatMatchDate(dt, now: fixedNow), '3 days ago, 9:00');
    });

    test('returns absolute spelled-out date older than a week', () {
      final dt = DateTime(2025, 9, 28, 14, 22);
      // No time component — older than 7 days drops the wall-clock.
      expect(formatMatchDate(dt, now: fixedNow), 'Sep 28, 2025');
    });

    test(
      'crosses the calendar-day boundary correctly when "now" is after midnight',
      () {
        // 1:00 AM looking back at 11:30 PM the previous day → "Yesterday",
        // not a confusing absolute time.
        final now = DateTime(2025, 10, 10, 1, 0);
        final dt = DateTime(2025, 10, 9, 23, 30);
        expect(formatMatchDate(dt, now: now), 'Yesterday, 23:30');
      },
    );

    test('crosses calendar boundary forward when "now" is before midnight', () {
      // 11:00 PM looking at 1:00 AM the same "join date" — same calendar
      // day, should read as Today.
      final now = DateTime(2025, 10, 10, 23, 0);
      final dt = DateTime(2025, 10, 10, 1, 15);
      expect(formatMatchDate(dt, now: now), 'Today, 1:15');
    });

    test('pads single-digit minutes with a leading zero', () {
      final dt = DateTime(2025, 10, 10, 8, 5);
      expect(formatMatchDate(dt, now: fixedNow), 'Today, 8:05');
    });

    test('handles all 12 months in the spelled-out fallback', () {
      // Pin the exact expected output for each month so an
      // index-off-by-one in the months array would surface immediately.
      final expected = [
        'Jan 3, 2024',
        'Feb 3, 2024',
        'Mar 3, 2024',
        'Apr 3, 2024',
        'May 3, 2024',
        'Jun 3, 2024',
        'Jul 3, 2024',
        'Aug 3, 2024',
        'Sep 3, 2024',
        'Oct 3, 2024',
        'Nov 3, 2024',
        'Dec 3, 2024',
      ];
      final cases = [
        DateTime(2024, 1, 3),
        DateTime(2024, 2, 3),
        DateTime(2024, 3, 3),
        DateTime(2024, 4, 3),
        DateTime(2024, 5, 3),
        DateTime(2024, 6, 3),
        DateTime(2024, 7, 3),
        DateTime(2024, 8, 3),
        DateTime(2024, 9, 3),
        DateTime(2024, 10, 3),
        DateTime(2024, 11, 3),
        DateTime(2024, 12, 3),
      ];
      for (var i = 0; i < cases.length; i++) {
        expect(
          formatMatchDate(cases[i], now: fixedNow),
          expected[i],
          reason: 'month index ${i + 1} (\$dt) ↔ expected "${expected[i]}"',
        );
      }
    });
  });
}
