import 'package:flutter/material.dart';
import 'package:parkinsondetetion/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../../app/app.locator.dart';
import '../../patience/patience_viewmodel.dart';
import '../../drawing_test/signature_canvas_view.dart';
import '../../drawing_test/camera_draw_view.dart';
import '../../drawing_test/gallery_draw_view.dart';

/// Shows options for drawing input and forwards the image to [vm].
void showDrawingOptions(BuildContext ctx, PatienceViewModel vm) {
  showModalBottomSheet<void>(
    context: ctx,
    builder: (c) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.draw),
              title: const Text('Draw on phone'),
              onTap: () {
                Navigator.of(c).pop();
                locator<NavigationService>().navigateToSignatureCanvasView(
                  onImageReady: vm.handleCanvasDrawing,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take picture'),
              onTap: () {
                Navigator.of(c).pop();
                locator<NavigationService>().navigateToCameraDrawView(
                  onImageReady: vm.handleCameraImage,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload picture'),
              onTap: () {
                Navigator.of(c).pop();
                locator<NavigationService>().navigateToGalleryDrawView(
                  onImageReady: vm.handleGalleryImage,
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
