import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kvart/settings/settings_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final AudioPlayer _previewPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  AlarmSound _selectedSound = SettingsService.availableSounds.first;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final soundEnabled = await _settingsService.isSoundEnabled();
    final vibrationEnabled = await _settingsService.isVibrationEnabled();
    final selectedSound = await _settingsService.getSelectedAlarmSound();

    setState(() {
      _soundEnabled = soundEnabled;
      _vibrationEnabled = vibrationEnabled;
      _selectedSound = selectedSound;
      _isLoadingSettings = false;
    });
  }

  Future<void> _toggleSound(bool value) async {
    await _settingsService.setSoundEnabled(value);
    setState(() {
      _soundEnabled = value;
    });
  }

  Future<void> _toggleVibration(bool value) async {
    await _settingsService.setVibrationEnabled(value);
    setState(() {
      _vibrationEnabled = value;
    });
  }

  Future<void> _selectSound(AlarmSound sound) async {
    await _settingsService.setSelectedSound(sound.path);
    setState(() {
      _selectedSound = sound;
    });
  }

  Future<void> _playSound(AlarmSound sound) async {
    if (!_soundEnabled) return;

    try {
      await _previewPlayer.stop();
      await _previewPlayer.setAsset(sound.path);
      await _previewPlayer.play();
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020C1D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingSettings
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle('Alarm Sound'),
                const SizedBox(height: 12),
                _buildSoundEnabledTile(),
                const SizedBox(height: 8),
                _buildSoundSelectionTiles(),
                const SizedBox(height: 32),
                _buildSectionTitle('Vibration'),
                const SizedBox(height: 12),
                _buildVibrationTile(),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSoundEnabledTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: const Text(
          'Enable Sound',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _soundEnabled
              ? 'Sound will play when timer completes'
              : 'Sound is disabled',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
        value: _soundEnabled,
        onChanged: _toggleSound,
        activeThumbColor: const Color(0xFF4CAF50),
        activeTrackColor: const Color(0xFF4CAF50).withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildSoundSelectionTiles() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: SettingsService.availableSounds.asMap().entries.map((entry) {
          final index = entry.key;
          final sound = entry.value;
          final isSelected = _selectedSound == sound;
          final isFirst = index == 0;

          return Column(
            children: [
              if (!isFirst)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                  indent: 16,
                  endIndent: 16,
                ),
              ListTile(
                title: Text(
                  sound.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                subtitle: Text(
                  sound.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                leading: Radio<AlarmSound>(
                  value: sound,
                  groupValue: _selectedSound,
                  onChanged: _soundEnabled
                      ? (AlarmSound? value) {
                          if (value != null) {
                            _selectSound(value);
                          }
                        }
                      : null,
                  fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF4CAF50);
                    }
                    return Colors.white.withValues(alpha: 0.5);
                  }),
                ),
                trailing: IconButton(
                  icon: Icon(
                    LucideIcons.play,
                    color: _soundEnabled
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                  onPressed: _soundEnabled ? () => _playSound(sound) : null,
                  tooltip: 'Play preview',
                ),
                contentPadding: const EdgeInsets.only(left: 8, right: 8),
                enabled: _soundEnabled,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVibrationTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: const Text(
          'Enable Vibration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _vibrationEnabled
              ? 'Device will vibrate when timer completes'
              : 'Device will not vibrate when timer completes',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
        value: _vibrationEnabled,
        onChanged: _toggleVibration,
        activeThumbColor: const Color(0xFF4CAF50),
        activeTrackColor: const Color(0xFF4CAF50).withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
