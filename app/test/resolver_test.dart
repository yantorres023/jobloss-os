import 'package:flutter_test/flutter_test.dart';
import 'package:jobloss_os/domain/local_date.dart';
import 'package:jobloss_os/domain/resolver.dart';
import 'package:jobloss_os/domain/rules.dart';
import 'package:jobloss_os/domain/user_data.dart';

import 'helpers.dart';

void main() {
  late RuleDataset ds;
  setUp(() => ds = realDataset());

  List<TaskInstance> resolve(UserData data, String today) =>
      resolveRoadmap(dataset: ds, data: data, today: d(today));

  TaskInstance? find(List<TaskInstance> r, String key) {
    for (final t in r) {
      if (t.key == key) return t;
    }
    return null;
  }

  UserData withDates(Map<String, String> dates, {Map<String, int> counts = const {}}) => UserData(
    profile: Profile(
      dates: {for (final e in dates.entries) e.key: d(e.value)},
      counts: {...counts},
      onboarded: true,
    ),
  );

  group('Rule applicability', () {
    test('before any dates only fact-free rules apply', () {
      final r = resolve(UserData(), '2026-09-25');
      expect(r.map((t) => t.rule.ruleId), ['us.scam_safety']);
    });

    test('last day worked unlocks first steps, not claim-setup steps', () {
      final r = resolve(withDates({'last_day_worked': '2026-09-24'}), '2026-09-25');
      final ids = r.map((t) => t.rule.ruleId).toSet();
      expect(ids, containsAll(['tx.apply_for_benefits', 'app.save_separation_papers']));
      expect(ids, isNot(contains('tx.register_workintexas')));
      expect(ids, isNot(contains('tx.request_payment')));
      expect(ids, isNot(contains('us.marketplace_window')));
    });

    test('applying auto-completes the apply step and unlocks claim setup', () {
      final r = resolve(
        withDates({'last_day_worked': '2026-09-24', 'applied_date': '2026-09-25'}),
        '2026-09-25',
      );
      final apply = find(r, 'tx.apply_for_benefits')!;
      expect(apply.isDone, isTrue);
      expect(apply.autoCompletedByFact, 'applied_date');
      expect(find(r, 'tx.register_workintexas'), isNotNull);
      expect(find(r, 'tx.find_first_filing_date'), isNotNull);
    });

    test('rules outside their effective window do not apply', () {
      final m = datasetMap();
      ruleIn(m, 'us.scam_safety')['effective_to'] = '2026-01-01';
      ds = datasetFrom(m);
      expect(resolve(UserData(), '2026-09-25'), isEmpty);
    });

    test('inactive rules do not apply', () {
      final m = datasetMap();
      ruleIn(m, 'us.scam_safety')['active'] = false;
      ds = datasetFrom(m);
      expect(resolve(UserData(), '2026-09-25'), isEmpty);
    });
  });

  group('Deadlines', () {
    test('WorkInTexas registration: 3 calendar days after applying, hard', () {
      final r = resolve(
        withDates({'last_day_worked': '2026-09-24', 'applied_date': '2026-09-25'}),
        '2026-09-25',
      );
      final t = find(r, 'tx.register_workintexas')!;
      // Applied Friday; business-day reading would be Wednesday. The app
      // deliberately uses the earlier calendar-day date (Monday).
      expect(t.due, d('2026-09-28'));
      expect(t.hardDeadline, d('2026-09-28'));
      expect(t.basis, DateBasis.computedEstimate);
    });

    test('Marketplace window: 60 days after coverage ends', () {
      final r = resolve(withDates({'coverage_end_date': '2026-09-30'}), '2026-09-25');
      expect(find(r, 'us.marketplace_window')!.hardDeadline, d('2026-11-29'));
    });

    test('asap step is due on the date it started applying', () {
      final r = resolve(withDates({'last_day_worked': '2026-09-20'}), '2026-09-25');
      final t = find(r, 'tx.apply_for_benefits')!;
      expect(t.due, d('2026-09-20'));
      expect(t.bucket(d('2026-09-25')), Bucket.today);
      expect(t.hardDeadline, isNull);
    });

    Notice notice(String type, {String? mailed, String? printed, String? event}) => Notice(
      id: 'n1',
      typeId: type,
      loggedOn: d('2026-09-25'),
      mailedDate: LocalDate.tryParse(mailed),
      printedDeadline: LocalDate.tryParse(printed),
      eventDate: LocalDate.tryParse(event),
    );

    test('determination: printed deadline wins over computed estimate', () {
      final data = UserData(
        notices: [notice('tx.determination', mailed: '2026-09-21', printed: '2026-10-05')],
      );
      final t = find(resolve(data, '2026-09-25'), 'tx.determination_deadline@n1')!;
      expect(t.due, d('2026-10-05'));
      expect(t.hardDeadline, d('2026-10-05'));
      expect(t.basis, DateBasis.printedOnNotice);
      expect(t.warnings, isEmpty);
    });

    test('determination: computed from mailing date (+14), labeled estimate', () {
      final data = UserData(notices: [notice('tx.determination', mailed: '2026-09-21')]);
      final t = find(resolve(data, '2026-09-25'), 'tx.determination_deadline@n1')!;
      expect(t.due, d('2026-10-05'));
      expect(t.basis, DateBasis.computedEstimate);
      expect(t.warnings.single, contains('Estimated'));
    });

    test('determination: no holiday/weekend extension (conservative)', () {
      // Mailed 2026-11-12; +14 = 2026-11-26 (Thanksgiving). Not extended.
      final data = UserData(notices: [notice('tx.determination', mailed: '2026-11-12')]);
      final t = find(resolve(data, '2026-11-13'), 'tx.determination_deadline@n1')!;
      expect(t.hardDeadline, d('2026-11-26'));
    });

    test('determination: a printed date much later than usual gets a warning', () {
      final data = UserData(
        notices: [notice('tx.determination', mailed: '2026-09-01', printed: '2026-10-30')],
      );
      final t = find(resolve(data, '2026-09-25'), 'tx.determination_deadline@n1')!;
      expect(t.due, d('2026-10-30'));
      expect(t.warnings.single, contains('Double-check'));
    });

    test('determination with no dates asks for them and has no hard deadline', () {
      final data = UserData(notices: [notice('tx.determination')]);
      final t = find(resolve(data, '2026-09-25'), 'tx.determination_deadline@n1')!;
      expect(t.basis, DateBasis.asap);
      expect(t.hardDeadline, isNull);
      expect(t.warnings.single, contains('Add the mailing date'));
    });

    test('hearing uses the event date from the letter', () {
      final data = UserData(
        notices: [notice('tx.hearing_notice', mailed: '2026-09-20', event: '2026-10-02')],
      );
      final t = find(resolve(data, '2026-09-25'), 'tx.prepare_for_hearing@n1')!;
      expect(t.due, d('2026-10-02'));
      expect(t.basis, DateBasis.eventOnNotice);
    });

    test('each logged letter creates its own task instance', () {
      final data = UserData(
        notices: [
          notice('tx.determination', mailed: '2026-09-01'),
          Notice(
            id: 'n2',
            typeId: 'tx.determination',
            loggedOn: d('2026-09-25'),
            mailedDate: d('2026-09-10'),
          ),
        ],
      );
      final r = resolve(data, '2026-09-25');
      expect(find(r, 'tx.determination_deadline@n1')!.due, d('2026-09-15'));
      expect(find(r, 'tx.determination_deadline@n2')!.due, d('2026-09-24'));
    });
  });

  group('Recurring payment requests', () {
    UserData claim({String? ended}) => withDates({
      'last_day_worked': '2026-08-28',
      'applied_date': '2026-08-31',
      'first_filing_date': '2026-09-13', // a Sunday
      'claim_ended_date': ?ended,
    });

    test('every 14 days from the First Filing Date, late after that Saturday', () {
      final r = resolve(claim(), '2026-09-25');
      final reqs = r.where((t) => t.rule.ruleId == 'tx.request_payment').toList();
      expect(reqs.map((t) => t.due), [
        d('2026-09-13'),
        d('2026-09-27'),
        d('2026-10-11'),
        d('2026-10-25'),
      ]);
      final first = reqs.first;
      expect(first.key, 'tx.request_payment#2026-09-13');
      expect(first.hardDeadline, d('2026-09-19'));
      expect(first.basis, DateBasis.userSchedule);
    });

    test('mid-week filing day: late-after is the Saturday of the same week', () {
      final data = withDates({'first_filing_date': '2026-09-16'}); // Wednesday
      final t = resolve(
        data,
        '2026-09-16',
      ).firstWhere((t) => t.rule.ruleId == 'tx.request_payment');
      expect(t.hardDeadline, d('2026-09-19'));
    });

    test('stops after the claim ended date', () {
      final r = resolve(claim(ended: '2026-10-01'), '2026-09-25');
      final dues = r.where((t) => t.rule.ruleId == 'tx.request_payment').map((t) => t.due);
      expect(dues, [d('2026-09-13'), d('2026-09-27')]);
    });

    test('old undone occurrences outside the look-back window are not generated', () {
      final r = resolve(withDates({'first_filing_date': '2026-01-04'}), '2026-09-25');
      final dues = r
          .where((t) => t.rule.ruleId == 'tx.request_payment')
          .map((t) => t.due!)
          .toList();
      expect(dues.first.isBefore(d('2026-09-25').addDays(-recurringLookbackDays)), isFalse);
      // Cadence is preserved: every date is a multiple of 14 days from the start.
      for (final x in dues) {
        expect(d('2026-01-04').daysUntil(x) % 14, 0);
      }
    });

    test('past completed occurrences are kept even outside the look-back', () {
      final data = withDates({'first_filing_date': '2026-01-04'});
      data.completions['tx.request_payment#2026-01-04'] = Completion(
        instanceKey: 'tx.request_payment#2026-01-04',
        ruleId: 'tx.request_payment',
        completedOn: d('2026-01-04'),
        ruleVersion: 1,
        datasetVersion: 'x',
      );
      final r = resolve(data, '2026-09-25');
      expect(find(r, 'tx.request_payment#2026-01-04')?.isDone, isTrue);
    });
  });

  group('Weekly work search', () {
    test('one instance per Sunday–Saturday week up to the current week', () {
      final data = withDates(
        {'work_search_start_date': '2026-09-09'}, // Wednesday
        counts: {'work_search_required_per_week': 3},
      );
      final weeks = resolve(
        data,
        '2026-09-25',
      ).where((t) => t.rule.ruleId == 'tx.work_search_week').toList();
      expect(weeks.map((t) => t.occurrence), [d('2026-09-06'), d('2026-09-13'), d('2026-09-20')]);
      expect(weeks.last.due, d('2026-09-26'));
      expect(weeks.last.hardDeadline, isNull);
    });

    test('needs the count from the TWC letter before it applies', () {
      final data = withDates({'work_search_start_date': '2026-09-09'});
      expect(
        resolve(data, '2026-09-25').where((t) => t.rule.ruleId == 'tx.work_search_week'),
        isEmpty,
      );
    });

    test('counts activities within the week only', () {
      final data = UserData(
        workSearch: [
          WorkSearchEntry(id: 'a', date: d('2026-09-19'), employer: 'Sat before'),
          WorkSearchEntry(id: 'b', date: d('2026-09-20'), employer: 'Sunday'),
          WorkSearchEntry(id: 'c', date: d('2026-09-26'), employer: 'Saturday'),
          WorkSearchEntry(id: 'e', date: d('2026-09-27'), employer: 'Next Sunday'),
        ],
      );
      expect(workSearchCountForWeek(data, d('2026-09-23')), 2);
    });
  });

  group('Dependencies, buckets and next deadline', () {
    test('steps wait for their dependency', () {
      final data = withDates({'applied_date': '2026-09-25'});
      // tx.apply_for_benefits needs last_day_worked, so it is absent here and
      // cannot block. Add it back and un-apply to see blocking.
      final r = resolve(data, '2026-09-25');
      expect(find(r, 'tx.tax_withholding')!.blockedBy, isEmpty);

      final m = datasetMap();
      ruleIn(m, 'tx.apply_for_benefits')['completes_with_fact'] = null;
      ds = datasetFrom(m);
      final r2 = resolve(
        withDates({'last_day_worked': '2026-09-20', 'applied_date': '2026-09-25'}),
        '2026-09-25',
      );
      final tax = find(r2, 'tx.tax_withholding')!;
      expect(tax.blockedBy, ['tx.apply_for_benefits']);
      expect(tax.bucket(d('2026-09-25')), Bucket.waiting);
    });

    test('buckets: today / upcoming / anytime / done', () {
      final data = withDates({'last_day_worked': '2026-09-24', 'applied_date': '2026-09-25'});
      final r = resolve(data, '2026-09-25');
      final today = d('2026-09-25');
      expect(find(r, 'tx.register_workintexas')!.bucket(today), Bucket.upcoming);
      expect(find(r, 'tx.choose_payment_option')!.bucket(today), Bucket.today);
      expect(find(r, 'tx.read_handbook')!.bucket(today), Bucket.anytime);
      expect(find(r, 'tx.apply_for_benefits')!.bucket(today), Bucket.done);
    });

    test('next deadline is the earliest open hard deadline', () {
      final data = withDates({
        'last_day_worked': '2026-09-24',
        'applied_date': '2026-09-25',
        'coverage_end_date': '2026-09-30',
      });
      data.notices.add(
        Notice(
          id: 'n',
          typeId: 'tx.determination',
          loggedOn: d('2026-09-25'),
          mailedDate: d('2026-09-20'),
        ),
      );
      final r = resolve(data, '2026-09-25');
      final next = nextDeadline(r, d('2026-09-25'))!;
      expect(next.key, 'tx.register_workintexas');
      expect(next.deadlineDate, d('2026-09-28'));
    });

    test('overdue hard deadlines are reported, not hidden', () {
      final data = UserData(
        notices: [
          Notice(
            id: 'n',
            typeId: 'tx.determination',
            loggedOn: d('2026-09-25'),
            mailedDate: d('2026-09-01'),
          ),
        ],
      );
      final r = resolve(data, '2026-09-25');
      final t = find(r, 'tx.determination_deadline@n')!;
      expect(t.isOverdue(d('2026-09-25')), isTrue);
      expect(nextDeadline(r, d('2026-09-25'))!.key, t.key);
    });
  });
}
