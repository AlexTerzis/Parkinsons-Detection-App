import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// MoCA visuoconstruction: copy the reference cube freehand.
class DrawCubeStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int) onScored;

  const DrawCubeStep({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  @override
  State<DrawCubeStep> createState() => _DrawCubeStepState();
}

class _DrawCubeStepState extends State<DrawCubeStep> {
  // Black on white, like the paper instrument.
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: AppTokens.canvasInk,
    exportBackgroundColor: AppTokens.canvasPaper,
  );

  /// Enables Next once something has been drawn, so the button state tells the
  /// patient whether their strokes registered.
  bool _hasDrawing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStrokesChanged);
  }

  void _onStrokesChanged() {
    final has = _controller.isNotEmpty;
    if (has != _hasDrawing && mounted) {
      setState(() => _hasDrawing = has);
    }
  }

  void _handleNext() {
    widget.onScored(_controller.isNotEmpty ? 1 : 0);
    widget.onNext();
  }

  @override
  void dispose() {
    _controller.removeListener(_onStrokesChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return TestStepScaffold(
      title: l10n.stepTitleCube,
      instruction: l10n.stepInstructionDrawCube,
      // The canvas must fill the space it is given; scrolling would swallow
      // the vertical strokes.
      scrollable: false,
      onNext: _handleNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            'assets/images/cube_reference.png',
            height: 140,
            fit: BoxFit.contain,
            semanticLabel: l10n.stepInstructionDrawCube,
          ),
          const AppGap.sm(),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTokens.canvasPaper,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Signature(
                  controller: _controller,
                  backgroundColor: AppTokens.canvasPaper,
                ),
              ),
            ),
          ),
          const AppGap.sm(),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _hasDrawing ? _controller.clear : null,
              icon: const Icon(Icons.undo),
              label: Text(l10n.stepClear),
            ),
          ),
        ],
      ),
    );
  }
}
