import 'package:flutter/material.dart';
import 'package:parkinsondetetion/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../../../app/app.locator.dart';
import '../../patience/patience_viewmodel.dart';

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
              title: Text(AppLocalizations.of(ctx)!.drawOnPhone),
              onTap: () {
                Navigator.of(c).pop();
                locator<NavigationService>().navigateToSignatureCanvasView(
                  onImageReady: vm.handleCanvasDrawing,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(ctx)!.takePicture),
              onTap: () {
                Navigator.of(c).pop();
                locator<NavigationService>().navigateToCameraDrawView(
                  onImageReady: vm.handleCameraImage,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(ctx)!.uploadPicture),
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
