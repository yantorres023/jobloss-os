import 'local_date.dart';

/// Everything the user stores. Lives only on the device (see SECURITY.md).
///
/// Never add fields for SSN, passwords, PINs, bank/card numbers, benefit
/// amounts or separation reason (DECISIONS D-007).

class Profile {
  Profile({
    this.jurisdiction = 'US-TX',
    Map<String, LocalDate>? dates,
    Map<String, int>? counts,
    this.onboarded = false,
  }) : dates = dates ?? {},
       counts = counts ?? {};

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    jurisdiction: j['jurisdiction'] as String? ?? 'US-TX',
    dates: {
      for (final e in (j['dates'] as Map<String, dynamic>? ?? {}).entries)
        e.key: ?LocalDate.tryParse(e.value as String?),
    },
    counts: {
      for (final e in (j['counts'] as Map<String, dynamic>? ?? {}).entries) e.key: e.value as int,
    },
    onboarded: j['onboarded'] as bool? ?? false,
  );

  String jurisdiction;
  final Map<String, LocalDate> dates;
  final Map<String, int> counts;
  bool onboarded;

  bool hasFact(String key) => dates.containsKey(key) || counts.containsKey(key);

  Map<String, dynamic> toJson() => {
    'jurisdiction': jurisdiction,
    'dates': {for (final e in dates.entries) e.key: e.value.toIso()},
    'counts': counts,
    'onboarded': onboarded,
  };
}

/// A letter or message the user received (from TWC, an insurer, etc.).
class Notice {
  Notice({
    required this.id,
    required this.typeId,
    required this.loggedOn,
    this.mailedDate,
    this.printedDeadline,
    this.eventDate,
    this.note = '',
    List<String>? attachmentIds,
  }) : attachmentIds = attachmentIds ?? [];

  factory Notice.fromJson(Map<String, dynamic> j) => Notice(
    id: j['id'] as String,
    typeId: j['type_id'] as String,
    loggedOn: LocalDate.parse(j['logged_on'] as String),
    mailedDate: LocalDate.tryParse(j['mailed_date'] as String?),
    printedDeadline: LocalDate.tryParse(j['printed_deadline'] as String?),
    eventDate: LocalDate.tryParse(j['event_date'] as String?),
    note: j['note'] as String? ?? '',
    attachmentIds: [for (final a in (j['attachment_ids'] as List? ?? [])) a as String],
  );

  final String id;
  final String typeId;
  final LocalDate loggedOn;
  LocalDate? mailedDate;
  LocalDate? printedDeadline;

  /// Appointment/hearing date, or other date the letter names.
  LocalDate? eventDate;
  String note;
  final List<String> attachmentIds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type_id': typeId,
    'logged_on': loggedOn.toIso(),
    'mailed_date': mailedDate?.toIso(),
    'printed_deadline': printedDeadline?.toIso(),
    'event_date': eventDate?.toIso(),
    'note': note,
    'attachment_ids': attachmentIds,
  };
}

/// The user marked a task instance done. Keyed by instance key so it survives
/// dataset updates; rule version is kept for the audit trail.
class Completion {
  Completion({
    required this.instanceKey,
    required this.ruleId,
    required this.completedOn,
    required this.ruleVersion,
    required this.datasetVersion,
    this.note = '',
  });

  factory Completion.fromJson(Map<String, dynamic> j) => Completion(
    instanceKey: j['instance_key'] as String,
    ruleId: j['rule_id'] as String,
    completedOn: LocalDate.parse(j['completed_on'] as String),
    ruleVersion: j['rule_version'] as int? ?? 0,
    datasetVersion: j['dataset_version'] as String? ?? '',
    note: j['note'] as String? ?? '',
  );

  final String instanceKey;
  final String ruleId;
  final LocalDate completedOn;
  final int ruleVersion;
  final String datasetVersion;
  String note;

  Map<String, dynamic> toJson() => {
    'instance_key': instanceKey,
    'rule_id': ruleId,
    'completed_on': completedOn.toIso(),
    'rule_version': ruleVersion,
    'dataset_version': datasetVersion,
    'note': note,
  };
}

enum SubmissionKind {
  application('Applied for benefits'),
  paymentRequest('Payment request'),
  registration('Registration (e.g. WorkInTexas)'),
  identity('Identity verification'),
  workSearchLogSent('Sent work search log'),
  appeal('Appeal filed'),
  documentSent('Sent a document'),
  phoneCall('Phone call'),
  other('Other');

  const SubmissionKind(this.label);
  final String label;
}

/// "What did I already submit?" — the user's own proof record.
class Submission {
  Submission({
    required this.id,
    required this.kind,
    required this.date,
    this.confirmation = '',
    this.note = '',
    this.instanceKey,
    List<String>? attachmentIds,
  }) : attachmentIds = attachmentIds ?? [];

  factory Submission.fromJson(Map<String, dynamic> j) => Submission(
    id: j['id'] as String,
    kind: SubmissionKind.values.firstWhere(
      (k) => k.name == j['kind'],
      orElse: () => SubmissionKind.other,
    ),
    date: LocalDate.parse(j['date'] as String),
    confirmation: j['confirmation'] as String? ?? '',
    note: j['note'] as String? ?? '',
    instanceKey: j['instance_key'] as String?,
    attachmentIds: [for (final a in (j['attachment_ids'] as List? ?? [])) a as String],
  );

  final String id;
  SubmissionKind kind;
  LocalDate date;
  String confirmation;
  String note;
  String? instanceKey;
  final List<String> attachmentIds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'date': date.toIso(),
    'confirmation': confirmation,
    'note': note,
    'instance_key': instanceKey,
    'attachment_ids': attachmentIds,
  };
}

/// One row of a work search log. Fields mirror the TWC Work Search Log form
/// (date, employer and contact info, type of contact, result).
class WorkSearchEntry {
  WorkSearchEntry({
    required this.id,
    required this.date,
    required this.employer,
    this.contact = '',
    this.activityType = '',
    this.result = '',
    this.note = '',
  });

  factory WorkSearchEntry.fromJson(Map<String, dynamic> j) => WorkSearchEntry(
    id: j['id'] as String,
    date: LocalDate.parse(j['date'] as String),
    employer: j['employer'] as String? ?? '',
    contact: j['contact'] as String? ?? '',
    activityType: j['activity_type'] as String? ?? '',
    result: j['result'] as String? ?? '',
    note: j['note'] as String? ?? '',
  );

  final String id;
  LocalDate date;
  String employer;
  String contact;
  String activityType;
  String result;
  String note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso(),
    'employer': employer,
    'contact': contact,
    'activity_type': activityType,
    'result': result,
    'note': note,
  };
}

/// A status the user saw (portal text, phone call outcome), copied verbatim.
class StatusNote {
  StatusNote({required this.id, required this.date, required this.text, this.where = ''});

  factory StatusNote.fromJson(Map<String, dynamic> j) => StatusNote(
    id: j['id'] as String,
    date: LocalDate.parse(j['date'] as String),
    text: j['text'] as String? ?? '',
    where: j['where'] as String? ?? '',
  );

  final String id;
  LocalDate date;
  String text;
  String where;

  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso(), 'text': text, 'where': where};
}

class AgencyQuestion {
  AgencyQuestion({
    required this.id,
    required this.text,
    this.ruleId,
    this.answer = '',
    this.answered = false,
  });

  factory AgencyQuestion.fromJson(Map<String, dynamic> j) => AgencyQuestion(
    id: j['id'] as String,
    text: j['text'] as String? ?? '',
    ruleId: j['rule_id'] as String?,
    answer: j['answer'] as String? ?? '',
    answered: j['answered'] as bool? ?? false,
  );

  final String id;
  String text;
  String? ruleId;
  String answer;
  bool answered;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'rule_id': ruleId,
    'answer': answer,
    'answered': answered,
  };
}

/// A photo or screenshot copied into app storage. [fileName] is relative to
/// the app's private attachments directory.
class Attachment {
  Attachment({required this.id, required this.fileName, required this.addedOn, this.caption = ''});

  factory Attachment.fromJson(Map<String, dynamic> j) => Attachment(
    id: j['id'] as String,
    fileName: j['file_name'] as String,
    addedOn: LocalDate.parse(j['added_on'] as String),
    caption: j['caption'] as String? ?? '',
  );

  final String id;
  final String fileName;
  final LocalDate addedOn;
  String caption;

  Map<String, dynamic> toJson() => {
    'id': id,
    'file_name': fileName,
    'added_on': addedOn.toIso(),
    'caption': caption,
  };
}

class Settings {
  Settings({this.remindersEnabled = true, this.reminderHour = 9});

  factory Settings.fromJson(Map<String, dynamic>? j) => Settings(
    remindersEnabled: j?['reminders_enabled'] as bool? ?? true,
    reminderHour: j?['reminder_hour'] as int? ?? 9,
  );

  bool remindersEnabled;
  int reminderHour;

  Map<String, dynamic> toJson() => {
    'reminders_enabled': remindersEnabled,
    'reminder_hour': reminderHour,
  };
}

/// Saved data came from a newer app version. It must not be overwritten.
class NewerDataVersionException implements Exception {
  NewerDataVersionException(this.version);
  final int version;

  @override
  String toString() =>
      'Your records were saved by a newer version of JobLoss OS (format $version). '
      'Update the app to open them.';
}

class UserData {
  UserData({
    Profile? profile,
    List<Notice>? notices,
    Map<String, Completion>? completions,
    List<Submission>? submissions,
    List<WorkSearchEntry>? workSearch,
    List<StatusNote>? statusNotes,
    List<AgencyQuestion>? questions,
    List<Attachment>? attachments,
    Settings? settings,
  }) : profile = profile ?? Profile(),
       notices = notices ?? [],
       completions = completions ?? {},
       submissions = submissions ?? [],
       workSearch = workSearch ?? [],
       statusNotes = statusNotes ?? [],
       questions = questions ?? [],
       attachments = attachments ?? [],
       settings = settings ?? Settings();

  factory UserData.fromJson(Map<String, dynamic> j) {
    final v = j['schema_version'] as int? ?? 1;
    if (v > currentSchemaVersion) throw NewerDataVersionException(v);
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) => [
      for (final e in (j[k] as List? ?? const [])) f(e as Map<String, dynamic>),
    ];
    return UserData(
      profile: Profile.fromJson(j['profile'] as Map<String, dynamic>? ?? {}),
      notices: list('notices', Notice.fromJson),
      completions: {for (final c in list('completions', Completion.fromJson)) c.instanceKey: c},
      submissions: list('submissions', Submission.fromJson),
      workSearch: list('work_search', WorkSearchEntry.fromJson),
      statusNotes: list('status_notes', StatusNote.fromJson),
      questions: list('questions', AgencyQuestion.fromJson),
      attachments: list('attachments', Attachment.fromJson),
      settings: Settings.fromJson(j['settings'] as Map<String, dynamic>?),
    );
  }

  static const currentSchemaVersion = 1;

  final Profile profile;
  final List<Notice> notices;
  final Map<String, Completion> completions;
  final List<Submission> submissions;
  final List<WorkSearchEntry> workSearch;
  final List<StatusNote> statusNotes;
  final List<AgencyQuestion> questions;
  final List<Attachment> attachments;
  final Settings settings;

  Map<String, dynamic> toJson() => {
    'schema_version': currentSchemaVersion,
    'profile': profile.toJson(),
    'notices': [for (final n in notices) n.toJson()],
    'completions': [for (final c in completions.values) c.toJson()],
    'submissions': [for (final s in submissions) s.toJson()],
    'work_search': [for (final w in workSearch) w.toJson()],
    'status_notes': [for (final s in statusNotes) s.toJson()],
    'questions': [for (final q in questions) q.toJson()],
    'attachments': [for (final a in attachments) a.toJson()],
    'settings': settings.toJson(),
  };
}
