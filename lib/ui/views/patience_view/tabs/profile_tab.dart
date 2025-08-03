import 'package:flutter/material.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'package:parkinsondetetion/app/app.locator.dart';
import 'package:parkinsondetetion/services/localization_service.dart';

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
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          // Date of birth field with localized hint.
          TextField(
            controller: viewModel.dobController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.dateOfBirth,
              border: const OutlineInputBorder(),
              hintText: AppLocalizations.of(context)!.dobHint,
            ),
          ),
          const SizedBox(height: 16),
          // Medication field.
          TextField(
            controller: viewModel.medicationController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.addMedication,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          // Language picker uses localization service to change app-wide locale.
          _LanguagePicker(localizationService: locator<LocalizationService>()),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.red, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => viewModel.logout(context),
            child: Text(
              AppLocalizations.of(context)!.logOut,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown that lets the user choose the desired app language.
class _LanguagePicker extends StatelessWidget {
  final LocalizationService localizationService;
  const _LanguagePicker({required this.localizationService});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(AppLocalizations.of(context)!.language),
        const SizedBox(width: 16),
        DropdownButton<Locale>(
          value: localizationService.locale,
          onChanged: (locale) {
            if (locale != null) {
              localizationService.setLocale(locale);
            }
          },
          items: [
            DropdownMenuItem(
              value: const Locale('en'),
              child: Text(AppLocalizations.of(context)!.english),
            ),
            DropdownMenuItem(
              value: const Locale('el'),
              child: Text(AppLocalizations.of(context)!.greek),
            ),
          ],
        ),
      ],
    );
  }
}
