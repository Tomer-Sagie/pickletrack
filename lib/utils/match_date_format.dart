/// Formats a match completion timestamp into a human-readable label.
///
/// Recent matches (within 7 calendar days) show a relative label plus
/// the wall-clock time: "Today, 14:32" / "Yesterday, 9:15" /
/// "3 days ago, 11:00". Older matches fall back to a fully spelled-out
/// date so the user doesn't have to guess which month numbers
/// correspond to: "Oct 4, 2025".
///
/// Compares calendar days (not wall-clock hours) so a match finished
/// at 11:30 PM and viewed at 1:00 AM reads as "Today" / "Yesterday"
/// rather than as a confusing absolute time.
///
/// Pass [now] to fix the "current" instant in tests. Defaults to
/// [DateTime.now] in production.
String formatMatchDate(DateTime dt, {DateTime? now}) {
  final referenceNow = now ?? DateTime.now();
  // Build both calendar-day dates in UTC. UTC has no daylight saving
  // transitions, so every successive calendar day is exactly 24 hours
  // apart. Using local DateTime instead makes `.difference().inDays`
  // fragile: a DST shift between two dates truncates the inDays value
  // (e.g. 23h59m → "0 days ago" instead of "1 days ago"), and also
  // becomes non-deterministic across test runs — native SQLite
  // initialization (createInMemoryDatabase() during phase6 widget
  // tests) invokes system tzset() calls that update the Dart VM's
  // timezone cache mid-run and shift the boundary mid-suite.
  final today = DateTime.utc(
    referenceNow.year,
    referenceNow.month,
    referenceNow.day,
  );
  final dtDay = DateTime.utc(dt.year, dt.month, dt.day);
  final diff = today.difference(dtDay).inDays;

  String relative;
  if (diff == 0) {
    relative = 'Today';
  } else if (diff == 1) {
    relative = 'Yesterday';
  } else if (diff < 7) {
    relative = '$diff days ago';
  } else {
    // Older than a week — fall back to a fully spelled-out date so the
    // user doesn't have to guess which month numbers correspond to.
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    relative = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  final time =
      '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  // When the relative label already has a year, the absolute time is
  // noise — drop it. Otherwise combine so the user can quickly check
  // both "when" and "what time" in a single glance.
  return diff < 7 ? '$relative, $time' : relative;
}
