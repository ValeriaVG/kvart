import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings and preferences
class SettingsService {
  // Singleton pattern
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Preference keys
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _selectedSoundKey = 'selected_sound';

  // Available alarm sounds
  static const List<AlarmSound> availableSounds = [
    AlarmSound(
      name: 'Game Unlock',
      path: 'assets/audio/game-ui-level-unlock-om-fx-1-1-00-05.mp3',
      description: 'Gentle chime sound by OM FX / Uppbeat.io',
    ),
    AlarmSound(
      name: 'Kalimba Ding',
      path: 'assets/audio/ding-kalimba-strike-tomas-herudek-1-00-05.mp3',
      description: 'Soft kalimba ding sound by Tomas Herudek / Uppbeat.io',
    ),
    AlarmSound(
      name: 'Double Bell',
      path:
          'assets/audio/message-notification-double-bell-the-foundation-1-00-02.mp3',
      description: 'Classic double bell sound by The Foundation / Uppbeat.io',
    ),
  ];

  // Default values
  static const bool _defaultSoundEnabled = true;
  static const bool _defaultVibrationEnabled = true;
  static const String _defaultSound =
      'assets/audio/game-ui-level-unlock-om-fx-1-1-00-05.mp3';

  /// Check if sound is enabled
  Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? _defaultSoundEnabled;
  }

  /// Set sound enabled/disabled
  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  /// Check if vibration is enabled
  Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? _defaultVibrationEnabled;
  }

  /// Set vibration enabled/disabled
  Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }

  /// Get selected alarm sound path
  Future<String> getSelectedSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedSoundKey) ?? _defaultSound;
  }

  /// Set selected alarm sound path
  Future<void> setSelectedSound(String soundPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedSoundKey, soundPath);
  }

  /// Get the AlarmSound object for the currently selected sound
  Future<AlarmSound> getSelectedAlarmSound() async {
    final soundPath = await getSelectedSound();
    return availableSounds.firstWhere(
      (sound) => sound.path == soundPath,
      orElse: () => availableSounds.first,
    );
  }
}

/// Model class for alarm sounds
class AlarmSound {
  final String name;
  final String path;
  final String description;

  const AlarmSound({
    required this.name,
    required this.path,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmSound &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;
}
