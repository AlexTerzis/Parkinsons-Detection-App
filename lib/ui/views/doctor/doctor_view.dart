import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/patient_report.dart';
import '../../common/widgets/widgets.dart';
import 'doctor_viewmodel.dart';

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
    final l10n = AppLocalizations.of(context)!;

    if (vm.isBusy) {
      return const Scaffold(body: AppLoading());
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          // Scrollable so the longer Greek labels cannot overflow horizontally
          // once the user scales text up.
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.tabProfile, icon: const Icon(Icons.person)),
              Tab(text: l10n.tabMyPatients, icon: const Icon(Icons.people)),
              Tab(text: l10n.tabCommunity, icon: const Icon(Icons.diversity_1)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProfileTab(context, vm, theme, l10n),
            _buildPatientsTab(vm, theme, l10n),
            _buildCommunityTab(vm, theme, l10n),
          ],
        ),
      ),
    );
  }

  /// Profile information form allowing the doctor to update basic details.
  Widget _buildProfileTab(BuildContext context, DoctorViewModel vm,
      ThemeData theme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: const Icon(Icons.person, size: 48),
          ),
          const AppGap.md(),
          Text(vm.name, style: theme.textTheme.headlineSmall),
          const AppGap.xs(),
          Text(vm.email, style: theme.textTheme.bodyMedium),
          const AppGap.lg(),
          TextField(
            controller: vm.nameController,
            decoration: InputDecoration(
              labelText: l10n.nameLabel,
            ),
          ),
          const AppGap.md(),
          TextField(
            controller: vm.specialtyController,
            decoration: InputDecoration(
              labelText: l10n.specialtyLabel,
            ),
          ),
          const AppGap.md(),
          TextField(
            controller: vm.locationController,
            decoration: InputDecoration(
              labelText: l10n.locationLabel,
            ),
          ),
          const AppGap.md(),
          const AppPreferencesSection(),
          const AppGap.md(),
          ElevatedButton.icon(
            onPressed: vm.isBusy
                ? null
                : () async {
                    await vm.saveProfile();
                    if (context.mounted) {
                      AppFeedback.success(context, l10n.profileSaved);
                    }
                  },
            icon: const Icon(Icons.save),
            label: Text(l10n.save),
          ),
         const AppGap.lg(),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error, width: 1.5),
            ),
            onPressed: () => vm.logout(context),
            icon: const Icon(Icons.logout),
            label: Text(l10n.logOut),
          ),
          const AppGap.lg(),
          const AppFooter(),
        ],
      ),
    );
  }

  /// Displays patients that have sent reports to this doctor.
  Widget _buildPatientsTab(
      DoctorViewModel vm, ThemeData theme, AppLocalizations l10n) {
    final patients = vm.reports.map((r) => r.patientId).toSet().toList();

    if (patients.isEmpty) {
      return AppEmptyState(
        icon: Icons.folder_open,
        title: l10n.noPatientReportsYet,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: patients.length,
      separatorBuilder: (_, __) => const AppGap.sm(),
      itemBuilder: (context, index) {
        final pid = patients[index];
        final reports =
            vm.reports.where((r) => r.patientId == pid).toList();
        return Card(
          child: ExpansionTile(
            title: Text(vm.patientName(pid)),
            subtitle: Text(l10n.reportsCountLabel(reports.length)),
            childrenPadding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                itemBuilder: (context, rIndex) {
                  final rep = reports[rIndex];
                  return ListTile(
                    title: Text(l10n.sentAtLabel(rep.sentAt.toLocal().toString())),
                    subtitle: Text(l10n.testsCountLabel(rep.results.length)),
                    onTap: () => _showReportDialog(context, rep, l10n),
                  );
                },
              ),
              const AppGap.sm(),
              TextField(
                controller: vm.noteController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: l10n.writeNotesHint,
                ),
              ),
              const AppGap.xs(),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () async {
                    await vm.addNoteToReportForPatient(pid);
                  },
                  child: Text(l10n.addNote),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Simple list of community posts. Currently uses sample data.
  Widget _buildCommunityTab(
      DoctorViewModel vm, ThemeData theme, AppLocalizations l10n) {
    if (vm.posts.isEmpty) {
      return AppEmptyState(
        icon: Icons.forum_outlined,
        title: l10n.noPostsYet,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: vm.posts.length,
      separatorBuilder: (_, __) => const AppGap.sm(),
      itemBuilder: (context, index) {
        final post = vm.posts[index];
        return Card(
          child: ListTile(
            title: Text(post['author'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['date'] ?? ''),
                const AppGap.xs(),
                Text(post['content'] ?? ''),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportDialog(
      BuildContext context, PatientReport report, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.reportTitle(report.sentAt.toLocal().toString())),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: report.results.map((r) {
                return ExpansionTile(
                  title: Text(r.type.name),
                  subtitle: Text(l10n.scorePercent((r.concernScore * 100).round())),
                  children: [
                    if (r.data.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Text(l10n.noAdditionalData),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
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
              child: Text(l10n.close),
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
