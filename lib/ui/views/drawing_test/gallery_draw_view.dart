import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';

/// Picks an image from the gallery and returns it via [onImageReady].
class GalleryDrawView extends StatefulWidget {
  const GalleryDrawView({super.key, required this.onImageReady});

  final ValueChanged<File> onImageReady;

  @override
  State<GalleryDrawView> createState() => _GalleryDrawViewState();
}

class _GalleryDrawViewState extends State<GalleryDrawView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_pick);
  }

  Future<void> _pick() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
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