import 'package:flutter/material.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../../common/widgets/app_preferences_section.dart';
import '../../patience/patience_viewmodel.dart';

/// ProfileTab extracts the profile editing UI from PatienceView.
/// It shows current user information and basic edit fields.
class ProfileTab extends StatelessWidget {
  final PatienceViewModel viewModel;
  const ProfileTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.primaryContainer,
            // Generic profile avatar icon.
            child: const Icon(Icons.person, size: 48),
          ),
          const SizedBox(height: 16),
          Text(viewModel.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(viewModel.email, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          // Name editing field.
          TextField(
            controller: viewModel.nameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.editName,
            ),
          ),
          const SizedBox(height: 16),
          // Date of birth field with localized hint.
          TextField(
            controller: viewModel.dobController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.dateOfBirth,
              hintText: AppLocalizations.of(context)!.dobHint,
            ),
          ),
          const SizedBox(height: 16),
          // Medication field.
          TextField(
            controller: viewModel.medicationController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.addMedication,
            ),
          ),
          const SizedBox(height: 16),
          const AppPreferencesSection(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: viewModel.isBusy
                ? null
                : () async {
                    await viewModel.saveExtraProfileFields();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .profileSaved)),
                      );
                    }
                  },
            icon: const Icon(Icons.save_alt),
            label: Text(AppLocalizations.of(context)!.saveProfile),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: viewModel.isBusy
                ? null
                : () async {
                    await viewModel.saveName();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .savedSuccessfully)),
                      );
                    }
                  },
            icon: const Icon(Icons.save),
            label: Text(AppLocalizations.of(context)!.saveChanges),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.5,
              ),
            ),
            onPressed: () => viewModel.logout(context),
            icon: const Icon(Icons.logout),
            label: Text(AppLocalizations.of(context)!.logOut),
          ),
        ],
      ),
    );
  }
}
