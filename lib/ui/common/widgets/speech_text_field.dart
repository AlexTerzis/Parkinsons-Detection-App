import 'package:flutter/material.dart';

import '../app_semantic_colors.dart';
import '../app_tokens.dart';

/// A text field with a dictation button in its suffix.
///
/// Every assessment that accepts a typed answer also accepts a spoken one, and
/// each of the eight screens that do had built this pairing itself — with the
/// mic variously black, green, `Icons.mic` when idle, or squeezed to 24px by
/// the input decorator.
///
/// The widget owns only the presentation. Speech recognition stays with the
/// step, which is where the locale, the grammar and the scoring live.
class SpeechTextField extends StatelessWidget {
  const SpeechTextField({
    super.key,
    required this.controller,
    required this.listening,
    required this.onListen,
    this.label,
    this.hintText,
    this.micTooltip,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.correct,
    this.style,
  });

  final TextEditingController controller;

  /// Whether the recognizer is currently capturing into this field. Drives the
  /// icon and disables the button, so two fields cannot listen at once.
  final bool listening;

  /// Null disables dictation for this field.
  final VoidCallback? onListen;

  final String? label;
  final String? hintText;
  final String? micTooltip;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final TextStyle? style;

  /// When non-null, shows a validity marker. Icon and colour together, never
  /// colour alone — the app's rule for every red/green signal.
  final bool? correct;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);

    return TextField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: style,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: correct == null
            ? null
            : Icon(
                correct! ? Icons.check_circle : Icons.circle_outlined,
                color: correct! ? semantic.success : null,
              ),
        suffixIcon: onListen == null
            ? null
            : IconButton(
                tooltip: micTooltip,
                icon: Icon(
                  listening ? Icons.mic : Icons.mic_none,
                  // Green only while actually capturing, so the state is
                  // readable at a glance mid-task.
                  color: listening ? semantic.success : null,
                ),
                onPressed: listening || !enabled ? null : onListen,
              ),
      ),
    );
  }
}

/// The panel that reveals example answers, at the cost of half a point.
///
/// Was a `Colors.yellow[100]` box repeated in five steps, each with its own
/// padding and none of them contrast-checked. Uses the warning container role,
/// which is chosen to carry text.
class HintPanel extends StatelessWidget {
  const HintPanel({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: semantic.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs / 2),
              child: Text(
                '• $line',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: semantic.onWarningContainer),
              ),
            ),
        ],
      ),
    );
  }
}
