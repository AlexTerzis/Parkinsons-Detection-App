import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';

/// Captures a photo using the device camera and returns it via [onImageReady].
class CameraDrawView extends StatefulWidget {
  const CameraDrawView({super.key, required this.onImageReady});

  final ValueChanged<File> onImageReady;

  @override
  State<CameraDrawView> createState() => _CameraDrawViewState();
}

class _CameraDrawViewState extends State<CameraDrawView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_capture);
  }

  Future<void> _capture() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      widget.onImageReady(File(file.path));
    }
    locator<NavigationService>().back();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}