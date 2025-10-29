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

class _VintageAmberTimerViewState extends State<VintageAmberTimerView> {
  bool _showBellAnimation = false;

  @override
  void initState() {
    super.initState();
    widget.controller.stateStream.listen((state) {
      if (state == TimerState.completed) {
        setState(() {
          _showBellAnimation = true;
        });
        // Hide the bell animation after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showBellAnimation = false;
            });
          }
        });
      } else if (state == TimerState.idle) {
        setState(() {
          _showBellAnimation = false;
        });
      }
    });
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

    final remainingSeconds = widget.secondsTotal - widget.secondsElapsed;
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
    final progress =
        (widget.secondsTotal - widget.secondsElapsed) / widget.secondsTotal;
    final minSide = min(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final digitWidth = (minSide - 32 * 2) / 5 - 24;
    final digitHeight = digitWidth * 80 / 48;

    return Stack(
      children: [
        // Noise and rustic lines background
        CustomPaint(
          painter: RusticNoisePainter(),
          size: Size.infinite,
          child: Container(),
        ),
        // Radial gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                Color(0x08FF8C00), // Subtle orange glow in center
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Main content
        // Main timer with progress arc
        CustomPaint(
          painter: VintageAmberArcPainter(progress),
          child: Center(
            child: GestureDetector(
              onTap: _showTimePicker,
              child: SevenSegmentDisplay(
                disabled: widget.ready == false,
                minutes: (widget.secondsTotal - widget.secondsElapsed) ~/ 60,
                seconds: (widget.secondsTotal - widget.secondsElapsed) % 60,
                digitWidth: digitWidth,
                digitHeight: digitHeight,
                // Classic vintage amber/orange terminal color
                onColor: const Color(0xFFFFB347), // Bright amber
                offColor: const Color(
                  0x18FF8C00,
                ), // Very dim amber for off segments
                segmentThickness: 10, // Slightly thicker for retro feel
              ),
            ),
          ),
        ),
        // Bell animation
        if (_showBellAnimation)
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - minSide / 3,
            left: MediaQuery.of(context).size.width / 2 - 32,
            child: const BellAnimation(
              size: 64,
              color: Color(0xFFFFB347), // Bright amber to match theme
            ),
          ),
        // Control button with rustic metallic styling
        Positioned(
          top: MediaQuery.of(context).size.height / 2 + minSide / 6 - 16,
          right: (MediaQuery.of(context).size.width - minSide) / 2 + 24,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: minSide / 3,
              height: minSide / 3,
              decoration: BoxDecoration(
                // Rusty metal background with border
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF2D1F0F), // Dark rusty center
                    Color(0xFF1A1108), // Darker edges
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFF6B5335), // Rusty brown border
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x60FF8C00),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  if (widget.controller.state == TimerState.running) {
                    widget.controller.pauseTimer();
                  } else {
                    widget.controller.startTimer();
                  }
                },
                borderRadius: BorderRadius.circular(minSide / 6),
                child: Center(
                  child: Icon(
                    _iconForState,
                    color: Color(0xFFFF9933), // Warning amber
                    size: minSide / 4,
                    shadows: [Shadow(color: Color(0xFFFF8C00), blurRadius: 12)],
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

/// Painter for rustic noise and scratches background
class RusticNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(12345); // Fixed seed for consistent pattern

    // Draw noise/grain texture with amber tones
    final noisePaint = Paint()..style = PaintingStyle.fill;

    // Create noise by drawing many small dots with amber color
    for (var i = 0; i < 3000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = random.nextDouble() * 0.4 + 0.1;
      // Mix of dark amber and rust colors
      final useAmber = random.nextBool();
      canvas.drawCircle(
        Offset(x, y),
        0.8,
        noisePaint
          ..color = useAmber
              ? Color.fromRGBO(139, 111, 71, opacity * 0.3) // Dusty tan
              : Color.fromRGBO(107, 83, 53, opacity * 0.2), // Rusty brown
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VintageAmberArcPainter extends CustomPainter {
  final double progress;

  VintageAmberArcPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = -pi * 1.5;
    const sweepAngle = pi * 1.5;
    const strokeWidth = 32.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final progressSweepAngle = sweepAngle * progress;

    // Draw outer rusty border ring
    final outerBorderPaint = Paint()
      ..color =
          const Color(0xFF6B5335) // Rusty brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, outerBorderPaint);

    // Draw the background track (dark rusty metal)
    final backgroundPaint = Paint()
      ..color = const Color(0xFF2D1F0F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);

    // Draw the progress arc with gradient effect
    // We'll approximate gradient by drawing multiple arcs with varying opacity

    final innerRadius = radius - strokeWidth / 6 + (strokeWidth / 6);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    final gradientPaint = Paint()
      ..color = const Color(0xFFFF9933)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      innerRect,
      startAngle,
      progressSweepAngle,
      false,
      gradientPaint,
    );

    // Add glow effect to the progress arc
    final glowPaint = Paint()
      ..color = const Color(0x40FF8C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawArc(rect, startAngle, progressSweepAngle, false, glowPaint);

    // Draw scratches and wear marks on the arc for rustic feel
    final scratchPaint = Paint()
      ..color = const Color(0x20000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Add a few random-looking scratches
    final random = Random(42); // Fixed seed for consistent scratches
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
