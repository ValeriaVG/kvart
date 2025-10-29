import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:kvart/timer.dart';

void main() {
  runApp(const KvartApp());
}

class KvartApp extends StatelessWidget {
  const KvartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Kvart Timer', home: const Timer());
  }
}
