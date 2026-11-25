import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/camera_task_protocol.dart';

/// A small animated picture of what a camera-test step asks for.
///
/// Drawn in code rather than shipped as images: it scales to any size, sits on
/// the dark camera overlay in any theme, is mirrored for the left hand, and
/// can *move* — the finger tap, the fist and the palm turning over are much
/// easier to copy from a loop than from a sentence.
///
/// The hands are drawn as they appear in the mirrored camera preview, so the
/// picture and the patient's own image on screen match: the right hand is on
/// the right, palm towards the camera with the thumb on the right.
class StepIllustration extends StatefulWidget {
  const StepIllustration({
    super.key,
    required this.type,
    this.hand,
    this.size = const Size(150, 120),
    this.color = Colors.white,
  });

  final CameraTaskType type;

  /// `'Left'` or `'Right'` for a one-hand step; `null` for a both-hands step.
  final String? hand;

  final Size size;
  final Color color;

  @override
  State<StepIllustration> createState() => _StepIllustrationState();
}

class _StepIllustrationState extends State<StepIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _periodFor(widget.type));

  static Duration _periodFor(CameraTaskType type) {
    switch (type) {
      case CameraTaskType.fingerTap:
        return const Duration(milliseconds: 450);
      case CameraTaskType.openClose:
        return const Duration(milliseconds: 650);
      case CameraTaskType.pronationSupination:
        return const Duration(milliseconds: 750);
      case CameraTaskType.rest:
      case CameraTaskType.posture:
        return const Duration(seconds: 1);
    }
  }

  bool get _moves => widget.type.isScored;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_moves && !reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = _moves ? 0.5 : 0;
    }
  }

  @override
  void didUpdateWidget(StepIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _controller.duration = _periodFor(widget.type);
      didChangeDependencies();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      child: SizedBox.fromSize(
        size: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: StepPainter(
              type: widget.type,
              hand: widget.hand,
              t: Curves.easeInOut.transform(_controller.value),
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints one frame of a [StepIllustration]. [t] runs 0-1 and back.
class StepPainter extends CustomPainter {
  StepPainter({
    required this.type,
    required this.hand,
    required this.t,
    required this.color,
  });

  final CameraTaskType type;
  final String? hand;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (type) {
      case CameraTaskType.rest:
        _table(canvas, size);
        for (final (x, mirror) in <(double, bool)>[(0.3, true), (0.7, false)]) {
          _flatHand(canvas, Offset(w * x, h * 0.84), h * 0.27, mirror, 1);
        }
      case CameraTaskType.posture:
        // Both hands raised, palms to the camera, fingers spread; no table
        // contact, which is what makes it a posture held against gravity.
        for (final (x, mirror) in <(double, bool)>[
          (0.28, true),
          (0.72, false)
        ]) {
          _hand(
            canvas,
            wrist: Offset(w * x, h * 0.7),
            unit: h * 0.21,
            mirror: mirror,
            spread: 1,
          );
        }
      case CameraTaskType.fingerTap:
      case CameraTaskType.openClose:
      case CameraTaskType.pronationSupination:
        final bool left = hand == 'Left';
        _table(canvas, size);
        // The other hand, resting on the table on its own side.
        _flatHand(canvas, Offset(w * (left ? 0.82 : 0.18), h * 0.9), h * 0.13,
            !left, 0.45);
        _hand(
          canvas,
          wrist: Offset(w * (left ? 0.42 : 0.58), h * 0.68),
          unit: h * 0.24,
          mirror: left,
          curl: type == CameraTaskType.openClose ? t : 0,
          tap: type == CameraTaskType.fingerTap ? t : 0,
          turn: type == CameraTaskType.pronationSupination
              ? math.cos(math.pi * t)
              : 1,
          elbowDown: true,
        );
    }
  }

  void _table(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height * 0.95;
    canvas.drawLine(
        Offset(size.width * 0.04, y), Offset(size.width * 0.96, y), paint);
  }

  /// A hand lying flat on the table, seen from in front and above.
  void _flatHand(
      Canvas canvas, Offset wrist, double unit, bool mirror, double alpha) {
    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.scale(1, 0.42);
    _hand(canvas,
        wrist: Offset.zero,
        unit: unit,
        mirror: mirror,
        alpha: alpha,
        back: true,
        forearmLength: 1.6);
    canvas.restore();
  }

  /// An upright hand, wrist at [wrist], fingers pointing up.
  ///
  /// [unit] is the palm width. [curl] closes the fingers into a fist (0 open,
  /// 1 closed); [tap] brings the index and thumb together; [turn] is the
  /// palm's apparent width as it rolls, from 1 (palm to camera) through 0
  /// (edge on) to -1 (back of the hand to camera); [spread] fans the fingers.
  void _hand(
    Canvas canvas, {
    required Offset wrist,
    required double unit,
    required bool mirror,
    double curl = 0,
    double tap = 0,
    double turn = 1,
    double spread = 0.35,
    double alpha = 1,
    bool back = false,
    bool elbowDown = false,
    double forearmLength = 1.3,
  }) {
    final bool showsBack = back || turn < 0;
    // Opaque shades rather than translucent ones, so a finger overlapping the
    // palm does not show up brighter where the two are drawn on top of each
    // other.
    Color shade(double k) => Color.lerp(Colors.black, color, k * alpha)!;
    final fill = Paint()..color = shade(showsBack ? 0.62 : 0.9);
    final arm = Paint()..color = shade(0.5);
    final detail = Paint()
      ..color = shade(showsBack ? 0.4 : 0.6)
      ..style = PaintingStyle.stroke
      // In palm-width units: the canvas is scaled by [unit] below.
      ..strokeWidth = 0.05
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.scale(unit, unit);

    // Forearm first, unaffected by the roll so the turning reads as the hand
    // rotating about the arm.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-0.33, -0.05, 0.66, forearmLength),
          const Radius.circular(0.3)),
      arm,
    );
    if (elbowDown) {
      canvas.drawCircle(Offset(0, forearmLength), 0.12, arm);
    }

    // Roll and mirror. A negative width is a hand seen from the back, which
    // also puts the thumb on the other side — exactly as a real hand does.
    final double width = turn.abs() < 0.12 ? 0.12 * turn.sign : turn;
    canvas.scale((mirror ? -1 : 1) * (width == 0 ? 0.12 : width), 1);

    // Palm.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-0.5, -1.1, 1.0, 1.15),
          const Radius.circular(0.3)),
      fill,
    );

    // Fingers, pinky to index, left to right; the thumb is on the right.
    const xs = <double>[-0.37, -0.12, 0.13, 0.37];
    const lengths = <double>[0.72, 0.95, 1.05, 0.95];
    for (int i = 0; i < 4; i++) {
      final bool isIndex = i == 3;
      double angle = (i - 1.5) * 0.12 * spread;
      if (isIndex) angle += tap * 1.3;
      final double length =
          lengths[i] * (1 - 0.68 * curl) * (isIndex ? 1 - 0.26 * tap : 1);
      _capsule(canvas, Offset(xs[i], -1.02), angle, length, 0.23, fill);
    }

    // Thumb, from the side of the palm, angled outwards; folds across the
    // fist as the hand closes, and swings in to meet the index on a tap.
    final double thumbAngle = 0.85 - 0.55 * curl - 0.3 * tap;
    _capsule(canvas, const Offset(0.42, -0.4), thumbAngle,
        (0.72 + 0.08 * tap) * (1 - 0.25 * curl), 0.26, fill);

    // A crease on the palm, knuckle marks on the back, so the two sides of the
    // turning hand look different.
    if (showsBack) {
      for (final x in xs) {
        canvas.drawCircle(
            Offset(x, -0.98), 0.035, detail..style = PaintingStyle.fill);
      }
      detail.style = PaintingStyle.stroke;
    } else {
      final crease = Path()
        ..moveTo(-0.38, -0.55)
        ..quadraticBezierTo(0.0, -0.35, 0.3, -0.62);
      canvas.drawPath(crease, detail);
    }

    canvas.restore();
  }

  /// A rounded finger rooted at [base], pointing up, rotated by [angle]
  /// (radians, positive towards the thumb side).
  void _capsule(Canvas canvas, Offset base, double angle, double length,
      double width, Paint paint) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-width / 2, -length, width, length + width / 2),
        Radius.circular(width / 2),
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(StepPainter old) =>
      old.t != t || old.type != type || old.hand != hand || old.color != color;
}
