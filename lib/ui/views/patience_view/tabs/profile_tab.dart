import 'package:flutter/material.dart';

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
            child: const Icon(Icons.person, size: 48),
          ),
          const SizedBox(height: 16),
          Text(viewModel.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(viewModel.email, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          TextField(
            controller: viewModel.nameController,
            decoration: const InputDecoration(
              labelText: 'Edit Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: viewModel.dobController,
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              border: OutlineInputBorder(),
              hintText: 'yyyy-mm-dd',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: viewModel.medicationController,
            decoration: const InputDecoration(
              labelText: 'Add Medication',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: viewModel.isBusy
                ? null
                : () async {
                    await viewModel.saveExtraProfileFields();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile saved')),
                      );
                    }
                  },
            icon: const Icon(Icons.save_alt),
            label: const Text('Save Profile'),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: viewModel.isBusy
                ? null
                : () async {
                    await viewModel.saveName();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved successfully')),
                      );
                    }
                  },
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.red, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => viewModel.logout(context),
            child: const Text(
              'LOG OUT',
              style: TextStyle(
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
