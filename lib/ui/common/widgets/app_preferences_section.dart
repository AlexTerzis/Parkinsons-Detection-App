import 'package:flutter/material.dart';
import 'package:parkinsondetetion/app/app.locator.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'package:parkinsondetetion/services/localization_service.dart';
import 'package:parkinsondetetion/services/text_scale_service.dart';

import '../app_tokens.dart';

/// Language and text-size controls, shared by the patient and doctor profile
/// tabs.
///
/// Reads both services from the locator directly, the way the language picker
/// it replaces did: there is no view state here, both services are app-scoped
/// singletons, and their notifications already rebuild this subtree from the
/// root of the app.
class AppPreferencesSection extends StatelessWidget {
  const AppPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final localization = locator<LocalizationService>();
    final textScale = locator<TextScaleService>();

    final sizeLabels = <String>[
      l10n.textSizeNormal,
      l10n.textSizeLarge,
      l10n.textSizeLarger,
      l10n.textSizeLargest,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.preferences, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<Locale>(
              initialValue: localization.locale,
              decoration: InputDecoration(
                labelText: l10n.language,
                prefixIcon: const Icon(Icons.translate),
              ),
              items: [
                DropdownMenuItem(
                  value: const Locale('en'),
                  child: Text(l10n.english),
                ),
                DropdownMenuItem(
                  value: const Locale('el'),
                  child: Text(l10n.greek),
                ),
              ],
              onChanged: (locale) {
                if (locale != null) localization.setLocale(locale);
              },
            ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            Text(l10n.textSize, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.textSizeSystemNote,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Discrete presets rather than a slider: a slider needs a
            // sustained precise drag, which is exactly what hand tremor makes
            // hard. One equal-width tile per step, so the row stays symmetric
            // whatever the localized labels are — a Wrap of chips broke into
            // ragged rows as soon as the labels grew.
            Row(
              children: List.generate(
                TextScaleService.steps.length,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: i == TextScaleService.steps.length - 1
                          ? 0
                          : AppSpacing.sm,
                    ),
                    child: _TextSizeTile(
                      label: sizeLabels[i],
                      // The glyph itself grows with the step, so the control
                      // shows what it does without a separate preview block.
                      scale: TextScaleService.steps[i] /
                          TextScaleService.defaultScale,
                      selected: textScale.stepIndex == i,
                      onTap: () => textScale.setStepIndex(i),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: textScale.scale == TextScaleService.defaultScale
                    ? null
                    : textScale.reset,
                icon: const Icon(Icons.restart_alt),
                label: Text(l10n.resetToDefault),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One text-size preset: a sample glyph at that step's scale over its label.
class _TextSizeTile extends StatelessWidget {
  final String label;
  final double scale;
  final bool selected;
  final VoidCallback onTap;

  const _TextSizeTile({
    required this.label,
    required this.scale,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final foreground = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed box so every tile is the same height whatever the glyph
              // scale, which is what keeps the row symmetric.
              SizedBox(
                height: 36,
                // scaleDown so the app-wide text scale, which also applies
                // here, cannot push the glyph out of its fixed box.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'A',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize:
                          (theme.textTheme.titleLarge?.fontSize ?? 22) * scale,
                      color: foreground,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
