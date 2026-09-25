import 'dart:convert';

import 'local_date.dart';
import 'rules.dart';

/// Phrases that would turn an organizer into an eligibility or legal advisor.
/// Rule text containing any of these fails validation (docs/SAFETY_BOUNDARY.md).
const List<String> bannedPhrases = [
  'you are eligible',
  'you are not eligible',
  'you qualify',
  'you do not qualify',
  "you don't qualify",
  'you will be approved',
  'you will get paid',
  'guaranteed',
  'you should appeal',
  'you must appeal',
  'you will win',
  'official app',
  'approved by twc',
];

class ValidationIssue {
  const ValidationIssue(this.ruleId, this.message);
  final String ruleId;
  final String message;

  @override
  String toString() => '[$ruleId] $message';
}

class ValidationResult {
  const ValidationResult(this.errors, this.warnings);
  final List<ValidationIssue> errors;
  final List<ValidationIssue> warnings;
  bool get isValid => errors.isEmpty;
}

/// Thrown when a dataset cannot be parsed or fails validation. The app refuses
/// to load such a dataset and keeps the last good one.
class InvalidDatasetException implements Exception {
  InvalidDatasetException(this.issues);
  final List<ValidationIssue> issues;

  @override
  String toString() =>
      'InvalidDatasetException(${issues.length} issues): ${issues.take(5).join('; ')}';
}

/// Parses and validates raw JSON. Throws [InvalidDatasetException] on failure.
RuleDataset parseAndValidateDataset(String raw) {
  final RuleDataset dataset;
  try {
    dataset = RuleDataset.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } on Object catch (e) {
    throw InvalidDatasetException([ValidationIssue('<dataset>', 'parse: $e')]);
  }
  final result = validateDataset(dataset);
  if (!result.isValid) throw InvalidDatasetException(result.errors);
  return dataset;
}

ValidationResult validateDataset(RuleDataset d) {
  final errors = <ValidationIssue>[];
  final warnings = <ValidationIssue>[];
  void err(String id, String m) => errors.add(ValidationIssue(id, m));
  void warn(String id, String m) => warnings.add(ValidationIssue(id, m));

  if (d.schemaVersion != RuleDataset.supportedSchemaVersion) {
    err('<dataset>', 'unsupported schema_version ${d.schemaVersion}');
  }
  if (d.datasetId.isEmpty) err('<dataset>', 'missing dataset_id');
  if (d.datasetVersion.isEmpty) err('<dataset>', 'missing dataset_version');
  if (!RegExp(r'^[A-Z]{2}(-[A-Z]{2})?$').hasMatch(d.jurisdiction)) {
    err('<dataset>', 'jurisdiction must look like US-TX');
  }
  if (d.publishedAt == null) err('<dataset>', 'missing/invalid published_at');
  if (d.officialDomains.isEmpty) err('<dataset>', 'official_domains empty');
  if (d.rules.isEmpty) err('<dataset>', 'no rules');

  final noticeIds = <String>{};
  for (final n in d.noticeTypes) {
    if (n.id.isEmpty || n.title.isEmpty) err(n.id, 'notice type needs id and title');
    if (!noticeIds.add(n.id)) err(n.id, 'duplicate notice type id');
  }

  for (final h in d.helpContacts) {
    if (h.url != null && !_isHttps(h.url!)) err(h.name, 'help contact url must be https');
  }

  final ids = <String>{};
  for (final r in d.rules) {
    final id = r.ruleId;
    if (!RegExp(r'^[a-z0-9_]+(\.[a-z0-9_]+)+$').hasMatch(id)) {
      err(id, 'rule_id must be dotted lower_snake (e.g. tx.apply)');
    }
    if (!ids.add(id)) err(id, 'duplicate rule_id');
    if (r.version < 1) err(id, 'version must be >= 1');
    if (r.jurisdiction != d.jurisdiction && r.jurisdiction != 'US') {
      err(id, 'jurisdiction ${r.jurisdiction} not in dataset ${d.jurisdiction} or US');
    }
    if (r.title.trim().isEmpty) err(id, 'empty title');
    if (r.description.trim().isEmpty) err(id, 'empty description');
    if (r.category.isEmpty) err(id, 'empty category');

    // Sources.
    final src = r.source;
    if (r.kind == RuleKind.official) {
      if (src == null) {
        err(id, 'official rule requires a source');
      } else {
        if (!src.isOfficialAuthority) {
          err(id, 'official rule source authority must be one of $officialAuthorities');
        }
        if (!_isOfficialUrl(src.url, d.officialDomains)) {
          err(id, 'official rule source must be https on an official domain: ${src.url}');
        }
        if (src.title.isEmpty) err(id, 'source title empty');
      }
    } else if (src != null && !_isHttps(src.url)) {
      err(id, 'source url must be https');
    }
    for (final s in r.additionalSources) {
      if (!_isHttps(s.url)) err(id, 'additional source must be https: ${s.url}');
    }

    // Dates.
    if (r.lastCheckedAt == null) err(id, 'missing last_checked_at');
    if (r.lastCheckedAt != null &&
        d.publishedAt != null &&
        r.lastCheckedAt!.isAfter(d.publishedAt!)) {
      err(id, 'last_checked_at is after dataset published_at');
    }
    if (r.review.status == ReviewStatus.verified && r.lastVerifiedAt == null) {
      err(id, 'verified rule needs last_verified_at');
    }
    if (r.effectiveFrom != null &&
        r.effectiveTo != null &&
        r.effectiveTo!.isBefore(r.effectiveFrom!)) {
      err(id, 'effective_to before effective_from');
    }
    if (r.kind == RuleKind.official && r.active && r.review.status != ReviewStatus.verified) {
      warn(id, 'official rule not human-verified (${r.review.status.name})');
    }

    // Applies-to.
    for (final f in r.appliesTo.requiresFacts) {
      if (!knownFacts.containsKey(f)) err(id, 'unknown fact in requires_facts: $f');
    }
    final rn = r.appliesTo.requiresNotice;
    if (rn != null && !noticeIds.contains(rn)) err(id, 'unknown notice type: $rn');
    if (r.completesWithFact != null && !knownFacts.containsKey(r.completesWithFact)) {
      err(id, 'unknown completes_with_fact: ${r.completesWithFact}');
    }

    _validateDeadline(r, err);

    // Safety lint.
    final text = [
      r.title,
      r.description,
      r.getHelp,
      ...r.questionsToAsk,
      ...r.documentsNeeded,
    ].join(' \n ').toLowerCase();
    for (final p in bannedPhrases) {
      if (text.contains(p)) err(id, 'contains banned phrase "$p"');
    }
    if (r.getHelp.trim().isEmpty && r.kind == RuleKind.official) {
      err(id, 'official rule needs get_help text');
    }
  }

  // Dependencies: exist, point at single-instance rules, no cycles.
  final byId = {for (final r in d.rules) r.ruleId: r};
  for (final r in d.rules) {
    for (final dep in r.dependsOn) {
      final target = byId[dep];
      if (target == null) {
        err(r.ruleId, 'depends_on unknown rule $dep');
      } else if (target.appliesTo.requiresNotice != null ||
          target.deadline.type == DeadlineType.recurring ||
          target.deadline.type == DeadlineType.weekly) {
        err(r.ruleId, 'depends_on must reference a single-instance rule: $dep');
      }
      if (dep == r.ruleId) err(r.ruleId, 'depends on itself');
    }
  }
  final cycle = _findCycle(byId);
  if (cycle != null) err(cycle, 'dependency cycle');

  for (final n in d.noticeTypes) {
    if (!d.rules.any((r) => r.appliesTo.requiresNotice == n.id)) {
      warn(n.id, 'notice type has no rule');
    }
  }

  return ValidationResult(errors, warnings);
}

void _validateDeadline(Rule r, void Function(String, String) err) {
  final dl = r.deadline;
  final id = r.ruleId;
  bool dateFact(String? f) => f != null && knownFacts[f] == FactType.date;
  switch (dl.type) {
    case DeadlineType.none:
    case DeadlineType.asap:
      break;
    case DeadlineType.offset:
      if (!dateFact(dl.fromFact)) err(id, 'offset needs a date from_fact');
      if (dl.days == null || dl.days! < 0 || dl.days! > 365) {
        err(id, 'offset days must be 0..365');
      }
      if (dl.fromFact != null && !r.appliesTo.requiresFacts.contains(dl.fromFact)) {
        err(id, 'offset from_fact must be listed in requires_facts');
      }
    case DeadlineType.notice:
      if (r.appliesTo.requiresNotice == null) {
        err(id, 'notice deadline needs applies_to.requires_notice');
      }
      final fb = dl.fallbackDaysFromMailed;
      if (fb != null && (fb < 1 || fb > 365)) err(id, 'fallback days 1..365');
    case DeadlineType.recurring:
      if (!dateFact(dl.fromFact)) err(id, 'recurring needs a date from_fact');
      if (dl.everyDays == null || dl.everyDays! < 1 || dl.everyDays! > 31) {
        err(id, 'every_days must be 1..31');
      }
      if (dl.untilFact != null && !dateFact(dl.untilFact)) {
        err(id, 'until_fact must be a date fact');
      }
    case DeadlineType.weekly:
      if (!dateFact(dl.fromFact)) err(id, 'weekly needs a date from_fact');
      if (dl.untilFact != null && !dateFact(dl.untilFact)) {
        err(id, 'until_fact must be a date fact');
      }
  }
  if (r.appliesTo.requiresNotice != null && dl.type != DeadlineType.notice) {
    err(id, 'rules that require a notice must use a notice deadline');
  }
}

String? _findCycle(Map<String, Rule> byId) {
  final state = <String, int>{}; // 1 = visiting, 2 = done
  String? found;
  void visit(String id) {
    if (found != null) return;
    state[id] = 1;
    for (final dep in byId[id]?.dependsOn ?? const <String>[]) {
      if (!byId.containsKey(dep)) continue;
      if (state[dep] == 1) {
        found = id;
        return;
      }
      if (state[dep] == null) visit(dep);
    }
    state[id] = 2;
  }

  for (final id in byId.keys) {
    if (state[id] == null) visit(id);
  }
  return found;
}

bool _isHttps(String url) {
  final u = Uri.tryParse(url);
  return u != null && u.scheme == 'https' && u.host.isNotEmpty;
}

bool _isOfficialUrl(String url, List<String> domains) {
  final u = Uri.tryParse(url);
  if (u == null || u.scheme != 'https') return false;
  final host = u.host.toLowerCase();
  return domains.any((d) => host == d || host.endsWith('.$d'));
}

/// Release gate: returns the official, active rules that still need human
/// source review. A public store release requires this list to be empty.
List<Rule> rulesBlockingRelease(RuleDataset d, LocalDate today) => [
  for (final r in d.rules)
    if (r.kind == RuleKind.official &&
        r.isInEffectOn(today) &&
        r.review.status != ReviewStatus.verified)
      r,
];
