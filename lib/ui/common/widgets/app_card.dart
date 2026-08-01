import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// A padded [Card], optionally tappable.
///
/// The app had ~20 `Card(child: Padding(...))` pairs with five different
/// paddings between them. Visual styling (colour, border, radius, zero
/// elevation) still comes from `cardTheme`; this widget only owns the padding
/// and the ink response.
///
/// Tappable cards wrap the content in [InkWell] *inside* the card rather than
/// using `Card(child: InkWell(...))` with a manual border radius, so the splash
/// is clipped by the card's own `clipBehavior: Clip.antiAlias`.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Announced by screen readers in place of the card's contents. Worth setting
  /// when the card's meaning is carried by a chart or an icon.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    final card = Card(
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              // Matches the card's own radius so the splash does not square off
              // the corners on slower devices where clipping lags the ink.
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: content,
            ),
    );

    if (semanticLabel == null) return card;
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: card,
    );
  }
}
