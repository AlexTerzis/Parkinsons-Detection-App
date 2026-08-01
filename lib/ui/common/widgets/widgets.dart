/// The app's shared UI component layer.
///
/// Import this barrel rather than the individual files: views should carry one
/// import for the design system, not eight.
///
/// Everything here resolves colour and type from `Theme.of(context)` and
/// spacing from `AppSpacing`. Nothing here holds state or talks to a service —
/// these are presentation widgets, composed by views and driven by view models.
library;

export '../app_semantic_colors.dart';
export '../app_tokens.dart';
export 'app_card.dart';
export 'app_feedback.dart';
export 'app_list_tile_card.dart';
export 'app_metric.dart';
export 'app_preferences_section.dart';
export 'app_scaffold.dart';
export 'app_section.dart';
export 'app_state_views.dart';
export 'speech_text_field.dart';
export 'test_step_scaffold.dart';
