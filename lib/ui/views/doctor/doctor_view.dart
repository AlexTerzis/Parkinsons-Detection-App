import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'doctor_viewmodel.dart';
import '../../../models/patient_report.dart';

/// Doctor dashboard with tab navigation similar to the patient view.
/// Tabs: profile editing, list of patient reports and a shared community feed.
class DoctorView extends StackedView<DoctorViewModel> {
  const DoctorView({super.key});

  @override
  Widget builder(
    BuildContext context,
    DoctorViewModel vm,
    Widget? child,
  ) {
    final ThemeData theme = Theme.of(context);

    if (vm.isBusy) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Profile', icon: Icon(Icons.person)),
              Tab(text: 'MyPatients', icon: Icon(Icons.people)),
              Tab(text: 'Community', icon: Icon(Icons.diversity_1)),
            ],
            indicatorColor: theme.colorScheme.primary,
          ),
        ),
        body: TabBarView(
          children: [
            _buildProfileTab(context, vm, theme),
            _buildPatientsTab(vm, theme),
            _buildCommunityTab(vm, theme),
          ],
        ),
      ),
    );
  }

  /// Profile information form allowing the doctor to update basic details.
  Widget _buildProfileTab(
      BuildContext context, DoctorViewModel vm, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: const Icon(Icons.person, size: 48),
          ),
          const SizedBox(height: 16),
          Text(vm.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(vm.email, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          TextField(
            controller: vm.nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: vm.specialtyController,
            decoration: const InputDecoration(
              labelText: 'Specialty',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: vm.locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: vm.isBusy
                ? null
                : () async {
                    await vm.saveProfile();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile saved')),
                      );
                    }
                  },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Displays patients that have sent reports to this doctor.
  Widget _buildPatientsTab(DoctorViewModel vm, ThemeData theme) {
    final patients = vm.reports.map((r) => r.patientId).toSet().toList();

    if (patients.isEmpty) {
      return const Center(child: Text('No patient reports yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final pid = patients[index];
        final reports =
            vm.reports.where((r) => r.patientId == pid).toList();
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(vm.patientName(pid)),
            subtitle: Text('Reports: ${reports.length}'),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                itemBuilder: (context, rIndex) {
                  final rep = reports[rIndex];
                  return ListTile(
                    title: Text('Sent: ${rep.sentAt.toLocal()}'),
                    subtitle: Text('Tests: ${rep.results.length}'),
                    onTap: () => _showReportDialog(context, rep),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: vm.noteController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Write notes for patient...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () async {
                    await vm.addNoteToReportForPatient(pid);
                  },
                  child: const Text('Add Note'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Simple list of community posts. Currently uses sample data.
  Widget _buildCommunityTab(DoctorViewModel vm, ThemeData theme) {
    if (vm.posts.isEmpty) {
      return const Center(child: Text('No posts yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vm.posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = vm.posts[index];
        return Card(
          child: ListTile(
            title: Text(post['author'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['date'] ?? ''),
                const SizedBox(height: 8),
                Text(post['content'] ?? ''),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, PatientReport report) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Report ${report.sentAt.toLocal()}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: report.results.map((r) {
                return ExpansionTile(
                  title: Text(r.type.name),
                  subtitle: Text('Score: ${(r.score * 100).round()}%'),
                  children: [
                    if (r.data.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No additional data'),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: r.data.entries
                              .map((e) => Text('${e.key}: ${e.value}'))
                              .toList(),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }

  @override
  DoctorViewModel viewModelBuilder(BuildContext context) => DoctorViewModel();

  @override
  void onViewModelReady(DoctorViewModel viewModel) {
    viewModel.init();
    super.onViewModelReady(viewModel);
  }
}
