import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/authentication_service.dart';
import '../../common/widgets/widgets.dart';
import 'login_viewmodel.dart';

/// Sign-in and sign-up, plus the guest entry point.
class LoginView extends StackedView<LoginViewModel> {
  LoginView({super.key});

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget builder(
    BuildContext context,
    LoginViewModel viewModel,
    Widget? child,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: GestureDetector(
        // Tapping the backdrop dismisses the keyboard, which otherwise hides
        // the primary button on short screens.
        onTap: () => FocusScope.of(context).unfocus(),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTokens.splashBackground,
                AppTokens.primaryDark,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  // Elevated rather than the themed outlined default: this card
                  // is a hero surface floating on the brand gradient.
                  child: Card(
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _form(context, viewModel, theme, l10n),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _form(
    BuildContext context,
    LoginViewModel viewModel,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final signingUp = !viewModel.isLoginMode;

    return [
      Text(
        viewModel.isLoginMode ? l10n.welcome : l10n.createAccount,
        style: theme.textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      const AppGap.lg(),

      if (signingUp) ...[
        TextFormField(
          controller: viewModel.nameController,
          textInputAction: TextInputAction.next,
          validator: (v) => viewModel.validateName(v, l10n),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person_outline),
            labelText: l10n.nameLabel,
          ),
        ),
        const AppGap.md(),
      ],

      TextFormField(
        controller: viewModel.emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: (v) => viewModel.validateEmail(v, l10n),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.email_outlined),
          labelText: l10n.emailLabel,
        ),
      ),
      const AppGap.md(),

      TextFormField(
        controller: viewModel.passwordController,
        obscureText: !viewModel.passwordVisible,
        textInputAction:
            signingUp ? TextInputAction.next : TextInputAction.done,
        validator: (v) => viewModel.validatePassword(v, l10n),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline),
          labelText: l10n.passwordLabel,
          suffixIcon: IconButton(
            icon: Icon(viewModel.passwordVisible
                ? Icons.visibility_off
                : Icons.visibility),
            onPressed: viewModel.togglePasswordVisibility,
          ),
        ),
      ),
      const AppGap.md(),

      if (signingUp) ...[
        TextFormField(
          controller: viewModel.confirmPasswordController,
          obscureText: !viewModel.confirmPasswordVisible,
          textInputAction: TextInputAction.done,
          validator: (v) => viewModel.validateConfirmPassword(v, l10n),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline),
            labelText: l10n.confirmPasswordLabel,
            suffixIcon: IconButton(
              icon: Icon(viewModel.confirmPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: viewModel.toggleConfirmPasswordVisibility,
            ),
          ),
        ),
        const AppGap.md(),
        Text(l10n.iAmA, style: theme.textTheme.bodyLarge),
        const AppGap.xs(),
        Wrap(
          spacing: AppSpacing.sm,
          children: UserRole.values.map((role) {
            return ChoiceChip(
              label: Text(
                role == UserRole.patient ? l10n.patient : l10n.doctor,
              ),
              selected: viewModel.selectedRole == role,
              onSelected: (_) => viewModel.selectRole(role),
            );
          }).toList(),
        ),
        const AppGap.md(),
      ],

      CheckboxListTile(
        title: Text(l10n.keepMeLoggedIn),
        value: viewModel.keepMeLoggedIn,
        onChanged: (value) => viewModel.setKeepMeLoggedIn(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),

      if (viewModel.errorMessage != null) ...[
        const AppGap.xs(),
        Text(
          viewModel.errorMessage!,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.error),
          textAlign: TextAlign.center,
        ),
        const AppGap.sm(),
      ],

      // The button reports progress itself, rather than a separate spinner
      // appearing below and pushing the layout around mid-submit.
      PrimaryAction(
        label: viewModel.isLoginMode ? l10n.login : l10n.signUp,
        busy: viewModel.isBusy,
        onPressed: () => _onAuthenticatePressed(context, viewModel),
      ),
      const AppGap.xs(),

      if (viewModel.isLoginMode)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: viewModel.isBusy
                ? null
                : () => _showForgotPasswordDialog(context, viewModel),
            child: Text(l10n.forgotPassword),
          ),
        ),

      TextButton(
        onPressed: viewModel.isBusy ? null : viewModel.toggleMode,
        child: Text(viewModel.isLoginMode
            ? l10n.dontHaveAccount
            : l10n.alreadyHaveAccount),
      ),

      if (viewModel.isLoginMode) ...[
        const Divider(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed:
              viewModel.isBusy ? null : () => viewModel.continueAsGuest(l10n),
          icon: const Icon(Icons.person_outline),
          label: Text(l10n.continueAsGuest),
        ),
      ],
    ];
  }

  @override
  LoginViewModel viewModelBuilder(BuildContext context) => LoginViewModel();

  void _showForgotPasswordDialog(
      BuildContext context, LoginViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          _ForgotPasswordDialog(viewModel: viewModel),
    );
  }

  void _onAuthenticatePressed(BuildContext context, LoginViewModel viewModel) {
    if (_formKey.currentState?.validate() ?? false) {
      viewModel.authenticate(
        email: viewModel.emailController.text,
        password: viewModel.passwordController.text,
        confirmPassword: viewModel.confirmPasswordController.text,
        l10n: AppLocalizations.of(context)!,
      );
    }
  }
}

/// Collects an address for a password-reset email.
///
/// Stateful so its controller is disposed. The version this replaces created a
/// `TextEditingController` inside the show call and never disposed it, leaking
/// one per attempt.
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.viewModel});

  final LoginViewModel viewModel;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.passwordRecovery),
      content: TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.emailLabel,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _send,
          child: Text(l10n.send),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    // Captured before the await: this dialog's context dies with the pop.
    final messengerContext = Navigator.of(context).context;

    await widget.viewModel.sendPasswordReset(_email.text, l10n);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (messengerContext.mounted) {
      AppFeedback.success(messengerContext, l10n.emailSent);
    }
  }
}
