import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(settings);
    tz.initializeTimeZones();
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails('main_channel', 'Notificações', importance: Importance.max, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> scheduleWaterNotification({
    required int hour,
    required int minute,
    required String body,
    int id = 100,
  }) async {
    await _notifications.zonedSchedule(
      id,
      'Hora de beber água!',
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails('water_channel', 'Água', importance: Importance.max, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleWeeklyUpdateNotification({
    required int weekday, // 1=Monday, 7=Sunday
    required int hour,
    required int minute,
    required String body,
    int id = 200,
  }) async {
    await _notifications.zonedSchedule(
      id,
      'Atualize seus dados!',
      body,
      _nextInstanceOfWeekday(weekday, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails('update_channel', 'Atualização', importance: Importance.max, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
