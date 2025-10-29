import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kvart/settings/settings_service.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';

class NotificationService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final SettingsService _settingsService = SettingsService();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // Request iOS permissions
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> timeIsUp() async {
    // Show local notification
    await _showNotification();

    // Play audio if enabled
    final soundEnabled = await _settingsService.isSoundEnabled();
    if (soundEnabled) {
      loadAudio().then((_) {
        _audioPlayer.play();
      });
    }

    // Vibrate if enabled
    final vibrationEnabled = await _settingsService.isVibrationEnabled();
    if (vibrationEnabled && await Vibration.hasVibrator()) {
      Vibration.vibrate(
        duration: 5000,
        preset: VibrationPreset.countdownTimerAlert,
      );
    }
  }

  Future<void> _showNotification() async {
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

    await _notificationsPlugin.show(
      0,
      'Timer Complete',
      'Your timer has finished!',
      notificationDetails,
    );
  }

  Future<void> loadAudio() async {
    final soundPath = await _settingsService.getSelectedSound();
    await _audioPlayer.setAsset(soundPath);
  }

  /// Play a preview of the alarm sound (for settings screen)
  Future<void> playPreview() async {
    final soundEnabled = await _settingsService.isSoundEnabled();
    if (soundEnabled) {
      await loadAudio();
      await _audioPlayer.play();
    }
  }

  /// Stop playing audio
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }
}
