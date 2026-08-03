import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_card.dart';
import 'app_section.dart';

/// Shared presentation for the introduction and result screens used by the
/// longer cognitive assessment batteries.
class AssessmentIntroContent extends StatelessWidget {
  const AssessmentIntroContent({
    super.key,
    required this.icon,
    required this.heading,
    required this.description,
    required this.durationLabel,
    required this.duration,
    required this.beforeTitle,
    required this.beforeItems,
    required this.measuresTitle,
    required this.measures,
    required this.note,
  });

  final IconData icon;
  final String heading;
  final String description;
  final String durationLabel;
  final String duration;
  final String beforeTitle;
  final List<String> beforeItems;
  final String measuresTitle;
  final List<String> measures;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.primary),
              const AppGap.md(),
              Text(heading, style: theme.textTheme.headlineSmall),
              const AppGap.sm(),
              Text(description),
              const AppGap.md(),
              Row(
                children: [
                  Icon(Icons.schedule,
                      size: 20, color: theme.colorScheme.primary),
                  const AppGap.wide(AppSpacing.xs),
                  Expanded(
                    child: Text('$durationLabel: $duration',
                        style: theme.textTheme.titleSmall),
                  ),
                ],
              ),
            ],
          ),
        ),
        const AppGap.md(),
        _InfoSection(
          title: measuresTitle,
          icon: Icons.psychology_alt_outlined,
          items: measures,
        ),
        const AppGap.md(),
        _InfoSection(
          title: beforeTitle,
          icon: Icons.checklist_outlined,
          items: beforeItems,
        ),
        const AppGap.md(),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const AppGap.wide(AppSpacing.sm),
              Expanded(child: Text(note)),
            ],
          ),
        ),
      ],
    );
  }
}

class AssessmentSavingContent extends StatelessWidget {
  const AssessmentSavingContent({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Center(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const AppGap.md(),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const AppGap.sm(),
              Text(description, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class AssessmentResultContent extends StatelessWidget {
  const AssessmentResultContent({
    super.key,
    required this.heading,
    required this.description,
    required this.scoreLabel,
    required this.score,
    required this.domainsTitle,
    required this.domains,
    required this.saved,
    required this.savedText,
    required this.notSavedText,
    required this.note,
  });

  final String heading;
  final String description;
  final String scoreLabel;
  final String score;
  final String domainsTitle;
  final List<String> domains;
  final bool saved;
  final String savedText;
  final String notSavedText;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = saved
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: theme.colorScheme.primary),
                  const AppGap.wide(AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(heading, style: theme.textTheme.titleLarge),
                        const AppGap.xxs(),
                        Text(description),
                      ],
                    ),
                  ),
                ],
              ),
              const AppGap.lg(),
              Text(scoreLabel, style: theme.textTheme.bodyMedium),
              const AppGap.xxs(),
              Text(score, style: theme.textTheme.displaySmall),
            ],
          ),
        ),
        const AppGap.md(),
        _InfoSection(
          title: domainsTitle,
          icon: Icons.fact_check_outlined,
          items: domains,
        ),
        const AppGap.md(),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(saved ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  color: statusColor),
              const AppGap.wide(AppSpacing.sm),
              Expanded(child: Text(saved ? savedText : notSavedText)),
            ],
          ),
        ),
        const AppGap.md(),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.medical_information_outlined,
                  color: theme.colorScheme.primary),
              const AppGap.wide(AppSpacing.sm),
              Expanded(child: Text(note)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const AppGap.wide(AppSpacing.sm),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const AppGap.sm(),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.check_circle_outline, size: 18),
                    ),
                    const AppGap.wide(AppSpacing.xs),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      );
}
