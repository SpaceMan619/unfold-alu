import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/unfold_theme.dart';

class MatchRing extends StatelessWidget {
  const MatchRing({
    super.key,
    required this.score,
    required this.color,
    this.size = 46,
    this.hasSignal = true,
  });

  final int score;
  final Color color;
  final double size;
  final bool hasSignal;

  @override
  Widget build(BuildContext context) {
    final stroke = size * 0.085;
    final progress = hasSignal ? score.clamp(0, 100) / 100 : 0.0;
    final ring = CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(progress: progress, color: color, stroke: stroke),
      child: Center(
        child: Text(
          hasSignal ? '$score%' : 'New',
          style: TextStyle(
            color: hasSignal ? color : UnfoldColors.muted,
            fontSize: size * (hasSignal ? 0.26 : 0.2),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );

    return Semantics(
      label: hasSignal ? '$score percent match' : 'Not yet matched',
      child: SizedBox.square(dimension: size, child: ring),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, progress * 2 * math.pi, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}
