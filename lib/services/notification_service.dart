import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Singleton service for scheduling and cancelling local notifications.
/// All public methods are no-ops on Flutter Web (kIsWeb) because
/// flutter_local_notifications does not support web.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<int, Timer> _webTimers = {};

  void _playReminderSound() async {
    if (kIsWeb) {
      try {
        await _audioPlayer.play(AssetSource('audio/medicine_alarm.mp3'));
      } catch (e) {
        debugPrint('NotificationService: Audio error - $e');
      }
    }
  }

  void _scheduleWebAudio(int id, DateTime scheduledDateTime, {Duration? repeatInterval}) {
    if (!kIsWeb) return;
    _webTimers[id]?.cancel();
    final delay = scheduledDateTime.difference(DateTime.now());
    if (delay.isNegative) return;

    if (repeatInterval == null) {
      _webTimers[id] = Timer(delay, () {
        _playReminderSound();
        _webTimers.remove(id);
      });
    } else {
      _webTimers[id] = Timer(delay, () {
        _playReminderSound();
        _webTimers[id] = Timer.periodic(repeatInterval, (_) => _playReminderSound());
      });
    }
  }

  /// True when running natively on a supported mobile/desktop platform.
  bool get isSupported =>
      !kIsWeb &&
      (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isWindows ||
          Platform.isLinux ||
          Platform.isMacOS);

  // ─── Notification details builder ───────────────────────────────────────────

  /// Build notification details at call time (not const) because
  /// vibrationPattern uses Int64List which cannot be const.
  NotificationDetails _buildNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'medicine_alarm_channel_v2',
        'Medicine Alarms',
        channelDescription:
            'High-priority alarm channel for medicine reminders',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('medicine_alarm'),
        enableVibration: true,
        vibrationPattern:
            Int64List.fromList([0, 500, 250, 500, 250, 500]),
        enableLights: true,
        ledColor: const Color.fromARGB(255, 0, 128, 255),
        ledOnMs: 1000,
        ledOffMs: 500,
        channelShowBadge: true,
        autoCancel: false,
        ongoing: false,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'medicine_alarm.mp3',
      ),
    );
  }

  // ─── Initialization ─────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized || !isSupported) {
      if (kIsWeb) {
        debugPrint('NotificationService: Web platform – skipping init.');
      }
      return;
    }

    try {
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Notification tapped: the app is brought to foreground automatically.
          debugPrint(
              'NotificationService: tapped – payload: ${response.payload}');
        },
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
      );

      _initialized = true;
      debugPrint('NotificationService: initialized successfully.');
    } catch (e) {
      debugPrint('NotificationService: init failed – $e');
    }
  }

  /// Top-level callback required for background notification handling.
  @pragma('vm:entry-point')
  static void _onBackgroundNotification(NotificationResponse response) {
    debugPrint(
        'NotificationService: background tap – payload: ${response.payload}');
  }

  // ─── Permission request ──────────────────────────────────────────────────────

  Future<void> requestPermissions() async {
    if (!isSupported) return;
    try {
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        await androidImpl?.requestExactAlarmsPermission();
      } else if (Platform.isIOS) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint('NotificationService: requestPermissions error – $e');
    }
  }

  // ─── One-time notification ───────────────────────────────────────────────────

  /// Schedules a single notification at [scheduledDateTime].
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    _scheduleWebAudio(id, scheduledDateTime);

    if (!_initialized || !isSupported) return;

    if (scheduledDateTime.isBefore(DateTime.now())) {
      debugPrint(
          'NotificationService: scheduled time is in the past – skipped.');
      return;
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDateTime, tz.local),
        notificationDetails: _buildNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint(
          'NotificationService: scheduled one-time #$id at $scheduledDateTime');
    } catch (e) {
      debugPrint('NotificationService: scheduleNotification error – $e');
    }
  }

  // ─── Repeating notification ──────────────────────────────────────────────────

  /// Schedules a repeating notification based on [repeatType]:
  ///   'Daily'    → repeats every day at the same time
  ///   'Weekly'   → repeats every week on the same day + time
  ///   'Monthly'  → repeats every month on the same day-of-month + time
  ///   'One Time' → falls back to [scheduleNotification]
  Future<void> scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    required String repeatType,
    String? payload,
  }) async {
    Duration? interval;
    if (repeatType == 'Daily') interval = const Duration(days: 1);
    else if (repeatType == 'Weekly') interval = const Duration(days: 7);
    else if (repeatType == 'Monthly') interval = const Duration(days: 30);
    _scheduleWebAudio(id, scheduledDateTime, repeatInterval: interval);

    if (!_initialized || !isSupported) return;

    if (repeatType == 'One Time') {
      await scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDateTime: scheduledDateTime,
        payload: payload,
      );
      return;
    }

    try {
      final tzDate = tz.TZDateTime.from(scheduledDateTime, tz.local);

      DateTimeComponents matchComponents;
      switch (repeatType) {
        case 'Daily':
          matchComponents = DateTimeComponents.time;
          break;
        case 'Weekly':
          matchComponents = DateTimeComponents.dayOfWeekAndTime;
          break;
        case 'Monthly':
          matchComponents = DateTimeComponents.dayOfMonthAndTime;
          break;
        default:
          matchComponents = DateTimeComponents.time;
      }

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: _buildNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
        payload: payload,
      );
      debugPrint(
          'NotificationService: scheduled $repeatType #$id starting $scheduledDateTime');
    } catch (e) {
      debugPrint(
          'NotificationService: scheduleRepeatingNotification error – $e');
    }
  }

  // ─── Cancellation ────────────────────────────────────────────────────────────

  Future<void> cancelNotification(int id) async {
    _webTimers[id]?.cancel();
    _webTimers.remove(id);

    if (!_initialized || !isSupported) return;
    try {
      await _notificationsPlugin.cancel(id: id);
      debugPrint('NotificationService: cancelled #$id');
    } catch (e) {
      debugPrint('NotificationService: cancelNotification error – $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    for (var timer in _webTimers.values) {
      timer.cancel();
    }
    _webTimers.clear();

    if (!_initialized || !isSupported) return;
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('NotificationService: cancelled all notifications');
    } catch (e) {
      debugPrint('NotificationService: cancelAllNotifications error – $e');
    }
  }
}
