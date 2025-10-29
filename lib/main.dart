import 'package:flutter/material.dart';
import 'timer/timer_screen.dart';

void main() {
  runApp(const KvartApp());
}

class KvartApp extends StatelessWidget {
  const KvartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Kvart Timer', home: const TimerScreen());
  }
}
