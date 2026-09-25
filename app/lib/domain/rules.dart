import 'local_date.dart';

/// Structured, versioned rule definitions. See docs/RULE_ARCHITECTURE.md.
///
/// Nothing in here reasons about eligibility. A rule only says: "this official
/// step exists, here is where it is written down, and here is how its date is
/// derived from dates the user typed in."

enum RuleKind { official, suggested }

enum ReviewStatus { verified, snippetOnly, needsReview }

enum DeadlineType {
  /// No date. Shown under "Anytime".
  none,

  /// Do it as soon as the rule applies. Due on the day it starts applying.
  asap,

  /// A fixed number of calendar days after a profile fact date.
  offset,

  /// Deadline comes from a letter the user logged. The date printed on the
  /// letter always wins; a fallback is computed from the mailing date and
  /// labeled as an estimate.
  notice,

  /// Every N days from a profile fact date (Texas payment requests).
  recurring,

  /// Each Sunday–Saturday week from a profile fact date (work search log).
  weekly,
}

/// Facts a user can enter about their own situation. Deliberately excludes
/// separation reason, SSN, credentials, bank details and benefit amounts
/// (DECISIONS D-007).
enum FactType { date, count }

const Map<String, FactType> knownFacts = {
  'last_day_worked': FactType.date,
  'applied_date': FactType.date,
  'first_filing_date': FactType.date,
  'work_search_start_date': FactType.date,
  'work_search_required_per_week': FactType.count,
  'coverage_end_date': FactType.date,
  'claim_ended_date': FactType.date,
};

const Set<String> officialAuthorities = {'STATE_AGENCY', 'FEDERAL_AGENCY', 'STATE_LEGISLATURE'};

class RuleSource {
  const RuleSource({
    required this.url,
    required this.authority,
    required this.title,
    this.sourceId,
  });

  factory RuleSource.fromJson(Map<String, dynamic> j) => RuleSource(
    url: j['url'] as String? ?? '',
    authority: j['authority'] as String? ?? '',
    title: j['title'] as String? ?? '',
    sourceId: j['source_id'] as String?,
  );

  final String url;
  final String authority;
  final String title;
  final String? sourceId;

  bool get isOfficialAuthority => officialAuthorities.contains(authority);
}

class RuleReview {
  const RuleReview({required this.status, this.notes = ''});

  factory RuleReview.fromJson(Map<String, dynamic>? j) {
    final raw = j?['status'] as String?;
    return RuleReview(
      status: switch (raw) {
        'verified' => ReviewStatus.verified,
        'snippet_only' => ReviewStatus.snippetOnly,
        _ => ReviewStatus.needsReview,
      },
      notes: j?['notes'] as String? ?? '',
    );
  }

  final ReviewStatus status;
  final String notes;
}

class DeadlineSpec {
  const DeadlineSpec({
    required this.type,
    this.fromFact,
    this.days,
    this.hard = false,
    this.fallbackDaysFromMailed,
    this.everyDays,
    this.untilFact,
    this.lateAfterEndOfCalendarWeek = false,
    this.label,
  });

  factory DeadlineSpec.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const DeadlineSpec(type: DeadlineType.none);
    final t = j['type'] as String?;
    return DeadlineSpec(
      type: DeadlineType.values.firstWhere(
        (d) => d.name == t,
        orElse: () => throw FormatException('Unknown deadline type: $t'),
      ),
      fromFact: j['from_fact'] as String?,
      days: j['days'] as int?,
      hard: j['hard'] as bool? ?? false,
      fallbackDaysFromMailed: j['fallback_days_from_mailed'] as int?,
      everyDays: j['every_days'] as int?,
      untilFact: j['until_fact'] as String?,
      lateAfterEndOfCalendarWeek: j['late_after'] == 'end_of_calendar_week',
      label: j['label'] as String?,
    );
  }

  final DeadlineType type;
  final String? fromFact;
  final int? days;

  /// A hard deadline has an official consequence if missed. Soft ones are
  /// targets ("as soon as possible").
  final bool hard;
  final int? fallbackDaysFromMailed;
  final int? everyDays;
  final String? untilFact;
  final bool lateAfterEndOfCalendarWeek;

  /// Short human label, e.g. "Appeal deadline".
  final String? label;
}

class AppliesTo {
  const AppliesTo({this.requiresFacts = const [], this.requiresNotice});

  factory AppliesTo.fromJson(Map<String, dynamic>? j) => AppliesTo(
    requiresFacts: _stringList(j?['requires_facts']),
    requiresNotice: j?['requires_notice'] as String?,
  );

  final List<String> requiresFacts;
  final String? requiresNotice;
}

class Rule {
  const Rule({
    required this.ruleId,
    required this.version,
    required this.jurisdiction,
    required this.title,
    required this.description,
    required this.category,
    required this.appliesTo,
    required this.kind,
    required this.source,
    required this.additionalSources,
    required this.lastCheckedAt,
    required this.lastVerifiedAt,
    required this.review,
    required this.effectiveFrom,
    required this.effectiveTo,
    required this.deadline,
    required this.documentsNeeded,
    required this.dependsOn,
    required this.completesWithFact,
    required this.questionsToAsk,
    required this.getHelp,
    required this.active,
  });

  factory Rule.fromJson(Map<String, dynamic> j) {
    final kindRaw = j['official_or_suggested'];
    return Rule(
      ruleId: j['rule_id'] as String? ?? '',
      version: j['version'] as int? ?? 0,
      jurisdiction: j['jurisdiction'] as String? ?? '',
      title: j['title'] as String? ?? '',
      description: j['description'] as String? ?? '',
      category: j['category'] as String? ?? '',
      appliesTo: AppliesTo.fromJson(j['applies_to'] as Map<String, dynamic>?),
      kind: switch (kindRaw) {
        'official' => RuleKind.official,
        'suggested' => RuleKind.suggested,
        _ => throw FormatException('official_or_suggested: $kindRaw'),
      },
      source: j['source'] == null ? null : RuleSource.fromJson(j['source'] as Map<String, dynamic>),
      additionalSources: [
        for (final s in (j['additional_sources'] as List? ?? const []))
          RuleSource.fromJson(s as Map<String, dynamic>),
      ],
      lastCheckedAt: LocalDate.tryParse(j['last_checked_at'] as String?),
      lastVerifiedAt: LocalDate.tryParse(j['last_verified_at'] as String?),
      review: RuleReview.fromJson(j['review'] as Map<String, dynamic>?),
      effectiveFrom: LocalDate.tryParse(j['effective_from'] as String?),
      effectiveTo: LocalDate.tryParse(j['effective_to'] as String?),
      deadline: DeadlineSpec.fromJson(j['deadline'] as Map<String, dynamic>?),
      documentsNeeded: _stringList(j['documents_needed']),
      dependsOn: _stringList(j['depends_on']),
      completesWithFact: j['completes_with_fact'] as String?,
      questionsToAsk: _stringList(j['questions_to_ask']),
      getHelp: j['get_help'] as String? ?? '',
      active: j['active'] as bool? ?? true,
    );
  }

  final String ruleId;
  final int version;
  final String jurisdiction;
  final String title;
  final String description;
  final String category;
  final AppliesTo appliesTo;
  final RuleKind kind;
  final RuleSource? source;
  final List<RuleSource> additionalSources;
  final LocalDate? lastCheckedAt;

  /// Date a human last checked the source page. Null until reviewed.
  final LocalDate? lastVerifiedAt;
  final RuleReview review;
  final LocalDate? effectiveFrom;
  final LocalDate? effectiveTo;
  final DeadlineSpec deadline;
  final List<String> documentsNeeded;
  final List<String> dependsOn;
  final String? completesWithFact;
  final List<String> questionsToAsk;

  /// When a professional or the agency is needed, in plain language.
  final String getHelp;
  final bool active;

  bool isInEffectOn(LocalDate day) {
    if (!active) return false;
    if (effectiveFrom != null && day.isBefore(effectiveFrom!)) return false;
    if (effectiveTo != null && day.isAfter(effectiveTo!)) return false;
    return true;
  }
}

class NoticeType {
  const NoticeType({
    required this.id,
    required this.title,
    required this.description,
    required this.asksMailedDate,
    required this.asksPrintedDeadline,
    required this.asksEventDate,
    required this.printedDeadlineLabel,
    required this.eventDateLabel,
  });

  factory NoticeType.fromJson(Map<String, dynamic> j) {
    final asks = _stringList(j['asks']);
    return NoticeType(
      id: j['id'] as String? ?? '',
      title: j['title'] as String? ?? '',
      description: j['description'] as String? ?? '',
      asksMailedDate: asks.contains('mailed_date'),
      asksPrintedDeadline: asks.contains('printed_deadline'),
      asksEventDate: asks.contains('event_date'),
      printedDeadlineLabel: j['printed_deadline_label'] as String? ?? 'Deadline printed on it',
      eventDateLabel: j['event_date_label'] as String? ?? 'Date on the letter',
    );
  }

  final String id;
  final String title;
  final String description;
  final bool asksMailedDate;
  final bool asksPrintedDeadline;
  final bool asksEventDate;
  final String printedDeadlineLabel;
  final String eventDateLabel;
}

class HelpContact {
  const HelpContact({
    required this.name,
    required this.description,
    this.url,
    this.phone,
    required this.authority,
  });

  factory HelpContact.fromJson(Map<String, dynamic> j) => HelpContact(
    name: j['name'] as String? ?? '',
    description: j['description'] as String? ?? '',
    url: j['url'] as String?,
    phone: j['phone'] as String?,
    authority: j['authority'] as String? ?? '',
  );

  final String name;
  final String description;
  final String? url;
  final String? phone;
  final String authority;
}

class RuleDataset {
  const RuleDataset({
    required this.schemaVersion,
    required this.datasetId,
    required this.datasetVersion,
    required this.jurisdiction,
    required this.jurisdictionName,
    required this.publishedAt,
    required this.officialDomains,
    required this.noticeTypes,
    required this.rules,
    required this.helpContacts,
  });

  factory RuleDataset.fromJson(Map<String, dynamic> j) => RuleDataset(
    schemaVersion: j['schema_version'] as int? ?? 0,
    datasetId: j['dataset_id'] as String? ?? '',
    datasetVersion: j['dataset_version'] as String? ?? '',
    jurisdiction: j['jurisdiction'] as String? ?? '',
    jurisdictionName: j['jurisdiction_name'] as String? ?? '',
    publishedAt: LocalDate.tryParse(j['published_at'] as String?),
    officialDomains: _stringList(j['official_domains']),
    noticeTypes: [
      for (final n in (j['notice_types'] as List? ?? const []))
        NoticeType.fromJson(n as Map<String, dynamic>),
    ],
    rules: [
      for (final r in (j['rules'] as List? ?? const [])) Rule.fromJson(r as Map<String, dynamic>),
    ],
    helpContacts: [
      for (final h in (j['help_contacts'] as List? ?? const []))
        HelpContact.fromJson(h as Map<String, dynamic>),
    ],
  );

  static const supportedSchemaVersion = 1;

  final int schemaVersion;
  final String datasetId;
  final String datasetVersion;
  final String jurisdiction;
  final String jurisdictionName;
  final LocalDate? publishedAt;
  final List<String> officialDomains;
  final List<NoticeType> noticeTypes;
  final List<Rule> rules;
  final List<HelpContact> helpContacts;

  Rule? ruleById(String id) {
    for (final r in rules) {
      if (r.ruleId == id) return r;
    }
    return null;
  }

  NoticeType? noticeTypeById(String id) {
    for (final n in noticeTypes) {
      if (n.id == id) return n;
    }
    return null;
  }
}

List<String> _stringList(Object? v) =>
    v == null ? const [] : [for (final e in v as List) e as String];
