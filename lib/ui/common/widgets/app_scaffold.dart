import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// The app's standard screen frame.
///
/// Replaces ~37 hand-built `Scaffold`s that each re-decided their own padding,
/// whether the body scrolled, and where the primary button went.
///
/// Two rules it enforces that the loose scaffolds did not:
///
/// * The primary action lives in a pinned bottom bar, above the system inset,
///   never floating in a [Stack] where scaled text can push it off screen.
/// * Body padding is uniform, so screens line up with each other.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.bottomAction,
    this.scrollable = true,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.showBackButton = true,
    this.floatingActionButton,
    this.backgroundColor,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;

  /// Pinned to the bottom, above the safe-area inset. Typically a
  /// [PrimaryAction] or a [Row] of buttons.
  final Widget? bottomAction;

  /// Whether [body] is wrapped in a scroll view. Turn this off for bodies that
  /// scroll themselves ([ListView], [TabBarView]) or must not scroll at all
  /// (a camera preview, a drawing canvas).
  final bool scrollable;

  final EdgeInsetsGeometry padding;
  final bool showBackButton;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: body);

    if (scrollable) {
      // The min-height + IntrinsicHeight pairing lets a body use Expanded or
      // Spacer while still scrolling once scaled text outgrows the viewport —
      // the case a plain SingleChildScrollView cannot express.
      content = LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: content),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: title == null && actions == null
          ? null
          : AppBar(
              title: title == null ? null : Text(title!),
              actions: actions,
              automaticallyImplyLeading: showBackButton,
            ),
      body: SafeArea(child: content),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomAction == null
          ? null
          : _BottomActionBar(child: bottomAction!),
    );
  }
}

/// Pinned container for a screen's primary action.
///
/// Carries a top border rather than an elevation shadow, matching the app bar's
/// bottom border — the theme deliberately disables surface tint and elevation
/// everywhere else.
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

/// A full-width primary button, sized for the bottom action bar.
///
/// Full width by design: a centred button of intrinsic width is a smaller
/// target, and this audience has hand tremor.
class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;

  /// Null disables the button. Prefer disabling over hiding, so the user can
  /// see what completing the screen will let them do.
  final VoidCallback? onPressed;

  final IconData? icon;

  /// Swaps the icon for a spinner and blocks input, for actions that await.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : (icon == null ? null : Icon(icon));

    return SizedBox(
      width: double.infinity,
      child: child == null
          ? FilledButton(
              onPressed: busy ? null : onPressed,
              child: Text(label),
            )
          : FilledButton.icon(
              onPressed: busy ? null : onPressed,
              icon: child,
              label: Text(label),
            ),
    );
  }
}
