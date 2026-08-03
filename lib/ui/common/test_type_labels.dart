import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../models/test_type.dart';

/// The display name of a test, in the user's language.
///
/// Lives in the UI layer and takes [AppLocalizations] rather than hanging off
/// the view model or the service: both of those built the name from a hardcoded
/// English switch, so a Greek results screen was labelled "Drawing", "Tremor",
/// "Tap" no matter what the language setting said.
///
/// These are the short names, chosen to fit a chart axis and a radar spoke.
/// The long forms (`drawingTest`, `fabTest`, …) stay for screen titles.
String testTypeLabel(AppLocalizations l10n, TestType type) {
  switch (type) {
    case TestType.drawing:
      return l10n.testNameDrawing;
    case TestType.questionnaire:
      return l10n.testNameQuestionnaire;
    case TestType.tremor:
      return l10n.testNameTremor;
    case TestType.tap:
      return l10n.testNameTap;
    case TestType.voice:
      return l10n.testNameVoice;
    case TestType.cameraDetection:
      return l10n.testNameCamera;
    case TestType.neuro:
      return l10n.testNameNeuro;
    case TestType.fab:
      return l10n.testNameFab;
  }
}
