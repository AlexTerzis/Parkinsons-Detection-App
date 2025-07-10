import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:signature/signature.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';

/// Lets the user draw freehand on screen and submits the result as a [ui.Image].
class SignatureCanvasView extends StatefulWidget {
  const SignatureCanvasView({super.key, required this.onImageReady});

  final ValueChanged<ui.Image> onImageReady;

  @override
  State<SignatureCanvasView> createState() => _SignatureCanvasViewState();
}

class _SignatureCanvasViewState extends State<SignatureCanvasView> {
  final SignatureController _controller =
      SignatureController(penStrokeWidth: 3, penColor: Colors.black);

  // Key to capture the canvas area for rendering
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.isEmpty) return;

    try {
      // Capture the rendered widget as an image
      final boundary =
          _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      widget.onImageReady(image);
      locator<NavigationService>().back();
    } catch (e) {
      debugPrint('Error capturing drawing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draw')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: RepaintBoundary(
                key: _canvasKey,
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _controller.clear,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
