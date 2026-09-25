import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app_controller.dart';
import 'data/store.dart';
import 'services/reminders.dart';
import 'ui/app_scope.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme.dart';

const datasetAsset = 'assets/rules/us_tx/rules.json';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final docs = await getApplicationSupportDirectory();
  final store = FileStore(Directory('${docs.path}/jobloss'));
  final reminders = LocalNotificationScheduler();
  try {
    await reminders.init();
  } on Object catch (e) {
    debugPrint('Reminders unavailable: $e');
  }
  final controller = AppController(
    store: store,
    reminders: reminders,
    attachmentsDir: store.attachmentsDir,
    loadDatasetJson: () => rootBundle.loadString(datasetAsset),
  );
  await controller.load();
  runApp(JobLossApp(controller: controller));
}

class JobLossApp extends StatelessWidget {
  const JobLossApp({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        title: 'JobLoss OS',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (app.dataError != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text('${app.dataError}', textAlign: TextAlign.center)),
          ),
        ),
      );
    }
    return app.data.profile.onboarded ? const HomeShell() : const OnboardingScreen();
  }
}
