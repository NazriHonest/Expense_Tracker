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

  Future<void> scheduleDailyHydration(
    int intervalMinutes,
    String username,
  ) async {
    // Cancel previous reminders
    for (int i = 0; i < 100; i++) {
      await flutterLocalNotificationsPlugin.cancel(id: 2000 + i);
    }

    if (intervalMinutes <= 0) return;

    final now = tz.TZDateTime.now(tz.local);

    // Define daily window
    final startHour = 7;
    final endHour = 23;

    int idCounter = 0;

    // Start from today at 7 AM
    tz.TZDateTime startTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      startHour,
    );

    // If current time is past today's window → start tomorrow
    if (now.hour >= endHour) {
      startTime = startTime.add(const Duration(days: 1));
    }

    // If before 7 AM → schedule from 7 AM today
    if (now.hour < startHour) {
      startTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        startHour,
      );
    }

    // Generate reminders for the whole day
    tz.TZDateTime scheduledTime = startTime;

    final messages = [
      '$username, time to drink water 💧',
      'Stay hydrated, $username!',
      '💧 $username, your body needs water.',
    ];

    while (scheduledTime.hour < endHour) {
      if (scheduledTime.isAfter(now)) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: 2000 + idCounter,
          title: 'Hydration Reminder',
          body: messages[idCounter % messages.length],
          scheduledDate: scheduledTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'health_channel',
              'Health Reminders',
              channelDescription: 'Daily hydration reminders',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // 🔁 Repeat daily
        );

        idCounter++;
      }

      scheduledTime = scheduledTime.add(Duration(minutes: intervalMinutes));
    }
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
