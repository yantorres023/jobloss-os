import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import 'data/store.dart';
import 'domain/dataset_validator.dart';
import 'domain/local_date.dart';
import 'domain/reminder_plan.dart';
import 'domain/resolver.dart';
import 'domain/rules.dart';
import 'domain/user_data.dart';
import 'services/reminders.dart';

typedef Clock = DateTime Function();

/// Owns the loaded dataset and user data, and every mutation of them.
class AppController extends ChangeNotifier {
  AppController({
    required this.store,
    required this.reminders,
    required this.loadDatasetJson,
    this.attachmentsDir,
    Clock? clock,
  }) : _clock = clock ?? DateTime.now;

  final UserDataStore store;
  final ReminderScheduler reminders;
  final Directory? attachmentsDir;
  final Future<String> Function() loadDatasetJson;
  final Clock _clock;
  final _random = Random.secure();

  RuleDataset? dataset;
  Object? datasetError;

  /// Set when stored records can't be read by this version; saving is off.
  Object? dataError;
  bool _saveBlocked = false;
  UserData data = UserData();
  bool loaded = false;
  List<TaskInstance>? _roadmap;
  Future<void> _pendingSave = Future.value();

  /// Completes when every queued save has been written.
  Future<void> flush() => _pendingSave;

  LocalDate get today => LocalDate.fromDateTime(_clock());

  Future<void> load() async {
    try {
      dataset = parseAndValidateDataset(await loadDatasetJson());
    } on Object catch (e) {
      // The app keeps working as a plain record keeper (fallback mode).
      datasetError = e;
      debugPrint('Dataset rejected: $e');
    }
    try {
      data = await store.load();
    } on NewerDataVersionException catch (e) {
      // Never overwrite records we can't read.
      dataError = e;
      _saveBlocked = true;
      data = UserData();
    }
    if (!_saveBlocked) await _purgeOrphanAttachments();
    loaded = true;
    _changed(save: false);
  }

  List<TaskInstance> get roadmap {
    final d = dataset;
    if (d == null) return const [];
    return _roadmap ??= resolveRoadmap(dataset: d, data: data, today: today);
  }

  List<TaskInstance> tasksIn(Bucket b) => [
    for (final t in roadmap)
      if (t.bucket(today) == b) t,
  ]..sort(compareTasks);

  TaskInstance? get nextHardDeadline => nextDeadline(roadmap, today);

  List<Completion> get retiredCompletions => orphanCompletions(roadmap, data);

  TaskInstance? taskByKey(String key) {
    for (final t in roadmap) {
      if (t.key == key) return t;
    }
    return null;
  }

  String newId() =>
      List.generate(8, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

  // ---- Profile ---------------------------------------------------------

  void completeOnboarding({
    required LocalDate? lastDayWorked,
    required LocalDate? appliedDate,
    required LocalDate? coverageEndDate,
  }) {
    final p = data.profile;
    _setDate('last_day_worked', lastDayWorked);
    _setDate('applied_date', appliedDate);
    _setDate('coverage_end_date', coverageEndDate);
    p.onboarded = true;
    _changed();
  }

  void setDateFact(String key, LocalDate? value) {
    _setDate(key, value);
    _changed();
  }

  void setCountFact(String key, int? value) {
    if (value == null) {
      data.profile.counts.remove(key);
    } else {
      data.profile.counts[key] = value;
    }
    _changed();
  }

  void _setDate(String key, LocalDate? value) {
    if (value == null) {
      data.profile.dates.remove(key);
    } else {
      data.profile.dates[key] = value;
    }
  }

  // ---- Tasks -------------------------------------------------------------

  void completeTask(TaskInstance t, {String note = ''}) {
    data.completions[t.key] = Completion(
      instanceKey: t.key,
      ruleId: t.rule.ruleId,
      completedOn: today,
      ruleVersion: t.rule.version,
      datasetVersion: dataset?.datasetVersion ?? '',
      note: note,
    );
    _changed();
  }

  void reopenTask(String instanceKey) {
    data.completions.remove(instanceKey);
    _changed();
  }

  // ---- Notices -------------------------------------------------------------

  Notice addNotice({
    required String typeId,
    LocalDate? mailedDate,
    LocalDate? printedDeadline,
    LocalDate? eventDate,
    String note = '',
    List<String> attachmentIds = const [],
  }) {
    final n = Notice(
      id: newId(),
      typeId: typeId,
      loggedOn: today,
      mailedDate: mailedDate,
      printedDeadline: printedDeadline,
      eventDate: eventDate,
      note: note,
      attachmentIds: [...attachmentIds],
    );
    data.notices.add(n);
    _changed();
    return n;
  }

  void updateNotice(Notice n) => _changed();

  void deleteNotice(Notice n) {
    data.notices.removeWhere((x) => x.id == n.id);
    // Completions for that letter's step go with it; they have no meaning alone.
    data.completions.removeWhere((k, _) => k.endsWith('@${n.id}'));
    _deleteAttachments(n.attachmentIds);
    _changed();
  }

  // ---- Log ---------------------------------------------------------------------

  Submission addSubmission({
    required SubmissionKind kind,
    required LocalDate date,
    String confirmation = '',
    String note = '',
    String? instanceKey,
    List<String> attachmentIds = const [],
  }) {
    final s = Submission(
      id: newId(),
      kind: kind,
      date: date,
      confirmation: confirmation,
      note: note,
      instanceKey: instanceKey,
      attachmentIds: [...attachmentIds],
    );
    data.submissions.add(s);
    _changed();
    return s;
  }

  void deleteSubmission(Submission s) {
    data.submissions.removeWhere((x) => x.id == s.id);
    _deleteAttachments(s.attachmentIds);
    _changed();
  }

  WorkSearchEntry addWorkSearch({
    required LocalDate date,
    required String employer,
    String contact = '',
    String activityType = '',
    String result = '',
    String note = '',
  }) {
    final w = WorkSearchEntry(
      id: newId(),
      date: date,
      employer: employer,
      contact: contact,
      activityType: activityType,
      result: result,
      note: note,
    );
    data.workSearch.add(w);
    _changed();
    return w;
  }

  void deleteWorkSearch(WorkSearchEntry w) {
    data.workSearch.removeWhere((x) => x.id == w.id);
    _changed();
  }

  void addStatusNote({required LocalDate date, required String text, String where = ''}) {
    data.statusNotes.add(StatusNote(id: newId(), date: date, text: text, where: where));
    _changed();
  }

  void deleteStatusNote(StatusNote s) {
    data.statusNotes.removeWhere((x) => x.id == s.id);
    _changed();
  }

  void addQuestion(String text, {String? ruleId}) {
    if (data.questions.any((q) => q.text == text)) return;
    data.questions.add(AgencyQuestion(id: newId(), text: text, ruleId: ruleId));
    _changed();
  }

  void updateQuestion(AgencyQuestion q) => _changed();

  void deleteQuestion(AgencyQuestion q) {
    data.questions.removeWhere((x) => x.id == q.id);
    _changed();
  }

  // ---- Attachments ------------------------------------------------------------

  /// Copies a picked file into private app storage and records it.
  Future<Attachment?> importAttachment(String sourcePath, {String caption = ''}) async {
    final dir = attachmentsDir;
    if (dir == null) return null;
    await dir.create(recursive: true);
    final id = newId();
    final dot = sourcePath.lastIndexOf('.');
    final ext = dot >= 0 ? sourcePath.substring(dot).toLowerCase() : '';
    final safeExt = RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(ext) ? ext : '';
    final name = '$id$safeExt';
    await File(sourcePath).copy('${dir.path}/$name');
    final a = Attachment(id: id, fileName: name, addedOn: today, caption: caption);
    data.attachments.add(a);
    _changed();
    return a;
  }

  File? attachmentFile(String id) {
    final dir = attachmentsDir;
    if (dir == null) return null;
    for (final a in data.attachments) {
      if (a.id == id) return File('${dir.path}/${a.fileName}');
    }
    return null;
  }

  /// Deletes image files no letter or log entry points to any more (e.g. a
  /// photo added to a form that was then cancelled). Privacy: removed means
  /// removed.
  Future<void> _purgeOrphanAttachments() async {
    final used = {
      for (final n in data.notices) ...n.attachmentIds,
      for (final s in data.submissions) ...s.attachmentIds,
    };
    final orphans = [
      for (final a in data.attachments)
        if (!used.contains(a.id)) a.id,
    ];
    if (orphans.isNotEmpty) _deleteAttachments(orphans);
    final dir = attachmentsDir;
    if (dir != null && await dir.exists()) {
      final known = {for (final a in data.attachments) a.fileName};
      await for (final f in dir.list()) {
        if (f is File && !known.contains(f.uri.pathSegments.last)) await f.delete();
      }
    }
    if (orphans.isNotEmpty) await store.save(data);
  }

  void _deleteAttachments(List<String> ids) {
    for (final id in ids) {
      final f = attachmentFile(id);
      if (f != null && f.existsSync()) f.deleteSync();
      data.attachments.removeWhere((a) => a.id == id);
    }
  }

  // ---- Settings / privacy -------------------------------------------------------

  Future<bool> setRemindersEnabled(bool on) async {
    var granted = true;
    if (on) granted = await reminders.requestPermission();
    data.settings.remindersEnabled = on;
    _changed();
    return granted;
  }

  /// Deletes everything: data file, backup, attachments, scheduled reminders.
  Future<void> deleteAllData() async {
    await reminders.cancelAll();
    await _pendingSave;
    await store.wipe();
    final dir = attachmentsDir;
    if (dir != null && await dir.exists()) await dir.delete(recursive: true);
    data = UserData();
    dataError = null;
    _saveBlocked = false;
    _roadmap = null;
    notifyListeners();
  }

  // ---- Internals ----------------------------------------------------------------

  void _changed({bool save = true}) {
    _roadmap = null;
    notifyListeners();
    if (save && !_saveBlocked) {
      // Serialize writes so two quick edits can't interleave on disk.
      final snapshot = data;
      _pendingSave = _pendingSave.then((_) => store.save(snapshot));
    }
    _reschedule();
  }

  Future<void> _reschedule() async {
    if (!data.settings.remindersEnabled || dataset == null) {
      await reminders.cancelAll();
      return;
    }
    final loc = reminders.location;
    await reminders.replaceAll(
      planReminders(
        roadmap: roadmap,
        location: loc,
        now: tz.TZDateTime.from(_clock(), loc),
        hour: data.settings.reminderHour,
      ),
    );
  }
}
