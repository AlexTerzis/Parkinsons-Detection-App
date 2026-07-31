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
              decoration: InputDecoration(labelText: l10n.language),
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
            // hard. Each chip clears the minimum tap target via the theme.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: List.generate(
                TextScaleService.steps.length,
                (i) => ChoiceChip(
                  label: Text(sizeLabels[i]),
                  selected: textScale.stepIndex == i,
                  onSelected: (_) => textScale.setStepIndex(i),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Not wrapped in its own MediaQuery: the app-wide override already
            // applies here, so this genuinely shows what every other screen
            // will look like. A locally scaled preview would drift from
            // reality, which is the usual bug in this kind of control.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.textSizePreviewTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.textSizePreviewBody,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xs),
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
