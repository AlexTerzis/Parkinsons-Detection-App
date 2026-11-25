import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/appointment.dart';
import '../../../models/patient_report.dart';
import '../../common/appointment_display.dart';
import '../../common/widgets/widgets.dart';
import 'doctor_viewmodel.dart';
import 'widgets/report_sections.dart';

/// One patient, in full: their reports, the tests inside them, and their
/// appointments.
///
/// A screen rather than an expanding row in the patient list. The list version
/// put a note field inside every row while sharing a single controller between
/// them, so typing a note for one patient showed it in all of them; and the
/// note was attached to whichever of that patient's reports came first, which
/// after ordering meant the newest, not the one being read. Both problems
/// disappear once a patient is a screen with its own state and notes attach to
/// the report they were written against.
class PatientDetailView extends StatefulWidget {
  const PatientDetailView({
    super.key,
    required this.viewModel,
    required this.patientId,
  });

  final DoctorViewModel viewModel;
  final String patientId;

  @override
  State<PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<PatientDetailView> {
  /// One controller for this screen, and therefore for this patient.
  final TextEditingController _note = TextEditingController();

  /// The report a note will be attached to. Defaults to the most recent, but
  /// the doctor can point it at an older one.
  String? _noteTarget;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<PatientReport> get _reports => widget.viewModel.reports
      .where((r) => r.patientId == widget.patientId)
      .toList(growable: false);

  Future<void> _addNote() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _note.text.trim();
    final target = _noteTarget ?? (_reports.isEmpty ? null : _reports.first.id);
    if (text.isEmpty || target == null) return;

    setState(() => _saving = true);
    try {
      await widget.viewModel.addNoteToReport(reportId: target, note: text);
      if (!mounted) return;
      _note.clear();
      AppFeedback.success(context, l10n.addNote);
    } catch (e) {
      if (mounted) AppFeedback.error(context, '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reports = _reports;
    final appointments =
        widget.viewModel.appointmentsFor(widget.patientId);

    final name = reports.isEmpty
        ? widget.viewModel.patientName(widget.patientId)
        : reports.first.displayName;

    return AppScaffold(
      title: name,
      // The body is a ListView, so it scrolls itself. Left on the default,
      // AppScaffold wraps it in an IntrinsicHeight that a viewport cannot
      // satisfy, and the whole body silently fails to lay out — the title
      // renders and everything below it is blank.
      scrollable: false,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (appointments.isNotEmpty) ...[
            SectionHeader(l10n.apptUpcoming),
            for (final appointment in appointments)
              _appointmentRow(context, appointment),
            const AppGap.md(),
          ],
          SectionHeader(l10n.testResults),
          if (reports.isEmpty)
            AppEmptyState(
              icon: Icons.folder_open,
              title: l10n.noPatientReportsYet,
            )
          else
            for (final report in reports) _reportSection(context, report),
          const AppGap.md(),
          SectionHeader(l10n.addNote),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (reports.length > 1) ...[
                  // Which report a note belongs to is the doctor's call, not
                  // whichever happened to sort first.
                  DropdownButtonFormField<String>(
                    initialValue: _noteTarget ?? reports.first.id,
                    decoration:
                        InputDecoration(labelText: l10n.reportsCountLabel(
                            reports.length)),
                    items: [
                      for (final report in reports)
                        DropdownMenuItem<String>(
                          value: report.id,
                          child: Text(
                            l10n.sentAtLabel(_shortDate(report.sentAt)),
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _noteTarget = value),
                  ),
                  const AppGap.sm(),
                ],
                TextField(
                  controller: _note,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(hintText: l10n.writeNotesHint),
                ),
                const AppGap.sm(),
                PrimaryAction(
                  label: l10n.addNote,
                  icon: Icons.note_add_outlined,
                  busy: _saving,
                  onPressed: reports.isEmpty || _saving ? null : _addNote,
                ),
              ],
            ),
          ),
          const AppGap.lg(),
        ],
      ),
    );
  }

  /// One report, read the way a clinician would work through it.
  ///
  /// Ordered by how much weight each part can carry. The baseline block leads:
  /// MoCA and FAB have published cut-offs, and the symptom questionnaire is
  /// what the patient actually reports. Then what the reasoning engine made of
  /// that. Then this app's own repeated sensor measures, collapsed to a level
  /// and a direction rather than listed reading by reading — their bands are
  /// provisional, and a long list of them next to a MoCA score implies a
  /// parity that does not exist. Last, what none of it could measure, which a
  /// list of results silently omits.
  Widget _reportSection(BuildContext context, PatientReport report) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            l10n.sentAtLabel(_shortDate(report.sentAt)),
            style: theme.textTheme.labelLarge,
          ),
        ),
        BaselineAssessments(report: report),
        const AppGap.xs(),
        ReasoningCard(report: report),
        const AppGap.xs(),
        DiagnosisCard(report: report),
        const AppGap.xs(),
        RepeatedMeasures(report: report),
        const AppGap.xs(),
        AssessmentGaps(report: report),
        if (report.notes.isNotEmpty) ...[
          const AppGap.xs(),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.doctorNotes, style: theme.textTheme.labelMedium),
                for (final note in report.notes) ...[
                  const AppGap.xxs(),
                  Text(note.note),
                  Text(
                    _shortDate(note.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _appointmentRow(BuildContext context, Appointment appointment) {
    return AppTileCard(
      icon: Icons.event,
      title: formatAppointmentTime(appointment.effectiveTime),
      // A ListTile hands its trailing whatever width it asks for and squeezes
      // the title with what remains, so at the largest text size a long status
      // label left the date nothing to sit in. Capping the chip makes it wrap
      // its own label instead, which costs a line of height rather than
      // overflowing the row.
      trailing: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.35,
        ),
        child: AppointmentStatusChip(status: appointment.status),
      ),
    );
  }

  static String _shortDate(DateTime when) {
    final local = when.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}
