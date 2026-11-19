import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';
import '../../../../models/app_user.dart';
import '../../../../models/appointment.dart';
import '../../../common/appointment_display.dart';
import '../../patience/patience_viewmodel.dart';
import '../widgets/appointment_sheet.dart';
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            // The send no longer blanks the screen while it runs, so the
            // progress and the outcome have to be said here — otherwise the
            // button appears to do nothing either way.
            busy: viewModel.isSendingResults,
            onPressed: viewModel.isSendingResults
                ? null
                : () => _sendToPrimary(context, doctor),
          ),
          const AppGap.xs(),
          _secondaryAction(
            label: l10n.diagnoses,
            icon: Icons.receipt_long,
            onPressed: () => _showDiagnoses(context),
          ),
          const AppGap.xs(),
          _secondaryAction(
            label: l10n.bookAppointment,
            icon: Icons.event_available,
            onPressed: () => showAppointmentSheet(context, viewModel, doctor),
          ),
          const AppGap.xs(),
          _secondaryAction(
            label: l10n.getSecondOpinion,
            icon: Icons.group,
            onPressed: () => _pickSecondOpinion(context),
          ),
          const AppGap.xs(),
          _secondaryAction(
            label: l10n.changeDoctor,
            icon: Icons.swap_horiz,
            onPressed: () => _pickPrimaryDoctor(context),
          ),
          const AppGap.xs(),
          // Destructive, so it is styled apart from the others and confirmed.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              onPressed: () => _leaveDoctor(context),
              icon: const Icon(Icons.person_remove_outlined),
              label: Text(l10n.leaveDoctor),
            ),
          ),
        ],
        const AppGap.lg(),
        _appointments(context),
        const AppGap.lg(),
        _secondOpinions(context),
      ],
    );
  }

  Future<void> _leaveDoctor(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final doctor = viewModel.primaryDoctor;
    if (doctor == null) return;
    final name = doctor.name ?? doctor.email;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leaveDoctorConfirmTitle(name)),
        // Spells out what does and does not happen. Reports already sent stay
        // with the doctor, and a patient should not have to guess at that.
        content: Text(l10n.leaveDoctorConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.leaveDoctorConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await viewModel.leavePrimaryDoctor();
    if (context.mounted) AppFeedback.success(context, l10n.leftDoctor(name));
  }

  Widget _appointments(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final upcoming = viewModel.upcomingAppointments;
    final past = viewModel.pastAppointments;
    if (upcoming.isEmpty && past.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.apptUpcoming),
        for (final appointment in [...upcoming, ...past])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _appointmentCard(context, appointment),
          ),
      ],
    );
  }

  Widget _appointmentCard(BuildContext context, Appointment appointment) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppointmentHeader(
            time: formatAppointmentTime(appointment.effectiveTime),
            status: appointment.status,
          ),
          Text(
            appointment.doctorDisplayName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (appointment.doctorMessage != null) ...[
            const AppGap.xs(),
            Text(l10n.apptDoctorMessage, style: theme.textTheme.labelMedium),
            Text(appointment.doctorMessage!),
          ],
          // A time the doctor suggested under the old flow. Shown, but no
          // longer one-tap acceptable: there is no request to make any more,
          // so the patient takes the time off the doctor's calendar like any
          // other. Only ever appears on appointments written before booking
          // became a calendar.
          if (appointment.status == AppointmentStatus.declined &&
              appointment.proposedFor != null) ...[
            const AppGap.xs(),
            Text(l10n.apptProposedTime(
                formatAppointmentTime(appointment.proposedFor!))),
          ],
          if (appointment.status.isOpen) ...[
            const AppGap.xs(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _cancelAppointment(context, appointment),
                icon: const Icon(Icons.close),
                label: Text(l10n.apptCancel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendToPrimary(BuildContext context, AppUser doctor) async {
    final l10n = AppLocalizations.of(context)!;

    if (viewModel.clinicalResults.isEmpty) {
      AppFeedback.info(context, l10n.completeOneTest);
      return;
    }

    try {
      await viewModel.sendResultsToPrimaryDoctor();
    } catch (e) {
      if (context.mounted) AppFeedback.error(context, '$e');
      return;
    }
    if (context.mounted) {
      AppFeedback.success(
        context,
        l10n.resultsSentTo(doctor.name ?? doctor.email),
      );
    }
  }

  Future<void> _cancelAppointment(
    BuildContext context,
    Appointment appointment,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.apptCancelConfirmTitle),
        content: Text(l10n.apptCancelConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.close),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.apptCancel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Cancelling gives the time back to the doctor's calendar, so someone
      // else can have it.
      await viewModel.cancelAppointment(appointment);
    } catch (e) {
      if (context.mounted) AppFeedback.error(context, '$e');
      return;
    }
    if (context.mounted) {
      AppFeedback.success(context, l10n.apptCancelledToast);
    }
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

    if (viewModel.clinicalResults.isEmpty) {
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
