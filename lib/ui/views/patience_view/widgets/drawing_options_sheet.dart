import 'package:flutter/material.dart';

import '../../drawing_test/signature_canvas_view.dart';
import '../../patience/patience_viewmodel.dart';

/// Introduces the freehand task, selects spiral or wave, then selects input.
void showDrawingOptions(BuildContext ctx, PatienceViewModel vm) {
  var drawingType = 'spiral';
  final isGreek = Localizations.localeOf(ctx).languageCode == 'el';
  String t(String en, String el) => isGreek ? el : en;

  showModalBottomSheet<void>(
    context: ctx,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gesture,
                  size: 44, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(t('Freehand drawing test', 'Τεστ ελεύθερης σχεδίασης'),
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(t(
                'Copy either a spiral or a wave freehand. Do not trace the reference. Draw naturally without trying to correct small movements.',
                'Αντιγράψτε ελεύθερα μια σπείρα ή ένα κύμα. Μην πατάτε πάνω στο πρότυπο. Σχεδιάστε φυσικά χωρίς να προσπαθείτε να διορθώσετε μικρές κινήσεις.',
              )),
              const SizedBox(height: 16),
              Text(t('Choose a drawing', 'Επιλέξτε σχέδιο'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'spiral',
                    icon: const Icon(Icons.track_changes),
                    label: Text(t('Spiral', 'Σπείρα')),
                  ),
                  ButtonSegment(
                    value: 'wave',
                    icon: const Icon(Icons.waves),
                    label: Text(t('Wave', 'Κύμα')),
                  ),
                ],
                selected: {drawingType},
                onSelectionChanged: (value) =>
                    setSheetState(() => drawingType = value.first),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: CustomPaint(
                  painter: DrawingReferencePainter(
                    drawingType: drawingType,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(t('Choose how to provide it', 'Επιλέξτε τρόπο καταχώρισης'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _MethodTile(
                icon: Icons.draw,
                title: t('Draw on phone — recommended',
                    'Σχεδίαση στο τηλέφωνο — προτείνεται'),
                subtitle: t('Uses a standard square canvas.',
                    'Χρησιμοποιεί τυποποιημένο τετράγωνο καμβά.'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(ctx).push(MaterialPageRoute<void>(
                    builder: (_) => SignatureCanvasView(
                      drawingType: drawingType,
                      onImageReady: (_) {},
                      onAnalyze: (image) => vm.handleCanvasDrawing(image,
                          drawingType: drawingType,
                          inputMethod: 'canvas',
                          replaceCurrent: true),
                    ),
                  ));
                },
              ),
              _MethodTile(
                icon: Icons.camera_alt_outlined,
                title: t('Photograph a paper drawing',
                    'Φωτογράφιση σχεδίου σε χαρτί'),
                subtitle: t('Use white paper, a dark pen, and even lighting.',
                    'Χρησιμοποιήστε λευκό χαρτί, σκούρο στυλό και ομοιόμορφο φωτισμό.'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  vm.pickDrawingFromCamera(drawingType);
                },
              ),
              _MethodTile(
                icon: Icons.photo_library_outlined,
                title: t('Upload an existing drawing',
                    'Μεταφόρτωση υπάρχοντος σχεδίου'),
                subtitle: t('The full drawing should be visible without shadows.',
                    'Το πλήρες σχέδιο πρέπει να φαίνεται χωρίς σκιές.'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  vm.pickDrawingFromGallery(drawingType);
                },
              ),
              const SizedBox(height: 8),
              Text(
                t('The classifier is a screening aid and not a diagnosis.',
                    'Ο ταξινομητής είναι βοήθημα προσυμπτωματικού ελέγχου και όχι διάγνωση.'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.icon, required this.title,
    required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      minVerticalPadding: 14,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
