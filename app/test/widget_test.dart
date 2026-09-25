import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobloss_os/app_controller.dart';
import 'package:jobloss_os/data/store.dart';
import 'package:jobloss_os/domain/user_data.dart';
import 'package:jobloss_os/main.dart';
import 'package:jobloss_os/services/reminders.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'helpers.dart';

Future<AppController> controller({UserData? data}) async {
  final c = AppController(
    store: InMemoryStore(data),
    reminders: NoopReminderScheduler(),
    loadDatasetJson: () async => rawDataset(),
    clock: () => DateTime(2026, 9, 25, 10),
  );
  await c.load();
  return c;
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('onboarding: states it is not TWC and needs Texas + acknowledgement', (tester) async {
    final c = await controller();
    await tester.pumpWidget(JobLossApp(controller: c));
    await tester.pumpAndSettle();

    expect(find.textContaining('not the Texas Workforce Commission'), findsOneWidget);
    expect(find.textContaining('never asks for your Social Security number'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Another state'), 200);
    await tester.tap(find.text('Another state'));
    await tester.pumpAndSettle();
    expect(find.textContaining('only covers Texas'), findsOneWidget);
    expect(find.text('Show my steps'), findsNothing);

    await tester.tap(find.text('Texas'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Show my steps'), 200);
    final button = find.widgetWithText(FilledButton, 'Show my steps');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
  });

  testWidgets('home answers "what today" and "next deadline", with the not-TWC banner', (
    tester,
  ) async {
    final c = await controller(
      data: UserData(
        profile: Profile(
          onboarded: true,
          dates: {'last_day_worked': d('2026-09-24'), 'applied_date': d('2026-09-25')},
        ),
      ),
    );
    await tester.pumpWidget(JobLossApp(controller: c));
    await tester.pumpAndSettle();

    expect(find.text('Unofficial organizer · Not TWC · Not legal advice'), findsOneWidget);
    expect(find.text('NEXT DEADLINE'), findsOneWidget);
    expect(find.text('Register on WorkInTexas.com'), findsOneWidget);
    expect(find.text('Choose how TWC pays you'), findsOneWidget);
  });

  testWidgets('task detail shows official source, review status and help', (tester) async {
    final c = await controller(
      data: UserData(
        profile: Profile(
          onboarded: true,
          dates: {'last_day_worked': d('2026-09-24'), 'applied_date': d('2026-09-25')},
        ),
      ),
    );
    await tester.pumpWidget(JobLossApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose how TWC pays you'));
    await tester.pumpAndSettle();

    expect(find.text('Official step'), findsOneWidget);
    expect(find.text('Source not yet human-checked'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Official source'), 200);
    expect(find.textContaining('Not yet checked by a person'), findsOneWidget);
    expect(find.text('www.twc.texas.gov'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Mark done'), 200);
    await tester.tap(find.text('Mark done'));
    await tester.pumpAndSettle();
    expect(c.taskByKey('tx.choose_payment_option')!.isDone, isTrue);
  });

  testWidgets('logging a determination letter creates an appeal deadline', (tester) async {
    final c = await controller(data: UserData(profile: Profile(onboarded: true)));
    c.addNotice(typeId: 'tx.determination', mailedDate: d('2026-09-21'));
    await tester.pumpWidget(JobLossApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('Read your determination and note the appeal deadline'), findsWidgets);
    expect(find.textContaining('Appeal deadline'), findsWidgets);
    expect(find.textContaining('Estimated by the app'), findsOneWidget);
  });
}
