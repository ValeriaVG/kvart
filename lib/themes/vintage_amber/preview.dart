import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:kvart/themes/vintage_amber/vintage_amber.dart';
import 'package:kvart/timer/timer_controller.dart';

@Preview(group: 'Vintage Amber Theme', name: 'New timer')
Widget vintageAmberThemePreview() => MediaQuery(
  data: const MediaQueryData(size: Size(390, 390)),
  child: SizedBox(
    width: 390,
    height: 390,
    child: VintageAmberTimerView(
      secondsTotal: 900,
      secondsElapsed: 0,
      controller: TimerController(secondsTotal: 900),
      ready: true,
      onSecondsChanged: null,
    ),
  ),
);

@Preview(group: 'Vintage Amber Theme', name: 'Elapsed timer')
Widget vintageAmberThemeElapsedPreview() => MediaQuery(
  data: const MediaQueryData(size: Size(390, 390)),
  child: SizedBox(
    width: 390,
    height: 390,
    child: VintageAmberTimerView(
      secondsTotal: 900,
      secondsElapsed: 450,
      controller: TimerController(secondsTotal: 900),
      ready: true,
      onSecondsChanged: null,
    ),
  ),
);
