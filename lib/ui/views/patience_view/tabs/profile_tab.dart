import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parkinsondetetion/app/app.locator.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../../../services/authentication_service.dart';
import '../../../common/widgets/widgets.dart';
import '../../patience/patience_viewmodel.dart';

/// ProfileTab extracts the profile editing UI from PatienceView.
/// It shows current user information and basic edit fields.
class ProfileTab extends StatelessWidget {
  final PatienceViewModel viewModel;
  const ProfileTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Identity header: who is signed in, at a glance.
          Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                child: const Icon(Icons.person, size: 44),
              ),
              const AppGap.md(),
              Text(
                viewModel.name,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const AppGap.xs(),
              Text(
                viewModel.email,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const AppGap.lg(),
          if (viewModel.isGuest) ...[
            const _GuestUpgradeCard(),
            const AppGap.md(),
          ],
          // The only editable profile field: the display name. Date of birth
          // and medication used to live here, but nothing in the app ever read
          // them back, so they only asked for health data with no purpose.
          _NameEditor(viewModel: viewModel),
          const AppGap.md(),
          const AppPreferencesSection(),
          const AppGap.lg(),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.outlineVariant),
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
            label: Text(l10n.logOut),
          ),
          const AppGap.lg(),
          const AppFooter(),
        ],
      ),
    );
  }

  /// Signs out, warning guests first.
  ///
  /// Signing out of an anonymous account is irreversible: it cannot be signed
  /// back into, so every result recorded against it is gone. A registered user
  /// is only ever one sign-in away from theirs, so they get no prompt.
  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    if (!viewModel.isGuest) {
      await viewModel.logout(context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.guestSignOutTitle),
        content: Text(l10n.guestSignOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.signOutAnyway),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await viewModel.logout(context);
    }
  }
}

/// Edits the display name, with a save action that only lights up once the
/// field actually differs from the saved name.
///
/// Replaces the two former buttons: one saved fields nothing read back, and the
/// other was a permanently enabled "save changes" that usually saved nothing.
class _NameEditor extends StatefulWidget {
  final PatienceViewModel viewModel;
  const _NameEditor({required this.viewModel});

  @override
  State<_NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<_NameEditor> {
  late final TextEditingController _controller = widget.viewModel.nameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    // The controller belongs to the view model, so only the listener is ours.
    _controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _dirty {
    final text = _controller.text.trim();
    return text.isNotEmpty && text != widget.viewModel.name.trim();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await widget.viewModel.saveName();
      if (mounted) AppFeedback.success(context, l10n.savedSuccessfully);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.editName, style: theme.textTheme.titleLarge),
            const AppGap.md(),
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_dirty && !_saving) _save();
              },
              decoration: InputDecoration(
                labelText: l10n.editName,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
            ),
            const AppGap.sm(),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: (_dirty && !_saving) ? _save : null,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(l10n.saveChanges),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Offers a guest a permanent account, keeping the results they already have.
///
/// Uses account linking rather than sign-up, so the uid is preserved and every
/// result recorded as a guest stays attached to it.
class _GuestUpgradeCard extends StatefulWidget {
  const _GuestUpgradeCard();

  @override
  State<_GuestUpgradeCard> createState() => _GuestUpgradeCardState();
}

class _GuestUpgradeCardState extends State<_GuestUpgradeCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _expanded = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _upgrade() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await locator<AuthenticationService>().linkAnonymousToEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      AppFeedback.success(context, l10n.accountCreatedKeptResults);
      setState(() => _expanded = false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        // Both codes mean the address is taken. Guest data cannot be merged
        // into an existing account, so say so rather than failing vaguely.
        _error = (e.code == 'email-already-in-use' ||
                e.code == 'credential-already-in-use')
            ? l10n.emailAlreadyInUse
            : (e.message ?? l10n.guestUpgradeFailed);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.guestUpgradeFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: cs.onSecondaryContainer),
                const AppGap.wide(AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.guestAccountTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: cs.onSecondaryContainer),
                  ),
                ),
              ],
            ),
            const AppGap.xs(),
            Text(
              l10n.guestAccountBody,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSecondaryContainer),
            ),
            const AppGap.md(),
            if (!_expanded)
              ElevatedButton.icon(
                onPressed: () => setState(() => _expanded = true),
                icon: const Icon(Icons.person_add_alt),
                label: Text(l10n.keepMyResults),
              )
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: l10n.emailLabel),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.emailRequired;
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v)) {
                          return l10n.invalidEmailAddress;
                        }
                        return null;
                      },
                    ),
                    const AppGap.sm(),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration:
                          InputDecoration(labelText: l10n.passwordLabel),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.passwordRequired;
                        }
                        if (v.length < 6) return l10n.passwordTooShort;
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const AppGap.sm(),
                      Text(
                        _error!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: cs.error),
                      ),
                    ],
                    const AppGap.md(),
                    ElevatedButton(
                      onPressed: _busy ? null : _upgrade,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.createAccount),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
