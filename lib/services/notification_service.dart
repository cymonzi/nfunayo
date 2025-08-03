import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  NotificationService(this._flutterLocalNotificationsPlugin);

  /// Initialize time zones and notification settings
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Schedule a set of daily notifications at specified times
  Future<void> scheduleNotifications() async {
    final List<Map<String, dynamic>> notificationTimes = [
      {
        'id': 1,
        'title': 'Good Morning!',
        'body': 'Start your day by tracking your expenses.',
        'hour': 8,
        'minute': 0,
      },
      {
        'id': 2,
        'title': 'Mid-Morning Check',
        'body': 'Don’t forget to log your morning expenses.',
        'hour': 10,
        'minute': 0,
      },
      {
        'id': 3,
        'title': 'Lunch Reminder',
        'body': 'Log your lunch expenses to stay on track.',
        'hour': 13,
        'minute': 0,
      },
      {
        'id': 4,
        'title': 'Evening Check-In',
        'body': 'Review your expenses for the day.',
        'hour': 18,
        'minute': 0,
      },
      {
        'id': 5,
        'title': 'Good Night!',
        'body': 'Log your final expenses before bed.',
        'hour': 21,
        'minute': 0,
      },
    ];

    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('notifications') ?? [];

    for (var notification in notificationTimes) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        notification['hour'],
        notification['minute'],
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notification['id'],
          notification['title'],
          notification['body'],
          scheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_notifications',
              'Daily Notifications',
              channelDescription: 'Daily reminders for expense tracking',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode:
              AndroidScheduleMode.exactAllowWhileIdle, // Required parameter
          matchDateTimeComponents:
              DateTimeComponents
                  .time, // Replaces uiLocalNotificationDateInterpretation
        );

        if (!notifications.contains(
          '${notification['title']}|${notification['body']}|${scheduledTime.toIso8601String()}',
        )) {
          notifications.add(
            '${notification['title']}|${notification['body']}|${scheduledTime.toIso8601String()}',
          );
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error scheduling notification: $e');
      }
    }

    await prefs.setStringList('notifications', notifications);
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Increment the unread badge count and update app icon
  Future<void> incrementUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt('unread_count') ?? 0;
    count += 1;
    await prefs.setInt('unread_count', count);
    await updateBadgeCount(count);
  }

  /// Clear unread count and remove badge
  Future<void> clearUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_count', 0);
    await updateBadgeCount(0);
  }

  /// Update app icon badge count
  Future<void> updateBadgeCount(int count) async {
    // If badge functionality is not needed, simply log or handle the count
  }
}
