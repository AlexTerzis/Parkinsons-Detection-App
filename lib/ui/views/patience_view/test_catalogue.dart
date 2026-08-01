import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/test_type.dart';
import '../camera_test/camera_test_view.dart';
import '../fab_test/fab_test_view.dart';
import '../neuro_test/neuro_test_view.dart';
import '../patience/patience_viewmodel.dart';
import '../questionnaire/questionnaire_view.dart';
import '../tap_test/tap_test_view.dart';
import '../tremor_test/tremor_test_view.dart';
import '../voice_test/voice_test_view.dart';
import 'widgets/drawing_options_sheet.dart';

/// How each test presents itself and where it goes when tapped.
///
/// Previously an inline list of string/icon maps plus an eight-branch
/// `if/else` chain, both inside `TestsTab.build`. Hanging it off the enum means
/// a new test type is a compile error here rather than a screen that silently
/// falls through to the camera test — which is what the old chain's `else` did.
extension TestPresentation on TestType {
  IconData get icon {
    switch (this) {
      case TestType.cameraDetection:
        return Icons.camera_alt;
      case TestType.tremor:
        return Icons.vibration;
      case TestType.tap:
        return Icons.touch_app;
      case TestType.drawing:
        return Icons.edit;
      case TestType.questionnaire:
        return Icons.question_answer;
      case TestType.voice:
        return Icons.mic;
      case TestType.neuro:
        return Icons.psychology;
      case TestType.fab:
        return Icons.psychology_alt_outlined;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case TestType.cameraDetection:
        return l10n.cameraDetectionTest;
      case TestType.tremor:
        return l10n.tremorTest;
      case TestType.tap:
        return l10n.tapTest;
      case TestType.drawing:
        return l10n.drawingTest;
      case TestType.questionnaire:
        return l10n.questionnaire;
      case TestType.voice:
        return l10n.voiceTest;
      case TestType.neuro:
        return l10n.neuropsychologicalTest;
      case TestType.fab:
        return l10n.fabTest;
    }
  }

  /// Opens the test.
  ///
  /// Returns the view's result, which only the camera test uses: it resolves
  /// `false` when no hands were detected, and the caller surfaces that.
  Future<Object?>? open(BuildContext context, PatienceViewModel viewModel) {
    final navigator = locator<NavigationService>();

    switch (this) {
      case TestType.cameraDetection:
        return navigator.navigateToView(const CameraTestView());
      case TestType.tremor:
        return navigator.navigateToView(const TremorTestView());
      case TestType.tap:
        return navigator.navigateToView(const TapTestView());
      case TestType.questionnaire:
        return navigator.navigateToView(const QuestionnaireView());
      case TestType.voice:
        return navigator.navigateToView(const VoiceTestView());
      case TestType.neuro:
        return navigator.navigateToView(const NeuroTestView());
      case TestType.fab:
        return navigator.navigateToView(const FABTestView());
      case TestType.drawing:
        // A sheet rather than a route: the drawing test has three entry points
        // (canvas, camera, gallery) to choose between first.
        showDrawingOptions(context, viewModel);
        return Future.value();
    }
  }
}

/// The tests offered on the Tests tab, in the order they are listed.
const List<TestType> orderedTestTypes = [
  TestType.cameraDetection,
  TestType.tremor,
  TestType.tap,
  TestType.drawing,
  TestType.questionnaire,
  TestType.voice,
  TestType.neuro,
  TestType.fab,
];
