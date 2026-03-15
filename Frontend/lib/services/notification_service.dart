import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked with payload: \${response.payload}');
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    // Request Android 13+ permissions
    if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        await androidImplementation?.requestNotificationsPermission();
        await androidImplementation?.requestExactAlarmsPermission();
    }
    
    // Request iOS permissions
    if (defaultTargetPlatform == TargetPlatform.iOS) {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            );
    }
  }

  Future<void> scheduleDailyHabitReminders() async {
    try {
        // 8:00 AM Reminder
        await _scheduleNotification(
            1,
            'Morning Habit Check',
            "Start your day right! Check your habits for today.",
            8,
            0,
        );

        // 1:00 PM Reminder
        await _scheduleNotification(
            2,
            'Afternoon Progress Boost',
            "How's your day going? Don't forget your mid-day habits!",
            13,
            0,
        );

        // 1:15 PM Reminder (New)
        await _scheduleNotification(
            4,
            'Quick Habit Reminder',
            "It's 1:15 PM! Just a quick nudge to stay on top of your goals.",
            13,
            40,
        );

        // 8:00 PM Reminder
        await _scheduleNotification(
            3,
            'Nightly Habit Wrap-up',
            "Almost done for the day! Have you completed all your habits?",
            20,
            0,
        );
        
        debugPrint("Daily notifications scheduled for 8 AM, 1 PM, 1:15 PM, and 8 PM");
    } catch (e) {
        debugPrint("Error scheduling notifications: \$e");
    }
  }

  Future<void> _scheduleNotification(int id, String title, String body, int hour, int minute) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'daily_habits_channel',
                'Daily Habits Reminder',
                channelDescription: 'Reminds you to complete your daily habits',
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
