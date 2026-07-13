import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/unfold_theme.dart';

/// A compact fit indicator: a track ring with a coloured progress arc and the
/// score at its centre. Deliberately flat — no glow, no orb — so it reads as an
/// instrument, not decoration. Shared between the discovery card and the detail
/// sheet (wrap in a [Hero] with a shared tag for a continuous open transition).
class MatchRing extends StatelessWidget {
  const MatchRing({
    super.key,
    required this.score,
    required this.color,
    this.size = 46,
    this.hasSignal = true,
    this.animate = true,
  });

  /// 0–100.
  final int score;

  /// Accent for the arc and the number (the opportunity's own colour).
  final Color color;

  final double size;

  /// When false the ring shows a neutral dash instead of a score — used before
  /// the student has any skills on file to match against.
  final bool hasSignal;

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final stroke = size * 0.085;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final target = (score.clamp(0, 100)) / 100;

    final ring = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: hasSignal ? target : 0),
      duration: (animate && !reduceMotion)
          ? const Duration(milliseconds: 900)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(
            progress: value,
            color: color,
            stroke: stroke,
          ),
          child: Center(
            child: hasSignal
                ? Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: size * 0.26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  )
                : Text(
                    'New',
                    style: TextStyle(
                      color: UnfoldColors.muted,
                      fontSize: size * 0.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        );
      },
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
