import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobloss_os/domain/dataset_validator.dart';
import 'package:jobloss_os/domain/rules.dart';

import 'helpers.dart';

void expectInvalid(Map<String, dynamic> m, Pattern messagePart) {
  expect(
    () => datasetFrom(m),
    throwsA(
      isA<InvalidDatasetException>().having(
        (e) => e.issues.map((i) => i.message).join('\n'),
        'issues',
        contains(messagePart),
      ),
    ),
  );
}

void main() {
  group('Bundled Texas dataset', () {
    late RuleDataset ds;
    setUp(() => ds = realDataset());

    test('parses and validates with no errors', () {
      expect(validateDataset(ds).errors, isEmpty);
      expect(ds.jurisdiction, 'US-TX');
      expect(ds.rules.length, greaterThan(15));
    });

    test('every active official rule has an official https source', () {
      for (final r in ds.rules.where((r) => r.kind == RuleKind.official)) {
        final src = r.source;
        expect(src, isNotNull, reason: r.ruleId);
        expect(Uri.parse(src!.url).scheme, 'https', reason: r.ruleId);
        expect(src.isOfficialAuthority, isTrue, reason: r.ruleId);
        expect(r.lastCheckedAt, isNotNull, reason: r.ruleId);
        expect(r.getHelp, isNotEmpty, reason: r.ruleId);
      }
    });

    test('rules are honest about review status (no fake verification)', () {
      // Sources were only seen via search summaries; none may claim to be
      // human-verified until a person actually checks them.
      for (final r in ds.rules) {
        expect(r.review.status, isNot(ReviewStatus.verified), reason: r.ruleId);
        expect(r.lastVerifiedAt, isNull, reason: r.ruleId);
      }
      expect(rulesBlockingRelease(ds, d('2026-09-25')), isNotEmpty);
    });

    test('never collects forbidden data', () {
      final raw = rawDataset().toLowerCase();
      for (final forbidden in ['"ssn"', 'password"', '"bank_account', '"separation_reason']) {
        expect(raw.contains(forbidden), isFalse, reason: forbidden);
      }
    });

    test('appeal deadlines are hard and fall back conservatively to mailing date', () {
      for (final id in ['tx.determination_deadline', 'tx.commission_appeal_deadline']) {
        final r = ds.ruleById(id)!;
        expect(r.deadline.hard, isTrue);
        expect(r.deadline.type, DeadlineType.notice);
        expect(r.deadline.fallbackDaysFromMailed, 14);
      }
    });
  });

  group('Invalid datasets are rejected', () {
    test('malformed JSON', () {
      expect(() => parseAndValidateDataset('{not json'), throwsA(isA<InvalidDatasetException>()));
    });

    test('unsupported schema version', () {
      final m = datasetMap()..['schema_version'] = 99;
      expectInvalid(m, 'schema_version');
    });

    test('official rule without source', () {
      final m = datasetMap();
      ruleIn(m, 'tx.apply_for_benefits')['source'] = null;
      expectInvalid(m, 'requires a source');
    });

    test('official rule citing a non-official domain', () {
      final m = datasetMap();
      ruleIn(m, 'tx.apply_for_benefits')['source']['url'] = 'https://claimyr.com/texas';
      expectInvalid(m, 'official domain');
    });

    test('lookalike domain does not pass as official', () {
      final m = datasetMap();
      ruleIn(m, 'tx.apply_for_benefits')['source']['url'] =
          'https://twc.texas.gov.evil.example/apply';
      expectInvalid(m, 'official domain');
    });

    test('official rule citing a non-official authority', () {
      final m = datasetMap();
      ruleIn(m, 'tx.apply_for_benefits')['source']['authority'] = 'LEGAL_AID';
      expectInvalid(m, 'authority');
    });

    test('http (not https) source', () {
      final m = datasetMap();
      ruleIn(m, 'tx.apply_for_benefits')['source']['url'] =
          'http://www.twc.texas.gov/services/apply-benefits';
      expectInvalid(m, 'official domain');
    });

    test('duplicate rule id', () {
      final m = datasetMap();
      final rules = m['rules'] as List;
      rules.add(jsonDecode(jsonEncode(rules.first)));
      expectInvalid(m, 'duplicate rule_id');
    });

    test('unknown fact', () {
      final m = datasetMap();
      ruleIn(m, 'tx.apply_for_benefits')['applies_to'] = {
        'requires_facts': ['separation_reason'],
      };
      expectInvalid(m, 'unknown fact');
    });

    test('unknown notice type', () {
      final m = datasetMap();
      ruleIn(m, 'tx.determination_deadline')['applies_to'] = {'requires_notice': 'tx.nope'};
      expectInvalid(m, 'unknown notice type');
    });

    test('dependency on missing rule and dependency cycles', () {
      final m = datasetMap();
      ruleIn(m, 'tx.tax_withholding')['depends_on'] = ['tx.missing'];
      expectInvalid(m, 'depends_on unknown rule');

      final c = datasetMap();
      ruleIn(c, 'tx.apply_for_benefits')['depends_on'] = ['tx.tax_withholding'];
      expectInvalid(c, 'dependency cycle');
    });

    test('offset deadline without its fact in requires_facts', () {
      final m = datasetMap();
      ruleIn(m, 'tx.register_workintexas')['applies_to'] = {'requires_facts': <String>[]};
      expectInvalid(m, 'from_fact must be listed');
    });

    test('bad recurring cadence', () {
      final m = datasetMap();
      ruleIn(m, 'tx.request_payment')['deadline']['every_days'] = 0;
      expectInvalid(m, 'every_days');
    });

    test('unknown deadline type', () {
      final m = datasetMap();
      ruleIn(m, 'tx.request_payment')['deadline']['type'] = 'monthly';
      expectInvalid(m, 'parse');
    });

    test('verified rule must carry a verification date', () {
      final m = datasetMap();
      ruleIn(m, 'tx.apply_for_benefits')['review'] = {'status': 'verified'};
      expectInvalid(m, 'last_verified_at');
    });

    test('last_checked_at after publication date', () {
      final m = datasetMap();
      ruleIn(m, 'tx.apply_for_benefits')['last_checked_at'] = '2030-01-01';
      expectInvalid(m, 'after dataset published_at');
    });

    test('effective_to before effective_from', () {
      final m = datasetMap();
      ruleIn(m, 'tx.apply_for_benefits')
        ..['effective_from'] = '2026-06-01'
        ..['effective_to'] = '2026-01-01';
      expectInvalid(m, 'effective_to');
    });

    test('eligibility / legal-advice language is banned', () {
      for (final phrase in [
        'You qualify for benefits.',
        'You should appeal this.',
        'Payment guaranteed.',
      ]) {
        final m = datasetMap();
        ruleIn(m, 'tx.apply_for_benefits')['description'] = phrase;
        expectInvalid(m, 'banned phrase');
      }
    });

    test('notice rule must use a notice deadline', () {
      final m = datasetMap();
      ruleIn(m, 'tx.determination_deadline')['deadline'] = {'type': 'asap'};
      expectInvalid(m, 'must use a notice deadline');
    });
  });

  group('Release gate', () {
    test('passes only when every active official rule is human-verified', () {
      final m = datasetMap();
      for (final r in (m['rules'] as List).cast<Map<String, dynamic>>()) {
        if (r['official_or_suggested'] == 'official') {
          r['review'] = {'status': 'verified'};
          r['last_verified_at'] = '2026-09-25';
        }
      }
      final ds = datasetFrom(m);
      expect(rulesBlockingRelease(ds, d('2026-09-25')), isEmpty);
    });

    test('inactive or expired rules do not block release', () {
      final m = datasetMap();
      for (final r in (m['rules'] as List).cast<Map<String, dynamic>>()) {
        r['active'] = false;
      }
      expect(rulesBlockingRelease(datasetFrom(m), d('2026-09-25')), isEmpty);
    });
  });
}
