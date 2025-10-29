import 'package:flutter/material.dart';
import 'package:kvart/themes/theme_service.dart';
import 'timer/timer_screen.dart';

import 'package:flutter/services.dart';

void main() {
  // Set status bar color to white
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  WidgetsFlutterBinding.ensureInitialized();
  ThemeService().getSelectedTimerTheme().then((theme) async {
    runApp(const KvartApp());
  });
}

class KvartApp extends StatelessWidget {
  const KvartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kvart Timer',
      home: const TimerScreen(),
      themeMode: ThemeMode.dark, // or ThemeMode.dark, ThemeMode.system
      theme: ThemeData.dark(),
      darkTheme: ThemeData.dark(),
    );
  }
}
