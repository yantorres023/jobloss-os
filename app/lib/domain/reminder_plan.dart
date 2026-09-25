import 'package:timezone/timezone.dart' as tz;

import 'local_date.dart';
import 'resolver.dart';

class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.instanceKey,
  });

  final int id;
  final tz.TZDateTime at;
  final String title;
  final String body;
  final String instanceKey;
}

/// iOS keeps at most 64 pending local notifications per app.
const int maxScheduledReminders = 60;

/// Plans local reminders for open tasks.
///
/// - Every open dated task: at [hour]:00 local time on its due date.
/// - Hard deadlines additionally 3 days and 1 day before.
/// - Reminders in the past are dropped.
/// Times are wall-clock in [location], so a 9:00 reminder stays 9:00 across
/// daylight-saving changes.
List<PlannedReminder> planReminders({
  required List<TaskInstance> roadmap,
  required tz.Location location,
  required tz.TZDateTime now,
  int hour = 9,
}) {
  final planned = <PlannedReminder>[];
  for (final t in roadmap) {
    if (t.isDone || t.blockedBy.isNotEmpty) continue;
    final due = t.due;
    if (due == null) continue;

    final offsets = <int>[0];
    final hard = t.hardDeadline;
    if (t.rule.deadline.hard && hard != null) {
      offsets.addAll([-3, -1]);
    }
    for (final off in offsets) {
      final day = (off == 0 ? due : (hard ?? due).addDays(off));
      final at = wallClock(location, day, hour);
      if (!at.isAfter(now)) continue;
      final label = t.rule.deadline.label ?? 'Due';
      final dateText = (hard ?? due).toIso();
      planned.add(
        PlannedReminder(
          id: stableId('${t.key}|$off'),
          at: at,
          title: off == 0 ? t.rule.title : '$label in ${-off} day${off == -1 ? '' : 's'}',
          body: off == 0
              ? 'Open JobLoss OS to see the step and the official source.'
              : '${t.rule.title} — $dateText. Check the date on your letter.',
          instanceKey: t.key,
        ),
      );
    }
  }
  planned.sort((a, b) => a.at.compareTo(b.at));
  return planned.take(maxScheduledReminders).toList();
}

tz.TZDateTime wallClock(tz.Location loc, LocalDate day, int hour) =>
    tz.TZDateTime(loc, day.year, day.month, day.day, hour);

/// 31-bit FNV-1a hash — stable across runs and platforms (unlike
/// String.hashCode), and fits Android's int notification id.
int stableId(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}
