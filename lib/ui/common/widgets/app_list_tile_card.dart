import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// A tappable row: leading icon, title, optional subtitle, optional trailing.
///
/// The tests list, the doctor list and the results list had each grown their own
/// `Card(child: ListTile(...))` with different leading colours and trailing
/// layouts. Sizing and colour still come from `listTileTheme`; this widget owns
/// the card wrapper, the leading icon treatment and the [AppSize.minTap] floor.
class AppTileCard extends StatelessWidget {
  const AppTileCard({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Draws the row in the selected state. Marked for screen readers too, so the
  /// selection is not conveyed by the container tint alone.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: selected ? scheme.secondaryContainer : null,
      child: ListTile(
        selected: selected,
        onTap: onTap,
        // The tremor audience needs more than the 56 the theme guarantees for
        // rows this dense; two lines of scaled text also need the headroom.
        minTileHeight: AppSize.minTap + AppSpacing.xs,
        leading: icon == null
            ? null
            : Container(
                width: AppSize.minTap,
                height: AppSize.minTap,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: AppOpacity.subtle),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing ??
            (onTap == null ? null : const Icon(Icons.chevron_right)),
      ),
    );
  }
}
