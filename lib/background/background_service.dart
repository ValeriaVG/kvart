import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

/// Background service that ensures timer notifications are sent
/// even when the app is in the background or killed
class BackgroundService {
  static const String _timerTaskName = 'timer_completion_task';
  static const String _timerEndTimeKey = 'timer_end_time';
  static const String _timerSecondsKey = 'timer_seconds_total';
  static const int _scheduledNotificationId = 999;

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Get the shared notification plugin instance
  /// This ensures all parts of the app use the same instance for cancellations
  static FlutterLocalNotificationsPlugin get notificationsPlugin =>
      _notificationsPlugin;

  /// Initialize the background service
  static Future<void> initialize() async {
    // Initialize timezone database for scheduled notifications
    tz.initializeTimeZones();

    // Initialize notifications plugin
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Only initialize WorkManager for Android (iOS uses scheduled notifications)
    if (!Platform.isIOS) {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    }
  }

  /// Schedule a background task to fire when the timer completes
  /// [secondsUntilComplete] - how many seconds until timer should complete
  static Future<void> scheduleTimerCompletion(int secondsUntilComplete) async {
    final endTime = DateTime.now().add(Duration(seconds: secondsUntilComplete));

    // Save timer end time to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timerEndTimeKey, endTime.millisecondsSinceEpoch);
    await prefs.setInt(_timerSecondsKey, secondsUntilComplete);

    // iOS: Use scheduled local notifications (more reliable than BGTaskScheduler)
    if (Platform.isIOS) {
      await _scheduleNotificationIOS(secondsUntilComplete);
    } else {
      // Android: Use WorkManager for background task
      await _scheduleWorkManagerTask(secondsUntilComplete);
    }
  }

  /// Schedule notification using flutter_local_notifications (iOS)
  static Future<void> _scheduleNotificationIOS(int secondsUntilComplete) async {
    // Cancel any existing scheduled notification
    await _notificationsPlugin.cancel(_scheduledNotificationId);

    // Schedule notification to fire at exact completion time
    // This is the ONLY notification - no separate foreground one
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true, // iOS default notification sound
      sound: 'default',
    );

    const notificationDetails = NotificationDetails(iOS: iosDetails);

    await _notificationsPlugin.zonedSchedule(
      _scheduledNotificationId,
      'Timer Complete',
      'Your timer has finished!',
      tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsUntilComplete)),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule WorkManager task (Android)
  static Future<void> _scheduleWorkManagerTask(int secondsUntilComplete) async {
    await Workmanager().cancelByUniqueName(_timerTaskName);

    await Workmanager().registerOneOffTask(
      _timerTaskName,
      _timerTaskName,
      initialDelay: Duration(seconds: secondsUntilComplete),
      constraints: Constraints(networkType: NetworkType.not_required),
    );
  }

  /// Cancel any scheduled timer completion tasks
  static Future<void> cancelTimerCompletion() async {
    // Cancel scheduled notification (iOS)
    await _notificationsPlugin.cancel(_scheduledNotificationId);

    // Cancel WorkManager task (Android)
    if (!Platform.isIOS) {
      await Workmanager().cancelByUniqueName(_timerTaskName);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timerEndTimeKey);
    await prefs.remove(_timerSecondsKey);
  }

  /// Check if timer should have completed by now
  static Future<bool> shouldTimerHaveCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final endTimeMillis = prefs.getInt(_timerEndTimeKey);

    if (endTimeMillis == null) return false;

    final endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
    return DateTime.now().isAfter(endTime);
  }
}

/// Background callback dispatcher
/// This runs in a separate isolate and must be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Check if this is our timer completion task
      if (task == BackgroundService._timerTaskName) {
        await _handleTimerCompletion();
      }
      return Future.value(true);
    } catch (e) {
      // Log error but don't crash
      return Future.value(false);
    }
  });
}

/// Handle timer completion in background
Future<void> _handleTimerCompletion() async {
  final prefs = await SharedPreferences.getInstance();
  final endTimeMillis = prefs.getInt(BackgroundService._timerEndTimeKey);

  if (endTimeMillis == null) return;

  final endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
  final now = DateTime.now();

  // Only send notification if we're past the end time
  if (now.isAfter(endTime)) {
    // Initialize and show notification
    final notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await notificationsPlugin.initialize(initSettings);

    // Show the notification
    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      channelDescription: 'Notifications for timer completion',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await notificationsPlugin.show(
      0,
      'Timer Complete',
      'Your timer has finished!',
      notificationDetails,
    );

    // Clean up the saved timer state
    await prefs.remove(BackgroundService._timerEndTimeKey);
    await prefs.remove(BackgroundService._timerSecondsKey);
  }
}
