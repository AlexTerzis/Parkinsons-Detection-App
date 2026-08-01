import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';
import '../../patience/patience_viewmodel.dart';
import '../widgets/doctor_picker_sheet.dart';

/// Lets the patient manage their doctor and read the feedback they send back.
class DoctorTab extends StatelessWidget {
  const DoctorTab({super.key, required this.viewModel});

  final PatienceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final doctor = viewModel.primaryDoctor;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (doctor == null)
          AppEmptyState(
            icon: Icons.medical_information_outlined,
            title: l10n.noDoctorSelected,
            action: FilledButton.icon(
              onPressed: () => _pickPrimaryDoctor(context),
              icon: const Icon(Icons.person_add),
              label: Text(l10n.selectDoctor),
            ),
          )
        else ...[
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name ?? doctor.email,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_details(context) != null) ...[
                        const AppGap.xxs(),
                        Text(
                          _details(context)!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const AppGap.wide(AppSpacing.xs),
                Chip(label: Text(l10n.myDoctor)),
              ],
            ),
          ),
          const AppGap.md(),
          PrimaryAction(
            label: l10n.sendResults,
            icon: Icons.send,
            onPressed: viewModel.sendResultsToPrimaryDoctor,
          ),
          const AppGap.xs(),
          _secondaryAction(
            label: l10n.diagnoses,
            icon: Icons.receipt_long,
            onPressed: () => _showDiagnoses(context),
          ),
          const AppGap.xs(),
          _secondaryAction(
            label: l10n.getSecondOpinion,
            icon: Icons.group,
            onPressed: () => _pickSecondOpinion(context),
          ),
        ],
        const AppGap.lg(),
        _secondOpinions(context),
      ],
    );
  }

  /// Specialty and location, joined only where both exist.
  String? _details(BuildContext context) {
    final doctor = viewModel.primaryDoctor;
    if (doctor == null) return null;
    final parts = [doctor.specialty, doctor.location]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(' • ');
  }

  Widget _secondaryAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  void _pickPrimaryDoctor(BuildContext context) {
    // No confirmation and no "complete a test first" gate: choosing a doctor
    // sends nothing, so neither applies.
    showDoctorPicker(
      context,
      viewModel,
      onSelect: (doctor) => viewModel.setPrimaryDoctor(doctor.uid),
    );
  }

  void _pickSecondOpinion(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (viewModel.results.isEmpty) {
      AppFeedback.info(context, l10n.completeOneTest);
      return;
    }

    showDoctorPicker(
      context,
      viewModel,
      excludePrimary: true,
      onSelect: (doctor) => viewModel.sendResultsToDoctor(doctor.uid),
      confirmationMessage: (doctor) =>
          l10n.resultsSentTo(doctor.name ?? doctor.email),
    );
  }

  Widget _secondOpinions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ids = viewModel.secondOpinionDoctorIds;
    if (ids.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.secondOpinions),
        for (final id in ids)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Card(
              child: ExpansionTile(
                title: Text(viewModel.doctorById(id)?.name ?? id),
                children: [
                  for (final report
                      in viewModel.reports.where((r) => r.doctorId == id))
                    ListTile(
                      title: Text(report.status.name.toUpperCase()),
                      subtitle: Text(
                        report.sentAt.toLocal().toString().split('.').first,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showDiagnoses(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(l10n.diagnoses),
                Expanded(
                  child: viewModel.reports.isEmpty
                      ? AppEmptyState(
                          icon: Icons.inbox_outlined,
                          title: l10n.noDoctorFeedback,
                        )
                      : ListView.separated(
                          itemCount: viewModel.reports.length,
                          separatorBuilder: (_, __) => const AppGap.xs(),
                          itemBuilder: (context, index) {
                            final report = viewModel.reports[index];
                            return Card(
                              child: ExpansionTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(
                                  viewModel.doctorName(report.doctorId),
                                ),
                                subtitle:
                                    Text(report.status.name.toUpperCase()),
                                children: [
                                  if (report.notes.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.md,
                                      ),
                                      child: Text(l10n.noNotesYet),
                                    )
                                  else
                                    for (final note in report.notes)
                                      ListTile(
                                        leading: const Icon(Icons.note),
                                        title: Text(note.note),
                                        subtitle: Text(
                                          note.createdAt
                                              .toIso8601String()
                                              .substring(0, 10),
                                        ),
                                      ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
