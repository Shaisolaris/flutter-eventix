/// Lightweight date/time formatting for the UI layer. Deliberately
/// dependency-free (no `intl` package) - Eventix only ever needs a handful
/// of short, English date and time labels for event listings and tickets.
const List<String> _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// [DateTime.weekday] is 1 (Monday) through 7 (Sunday); index accordingly.
const List<String> _weekdayAbbreviations = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// e.g. "Sat, Sep 12".
String formatEventDate(DateTime dateTime) {
  final weekday = _weekdayAbbreviations[dateTime.weekday - 1];
  final month = _monthAbbreviations[dateTime.month - 1];
  return '$weekday, $month ${dateTime.day}';
}

/// e.g. "7:00 PM". Midnight is "12:00 AM", noon is "12:00 PM".
String formatEventTime(DateTime dateTime) {
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}

/// e.g. "Sat, Sep 12 · 7:00 PM" - the combined label used on event cards,
/// the detail screen, and ticket cards.
String formatEventDateTime(DateTime dateTime) {
  return '${formatEventDate(dateTime)} · ${formatEventTime(dateTime)}';
}

/// e.g. "Sep 12, 2026" - used where a full, year-inclusive date stands
/// alone (e.g. a saved-event subtitle).
String formatShortDate(DateTime dateTime) {
  return '${_monthAbbreviations[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
}
