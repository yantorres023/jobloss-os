import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_plan.dart';

/// Schedules local, on-device notifications. Nothing is sent to a server.
abstract class ReminderScheduler {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> replaceAll(List<PlannedReminder> reminders);
  Future<void> cancelAll();
  tz.Location get location;
}

class NoopReminderScheduler implements ReminderScheduler {
  final List<PlannedReminder> scheduled = [];

  @override
  tz.Location get location => tz.UTC;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    scheduled
      ..clear()
      ..addAll(reminders);
  }

  @override
  Future<void> cancelAll() async => scheduled.clear();
}

class LocalNotificationScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  tz.Location _location = tz.UTC;

  @override
  tz.Location get location => _location;

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      _location = tz.getLocation(info.identifier);
    } on Object catch (e) {
      // Fall back to Central time: most of Texas. Reminders are best-effort.
      debugPrint('Time zone lookup failed: $e');
      _location = tz.getLocation('America/Chicago');
    }
    tz.setLocalLocation(_location);
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: false, sound: true) ?? false;
    }
    return false;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    await _plugin.cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'deadlines',
        'Deadlines and steps',
        channelDescription: 'Reminders for steps and deadlines you track',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        scheduledDate: r.at,
        notificationDetails: details,
        // Inexact: no exact-alarm permission needed. Reminders are set for
        // the morning of the day, so minutes of drift don't matter.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
        payload: r.instanceKey,
      );
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
