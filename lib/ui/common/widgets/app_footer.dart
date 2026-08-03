import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../app_tokens.dart';
import 'app_info_button.dart';

/// The quiet footer at the bottom of a profile tab: what this app is not, the
/// legal documents, and which build is running.
///
/// The disclaimer is deliberately reachable from the profile rather than only
/// from a result screen. A screening app that produces a percentage invites
/// being read as a diagnosis, so the statement that it is not one has to live
/// somewhere permanent, not only next to the score.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: cs.outlineVariant),
        const SizedBox(height: AppSpacing.sm),

        // The one-line version of the disclaimer, always visible; the full
        // text is one tap away. Showing only a link would mean most users
        // never read any of it.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.screeningDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          children: [
            _FooterLink(
              label: l10n.medicalDisclaimer,
              onTap: () => _showDocument(
                context,
                title: l10n.medicalDisclaimer,
                body: l10n.medicalDisclaimerBody,
              ),
            ),
            _FooterLink(
              label: l10n.privacyPolicy,
              onTap: () => _showDocument(
                context,
                title: l10n.privacyPolicy,
                body: l10n.legalDocumentPlaceholder,
              ),
            ),
            _FooterLink(
              label: l10n.termsOfService,
              onTap: () => _showDocument(
                context,
                title: l10n.termsOfService,
                body: l10n.legalDocumentPlaceholder,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xs),
        const Center(child: _VersionLabel()),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  /// Shows a legal document in a scrollable dialog.
  static Future<void> _showDocument(
    BuildContext context, {
    required String title,
    required String body,
  }) =>
      showAppInfoDialog(context, title: title, body: body);
}

/// A low-emphasis text link sized for the footer.
class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        // Keeps the row compact without dropping under the minimum tap
        // target, which the default tap-target size still enforces.
        visualDensity: VisualDensity.compact,
        textStyle: theme.textTheme.labelLarge,
      ),
      child: Text(label),
    );
  }
}

/// Reads the running version and build number from the platform.
///
/// Taken from the package rather than a constant so it cannot drift from what
/// was actually shipped — the version in a bug report is only useful if it is
/// the real one.
class _VersionLabel extends StatefulWidget {
  const _VersionLabel();

  @override
  State<_VersionLabel> createState() => _VersionLabelState();
}

class _VersionLabelState extends State<_VersionLabel> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (_) {
      // A missing version is not worth an error state: the rest of the
      // footer is still useful, so the line simply stays empty.
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = _version;
    if (version == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Text(
      AppLocalizations.of(context)!.appVersion(version),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
