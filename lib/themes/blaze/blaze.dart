import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart'
    show CupertinoTimerPicker, CupertinoTimerPickerMode;
import 'package:flutter/material.dart';
import 'package:kvart/timer/timer_controller.dart';
import 'package:kvart/timer/timer_view.dart';
import 'package:kvart/widgets/bell_animation.dart';
import 'package:kvart/widgets/seven_segment_display.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Blaze theme — dark background with a fiery gradient accent
class BlazeTimerView extends StatefulWidget implements TimerView {
  @override
  final int secondsTotal;
  @override
  final int secondsElapsed;
  @override
  final TimerController controller;
  @override
  final void Function(int)? onSecondsChanged;
  @override
  final bool ready;

  const BlazeTimerView({
    super.key,
    required this.secondsTotal,
    required this.secondsElapsed,
    required this.controller,
    required this.ready,
    this.onSecondsChanged,
  });

  @override
  State<BlazeTimerView> createState() => _BlazeTimerViewState();
}

class _BlazeTimerViewState extends State<BlazeTimerView>
    with TickerProviderStateMixin {
  bool _showBellAnimation = false;
  late final AnimationController _pulseController;
  late final AnimationController _emberController;
  final List<_Ember> _embers = [];
  final _random = Random();
  StreamSubscription<TimerState>? _stateSubscription;

  @override
  void initState() {
    super.initState();

    // Pulsing glow when paused
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Ember particle driver
    _emberController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateEmbers);

    // Sync with current state (e.g. when switching themes mid-run)
    if (widget.controller.state == TimerState.running) {
      _emberController.repeat();
    } else if (widget.controller.state == TimerState.paused) {
      _pulseController.repeat(reverse: true);
    }

    _stateSubscription = widget.controller.stateStream.listen((state) {
      if (!mounted) return;
      if (state == TimerState.completed) {
        _pulseController.stop();
        _emberController.stop();
        setState(() {
          _showBellAnimation = true;
        });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showBellAnimation = false;
            });
          }
        });
      } else if (state == TimerState.running) {
        _pulseController.stop();
        _emberController.repeat();
      } else if (state == TimerState.paused) {
        _emberController.stop();
        _pulseController.repeat(reverse: true);
      } else if (state == TimerState.idle) {
        _pulseController.stop();
        _emberController.stop();
        _embers.clear();
        setState(() {
          _showBellAnimation = false;
        });
      }
    });
  }

  void _updateEmbers() {
    setState(() {
      // Spawn new embers along the arc
      if (_embers.length < 14 && _random.nextDouble() < 0.3) {
        _embers.add(_Ember.spawn(_random));
      }

      // Update existing embers
      for (final ember in _embers) {
        ember.life -= 0.012;
        ember.y -= ember.speed;
        ember.x += ember.drift;
        ember.opacity = (ember.life).clamp(0.0, 1.0) * 0.8;
      }

      _embers.removeWhere((e) => e.life <= 0);
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _pulseController.dispose();
    _emberController.dispose();
    super.dispose();
  }

  IconData get _iconForState {
    switch (widget.controller.state) {
      case TimerState.running:
        return LucideIcons.pause;
      case TimerState.idle:
      case TimerState.paused:
        return LucideIcons.play;
      case TimerState.completed:
        return LucideIcons.repeat;
    }
  }

  void _showTimePicker() {
    if (widget.controller.state == TimerState.running) return;

    final remainingSeconds = max(
      0,
      widget.secondsTotal - widget.secondsElapsed,
    );
    final initialMinutes = remainingSeconds ~/ 60;
    final initialSeconds = remainingSeconds % 60;

    int selectedSeconds = remainingSeconds;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          backgroundColor: const Color(0xFF0C0B0B),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0x99FFFFFF),
                            fontSize: 18,
                          ),
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFFD529),
                            Color(0xFFFF784C),
                            Color(0xFFF85262),
                            Color(0xFFE51A55),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'Set Timer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.onSecondsChanged?.call(selectedSeconds);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Color(0xFFFF784C),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0x33FF784C),
                        Color(0x33F85262),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      height: 400,
                      child: CupertinoTimerPicker(
                        mode: CupertinoTimerPickerMode.ms,
                        initialTimerDuration: Duration(
                          minutes: initialMinutes,
                          seconds: initialSeconds,
                        ),
                        onTimerDurationChanged: (Duration duration) {
                          selectedSeconds = duration.inSeconds;
                        },
                        backgroundColor: const Color(0xFF0C0B0B),
                        itemExtent: 64,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = max(
      0,
      widget.secondsTotal - widget.secondsElapsed,
    );
    final progress = remainingSeconds / widget.secondsTotal;
    final minSide = min(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final digitWidth = (minSide - 32 * 2) / 5 - 24;
    final digitHeight = digitWidth * 80 / 48;

    return Stack(
      children: [
        // Warm radial glow behind the timer
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.6,
              colors: [
                Color(0x18E51A55), // Subtle pink/red core
                Color(0x08FF784C), // Faint orange ring
                Colors.transparent,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Progress arc
        CustomPaint(
          painter: _BlazeArcPainter(
            progress,
            embers: _embers,
            pulseValue: _pulseController.isAnimating
                ? _pulseController.value
                : null,
          ),
          child: Center(
            child: GestureDetector(
              onTap: _showTimePicker,
              child: SevenSegmentDisplay(
                disabled: widget.ready == false,
                minutes: remainingSeconds ~/ 60,
                seconds: remainingSeconds % 60,
                digitWidth: digitWidth,
                digitHeight: digitHeight,
                onColor: const Color(0xFFFFE4B5),
                offColor: const Color(0x12FFE4B5),
              ),
            ),
          ),
        ),
        // Bell animation
        if (_showBellAnimation)
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - minSide / 3,
            left: MediaQuery.of(context).size.width / 2 - 32,
            child: const BellAnimation(size: 64, color: Color(0xFFFF784C)),
          ),
        // Control button
        Positioned(
          top: MediaQuery.of(context).size.height / 2 + minSide / 6 - 16,
          right: (MediaQuery.of(context).size.width - minSide) / 2 + 24,
          child: GestureDetector(
            onTap: () {
              if (widget.controller.state == TimerState.running) {
                widget.controller.pauseTimer();
              } else {
                widget.controller.startTimer();
              }
            },
            child: SizedBox(
              width: minSide / 3,
              height: minSide / 3,
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFD529),
                      Color(0xFFFF784C),
                      Color(0xFFF85262),
                      Color(0xFFE51A55),
                    ],
                  ).createShader(bounds),
                  child: Icon(
                    _iconForState,
                    color: Colors.white,
                    size: minSide / 4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlazeArcPainter extends CustomPainter {
  final double progress;
  final List<_Ember> _embers;
  final double? _pulseValue;

  _BlazeArcPainter(
    this.progress, {
    List<_Ember> embers = const [],
    double? pulseValue,
  }) : _embers = embers,
       _pulseValue = pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    // Arc goes from bottom (6 o'clock) clockwise 270° to right (3 o'clock)
    const startAngle = pi / 2; // 6 o'clock
    const sweepAngle = pi * 1.5; // 270° clockwise
    const strokeWidth = 32.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final progressSweepAngle = sweepAngle * progress;

    // Background track — white 5%
    final backgroundPaint = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);

    if (progressSweepAngle <= 0) return;

    // Rotate canvas so the arc starts at angle 0, keeping the gradient
    // well within 0–π*1.5 and away from the 0/2π wrap boundary.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(startAngle);
    canvas.translate(-center.dx, -center.dy);

    // Gradient covers full 360° to prevent wrap-around color bleeding.
    // Arc occupies 0–270° (0.0–0.75 of full circle).
    // Yellow extends past 270° so the round cap stays yellow.
    final blazeGradient = SweepGradient(
      center: Alignment.center,
      colors: const [
        Color(0xFFE51A55), // Hot pink (start)
        Color(0xFFF85262), // Coral
        Color(0xFFFF784C), // Orange
        Color(0xFFFFD529), // Yellow (end of arc)
        Color(0xFFFFD529), // Yellow (hold for cap)
        Color(0xFFE51A55), // Hot pink (fill gap)
        Color(0xFFE51A55), // Hot pink (back to start)
      ],
      stops: const [0.0, 0.22, 0.45, 0.73, 0.82, 0.83, 1.0],
    );

    // Main gradient arc
    final gradientPaint = Paint()
      ..shader = blazeGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, progressSweepAngle, false, gradientPaint);

    // Outer glow — pulses when paused
    final glowOpacity = _pulseValue != null ? 0.3 + 0.4 * _pulseValue : 0.5;
    final glowPaint = Paint()
      ..shader = blazeGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 16
      ..strokeCap = StrokeCap.butt
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final glowRect = Rect.fromCircle(
      center: center,
      radius: radius + strokeWidth + 40,
    );
    canvas.saveLayer(
      glowRect,
      Paint()..color = Color.fromRGBO(255, 255, 255, glowOpacity),
    );
    canvas.drawArc(rect, 0, progressSweepAngle, false, glowPaint);
    canvas.restore();

    canvas.restore();

    // Ember particles
    for (final ember in _embers) {
      // Position ember along the progress arc
      final angle = startAngle + progressSweepAngle * ember.arcPosition;
      final baseX = center.dx + radius * cos(angle);
      final baseY = center.dy + radius * sin(angle);

      final emberPaint = Paint()
        ..color = ember.color.withValues(alpha: ember.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(
        Offset(baseX + ember.x, baseY + ember.y),
        ember.size,
        emberPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BlazeArcPainter oldDelegate) => true;
}

class _Ember {
  double x;
  double y;
  double speed;
  double drift;
  double life;
  double opacity;
  double size;
  double arcPosition; // 0–1, where along the arc this ember spawns
  Color color;

  _Ember({
    required this.x,
    required this.y,
    required this.speed,
    required this.drift,
    required this.life,
    required this.opacity,
    required this.size,
    required this.arcPosition,
    required this.color,
  });

  static _Ember spawn(Random rng) {
    const colors = [
      Color(0xFFFFD529),
      Color(0xFFFF784C),
      Color(0xFFF85262),
      Color(0xFFFFAA33),
    ];
    return _Ember(
      x: 0,
      y: 0,
      speed: 0.4 + rng.nextDouble() * 0.8,
      drift: (rng.nextDouble() - 0.5) * 0.6,
      life: 0.7 + rng.nextDouble() * 0.3,
      opacity: 0.8,
      size: 1.5 + rng.nextDouble() * 2.5,
      arcPosition: rng.nextDouble(),
      color: colors[rng.nextInt(colors.length)],
    );
  }
}
