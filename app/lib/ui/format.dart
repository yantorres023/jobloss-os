import 'package:intl/intl.dart';

import '../domain/local_date.dart';
import '../domain/resolver.dart';

DateTime _dt(LocalDate d) => DateTime(d.year, d.month, d.day);

String formatDate(LocalDate d) => DateFormat('EEE, MMM d, y').format(_dt(d));
String formatShort(LocalDate d) => DateFormat('MMM d').format(_dt(d));

/// "Today", "Tomorrow", "In 5 days", "2 days ago".
String relativeDay(LocalDate d, LocalDate today) {
  final n = today.daysUntil(d);
  if (n == 0) return 'Today';
  if (n == 1) return 'Tomorrow';
  if (n == -1) return 'Yesterday';
  if (n > 1) return 'In $n days';
  return '${-n} days ago';
}

/// One line describing when a task is due, for list rows.
String dueLine(TaskInstance t, LocalDate today) {
  if (t.isDone) {
    final c = t.completion;
    return c == null ? 'Done' : 'Done ${formatShort(c.completedOn)}';
  }
  final d = t.deadlineDate ?? t.due;
  if (d == null) return 'Anytime';
  final label = t.rule.deadline.label;
  final hard = t.rule.deadline.hard && t.hardDeadline != null;
  if (hard && d.isBefore(today)) {
    return '${label ?? 'Deadline'} was ${formatShort(d)} — check your letter';
  }
  if (t.basis == DateBasis.asap && !hard) {
    return d.isAfter(today) ? 'Starts ${formatShort(d)}' : 'As soon as you can';
  }
  final prefix = hard ? (label ?? 'Deadline') : 'Do by';
  return '$prefix: ${formatShort(d)} (${relativeDay(d, today).toLowerCase()})';
}

String basisText(DateBasis b) => switch (b) {
  DateBasis.none => 'No date',
  DateBasis.asap => 'As soon as possible',
  DateBasis.printedOnNotice => 'Date you entered from your letter',
  DateBasis.eventOnNotice => 'Appointment/hearing date from your letter',
  DateBasis.computedEstimate => 'Estimated by the app from a date you entered — your letter wins',
  DateBasis.userSchedule => 'From the filing/work-search dates you entered',
};
