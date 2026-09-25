import 'local_date.dart';
import 'rules.dart';
import 'user_data.dart';

/// Where a task's date came from. Shown to the user next to every date.
enum DateBasis {
  /// No date.
  none,

  /// "As soon as possible" — due the day the step starts applying.
  asap,

  /// The user typed the date printed on their letter. Most trustworthy.
  printedOnNotice,

  /// The user typed an appointment/hearing date from their letter.
  eventOnNotice,

  /// Computed by the app from a date the user entered. Always an estimate.
  computedEstimate,

  /// Derived from the user's own schedule (e.g. First Filing Date).
  userSchedule,
}

enum Bucket { today, upcoming, anytime, waiting, done }

class TaskInstance {
  TaskInstance({
    required this.key,
    required this.rule,
    required this.due,
    required this.hardDeadline,
    required this.basis,
    this.notice,
    this.occurrence,
    this.completion,
    this.autoCompletedByFact,
    this.blockedBy = const [],
    this.warnings = const [],
  });

  /// Stable id: `rule` | `rule@noticeId` | `rule#yyyy-mm-dd`.
  final String key;
  final Rule rule;

  /// When to do it.
  final LocalDate? due;

  /// Last day before an official consequence, when known. May equal [due].
  final LocalDate? hardDeadline;
  final DateBasis basis;
  final Notice? notice;
  final LocalDate? occurrence;
  final Completion? completion;
  final String? autoCompletedByFact;
  final List<String> blockedBy;
  final List<String> warnings;

  bool get isDone => completion != null || autoCompletedByFact != null;

  /// The date that matters most for "what deadline is next".
  LocalDate? get deadlineDate => hardDeadline ?? due;

  bool isOverdue(LocalDate today) {
    final d = deadlineDate;
    return !isDone && d != null && d.isBefore(today);
  }

  Bucket bucket(LocalDate today) {
    if (isDone) return Bucket.done;
    if (blockedBy.isNotEmpty) return Bucket.waiting;
    if (due == null) return Bucket.anytime;
    if (!due!.isAfter(today)) return Bucket.today;
    return Bucket.upcoming;
  }
}

/// Past recurring occurrences older than this are not generated, so someone
/// who starts using the app mid-claim isn't buried in "overdue" items.
const int recurringLookbackDays = 28;

/// Future recurring occurrences are generated this far ahead.
const int recurringHorizonDays = 35;

/// Resolves the user's roadmap. Pure function: same inputs, same output.
List<TaskInstance> resolveRoadmap({
  required RuleDataset dataset,
  required UserData data,
  required LocalDate today,
}) {
  final profile = data.profile;
  final out = <TaskInstance>[];

  for (final rule in dataset.rules) {
    if (!rule.isInEffectOn(today)) continue;
    if (!rule.appliesTo.requiresFacts.every(profile.hasFact)) continue;

    final noticeType = rule.appliesTo.requiresNotice;
    if (noticeType != null) {
      for (final n in data.notices.where((n) => n.typeId == noticeType)) {
        out.add(_noticeInstance(rule, n, data));
      }
      continue;
    }

    switch (rule.deadline.type) {
      case DeadlineType.recurring:
        out.addAll(_recurring(rule, data, today));
      case DeadlineType.weekly:
        out.addAll(_weekly(rule, data, today));
      default:
        out.add(_single(rule, data, today));
    }
  }

  // Dependencies are resolved after all instances exist.
  final doneRules = {
    for (final t in out)
      if (t.isDone) t.rule.ruleId,
  };
  final present = {for (final t in out) t.rule.ruleId};
  return [
    for (final t in out)
      if (t.rule.dependsOn.isEmpty || t.isDone)
        t
      else
        _withBlockers(t, [
          for (final dep in t.rule.dependsOn)
            if (!doneRules.contains(dep) && present.contains(dep)) dep,
        ]),
  ];
}

TaskInstance _withBlockers(TaskInstance t, List<String> blockers) => TaskInstance(
  key: t.key,
  rule: t.rule,
  due: t.due,
  hardDeadline: t.hardDeadline,
  basis: t.basis,
  notice: t.notice,
  occurrence: t.occurrence,
  completion: t.completion,
  autoCompletedByFact: t.autoCompletedByFact,
  blockedBy: blockers,
  warnings: t.warnings,
);

TaskInstance _single(Rule rule, UserData data, LocalDate today) {
  final p = data.profile;
  final dl = rule.deadline;
  LocalDate? due;
  LocalDate? hard;
  var basis = DateBasis.none;

  switch (dl.type) {
    case DeadlineType.asap:
      // Due on the latest date among the facts that made it apply, or today
      // if it applies without facts.
      final factDates = [for (final f in rule.appliesTo.requiresFacts) ?p.dates[f]];
      due = factDates.isEmpty ? today : factDates.reduce(LocalDate.max);
      basis = DateBasis.asap;
    case DeadlineType.offset:
      final from = p.dates[dl.fromFact]!;
      due = from.addDays(dl.days!);
      basis = DateBasis.computedEstimate;
    default:
      break;
  }
  if (dl.hard) hard = due;

  final factKey = rule.completesWithFact;
  return TaskInstance(
    key: rule.ruleId,
    rule: rule,
    due: due,
    hardDeadline: hard,
    basis: basis,
    completion: data.completions[rule.ruleId],
    autoCompletedByFact: factKey != null && p.hasFact(factKey) ? factKey : null,
  );
}

TaskInstance _noticeInstance(Rule rule, Notice n, UserData data) {
  final dl = rule.deadline;
  final warnings = <String>[];
  LocalDate? due;
  LocalDate? hard;
  DateBasis basis;

  final computed = (n.mailedDate != null && dl.fallbackDaysFromMailed != null)
      ? n.mailedDate!.addDays(dl.fallbackDaysFromMailed!)
      : null;

  if (n.printedDeadline != null) {
    due = n.printedDeadline;
    basis = DateBasis.printedOnNotice;
    if (computed != null && n.printedDeadline!.isAfter(computed.addDays(3))) {
      warnings.add(
        'The date you entered is later than the usual '
        '${dl.fallbackDaysFromMailed}-day window from the mailing date '
        '(${computed.toIso()}). Double-check the date printed on the letter.',
      );
    }
  } else if (n.eventDate != null) {
    due = n.eventDate;
    basis = DateBasis.eventOnNotice;
  } else if (computed != null) {
    due = computed;
    basis = DateBasis.computedEstimate;
    warnings.add(
      'Estimated from the mailing date. Use the date printed on your letter '
      'if it shows one.',
    );
  } else {
    due = n.loggedOn;
    basis = DateBasis.asap;
    if (dl.hard) {
      warnings.add(
        'Add the mailing date or the deadline printed on the letter so the '
        'app can remind you in time.',
      );
    }
  }
  if (dl.hard && basis != DateBasis.asap) hard = due;

  final key = '${rule.ruleId}@${n.id}';
  return TaskInstance(
    key: key,
    rule: rule,
    due: due,
    hardDeadline: hard,
    basis: basis,
    notice: n,
    completion: data.completions[key],
    warnings: warnings,
  );
}

Iterable<TaskInstance> _recurring(Rule rule, UserData data, LocalDate today) sync* {
  final p = data.profile;
  final dl = rule.deadline;
  final start = p.dates[dl.fromFact]!;
  final until = dl.untilFact == null ? null : p.dates[dl.untilFact];
  final horizon = today.addDays(recurringHorizonDays);
  final lookback = today.addDays(-recurringLookbackDays);
  final every = dl.everyDays!;

  // Walk from the first date so completed occurrences older than the
  // look-back window are still returned (history is never dropped).
  var date = start;
  while (!date.isAfter(horizon)) {
    if (until != null && date.isAfter(until)) break;
    final key = '${rule.ruleId}#${date.toIso()}';
    final completion = data.completions[key];
    final late = dl.lateAfterEndOfCalendarWeek ? date.endOfWeekSaturday : null;
    if (!date.isBefore(lookback) || completion != null) {
      yield TaskInstance(
        key: key,
        rule: rule,
        due: date,
        hardDeadline: dl.hard ? (late ?? date) : late,
        basis: DateBasis.userSchedule,
        occurrence: date,
        completion: completion,
      );
    }
    date = date.addDays(every);
  }
}

Iterable<TaskInstance> _weekly(Rule rule, UserData data, LocalDate today) sync* {
  final p = data.profile;
  final dl = rule.deadline;
  final start = p.dates[dl.fromFact]!.startOfWeekSunday;
  final until = dl.untilFact == null ? null : p.dates[dl.untilFact];
  final lookback = today.addDays(-recurringLookbackDays).startOfWeekSunday;
  final lastWeek = today.startOfWeekSunday;

  var week = start;
  while (!week.isAfter(lastWeek)) {
    if (until != null && week.isAfter(until)) break;
    final key = '${rule.ruleId}#${week.toIso()}';
    final end = week.endOfWeekSaturday;
    final completion = data.completions[key];
    if (week.isBefore(lookback) && completion == null) {
      week = week.addDays(7);
      continue;
    }
    yield TaskInstance(
      key: key,
      rule: rule,
      due: end,
      hardDeadline: dl.hard ? end : null,
      basis: DateBasis.userSchedule,
      occurrence: week,
      completion: completion,
    );
    week = week.addDays(7);
  }
}

/// Completions whose rule no longer exists or no longer produces that
/// instance (e.g. retired by a dataset update). They are kept and shown in
/// "Done" so the user's history is never silently lost.
List<Completion> orphanCompletions(List<TaskInstance> roadmap, UserData data) {
  final keys = {for (final t in roadmap) t.key};
  return [
    for (final c in data.completions.values)
      if (!keys.contains(c.instanceKey)) c,
  ];
}

/// Next open item with a deadline, earliest first (overdue first).
TaskInstance? nextDeadline(List<TaskInstance> roadmap, LocalDate today) {
  final open = [
    for (final t in roadmap)
      if (!t.isDone && t.deadlineDate != null && t.rule.deadline.hard) t,
  ]..sort((a, b) => a.deadlineDate!.compareTo(b.deadlineDate!));
  return open.isEmpty ? null : open.first;
}

/// Sorting for lists: overdue/earliest first, undated last, stable by title.
int compareTasks(TaskInstance a, TaskInstance b) {
  final ad = a.due, bd = b.due;
  if (ad != null && bd != null) {
    final c = ad.compareTo(bd);
    if (c != 0) return c;
  } else if (ad != null) {
    return -1;
  } else if (bd != null) {
    return 1;
  }
  if (a.rule.deadline.hard != b.rule.deadline.hard) {
    return a.rule.deadline.hard ? -1 : 1;
  }
  return a.rule.title.compareTo(b.rule.title);
}

/// Work search activities recorded in the Sunday–Saturday week containing
/// [anyDayInWeek]. This is a count, not a judgement of compliance.
int workSearchCountForWeek(UserData data, LocalDate anyDayInWeek) {
  final start = anyDayInWeek.startOfWeekSunday;
  final end = start.endOfWeekSaturday;
  return data.workSearch.where((w) => !w.date.isBefore(start) && !w.date.isAfter(end)).length;
}
