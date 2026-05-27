import 'dart:math' as math;

import 'package:flutter/material.dart';

class VelaLogoMark extends StatelessWidget {
  const VelaLogoMark({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _VelaLogoPainter(
        background: Theme.of(context).colorScheme.primary,
        foreground: const Color(0xFF0C0D0E),
      ),
    );
  }
}

class _VelaLogoPainter extends CustomPainter {
  const _VelaLogoPainter({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final rect = Offset.zero & size;
    final radius = shortest * 0.2;
    final backgroundPaint = Paint()..color = background;
    final foregroundPaint = Paint()
      ..color = foreground
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      backgroundPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(shortest * 0.055),
        Radius.circular(radius * 0.74),
      ),
      Paint()
        ..color = foreground.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = shortest * 0.035,
    );

    foregroundPaint.strokeWidth = shortest * 0.12;
    final vPath = Path()
      ..moveTo(shortest * 0.33, shortest * 0.36)
      ..lineTo(shortest * 0.5, shortest * 0.72)
      ..lineTo(shortest * 0.67, shortest * 0.36);
    canvas.drawPath(vPath, foregroundPaint);

    final dotPaint = Paint()..color = foreground;
    canvas.drawCircle(
      Offset(shortest * 0.5, shortest * 0.34),
      shortest * 0.028,
      dotPaint,
    );

    foregroundPaint.strokeWidth = shortest * 0.04;
    for (final radius in [shortest * 0.13, shortest * 0.22]) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(shortest * 0.5, shortest * 0.34),
          radius: radius,
        ),
        math.pi * 1.14,
        math.pi * 0.72,
        false,
        foregroundPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_VelaLogoPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.foreground != foreground;
  }
}
