import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../services/authentication_service.dart';
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
              colors: [Color(0xff4e54c8), Color(0xff8f94fb)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            viewModel.isLoginMode
                                ? 'Welcome Back'
                                : 'Create Account',
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Name (sign-up only)
                          if (!viewModel.isLoginMode) ...[
                            TextFormField(
                              controller: viewModel.nameController,
                              validator: viewModel.validateName,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email
                          TextFormField(
                            controller: viewModel.emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: viewModel.validateEmail,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined),
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: viewModel.passwordController,
                            obscureText: !viewModel.passwordVisible,
                            validator: viewModel.validatePassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(viewModel.passwordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: viewModel.togglePasswordVisibility,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Confirm password for sign-up
                          if (!viewModel.isLoginMode) ...[
                            TextFormField(
                              controller: viewModel.confirmPasswordController,
                              obscureText: !viewModel.confirmPasswordVisible,
                              validator: viewModel.validateConfirmPassword,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline),
                                labelText: 'Confirm Password',
                                border: const OutlineInputBorder(),
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

                            // Role selection modern chips
                            Text('I am a', style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              children: UserRole.values.map((role) {
                                return ChoiceChip(
                                  label: Text(role == UserRole.patient
                                      ? 'Patient'
                                      : 'Doctor'),
                                  selected: viewModel.selectedRole == role,
                                  onSelected: (_) => viewModel.selectRole(role),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (viewModel.errorMessage != null) ...[
                            Text(
                              viewModel.errorMessage!,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Primary action button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: viewModel.isBusy
                                  ? null
                                  : () => _onAuthenticatePressed(viewModel),
                              child: Text(
                                  viewModel.isLoginMode ? 'Login' : 'Sign Up'),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (viewModel.isLoginMode) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: viewModel.isBusy
                                    ? null
                                    : () => _showForgotPasswordDialog(
                                        context, viewModel),
                                child: const Text('Forgot password?'),
                              ),
                            ),
                          ],

                          TextButton(
                            onPressed:
                                viewModel.isBusy ? null : viewModel.toggleMode,
                            child: Text(viewModel.isLoginMode
                                ? "Don't have an account? Sign Up"
                                : 'Already have an account? Login'),
                          ),

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
          title: const Text('Password Recovery'),
          content: TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await viewModel.sendPasswordReset(emailCtrl.text);
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'If the email exists, a reset link has been sent.'),
                  ));
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  void _onAuthenticatePressed(LoginViewModel viewModel) {
    if (_formKey.currentState?.validate() ?? false) {
      viewModel.authenticate(
        email: viewModel.emailController.text,
        password: viewModel.passwordController.text,
        confirmPassword: viewModel.confirmPasswordController.text,
      );
    }
  }
}
