import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:signature/signature.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/app_tokens.dart';

class SignatureCanvasView extends StatefulWidget {
  const SignatureCanvasView({
    super.key,
    required this.onImageReady,
    this.drawingType = 'spiral',
    this.onAnalyze,
  });

  final ValueChanged<ui.Image> onImageReady;
  final String drawingType;

  /// Used by the guided flow so the canvas remains visible while inference is
  /// running. [onImageReady] stays available for generated-route compatibility.
  final Future<void> Function(ui.Image image)? onAnalyze;

  @override
  State<SignatureCanvasView> createState() => _SignatureCanvasViewState();
}

class _SignatureCanvasViewState extends State<SignatureCanvasView> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: AppTokens.canvasInk,
  );
  final GlobalKey _canvasKey = GlobalKey();
  double _canvasSize = 300;
  String? _qualityMessage;
  bool _submitting = false;

  bool get _isGreek => Localizations.localeOf(context).languageCode == 'el';
  String _t(String en, String el) => _isGreek ? el : en;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_drawingChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_drawingChanged)
      ..dispose();
    super.dispose();
  }

  void _drawingChanged() {
    if (mounted) setState(() => _qualityMessage = null);
  }

  String? _validateDrawing() {
    if (_controller.points.length < 30) {
      return _t('The drawing is too short. Try to complete the full shape.',
          'Το σχέδιο είναι πολύ μικρό. Προσπαθήστε να ολοκληρώσετε ολόκληρο το σχήμα.');
    }
    final width = (_controller.maxXValue! - _controller.minXValue!) / _canvasSize;
    final height = (_controller.maxYValue! - _controller.minYValue!) / _canvasSize;
    final tooSmall = widget.drawingType == 'wave'
        ? width < .55 || height < .10
        : width < .32 || height < .32;
    if (tooSmall) {
      return _t('Use more of the canvas so the full drawing can be analysed.',
          'Χρησιμοποιήστε μεγαλύτερο μέρος του καμβά ώστε να αναλυθεί ολόκληρο το σχέδιο.');
    }
    const margin = 7.0;
    if (_controller.minXValue! < margin ||
        _controller.minYValue! < margin ||
        _controller.maxXValue! > _canvasSize - margin ||
        _controller.maxYValue! > _canvasSize - margin) {
      return _t('Part of the drawing is too close to the edge. Clear it and leave a small margin.',
          'Μέρος του σχεδίου είναι πολύ κοντά στην άκρη. Διαγράψτε το και αφήστε ένα μικρό περιθώριο.');
    }
    return null;
  }

  Future<void> _submit() async {
    final message = _validateDrawing();
    if (message != null) {
      setState(() => _qualityMessage = message);
      return;
    }
    setState(() => _submitting = true);
    try {
      final boundary =
          _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      if (widget.onAnalyze != null) {
        await widget.onAnalyze!(image);
      } else {
        widget.onImageReady(image);
        if (mounted) locator<NavigationService>().back();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _qualityMessage = _t('Could not capture the drawing. Please try again.',
              'Δεν ήταν δυνατή η καταγραφή του σχεδίου. Δοκιμάστε ξανά.');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeName = widget.drawingType == 'wave'
        ? _t('wave', 'κύμα')
        : _t('spiral', 'σπείρα');
    return Scaffold(
      appBar: AppBar(title: Text(l10n.drawTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = math.min(constraints.maxWidth - 32, 420).toDouble();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_t('Copy this $typeName freehand',
                          'Αντιγράψτε ελεύθερα αυτό το $typeName'),
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_t('Look at the reference, then draw it naturally in the square below. Do not trace it.',
                      'Κοιτάξτε το πρότυπο και σχεδιάστε το φυσικά στο παρακάτω τετράγωνο. Μην πατάτε πάνω στο πρότυπο.')),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 120,
                    child: CustomPaint(
                      painter: DrawingReferencePainter(
                        drawingType: widget.drawingType,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Container(
                      width: _canvasSize,
                      height: _canvasSize,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTokens.outline, width: 2),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: RepaintBoundary(
                        key: _canvasKey,
                        child: Signature(
                          controller: _controller,
                          width: _canvasSize,
                          height: _canvasSize,
                          backgroundColor: AppTokens.canvasPaper,
                        ),
                      ),
                    ),
                  ),
                  if (_qualityMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(_qualityMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: _submitting || _controller.isEmpty
                          ? null : _controller.undo,
                      icon: const Icon(Icons.undo),
                      label: Text(_t('Undo', 'Αναίρεση')),
                    )),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: OutlinedButton.icon(
                      onPressed: _submitting || _controller.isEmpty
                          ? null : _controller.clear,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.clearAction),
                    )),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox.square(dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.analytics_outlined),
                    label: Text(_t('Analyse drawing', 'Ανάλυση σχεδίου')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Reference only; it is deliberately outside the captured [RepaintBoundary].
class DrawingReferencePainter extends CustomPainter {
  const DrawingReferencePainter({required this.drawingType, required this.color});
  final String drawingType;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path();
    if (drawingType == 'wave') {
      final middle = size.height / 2;
      path.moveTo(8, middle);
      for (double x = 8; x <= size.width - 8; x += 2) {
        final y = middle + math.sin((x - 8) / (size.width - 16) * math.pi * 6)
            * size.height * .30;
        path.lineTo(x, y);
      }
    } else {
      final center = size.center(Offset.zero);
      for (double angle = 0; angle <= math.pi * 8; angle += .08) {
        final radius = angle / (math.pi * 8) * math.min(size.width, size.height) * .43;
        final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
        angle == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DrawingReferencePainter oldDelegate) =>
      drawingType != oldDelegate.drawingType || color != oldDelegate.color;
}
