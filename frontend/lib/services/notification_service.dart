import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

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

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

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

    // Request iOS permissions
    final iosImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Request Samsung-specific permissions
    await _requestSamsungPermissions();
  }

  /// Request Samsung-specific permissions for reliable notifications
  Future<void> _requestSamsungPermissions() async {
    if (!Platform.isAndroid) return;

    // Request schedule exact alarm permission is already requested above
    // Battery optimization needs to be requested via intent
    debugPrint('🔔 Samsung permissions requested');
  }

  /// Check if battery optimization is enabled (notifications may be unreliable)
  Future<bool> isBatteryOptimizationEnabled() async {
    if (!Platform.isAndroid) return false;
    // Use platform channel to check battery optimization status
    return false; // Default to false, actual check requires native code
  }

  /// Open battery optimization settings for the user to disable
  Future<void> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;

    // Open battery optimization settings via intent
    try {
      const intent = 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS';
      await launchUrl(
        Uri.parse(intent),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not open battery optimization settings: $e');
      // Fallback: open app settings
      await openAppSettings();
    }
  }

  /// Open Samsung auto-start settings
  Future<void> requestAutoStartPermission() async {
    if (!Platform.isAndroid) return;

    // Try to open Samsung auto-start settings
    const samsungAutoStart = 'com.samsung.android.lool';
    try {
      await launchUrl(
        Uri.parse('android-app://$samsungAutoStart'),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not open Samsung auto-start: $e');
    }
  }

  /// Show a dialog guiding Samsung users to enable all required permissions
  Future<void> showSamsungPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.battery_charging_full, color: Colors.green),
          title: const Text('Enable Notifications'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'For reliable hydration reminders on Samsung devices, please enable these settings:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                NotificationService.buildPermissionItem(
                  '1. Battery Optimization',
                  'Settings → Apps → Expense Tracker → Battery → Unrestricted',
                ),
                NotificationService.buildPermissionItem(
                  '2. Auto-start',
                  'Settings → Apps → Expense Tracker → Enable "Allow background activity"',
                ),
                NotificationService.buildPermissionItem(
                  '3. Notifications',
                  'Settings → Apps → Expense Tracker → Notifications → Enable all',
                ),
                NotificationService.buildPermissionItem(
                  '4. Lock in Recent Apps',
                  'Open recent apps → Tap app icon → Tap "Keep open"',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await NotificationService().requestDisableBatteryOptimization();
              },
              child: const Text('Open Battery Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Helper widget to build permission list items
  static Widget buildPermissionItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          channelDescription: 'Main channel for notifications',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
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
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Schedules repeating daily hydration reminders.
  ///
  /// Uses [matchDateTimeComponents: DateTimeComponents.time] so each
  /// notification repeats every day at the same time automatically.
  /// Reminders are spaced by [intervalMinutes] between 7 AM and 11 PM.
  Future<void> scheduleDailyHydration(
    int intervalMinutes,
    String username,
  ) async {
    // Cancel previous hydration reminders (IDs 2000–2099)
    for (int i = 0; i < 100; i++) {
      await flutterLocalNotificationsPlugin.cancel(id: 2000 + i);
    }

    if (intervalMinutes <= 0) return;

    final now = tz.TZDateTime.now(tz.local);

    // Define daily window: 7 AM to 11 PM
    const startHour = 7;
    const endHour = 23;

    int idCounter = 0;

    // Build the schedule starting from 7 AM today
    tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      startHour,
      0, // minute
    );

    final messages = [
      '$username, time to drink water 💧',
      'Stay hydrated, $username!',
      '💧 $username, your body needs water.',
      'Water break, $username! 🥤',
      'Keep drinking water, $username! 💦',
      'Hydration time, $username! 🚰',
      'Don\'t forget to drink water, $username!',
    ];

    // Schedule a notification for each slot in the daily window.
    while (scheduledTime.hour < endHour && idCounter < 100) {
      // Ensure the first scheduled time is in the future
      tz.TZDateTime targetTime = scheduledTime;
      if (targetTime.isBefore(now)) {
        // Move to tomorrow at the same time
        targetTime = targetTime.add(const Duration(days: 1));
      }

      // Only schedule if still within today's window after adjustment
      if (targetTime.isAfter(now)) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: 2000 + idCounter,
          title: 'Hydration Reminder 💧',
          body: messages[idCounter % messages.length],
          scheduledDate: targetTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'health_channel',
              'Health Reminders',
              channelDescription: 'Daily hydration reminders',
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
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

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> getPendingNotificationRequests() async {
    final pending = await flutterLocalNotificationsPlugin
        .pendingNotificationRequests();
    print('📋 Pending notifications: $pending');
  }
}
