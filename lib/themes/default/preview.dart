import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:kvart/themes/default/default.dart';
import 'package:kvart/timer/timer_controller.dart';

@Preview(group: 'Default Theme', name: 'New timer')
Widget defaultThemePreview() => MediaQuery(
  data: const MediaQueryData(size: Size(390, 390)),
  child: SizedBox(
    width: 390,
    height: 390,
    child: DefaultTimerView(
      secondsTotal: 900,
      secondsElapsed: 0,
      controller: TimerController(secondsTotal: 900),
      ready: true,
      onSecondsChanged: null,
    ),
  ),
);

@Preview(group: 'Default Theme', name: 'Elapsed timer')
Widget defaultThemeElapsedPreview() => MediaQuery(
  data: const MediaQueryData(size: Size(390, 390)),
  child: SizedBox(
    width: 390,
    height: 390,
    child: DefaultTimerView(
      secondsTotal: 900,
      secondsElapsed: 450,
      controller: TimerController(secondsTotal: 900),
      ready: true,
      onSecondsChanged: null,
    ),
  ),
);
