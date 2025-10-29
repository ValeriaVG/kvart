import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kvart/notification/notification_service.dart';
import 'package:kvart/settings/settings_screen.dart';
import 'package:kvart/themes/default.dart';
import 'package:kvart/themes/vintage_amber.dart';
import 'package:kvart/timer/timer_controller.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  bool _areSettingsLoaded = false;
  int _secondsTotal = 15 * 60; // Default to 15 minutes
  late final TimerController _timerController;
  final NotificationService _notificationService = NotificationService();

  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedTimer();
    _notificationService.initialize();
    _timerController = TimerController(
      secondsTotal: _secondsTotal,
      onComplete: () {
        _notificationService.timeIsUp();
      },
    );
    // Set status bar color to white
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  Future<void> _loadSavedTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSeconds = prefs.getInt('timer_seconds');

    if (savedSeconds != null && savedSeconds > 0) {
      setState(() {
        _secondsTotal = savedSeconds;
        _timerController.resetTimer(_secondsTotal);

        _areSettingsLoaded = true;
      });
    } else {
      setState(() {
        _areSettingsLoaded = true;
      });
    }

    _timerController.elapsedSeconds.listen((seconds) {
      setState(() {
        _secondsElapsed = seconds;
      });
    });
  }

  Future<void> _saveTimer(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timer_seconds', seconds);
  }

  void _updateTotalSeconds(int newSeconds) {
    if (_timerController.state == TimerState.running) return;

    setState(() {
      _secondsTotal = newSeconds;
      _secondsElapsed = 0;
    });
    _timerController.resetTimer(_secondsTotal);
    _saveTimer(newSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020C1D),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              LucideIcons.settings,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: VintageAmberTimerView(
          secondsTotal: _secondsTotal,
          secondsElapsed: _secondsElapsed,
          controller: _timerController,
          onSecondsChanged: _updateTotalSeconds,
          ready: _areSettingsLoaded,
        ),
      ),
    );
  }
}
