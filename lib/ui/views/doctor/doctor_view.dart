import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../l10n/app_localizations.dart';
import '../../common/widgets/widgets.dart';
import '../../../models/appointment.dart';
import 'doctor_appointments_tab.dart';
import 'doctor_viewmodel.dart';
import 'patient_detail_view.dart';

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
      length: 4,
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
              Tab(
                text: l10n.apptTabTitle,
                icon: const Icon(Icons.event_available),
              ),
              Tab(text: l10n.tabCommunity, icon: const Icon(Icons.diversity_1)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProfileTab(context, vm, theme, l10n),
            _buildPatientsTab(vm, theme, l10n),
            DoctorAppointmentsTab(viewModel: vm),
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

  /// Displays patients this doctor has heard from.
  ///
  /// Each row opens a screen rather than expanding in place. The expanding
  /// version carried a note field in every row backed by one shared controller,
  /// so a note typed for one patient appeared in all of them, and it attached
  /// to whichever of that patient's reports sorted first rather than the one
  /// being read.
  ///
  /// Patients are drawn from reports *and* appointments: someone who booked but
  /// has not sent results yet is still a patient, and used to be invisible.
  Widget _buildPatientsTab(
      DoctorViewModel vm, ThemeData theme, AppLocalizations l10n) {
    final patients = <String>{
      ...vm.reports.map((r) => r.patientId),
      ...vm.appointments.map((a) => a.patientId),
    }.toList();

    // A failed query is reported as a failure. Falling through to the empty
    // state made a permissions or index error look like a doctor with no
    // patients, which is the one reading that suggests doing nothing about it.
    if (vm.reportsError != null && patients.isEmpty) {
      return AppErrorState(message: l10n.reportsLoadFailed);
    }

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
        final reports = vm.reports.where((r) => r.patientId == pid).length;
        final pending = vm.appointments
            .where((a) => a.patientId == pid && a.status.needsDoctor)
            .length;

        return AppTileCard(
          icon: Icons.person_outline,
          title: vm.patientName(pid),
          subtitle: l10n.reportsCountLabel(reports),
          // Surfaces a waiting request on the patient row, so a doctor working
          // through their list does not have to visit the other tab to find out
          // which of them is waiting on an answer.
          trailing: pending > 0
              ? Chip(label: Text(l10n.apptPending))
              : const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  PatientDetailView(viewModel: vm, patientId: pid),
            ),
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

  @override
  DoctorViewModel viewModelBuilder(BuildContext context) => DoctorViewModel();

  @override
  void onViewModelReady(DoctorViewModel viewModel) {
    viewModel.init();
    super.onViewModelReady(viewModel);
  }
}
