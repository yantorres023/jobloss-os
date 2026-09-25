import 'package:flutter_test/flutter_test.dart';
import 'package:jobloss_os/domain/reminder_plan.dart';
import 'package:jobloss_os/domain/resolver.dart';
import 'package:jobloss_os/domain/user_data.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'helpers.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  List<TaskInstance> roadmapWithDetermination(String mailed, String today) => resolveRoadmap(
    dataset: realDataset(),
    data: UserData(
      notices: [
        Notice(id: 'n', typeId: 'tx.determination', loggedOn: d(today), mailedDate: d(mailed)),
      ],
    ),
    today: d(today),
  );

  test('hard deadline gets reminders 3 days before, 1 day before and on the day at 9:00 local', () {
    final chicago = tz.getLocation('America/Chicago');
    final roadmap = roadmapWithDetermination('2026-09-21', '2026-09-22'); // deadline 2026-10-05
    final plan = planReminders(
      roadmap: roadmap,
      location: chicago,
      now: tz.TZDateTime(chicago, 2026, 9, 22, 12),
    ).where((p) => p.instanceKey == 'tx.determination_deadline@n').toList();
    expect(plan.map((p) => '${p.at.year}-${p.at.month}-${p.at.day} ${p.at.hour}:00'), [
      '2026-10-2 9:00',
      '2026-10-4 9:00',
      '2026-10-5 9:00',
    ]);
  });

  test('9:00 stays 9:00 local across the DST change (Nov 1, 2026)', () {
    final chicago = tz.getLocation('America/Chicago');
    // Mailed 2026-10-20 -> deadline 2026-11-03; reminders 10-31 (CDT), 11-02 and 11-03 (CST).
    final plan = planReminders(
      roadmap: roadmapWithDetermination('2026-10-20', '2026-10-21'),
      location: chicago,
      now: tz.TZDateTime(chicago, 2026, 10, 21, 8),
    ).where((p) => p.instanceKey == 'tx.determination_deadline@n').toList();
    expect(plan.every((p) => p.at.hour == 9), isTrue);
    expect(plan.first.at.toUtc().hour, 14); // CDT = UTC-5
    expect(plan.last.at.toUtc().hour, 15); // CST = UTC-6
  });

  test('El Paso (Mountain time) gets 9:00 Mountain, not Central', () {
    final denver = tz.getLocation('America/Denver');
    final plan = planReminders(
      roadmap: roadmapWithDetermination('2026-09-21', '2026-09-22'),
      location: denver,
      now: tz.TZDateTime(denver, 2026, 9, 22, 12),
    );
    expect(plan.first.at.hour, 9);
    expect(plan.first.at.toUtc().hour, 15); // MDT = UTC-6
  });

  test('reminders in the past are not scheduled', () {
    final chicago = tz.getLocation('America/Chicago');
    final plan = planReminders(
      roadmap: roadmapWithDetermination('2026-09-21', '2026-10-04'),
      location: chicago,
      now: tz.TZDateTime(chicago, 2026, 10, 4, 10), // after 9:00 on the day-before reminder
    ).where((p) => p.instanceKey == 'tx.determination_deadline@n');
    expect(plan.map((p) => p.at.day), [5]);
  });

  test('done and waiting tasks get no reminders; count is capped', () {
    final data = UserData(
      profile: Profile(dates: {'first_filing_date': d('2026-09-27')}),
      notices: [
        for (var i = 0; i < 80; i++)
          Notice(
            id: 'n$i',
            typeId: 'tx.info_request',
            loggedOn: d('2026-09-25'),
            printedDeadline: d('2026-10-20'),
          ),
      ],
    );
    final roadmap = resolveRoadmap(dataset: realDataset(), data: data, today: d('2026-09-25'));
    data.completions['tx.request_payment#2026-09-27'] = Completion(
      instanceKey: 'tx.request_payment#2026-09-27',
      ruleId: 'tx.request_payment',
      completedOn: d('2026-09-27'),
      ruleVersion: 1,
      datasetVersion: 'x',
    );
    final roadmap2 = resolveRoadmap(dataset: realDataset(), data: data, today: d('2026-09-25'));
    final utc = tz.UTC;
    final plan = planReminders(
      roadmap: roadmap2,
      location: utc,
      now: tz.TZDateTime(utc, 2026, 9, 25),
    );
    expect(plan.length, maxScheduledReminders);
    expect(plan.any((p) => p.instanceKey == 'tx.request_payment#2026-09-27'), isFalse);
    expect(roadmap.length, greaterThan(roadmap2.where((t) => t.isDone).length));
  });

  test('notification ids are stable and distinct', () {
    expect(stableId('a|0'), stableId('a|0'));
    expect(stableId('a|0'), isNot(stableId('a|-1')));
    expect(stableId('x' * 500), inInclusiveRange(0, 0x7fffffff));
  });
}
