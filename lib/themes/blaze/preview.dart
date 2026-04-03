import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:kvart/themes/blaze/blaze.dart';
import 'package:kvart/timer/timer_controller.dart';

@Preview(group: 'Blaze Theme', name: 'New timer')
Widget blazeThemePreview() => MediaQuery(
  data: const MediaQueryData(size: Size(390, 390)),
  child: SizedBox(
    width: 390,
    height: 390,
    child: BlazeTimerView(
      secondsTotal: 900,
      secondsElapsed: 0,
      controller: TimerController(secondsTotal: 900),
      ready: true,
      onSecondsChanged: null,
    ),
  ),
);

@Preview(group: 'Blaze Theme', name: 'Elapsed timer')
Widget blazeThemeElapsedPreview() => MediaQuery(
  data: const MediaQueryData(size: Size(390, 390)),
  child: SizedBox(
    width: 390,
    height: 390,
    child: BlazeTimerView(
      secondsTotal: 900,
      secondsElapsed: 450,
      controller: TimerController(secondsTotal: 900),
      ready: true,
      onSecondsChanged: null,
    ),
  ),
);
