import 'package:flutter_test/flutter_test.dart';
import 'package:jobloss_os/domain/resolver.dart';
import 'package:jobloss_os/domain/user_data.dart';

import 'helpers.dart';

/// A dataset update must never silently erase what the user already did.
void main() {
  UserData userData() {
    final data = UserData(
      profile: Profile(
        dates: {
          'last_day_worked': d('2026-09-01'),
          'applied_date': d('2026-09-02'),
          'first_filing_date': d('2026-09-13'),
        },
        onboarded: true,
      ),
    );
    for (final key in [
      'tx.register_workintexas',
      'tx.request_payment#2026-09-13',
      'tx.tax_withholding',
    ]) {
      data.completions[key] = Completion(
        instanceKey: key,
        ruleId: key.split('#').first,
        completedOn: d('2026-09-14'),
        ruleVersion: 1,
        datasetVersion: '2026.09.25-1',
      );
    }
    return data;
  }

  test('rule text/version change keeps completion', () {
    final m = datasetMap()..['dataset_version'] = '2026.10.01-1';
    ruleIn(m, 'tx.register_workintexas')
      ..['version'] = 2
      ..['title'] = 'Register on WorkInTexas.com (updated wording)';
    final r = resolveRoadmap(dataset: datasetFrom(m), data: userData(), today: d('2026-09-25'));
    final t = r.firstWhere((t) => t.key == 'tx.register_workintexas');
    expect(t.isDone, isTrue);
    expect(t.rule.version, 2);
    // Audit trail still shows which version the user completed.
    expect(t.completion!.ruleVersion, 1);
  });

  test('deadline change moves the date but keeps completion', () {
    final m = datasetMap();
    ruleIn(m, 'tx.register_workintexas')['deadline']['days'] = 5;
    final r = resolveRoadmap(dataset: datasetFrom(m), data: userData(), today: d('2026-09-25'));
    final t = r.firstWhere((t) => t.key == 'tx.register_workintexas');
    expect(t.due, d('2026-09-07'));
    expect(t.isDone, isTrue);
  });

  test('removed rule: completion is preserved as a retired record', () {
    final m = datasetMap();
    (m['rules'] as List).removeWhere((r) => (r as Map)['rule_id'] == 'tx.tax_withholding');
    final data = userData();
    final r = resolveRoadmap(dataset: datasetFrom(m), data: data, today: d('2026-09-25'));
    expect(r.any((t) => t.rule.ruleId == 'tx.tax_withholding'), isFalse);
    final orphans = orphanCompletions(r, data);
    expect(orphans.map((c) => c.instanceKey), ['tx.tax_withholding']);
    // The raw record is untouched.
    expect(data.completions.containsKey('tx.tax_withholding'), isTrue);
  });

  test('recurring cadence change keeps completed past occurrences visible', () {
    final m = datasetMap();
    ruleIn(m, 'tx.request_payment')['deadline']['every_days'] = 7;
    final data = userData();
    final r = resolveRoadmap(dataset: datasetFrom(m), data: data, today: d('2026-09-25'));
    expect(r.firstWhere((t) => t.key == 'tx.request_payment#2026-09-13').isDone, isTrue);
    expect(orphanCompletions(r, data).where((c) => c.ruleId == 'tx.request_payment'), isEmpty);
  });

  test('changing a user date keeps completions (keys are stable)', () {
    final data = userData();
    data.profile.dates['applied_date'] = d('2026-09-03');
    final r = resolveRoadmap(dataset: realDataset(), data: data, today: d('2026-09-25'));
    expect(r.firstWhere((t) => t.key == 'tx.register_workintexas').isDone, isTrue);
  });
}
