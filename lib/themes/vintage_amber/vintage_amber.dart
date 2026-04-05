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

/// Vintage amber theme with post-apocalyptic display aesthetics
/// Retro-futuristic interface inspired by classic wasteland survival gear
class VintageAmberTimerView extends StatefulWidget implements TimerView {
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

  const VintageAmberTimerView({
    super.key,
    required this.secondsTotal,
    required this.secondsElapsed,
    required this.controller,
    required this.ready,
    this.onSecondsChanged,
  });

  @override
  State<VintageAmberTimerView> createState() => _VintageAmberTimerViewState();
}

class _VintageAmberTimerViewState extends State<VintageAmberTimerView>
    with TickerProviderStateMixin {
  bool _showBellAnimation = false;
  late final AnimationController _pulseController;
  StreamSubscription<TimerState>? _stateSubscription;

  @override
  void initState() {
    super.initState();

    // Pulsing glow when paused
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Sync with current state (e.g. when switching themes mid-run)
    if (widget.controller.state == TimerState.paused) {
      _pulseController.repeat(reverse: true);
    }

    _stateSubscription = widget.controller.stateStream.listen((state) {
      if (!mounted) return;
      if (state == TimerState.completed) {
        _pulseController.stop();
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
      } else if (state == TimerState.paused) {
        _pulseController.repeat(reverse: true);
      } else if (state == TimerState.idle) {
        _pulseController.stop();
        setState(() {
          _showBellAnimation = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _pulseController.dispose();
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

    // Ensure remaining seconds is never negative
    final remainingSeconds = max(0, widget.secondsTotal - widget.secondsElapsed);
    final initialMinutes = remainingSeconds ~/ 60;
    final initialSeconds = remainingSeconds % 60;

    int selectedSeconds = remainingSeconds;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          backgroundColor: const Color(0xFF1A1108), // Dark rusty brown
          child: SafeArea(
            child: Column(
              children: [
                // Header with rusted metallic feel
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            color: Color(0xFF8B6F47), // Dusty tan
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Text(
                        'SET TIMER',
                        style: TextStyle(
                          color: Color(0xFFFFB347), // Bright amber
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(color: Color(0x80FF8C00), blurRadius: 8),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.onSecondsChanged?.call(selectedSeconds);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'DONE',
                          style: TextStyle(
                            color: Color(0xFFFF9933), // Warning amber
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFF8B6F47),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Time Picker with terminal aesthetics
                Expanded(
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.ms,
                    initialTimerDuration: Duration(
                      minutes: initialMinutes,
                      seconds: initialSeconds,
                    ),
                    onTimerDurationChanged: (Duration duration) {
                      selectedSeconds = duration.inSeconds;
                    },
                    backgroundColor: const Color(0xFF1A1108),
                    itemExtent:
                        48, // Reduced from 64 to better center the selection indicator
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
    // Ensure remaining seconds is never negative
    final remainingSeconds = max(0, widget.secondsTotal - widget.secondsElapsed);
    final progress = remainingSeconds / widget.secondsTotal;
    final minSide = min(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final digitWidth = (minSide - 32 * 2) / 5 - 24;
    final digitHeight = digitWidth * 80 / 48;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showTimePicker,
      child: Stack(
        children: [
        // Noise and rustic lines background
        IgnorePointer(
          child: CustomPaint(
            painter: _RusticNoisePainter(),
            size: Size.infinite,
            child: Container(),
          ),
        ),
        // Radial gradient overlay
        IgnorePointer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  Color(0x08FF8C00),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Main timer with progress arc
        IgnorePointer(
          child: CustomPaint(
            painter: _VintageAmberArcPainter(
              progress,
              pulseValue: _pulseController.isAnimating
                  ? _pulseController.value
                  : null,
            ),
            child: Center(
              child: SevenSegmentDisplay(
                disabled: widget.ready == false,
                minutes: remainingSeconds ~/ 60,
                seconds: remainingSeconds % 60,
                digitWidth: digitWidth,
                digitHeight: digitHeight,
                onColor: const Color(0xFFFFB347),
                offColor: const Color(0x18FF8C00),
                segmentThickness: 10,
              ),
            ),
          ),
        ),
        // CRT scan lines overlay
        IgnorePointer(
          child: CustomPaint(
            painter: _CrtScanLinePainter(),
            size: Size.infinite,
            child: Container(),
          ),
        ),
        // Bell animation
        if (_showBellAnimation)
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - minSide / 3,
            left: MediaQuery.of(context).size.width / 2 - 32,
            child: const IgnorePointer(
              child: BellAnimation(
                size: 64,
                color: Color(0xFFFFB347),
              ),
            ),
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
                child: Icon(
                  _iconForState,
                  color: const Color(0xFFFF9933),
                  size: minSide / 4,
                  shadows: const [
                    Shadow(color: Color(0xFFFF8C00), blurRadius: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}

class _RusticNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(12345);
    final noisePaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 3000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = random.nextDouble() * 0.4 + 0.1;
      final useAmber = random.nextBool();
      canvas.drawCircle(
        Offset(x, y),
        0.8,
        noisePaint
          ..color = useAmber
              ? Color.fromRGBO(139, 111, 71, opacity * 0.3)
              : Color.fromRGBO(107, 83, 53, opacity * 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CrtScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0A000000)
      ..style = PaintingStyle.fill;

    // Draw horizontal scan lines every 3 pixels
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VintageAmberArcPainter extends CustomPainter {
  final double progress;
  final double? _pulseValue;

  _VintageAmberArcPainter(this.progress, {double? pulseValue})
      : _pulseValue = pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = -pi * 1.5;
    const sweepAngle = pi * 1.5;
    const strokeWidth = 32.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final progressSweepAngle = sweepAngle * progress;

    // Outer rusty border ring
    final outerBorderPaint = Paint()
      ..color = const Color(0xFF6B5335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, outerBorderPaint);

    // Background track
    final backgroundPaint = Paint()
      ..color = const Color(0xFF2D1F0F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);

    // Gauge tick marks around the arc
    final tickPaint = Paint()
      ..color = const Color(0xFF8B6F47)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final majorTickPaint = Paint()
      ..color = const Color(0xFFAA8855)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const tickCount = 27; // One per 10° of 270°
    for (var i = 0; i <= tickCount; i++) {
      final angle = startAngle + sweepAngle * (i / tickCount);
      final isMajor = i % 3 == 0;
      final innerR = radius + strokeWidth / 2 + 8;
      final outerR = innerR + (isMajor ? 10 : 5);
      canvas.drawLine(
        Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
        Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
        isMajor ? majorTickPaint : tickPaint,
      );
    }

    // Progress arc
    final gradientPaint = Paint()
      ..color = const Color(0xFFFF9933)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, progressSweepAngle, false, gradientPaint);

    // Glow — pulses when paused
    final glowOpacity = _pulseValue != null
        ? 0.2 + 0.4 * _pulseValue
        : 0.4;
    final glowPaint = Paint()
      ..color = Color.fromRGBO(255, 140, 0, glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawArc(rect, startAngle, progressSweepAngle, false, glowPaint);

    // Scratches for worn look
    final scratchPaint = Paint()
      ..color = const Color(0x20000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final random = Random(42);
    for (var i = 0; i < 8; i++) {
      final scratchAngle = startAngle + (sweepAngle * random.nextDouble());
      final scratchLength = strokeWidth * (0.5 + random.nextDouble() * 0.5);
      final scratchStart = Offset(
        center.dx + (radius - strokeWidth / 2) * cos(scratchAngle),
        center.dy + (radius - strokeWidth / 2) * sin(scratchAngle),
      );
      final scratchEnd = Offset(
        center.dx +
            (radius - strokeWidth / 2 + scratchLength) * cos(scratchAngle),
        center.dy +
            (radius - strokeWidth / 2 + scratchLength) * sin(scratchAngle),
      );
      canvas.drawLine(scratchStart, scratchEnd, scratchPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VintageAmberArcPainter oldDelegate) => true;
}
