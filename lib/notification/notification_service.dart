import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kvart/background/background_service.dart';
import 'package:kvart/settings/settings_service.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';

class NotificationService {
  final AudioPlayer _audioPlayer = AudioPlayer(
    handleAudioSessionActivation: false,
  );
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final SettingsService _settingsService = SettingsService();

  Future<void> initialize() async {
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

    // Request iOS permissions
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> timeIsUp() async {
    // Don't show a separate foreground notification - let the scheduled one fire
    // This prevents duplicate notifications
    // The scheduled notification will fire automatically at completion time

    // Play audio if enabled
    final soundEnabled = await _settingsService.isSoundEnabled();
    if (soundEnabled) {
      loadAudio()
          .then((_) {
            _audioPlayer.play().catchError((error) {
              // Handle audio playback error
              log('Error playing audio: $error');
            });
          })
          .catchError((error) {
            // Handle audio loading error
            log('Error loading audio: $error');
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

  /// Schedule a background notification for when timer completes
  /// This ensures notification is sent even if app is backgrounded/killed
  Future<void> scheduleTimerCompletion(int secondsUntilComplete) async {
    await BackgroundService.scheduleTimerCompletion(secondsUntilComplete);
  }

  /// Cancel any scheduled background timer notifications
  Future<void> cancelScheduledNotification() async {
    // Use the shared notification plugin to ensure we cancel on the same instance
    // that created the scheduled notification
    await BackgroundService.notificationsPlugin.cancel(
      999,
    ); // ID from BackgroundService
    await BackgroundService.cancelTimerCompletion();
  }
}
