import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../models/test_type.dart';
import '../../common/widgets/widgets.dart';
import '../test_complete/test_complete_view.dart';

class DrawingResultView extends StatelessWidget {
  const DrawingResultView({
    super.key,
    required this.pngBytes,
    required this.drawingType,
    required this.inputMethod,
    required this.label,
    required this.parkinsonProbability,
    required this.saved,
  });

  final Uint8List pngBytes;
  final String drawingType;
  final String inputMethod;
  final String label;
  final double parkinsonProbability;
  final bool saved;

  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;

  @override
  Widget build(BuildContext context) {
    final healthyProbability = 1 - parkinsonProbability;
    final displayedProbability = label == 'Parkinson'
        ? parkinsonProbability
        : healthyProbability;
    return AppScaffold(
      title: _t(context, 'Drawing results', 'Αποτελέσματα σχεδίασης'),
      showBackButton: false,
      bottomAction: PrimaryAction(
        label: _t(context, 'Next', 'Επόμενο'),
        icon: Icons.arrow_forward,
        onPressed: () => showTestComplete(
          type: TestType.drawing,
          concern: parkinsonProbability.clamp(0, 1).toDouble(),
          saved: saved,
        ),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t(context, 'Submitted drawing', 'Υποβληθέν σχέδιο'),
              style: Theme.of(context).textTheme.titleMedium),
          const AppGap.sm(),
          Center(child: Container(
            constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
            decoration: BoxDecoration(border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant)),
            child: Image.memory(pngBytes, fit: BoxFit.contain),
          )),
          const AppGap.sm(),
          Text(_t(context,
            'Task: ${drawingType == 'wave' ? 'Freehand wave' : 'Freehand spiral'} · Input: $inputMethod',
            'Δοκιμασία: ${drawingType == 'wave' ? 'Ελεύθερο κύμα' : 'Ελεύθερη σπείρα'} · Είσοδος: $inputMethod')),
          const AppGap.xs(),
          Row(children: [
            Icon(inputMethod == 'canvas'
                ? Icons.check_circle_outline : Icons.info_outline,
                size: 20, color: Theme.of(context).colorScheme.primary),
            const AppGap.wide(AppSpacing.xs),
            Expanded(child: Text(inputMethod == 'canvas'
                ? _t(context, 'The drawing passed the canvas completeness checks.',
                    'Το σχέδιο πέρασε τους ελέγχους πληρότητας του καμβά.')
                : _t(context, 'Check the preview for cropping, shadows, or poor contrast.',
                    'Ελέγξτε την προεπισκόπηση για περικοπή, σκιές ή χαμηλή αντίθεση.'))),
          ]),
        ])),
        const AppGap.md(),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t(context, 'Preliminary model output',
              'Προκαταρκτικό αποτέλεσμα μοντέλου'),
              style: Theme.of(context).textTheme.titleMedium),
          const AppGap.sm(),
          Text(label == 'Parkinson'
              ? _t(context, 'Concerning pattern', 'Πρότυπο που χρειάζεται προσοχή')
              : _t(context, 'Healthy pattern', 'Υγιές πρότυπο'),
              style: Theme.of(context).textTheme.headlineSmall),
          const AppGap.xs(),
          Text(_t(context,
              'Model confidence: ${(displayedProbability * 100).toStringAsFixed(1)}%',
              'Βεβαιότητα μοντέλου: ${(displayedProbability * 100).toStringAsFixed(1)}%')),
          const AppGap.sm(),
          Text(saved
              ? _t(context, 'The result and drawing were saved.',
                  'Το αποτέλεσμα και το σχέδιο αποθηκεύτηκαν.')
              : _t(context, 'The result could not be saved.',
                  'Το αποτέλεσμα δεν ήταν δυνατό να αποθηκευτεί.')),
        ])),
        const AppGap.md(),
        AppCard(child: Text(_t(context,
          'This classifier is a screening aid. It cannot diagnose Parkinson’s disease and should be interpreted with the other assessments.',
          'Ο ταξινομητής είναι βοήθημα προσυμπτωματικού ελέγχου. Δεν μπορεί να διαγνώσει τη νόσο Πάρκινσον και πρέπει να ερμηνεύεται μαζί με τις άλλες αξιολογήσεις.',
        ))),
        const AppGap.md(),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.replay),
          label: Text(_t(context, 'Draw again', 'Σχεδίαση ξανά')),
        ),
      ]),
    );
  }
}
