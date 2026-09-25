/// A calendar date with no time or time zone.
///
/// Unemployment deadlines are calendar dates printed on letters. Storing them
/// as [DateTime] invites off-by-one errors around midnight and DST, so every
/// date in the domain layer is a [LocalDate]. Arithmetic is done in UTC, where
/// every day is exactly 24 hours.
class LocalDate implements Comparable<LocalDate> {
  LocalDate(this.year, this.month, this.day) {
    final check = DateTime.utc(year, month, day);
    if (check.year != year || check.month != month || check.day != day) {
      throw ArgumentError('Invalid date: $year-$month-$day');
    }
  }

  factory LocalDate.fromDateTime(DateTime dt) => LocalDate(dt.year, dt.month, dt.day);

  /// Parses `YYYY-MM-DD`. Throws [FormatException] on anything else.
  factory LocalDate.parse(String s) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
    if (m == null) throw FormatException('Expected YYYY-MM-DD', s);
    try {
      return LocalDate(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
    } on ArgumentError {
      throw FormatException('Invalid calendar date', s);
    }
  }

  static LocalDate? tryParse(String? s) {
    if (s == null) return null;
    try {
      return LocalDate.parse(s);
    } on FormatException {
      return null;
    }
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  LocalDate addDays(int days) => LocalDate.fromDateTime(_utc.add(Duration(days: days)));

  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  /// ISO weekday: Monday = 1 ... Sunday = 7.
  int get weekday => _utc.weekday;

  /// Sunday on or before this date. Texas payment-request "calendar weeks"
  /// and work-search weeks are treated as Sunday–Saturday.
  LocalDate get startOfWeekSunday => addDays(-(weekday % 7));

  /// Saturday on or after this date.
  LocalDate get endOfWeekSaturday => startOfWeekSunday.addDays(6);

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  static LocalDate min(LocalDate a, LocalDate b) => a.isBefore(b) ? a : b;
  static LocalDate max(LocalDate a, LocalDate b) => a.isAfter(b) ? a : b;

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  String toString() => toIso();
}
