import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Notification IDs
  static const int _waterReminderId = 1000;
  static const int _profileUpdateId = 2000;
  static const int _mealPlanId = 3000;
  static const int _workoutReminderId = 4000;
  static const int _weeklyReportId = 5000;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
      // Android initialization
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization  
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      print('✅ NotificationService inicializado com sucesso');
      
    } catch (e) {
      print('❌ Erro ao inicializar NotificationService: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 13+ notification permission
      final status = await Permission.notification.request();
      print('📱 Permissão de notificação (Android): $status');
      
      // Schedule exact alarm permission for Android 12+
      await Permission.scheduleExactAlarm.request();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS notification permissions
      await _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    print('🔔 Notificação tocada: $payload');
    
    // Handle different notification types
    switch (payload) {
      case 'water_reminder':
        // Navigate to water logging screen
        break;
      case 'profile_update':
        // Navigate to profile update screen
        break;
      case 'meal_plan':
        // Navigate to meal plan screen
        break;
      case 'workout':
        // Navigate to workout screen  
        break;
      case 'weekly_report':
        // Navigate to reports screen
        break;
    }
  }

  // =================  WATER REMINDERS =================

  Future<void> scheduleWaterReminders() async {
    if (!_isInitialized) await initialize();

    // Cancel existing water reminders
    await cancelWaterReminders();

    // Schedule water reminders every 2 hours from 8am to 10pm
    final times = [8, 10, 12, 14, 16, 18, 20, 22];
    
    for (int i = 0; i < times.length; i++) {
      final hour = times[i];
      
      await _notifications.zonedSchedule(
        _waterReminderId + i,
        '💧 Hora de beber água!',
        'Hidrate-se para manter sua saúde em dia. Meta diária: 2-3 litros',
        _nextInstanceOfTime(hour, 0),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'water_reminders',
            'Lembretes de Água',
            channelDescription: 'Notificações para lembrar de beber água',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/water_icon',
            color: Color(0xFF2196F3),
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'water_reminder',
            sound: 'default.caf',
          ),
        ),
        payload: 'water_reminder',
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    await _saveLastScheduled('water_reminders');
    print('💧 Lembretes de água agendados: ${times.length} notificações');
  }

  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < 8; i++) {
      await _notifications.cancel(_waterReminderId + i);
    }
  }

  // =================  PROFILE UPDATE REMINDERS =================

  Future<void> scheduleProfileUpdateReminder() async {
    if (!_isInitialized) await initialize();

    await _notifications.cancel(_profileUpdateId);

    // Schedule for 7 days from now at 9 AM
    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(days: 7));
    final nextUpdate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      9, // 9 AM
    );

    await _notifications.zonedSchedule(
      _profileUpdateId,
      '📊 Atualize seus dados!',
      'Já fazem 7 dias! Que tal atualizar seu peso e medidas para acompanhar seu progresso?',
      nextUpdate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'profile_updates',
          'Atualizações de Perfil',
          channelDescription: 'Lembretes para atualizar dados do perfil',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/profile_icon',
          color: Color(0xFF4CAF50),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'profile_update',
          sound: 'default.caf',
        ),
      ),
      payload: 'profile_update',
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _saveLastScheduled('profile_update');
    print('📊 Lembrete de atualização de perfil agendado para: $nextUpdate');
  }

  // =================  MEAL PLAN REMINDERS =================

  Future<void> scheduleMealPlanReminder() async {
    if (!_isInitialized) await initialize();

    await _notifications.cancel(_mealPlanId);

    // Schedule for every Sunday at 8 AM
    final nextSunday = _nextInstanceOfWeekday(DateTime.sunday, 8, 0);

    await _notifications.zonedSchedule(
      _mealPlanId,
      '🍽️ Nova semana, novo plano!',
      'Que tal gerar um novo plano alimentar para esta semana?',
      nextSunday,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_plans',
          'Planos Alimentares',
          channelDescription: 'Lembretes para criar novos planos alimentares',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/meal_icon',
          color: Color(0xFFFF9800),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'meal_plan',
          sound: 'default.caf',
        ),
      ),
      payload: 'meal_plan',
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _saveLastScheduled('meal_plan');
    print('🍽️ Lembrete de plano alimentar agendado para domingos às 8h');
  }

  // =================  WORKOUT REMINDERS =================

  Future<void> scheduleWorkoutReminders() async {
    if (!_isInitialized) await initialize();

    // Cancel existing workout reminders
    for (int i = 0; i < 7; i++) {
      await _notifications.cancel(_workoutReminderId + i);
    }

    // Schedule workout reminders for Monday, Wednesday, Friday at 7 PM
    final workoutDays = [DateTime.monday, DateTime.wednesday, DateTime.friday];
    
    for (int i = 0; i < workoutDays.length; i++) {
      final nextWorkout = _nextInstanceOfWeekday(workoutDays[i], 19, 0); // 7 PM

      await _notifications.zonedSchedule(
        _workoutReminderId + i,
        '🏋️ Hora do treino!',
        'Seu corpo está esperando! Que tal fazer um treino hoje?',
        nextWorkout,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'workouts',
            'Lembretes de Treino',
            channelDescription: 'Notificações para lembrar dos treinos',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/workout_icon',
            color: Color(0xFFE91E63),
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'workout',
            sound: 'default.caf',
          ),
        ),
        payload: 'workout',
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    await _saveLastScheduled('workout_reminders');
    print('🏋️ Lembretes de treino agendados para segunda, quarta e sexta às 19h');
  }

  // =================  WEEKLY REPORTS =================

  Future<void> scheduleWeeklyReport() async {
    if (!_isInitialized) await initialize();

    await _notifications.cancel(_weeklyReportId);

    // Schedule for every Saturday at 6 PM
    final nextSaturday = _nextInstanceOfWeekday(DateTime.saturday, 18, 0);

    await _notifications.zonedSchedule(
      _weeklyReportId,
      '📈 Seu relatório semanal está pronto!',
      'Veja como foi sua semana e descubra insights sobre seu progresso',
      nextSaturday,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_reports',
          'Relatórios Semanais',
          channelDescription: 'Notificações de relatórios semanais',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/report_icon',
          color: Color(0xFF9C27B0),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'weekly_report',
          sound: 'default.caf',
        ),
      ),
      payload: 'weekly_report',
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _saveLastScheduled('weekly_report');
    print('📈 Relatório semanal agendado para sábados às 18h');
  }

  // =================  HELPER METHODS =================

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  Future<void> _saveLastScheduled(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_scheduled_$type', DateTime.now().toIso8601String());
  }

  // =================  PUBLIC METHODS =================

  /// Agenda todas as notificações do app
  Future<void> scheduleAllNotifications() async {
    await initialize();
    
    await Future.wait([
      scheduleWaterReminders(),
      scheduleProfileUpdateReminder(),
      scheduleMealPlanReminder(),
      scheduleWorkoutReminders(),
      scheduleWeeklyReport(),
    ]);
    
    print('🔔 Todas as notificações foram agendadas com sucesso!');
  }

  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🔕 Todas as notificações foram canceladas');
  }

  /// Mostra uma notificação imediata
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'immediate',
          'Notificações Imediatas',
          channelDescription: 'Notificações importantes imediatas',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default.caf',
        ),
      ),
      payload: payload,
    );
  }

  /// Lista todas as notificações pendentes
  Future<void> listPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    print('📋 Notificações pendentes: ${pending.length}');
    for (final notification in pending) {
      print('  - ID: ${notification.id}, Title: ${notification.title}');
    }
  }
}