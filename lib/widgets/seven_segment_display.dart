import 'package:flutter/material.dart';

/// A widget that displays a single digit (0-9) using a seven-segment display style.
///
/// The segments are arranged like this:
///     _a_
///   f|   |b
///     _g_
///   e|   |c
///     _d_
class SevenSegmentDigit extends StatelessWidget {
  final int? digit;
  final Color onColor;
  final Color offColor;
  final double width;
  final double height;
  final double segmentThickness;

  const SevenSegmentDigit({
    super.key,
    required this.digit,
    required this.onColor,
    required this.offColor,
    required this.width,
    required this.height,
    required this.segmentThickness,
  }) : assert(
         (digit == null || (digit >= 0 && digit <= 9)),
         'Digit must be between 0 and 9',
       );

  /// Returns which segments should be lit for each digit (0-9)
  /// Segments: [a, b, c, d, e, f, g]
  static List<bool> _getSegmentsForDigit(int? digit) {
    switch (digit) {
      case 0:
        return [true, true, true, true, true, true, false];
      case 1:
        return [false, true, true, false, false, false, false];
      case 2:
        return [true, true, false, true, true, false, true];
      case 3:
        return [true, true, true, true, false, false, true];
      case 4:
        return [false, true, true, false, false, true, true];
      case 5:
        return [true, false, true, true, false, true, true];
      case 6:
        return [true, false, true, true, true, true, true];
      case 7:
        return [true, true, true, false, false, false, false];
      case 8:
        return [true, true, true, true, true, true, true];
      case 9:
        return [true, true, true, true, false, true, true];
      default:
        return [false, false, false, false, false, false, false];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(segmentThickness / 2),
      child: CustomPaint(
        size: Size(width, height),
        painter: _SevenSegmentPainter(
          segments: _getSegmentsForDigit(digit),
          onColor: onColor,
          offColor: offColor,
          segmentThickness: segmentThickness,
        ),
      ),
    );
  }
}

class _SevenSegmentPainter extends CustomPainter {
  final List<bool> segments;
  final Color onColor;
  final Color offColor;
  final double segmentThickness;

  _SevenSegmentPainter({
    required this.segments,
    required this.onColor,
    required this.offColor,
    required this.segmentThickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final t = segmentThickness;

    // Calculate segment positions
    final topY = t / 2;
    final middleY = size.height / 2;
    final bottomY = size.height - t / 2;
    final leftX = t / 2;
    final rightX = size.width - t / 2;
    final centerX = size.width / 2;

    final height = size.height / 2 - t / 2;
    final width = size.width - t;

    // Draw each segment
    // Segment A (top horizontal)
    _drawHorizontalSegment(
      canvas,
      paint,
      Offset(centerX, topY),
      width,
      segments[0] ? onColor : offColor,
    );

    // Segment B (top right vertical)
    _drawVerticalSegment(
      canvas,
      paint,
      Offset(rightX, middleY - height / 2),
      height,
      segments[1] ? onColor : offColor,
    );

    // Segment C (bottom right vertical)
    _drawVerticalSegment(
      canvas,
      paint,
      Offset(rightX, middleY + height / 2),
      height,
      segments[2] ? onColor : offColor,
    );

    // Segment D (bottom horizontal)
    _drawHorizontalSegment(
      canvas,
      paint,
      Offset(centerX, bottomY),
      width,
      segments[3] ? onColor : offColor,
    );

    // Segment E (bottom left vertical)
    _drawVerticalSegment(
      canvas,
      paint,
      Offset(leftX, middleY + height / 2),
      height,
      segments[4] ? onColor : offColor,
    );

    // Segment F (top left vertical)
    _drawVerticalSegment(
      canvas,
      paint,
      Offset(leftX, middleY - height / 2),
      height,
      segments[5] ? onColor : offColor,
    );

    // Segment G (middle horizontal)
    _drawHorizontalSegment(
      canvas,
      paint,
      Offset(centerX, middleY),
      width,
      segments[6] ? onColor : offColor,
    );
  }

  void _drawHorizontalSegment(
    Canvas canvas,
    Paint paint,
    Offset center,
    double length,
    Color color,
  ) {
    paint.color = color;
    final cx = center.dx;
    final cy = center.dy;
    final w = length;
    final h = segmentThickness;

    final path = Path()
      ..moveTo(cx - w / 2, cy)
      ..lineTo(cx - w / 2 + h / 2, cy - h / 2)
      ..lineTo(cx + w / 2 - h / 2, cy - h / 2)
      ..lineTo(cx + w / 2, cy)
      ..lineTo(cx + w / 2 - h / 2, cy + h / 2)
      ..lineTo(cx - w / 2 + h / 2, cy + h / 2)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawVerticalSegment(
    Canvas canvas,
    Paint paint,
    Offset center,
    double length,
    Color color,
  ) {
    paint.color = color;
    final cx = center.dx;
    final cy = center.dy;
    final w = segmentThickness;
    final h = length;

    final path = Path()
      ..moveTo(cx, cy - h / 2)
      ..lineTo(cx + w / 2, cy - h / 2 + w / 2)
      ..lineTo(cx + w / 2, cy + h / 2 - w / 2)
      ..lineTo(cx, cy + h / 2)
      ..lineTo(cx - w / 2, cy + h / 2 - w / 2)
      ..lineTo(cx - w / 2, cy - h / 2 + w / 2)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SevenSegmentPainter oldDelegate) {
    return segments != oldDelegate.segments ||
        onColor != oldDelegate.onColor ||
        offColor != oldDelegate.offColor ||
        segmentThickness != oldDelegate.segmentThickness;
  }
}

class DigitSeparatorPainter extends CustomPainter {
  final Color color;
  final double thickness;

  DigitSeparatorPainter({required this.color, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY1 = size.height * 0.25;
    final centerY2 = size.height * 0.75;

    // Draw top dot
    canvas.drawCircle(Offset(centerX, centerY1), thickness / 2, paint);

    // Draw bottom dot
    canvas.drawCircle(Offset(centerX, centerY2), thickness / 2, paint);
  }

  @override
  bool shouldRepaint(covariant DigitSeparatorPainter oldDelegate) {
    return color != oldDelegate.color || thickness != oldDelegate.thickness;
  }
}

class SevenSegmentDisplay extends StatelessWidget {
  final int minutes;
  final int seconds;
  final Color onColor;
  final Color offColor;
  final double digitWidth;
  final double digitHeight;
  final double segmentThickness;

  const SevenSegmentDisplay({
    super.key,
    required this.minutes,
    required this.seconds,
    this.onColor = const Color(0xFFFFFFFF),
    this.offColor = const Color(0x0DFFFFFF),
    this.digitWidth = 48,
    this.digitHeight = 80,
    this.segmentThickness = 8,
  });

  @override
  Widget build(BuildContext context) {
    final minTens = (minutes ~/ 10) % 10;
    final minUnits = minutes % 10;
    final secTens = (seconds ~/ 10) % 10;
    final secUnits = seconds % 10;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SevenSegmentDigit(
          digit: minTens,
          width: digitWidth,
          height: digitHeight,
          segmentThickness: segmentThickness,
          onColor: onColor,
          offColor: offColor,
        ),
        SizedBox(width: segmentThickness / 2),
        SevenSegmentDigit(
          digit: minUnits,
          width: digitWidth,
          height: digitHeight,
          segmentThickness: segmentThickness,
          onColor: onColor,
          offColor: offColor,
        ),
        SizedBox(width: segmentThickness / 2),
        CustomPaint(
          size: Size(segmentThickness * 2, digitHeight),
          painter: DigitSeparatorPainter(
            color: onColor,
            thickness: segmentThickness,
          ),
        ),
        SizedBox(width: segmentThickness / 2),
        SevenSegmentDigit(
          digit: secTens,
          width: digitWidth,
          height: digitHeight,
          segmentThickness: segmentThickness,
          onColor: onColor,
          offColor: offColor,
        ),
        SizedBox(width: segmentThickness / 2),
        SevenSegmentDigit(
          digit: secUnits,
          width: digitWidth,
          height: digitHeight,
          segmentThickness: segmentThickness,
          onColor: onColor,
          offColor: offColor,
        ),
      ],
    );
  }
}
