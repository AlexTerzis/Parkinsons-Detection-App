import 'package:flutter/material.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'package:stacked/stacked.dart';

import '../../../services/authentication_service.dart';
import '../../common/app_tokens.dart';
import 'login_viewmodel.dart';

class LoginView extends StackedView<LoginViewModel> {
  LoginView({Key? key}) : super(key: key);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget builder(
    BuildContext context,
    LoginViewModel viewModel,
    Widget? child,
  ) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                // Elevated rather than the themed outlined default: this card
                // is a hero surface floating on the brand gradient.
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header switches text based on authentication mode.
                          Text(
                            viewModel.isLoginMode
                                ? AppLocalizations.of(context)!.welcome
                                : AppLocalizations.of(context)!.createAccount,
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          if (!viewModel.isLoginMode) ...[
                            TextFormField(
                              controller: viewModel.nameController,
                              validator: (v) => viewModel.validateName(
                                  v, AppLocalizations.of(context)!),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person_outline),
                                // Localized label for user's name.
                                labelText:
                                    AppLocalizations.of(context)!.nameLabel,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextFormField(
                            controller: viewModel.emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => viewModel.validateEmail(
                                v, AppLocalizations.of(context)!),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email_outlined),
                              labelText:
                                  AppLocalizations.of(context)!.emailLabel,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: viewModel.passwordController,
                            obscureText: !viewModel.passwordVisible,
                            validator: (v) => viewModel.validatePassword(
                                v, AppLocalizations.of(context)!),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              labelText:
                                  AppLocalizations.of(context)!.passwordLabel,
                              suffixIcon: IconButton(
                                icon: Icon(viewModel.passwordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: viewModel.togglePasswordVisibility,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (!viewModel.isLoginMode) ...[
                            TextFormField(
                              controller: viewModel.confirmPasswordController,
                              obscureText: !viewModel.confirmPasswordVisible,
                              validator: (v) => viewModel.validateConfirmPassword(
                                  v, AppLocalizations.of(context)!),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline),
                                labelText: AppLocalizations.of(context)!
                                    .confirmPasswordLabel,
                                suffixIcon: IconButton(
                                  icon: Icon(viewModel.confirmPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed:
                                      viewModel.toggleConfirmPasswordVisibility,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Role selection prompt.
                            Text(AppLocalizations.of(context)!.iAmA,
                                style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              children: UserRole.values.map((role) {
                                return ChoiceChip(
                                  label: Text(role == UserRole.patient
                                      ? AppLocalizations.of(context)!.patient
                                      : AppLocalizations.of(context)!.doctor),
                                  selected: viewModel.selectedRole == role,
                                  onSelected: (_) => viewModel.selectRole(role),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          CheckboxListTile(
                            title: Text(
                                AppLocalizations.of(context)!.keepMeLoggedIn),
                            value: viewModel.keepMeLoggedIn,
                            onChanged: (value) => viewModel.setKeepMeLoggedIn(value ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),

                          if (viewModel.errorMessage != null) ...[
                            Text(
                              viewModel.errorMessage!,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // No fixed height: the theme supplies the minimum
                          // tap target, and a tight SizedBox here would stop
                          // the button growing when the user scales text up.
                          ElevatedButton(
                            onPressed: viewModel.isBusy
                                ? null
                                : () =>
                                    _onAuthenticatePressed(context, viewModel),
                            child: Text(viewModel.isLoginMode
                                ? AppLocalizations.of(context)!.login
                                : AppLocalizations.of(context)!.signUp),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          if (viewModel.isLoginMode) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: viewModel.isBusy
                                    ? null
                                    : () => _showForgotPasswordDialog(
                                        context, viewModel),
                                child: Text(
                                    AppLocalizations.of(context)!.forgotPassword),
                              ),
                            ),
                          ],

                          TextButton(
                            onPressed:
                                viewModel.isBusy ? null : viewModel.toggleMode,
                            child: Text(viewModel.isLoginMode
                                ? AppLocalizations.of(context)!.dontHaveAccount
                                : AppLocalizations.of(context)!
                                    .alreadyHaveAccount),
                          ),

                          if (viewModel.isLoginMode) ...[
                            const Divider(height: AppSpacing.lg),
                            OutlinedButton.icon(
                              onPressed: viewModel.isBusy
                                  ? null
                                  : () => viewModel.continueAsGuest(
                                      AppLocalizations.of(context)!),
                              icon: const Icon(Icons.person_outline),
                              label: Text(
                                AppLocalizations.of(context)!.continueAsGuest,
                              ),
                            ),
                          ],

                          if (viewModel.isBusy) ...[
                            const SizedBox(height: 16),
                            const Center(child: CircularProgressIndicator()),
                          ],
                        ],
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

  @override
  LoginViewModel viewModelBuilder(BuildContext context) => LoginViewModel();

  void _showForgotPasswordDialog(
      BuildContext context, LoginViewModel viewModel) {
    final TextEditingController emailCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(AppLocalizations.of(context)!.passwordRecovery),
          content: TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.emailLabel,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                await viewModel.sendPasswordReset(
                    emailCtrl.text, AppLocalizations.of(context)!);
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.emailSent),
                    ),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.send),
            ),
          ],
        );
      },
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
