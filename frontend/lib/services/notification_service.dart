import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // FIX: Use 'settings' as named parameter based on lints
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          channelDescription: 'Main channel for notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // FIX: Using named arguments if 'show' requires them.
    // Usually 'show' is positional, but given the 'zonedSchedule' lints,
    // and if I can't verify 'show' signature, I'll rely on common patterns.
    // However, lints for 'show' (line 49 in previous file) said "0 expected but 4 found".
    // This confirms 'show' takes NO positional args. So it MUST be named.
    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // FIX: Use named arguments
    // Removed 'uiLocalNotificationDateInterpretation' as lints said it's undefined parameter.
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel',
          'Scheduled Notifications',
          channelDescription: 'Channel for scheduled reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleWaterReminder(int intervalMinutes) async {
    for (int i = 0; i < 10; i++) {
      await flutterLocalNotificationsPlugin.cancel(id: 1000 + i);
    }

    if (intervalMinutes <= 0) return;

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 1; i <= 10; i++) {
      final scheduledTime = now.add(Duration(minutes: intervalMinutes * i));
      if (scheduledTime.hour >= 23 || scheduledTime.hour < 7) continue;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: 1000 + i,
        title: 'Hydration Reminder',
        body: 'Time to drink some water!',
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'health_channel',
            'Health Reminders',
            channelDescription: 'Reminders for water and breaks',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
