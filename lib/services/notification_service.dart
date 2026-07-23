import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<void> init() async {
    if (_initialized) return;
    if (!isSupported) {
      debugPrint('Notifications are not supported on this platform.');
      return;
    }

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );
      _initialized = true;
      debugPrint('Notification Service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (!isSupported) return;
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      } else if (Platform.isIOS) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    if (!_initialized || !isSupported) return;

    try {
      final now = DateTime.now();
      if (scheduledDateTime.isBefore(now)) {
        return;
      }

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDateTime, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminders_channel',
            'Medicine Reminders',
            channelDescription: 'Channel for medicine reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
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
      debugPrint('Scheduled notification $id at $scheduledDateTime');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized || !isSupported) return;
    try {
      await _notificationsPlugin.cancel(id: id);
      debugPrint('Canceled notification $id');
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_initialized || !isSupported) return;
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('Canceled all notifications');
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }
}
