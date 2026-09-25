import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobloss_os/app_controller.dart';
import 'package:jobloss_os/data/store.dart';
import 'package:jobloss_os/domain/export.dart';
import 'package:jobloss_os/domain/resolver.dart';
import 'package:jobloss_os/domain/user_data.dart';
import 'package:jobloss_os/services/reminders.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'helpers.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late Directory tmp;
  final controllers = <AppController>[];
  setUp(() => tmp = Directory.systemTemp.createTempSync('jobloss_test'));
  tearDown(() async {
    // Let queued background saves finish before removing the directory.
    for (final c in controllers) {
      await c.flush();
    }
    controllers.clear();
    tmp.deleteSync(recursive: true);
  });

  Future<AppController> makeController({
    UserDataStore? store,
    String Function()? dataset,
    NoopReminderScheduler? reminders,
  }) async {
    final s = store ?? FileStore(Directory('${tmp.path}/data'));
    final c = AppController(
      store: s,
      reminders: reminders ?? NoopReminderScheduler(),
      attachmentsDir: s is FileStore ? s.attachmentsDir : Directory('${tmp.path}/att'),
      loadDatasetJson: () async => (dataset ?? rawDataset)(),
      clock: () => DateTime(2026, 9, 25, 10),
    );
    await c.load();
    controllers.add(c);
    return c;
  }

  test('onboarding, completing and persisting across restarts', () async {
    final c = await makeController();
    c.completeOnboarding(
      lastDayWorked: d('2026-09-24'),
      appliedDate: d('2026-09-25'),
      coverageEndDate: null,
    );
    final reg = c.taskByKey('tx.register_workintexas')!;
    c.completeTask(reg, note: 'done at library');
    await c.flush();

    final c2 = await makeController();
    expect(c2.data.profile.onboarded, isTrue);
    final again = c2.taskByKey('tx.register_workintexas')!;
    expect(again.isDone, isTrue);
    expect(again.completion!.note, 'done at library');
    expect(again.completion!.datasetVersion, '2026.09.25-1');
  });

  test('reminders are rescheduled on change and cleared when disabled', () async {
    final r = NoopReminderScheduler();
    final c = await makeController(reminders: r);
    c.completeOnboarding(
      lastDayWorked: d('2026-09-24'),
      appliedDate: d('2026-09-25'),
      coverageEndDate: null,
    );
    await Future<void>.delayed(Duration.zero);
    expect(r.scheduled.any((p) => p.instanceKey == 'tx.register_workintexas'), isTrue);
    data(c).settings.remindersEnabled = false;
    await c.setRemindersEnabled(false);
    await Future<void>.delayed(Duration.zero);
    expect(r.scheduled, isEmpty);
    await c.flush();
  });

  test('invalid dataset: app falls back to record-keeping mode, data intact', () async {
    final c = await makeController(dataset: () => '{"schema_version": 1, "rules": []}');
    expect(c.dataset, isNull);
    expect(c.datasetError, isNotNull);
    expect(c.roadmap, isEmpty);
    c.addStatusNote(date: d('2026-09-25'), text: 'Pending');
    await c.flush();
    final c2 = await makeController();
    expect(c2.data.statusNotes.single.text, 'Pending');
  });

  test('attachments are copied privately and deleted with their letter', () async {
    final c = await makeController();
    final src = File('${tmp.path}/photo.JPG')..writeAsBytesSync([1, 2, 3]);
    final a = (await c.importAttachment(src.path))!;
    final stored = c.attachmentFile(a.id)!;
    expect(stored.existsSync(), isTrue);
    expect(stored.path.endsWith('.jpg'), isTrue);
    final n = c.addNotice(
      typeId: 'tx.determination',
      mailedDate: d('2026-09-21'),
      attachmentIds: [a.id],
    );
    c.completeTask(c.taskByKey('tx.determination_deadline@${n.id}')!);
    c.deleteNotice(n);
    expect(stored.existsSync(), isFalse);
    expect(c.data.attachments, isEmpty);
    expect(c.data.completions.keys.where((k) => k.contains(n.id)), isEmpty);
  });

  test('orphaned attachments (from a cancelled form) are purged on load', () async {
    final c = await makeController();
    final src = File('${tmp.path}/x.png')..writeAsBytesSync([1]);
    final a = (await c.importAttachment(src.path))!;
    final f = c.attachmentFile(a.id)!;
    await c.flush();
    final c2 = await makeController();
    expect(c2.data.attachments, isEmpty);
    expect(f.existsSync(), isFalse);
  });

  test('delete all data wipes file, backup, attachments and reminders', () async {
    final r = NoopReminderScheduler();
    final c = await makeController(reminders: r);
    c.completeOnboarding(
      lastDayWorked: d('2026-09-24'),
      appliedDate: d('2026-09-25'),
      coverageEndDate: d('2026-09-30'),
    );
    final src = File('${tmp.path}/p.png')..writeAsBytesSync([9]);
    final a = (await c.importAttachment(src.path))!;
    c.addSubmission(
      kind: SubmissionKind.registration,
      date: d('2026-09-25'),
      attachmentIds: [a.id],
    );
    c.addWorkSearch(date: d('2026-09-25'), employer: 'Acme');
    await c.flush();
    await c.deleteAllData();

    final dataDir = Directory('${tmp.path}/data');
    final leftovers = dataDir.existsSync()
        ? dataDir.listSync(recursive: true)
        : <FileSystemEntity>[];
    expect(leftovers, isEmpty);
    expect(r.scheduled, isEmpty);
    expect(c.data.profile.onboarded, isFalse);
    final c2 = await makeController();
    expect(c2.data.workSearch, isEmpty);
    expect(c2.data.profile.onboarded, isFalse);
  });

  test('export contains the user record, disclaimer and sources, and round-trips', () async {
    final c = await makeController();
    c.completeOnboarding(
      lastDayWorked: d('2026-09-24'),
      appliedDate: d('2026-09-25'),
      coverageEndDate: null,
    );
    c.addNotice(typeId: 'tx.determination', mailedDate: d('2026-09-21'), note: 'about separation');
    c.addSubmission(
      kind: SubmissionKind.paymentRequest,
      date: d('2026-09-25'),
      confirmation: 'ABC123',
    );
    c.addWorkSearch(
      date: d('2026-09-23'),
      employer: 'Acme Corp',
      contact: 'hr@acme.example',
      activityType: 'Applied for a job',
      result: 'Applied',
    );
    c.addQuestion('Do I keep requesting payment during an appeal?');
    final text = buildTextExport(
      dataset: c.dataset!,
      data: c.data,
      roadmap: c.roadmap,
      today: c.today,
    );
    expect(text, contains('not from the Texas Workforce Commission'));
    expect(text, contains('ABC123'));
    expect(text, contains('Acme Corp'));
    expect(text, contains('mailed 2026-09-21'));
    expect(text, contains('https://www.twc.texas.gov'));
    expect(text, contains('estimate — check your letter'));

    final json = jsonDecode(buildJsonExport(c.data, c.dataset!)) as Map<String, dynamic>;
    final restored = UserData.fromJson(json['data'] as Map<String, dynamic>);
    expect(restored.submissions.single.confirmation, 'ABC123');
    expect(restored.workSearch.single.employer, 'Acme Corp');
    expect(restored.notices.single.mailedDate, d('2026-09-21'));
    expect(restored.profile.dates['applied_date'], d('2026-09-25'));
    final roadmap = resolveRoadmap(dataset: c.dataset!, data: restored, today: c.today);
    expect(roadmap.length, c.roadmap.length);
  });

  group('FileStore', () {
    test('falls back to backup when the main file is corrupt', () async {
      final s = FileStore(Directory('${tmp.path}/fs'));
      await s.save(UserData(profile: Profile(onboarded: true)));
      await s.save(
        UserData(profile: Profile(onboarded: true, counts: {'work_search_required_per_week': 3})),
      );
      File('${tmp.path}/fs/jobloss_data.json').writeAsStringSync('{"broken":');
      final loaded = await s.load();
      expect(loaded.profile.onboarded, isTrue);
    });

    test('data from a newer app version is never overwritten', () async {
      final dir = Directory('${tmp.path}/nv')..createSync();
      final file = File('${dir.path}/jobloss_data.json')
        ..writeAsStringSync(
          jsonEncode({
            'schema_version': 99,
            'profile': {'onboarded': true},
          }),
        );
      final c = await makeController(store: FileStore(dir));
      expect(c.dataError, isA<NewerDataVersionException>());
      c.addStatusNote(date: d('2026-09-25'), text: 'x');
      await c.flush();
      expect(jsonDecode(file.readAsStringSync())['schema_version'], 99);
    });

    test('missing file starts fresh', () async {
      final loaded = await FileStore(Directory('${tmp.path}/none')).load();
      expect(loaded.profile.onboarded, isFalse);
    });
  });
}

UserData data(AppController c) => c.data;
