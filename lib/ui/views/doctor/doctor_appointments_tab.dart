import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/appointment.dart';
import '../../../models/availability_slot.dart';
import '../../common/appointment_display.dart';
import '../../common/widgets/widgets.dart';
import 'doctor_viewmodel.dart';

/// The doctor's appointment book, as a calendar they publish onto.
///
/// The doctor says when they are free and patients take those times; there is
/// no queue of requests to work through, because a booking is settled the
/// moment it is made. What is left of the old flow is the pending section at
/// the top, which appears only if a request written under it is still waiting —
/// nothing creates those any more, and stranding the ones that exist would mean
/// a patient waiting on an answer that could never come.
class DoctorAppointmentsTab extends StatefulWidget {
  const DoctorAppointmentsTab({super.key, required this.viewModel});

  final DoctorViewModel viewModel;

  @override
  State<DoctorAppointmentsTab> createState() => _DoctorAppointmentsTabState();
}

class _DoctorAppointmentsTabState extends State<DoctorAppointmentsTab> {
  late DateTime _month = DateTime.now();
  late DateTime _selectedDay = MonthCalendar.dayOf(DateTime.now());

  DoctorViewModel get _vm => widget.viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offCalendar = _vm.appointmentsOffCalendar;
    final onDay = _vm.slotsOn(_selectedDay);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (_vm.slotsError != null) ...[
          AppErrorState(message: l10n.apptCalendarError),
          const AppGap.md(),
        ],
        if (offCalendar.isNotEmpty) ...[
          SectionHeader(l10n.apptPending),
          for (final appointment in offCalendar)
            _OffCalendarCard(viewModel: _vm, appointment: appointment),
          const AppGap.md(),
        ],
        SectionHeader(l10n.apptCalendar),
        MonthCalendar(
          month: _month,
          selectedDay: _selectedDay,
          onMonthChanged: (value) => setState(() => _month = value),
          onSelectDay: (day) => setState(() => _selectedDay = day),
          markerCount: _vm.slotCountOn,
          // Green where someone is actually coming in, so a booked day stands
          // out from one that is merely on offer.
          markerColor: (day) => _vm.slotsOn(day).any((s) => !s.isOpen)
              ? AppSemanticColors.of(context).success
              : null,
        ),
        const AppGap.sm(),
        OutlinedButton.icon(
          onPressed: _addTimes,
          icon: const Icon(Icons.more_time),
          label: Text(l10n.apptAddTimes),
        ),
        const AppGap.md(),
        SectionHeader(
          MaterialLocalizations.of(context).formatMediumDate(_selectedDay),
        ),
        if (onDay.isEmpty)
          AppEmptyState(
            icon: Icons.event_available,
            title: l10n.apptNoSlotsOnDay,
          )
        else
          for (final slot in onDay) _slotTile(context, slot),
        const AppGap.lg(),
      ],
    );
  }

  Widget _slotTile(BuildContext context, AvailabilitySlot slot) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final time = _formatTime(context, slot.start);

    if (slot.isOpen) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: AppTileCard(
          icon: Icons.schedule,
          title: time,
          subtitle: l10n.apptSlotOpen,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.apptRemoveSlot,
            onPressed: () => _withdraw(slot),
          ),
        ),
      );
    }

    final appointment = _vm.appointmentForSlot(slot);
    final status = appointment?.status ?? AppointmentStatus.confirmed;
    final accent = appointmentStatusColor(context, status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: DecoratedBox(
        // A left edge in the status colour. Reinforces the chip beside it
        // without repainting the whole card, which would fight the text.
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accent, width: 4)),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppointmentHeader(time: time, status: status),
              Text(
                // The name comes off the appointment itself; the doctor cannot
                // read the patient's profile to look it up.
                appointment?.patientDisplayName ?? l10n.apptSlotBooked,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (appointment?.patientNote != null) ...[
                const AppGap.xs(),
                Text(l10n.apptPatientNote, style: theme.textTheme.labelMedium),
                Text(appointment!.patientNote!),
              ],
              if (appointment != null &&
                  appointment.status == AppointmentStatus.confirmed) ...[
                const AppGap.xs(),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.xs,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _vm.markAppointmentCompleted(appointment.id),
                      icon: const Icon(Icons.done_all),
                      label: Text(l10n.apptMarkCompleted),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () => _cancelBooking(appointment),
                      icon: const Icon(Icons.event_busy),
                      label: Text(l10n.apptCancel),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _withdraw(AvailabilitySlot slot) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _vm.withdrawSlot(slot.id);
    } catch (e) {
      if (mounted) AppFeedback.error(context, '$e');
      return;
    }
    if (mounted) AppFeedback.success(context, l10n.apptSlotRemoved);
  }

  Future<void> _cancelBooking(Appointment appointment) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.apptCancelConfirmTitle),
        content: Text(l10n.apptCancelBookingBody),
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
            child: Text(l10n.apptCancel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _vm.cancelBooking(appointment);
    } catch (e) {
      if (mounted) AppFeedback.error(context, '$e');
      return;
    }
    if (mounted) AppFeedback.success(context, l10n.apptCancelledToast);
  }

  /// Publishes a run of times on the selected day.
  Future<void> _addTimes() async {
    final l10n = AppLocalizations.of(context)!;

    final range = await showDialog<_TimeRange>(
      context: context,
      builder: (_) => _AddTimesDialog(day: _selectedDay),
    );
    if (range == null || !mounted) return;

    try {
      final added = await _vm.publishSlots(
        day: _selectedDay,
        from: range.from,
        to: range.to,
        durationMinutes: range.durationMinutes,
      );
      if (!mounted) return;
      if (added == 0) {
        // Not an error — the doctor asked for times that are already offered.
        AppFeedback.info(context, l10n.apptNothingToPublish);
      } else {
        AppFeedback.success(context, l10n.apptPublished(added));
      }
    } catch (e) {
      if (mounted) AppFeedback.error(context, '$e');
    }
  }
}

/// A run of free time, and how finely to cut it up.
class _TimeRange {
  const _TimeRange({
    required this.from,
    required this.to,
    required this.durationMinutes,
  });

  final Duration from;
  final Duration to;
  final int durationMinutes;
}

class _AddTimesDialog extends StatefulWidget {
  const _AddTimesDialog({required this.day});

  final DateTime day;

  @override
  State<_AddTimesDialog> createState() => _AddTimesDialogState();
}

class _AddTimesDialogState extends State<_AddTimesDialog> {
  TimeOfDay _from = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 13, minute: 0);
  int _durationMinutes = AvailabilitySlot.defaultDurationMinutes;

  static const List<int> _durations = <int>[15, 20, 30, 45, 60];

  Duration get _fromDuration => Duration(hours: _from.hour, minutes: _from.minute);
  Duration get _toDuration => Duration(hours: _to.hour, minutes: _to.minute);

  Future<void> _pick({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _from : _to,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizations = MaterialLocalizations.of(context);
    final valid = _toDuration > _fromDuration;

    // How many slots this would come to, shown before committing: "9 to 13
    // every 30 minutes" is easier to sanity-check as "8 appointments" than as
    // two times and an interval.
    final count = valid
        ? ((_toDuration - _fromDuration).inMinutes ~/ _durationMinutes)
        : 0;

    return AlertDialog(
      title: Text(l10n.apptAddTimesTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(localizations.formatMediumDate(widget.day)),
          const AppGap.sm(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.play_arrow),
            title: Text(l10n.apptFrom),
            subtitle: Text(_from.format(context)),
            onTap: () => _pick(isStart: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.stop),
            title: Text(l10n.apptTo),
            subtitle: Text(_to.format(context)),
            onTap: () => _pick(isStart: false),
          ),
          const AppGap.sm(),
          DropdownButtonFormField<int>(
            initialValue: _durationMinutes,
            decoration: InputDecoration(labelText: l10n.apptSlotLength),
            items: [
              for (final minutes in _durations)
                DropdownMenuItem<int>(
                  value: minutes,
                  child: Text(l10n.apptMinutes(minutes)),
                ),
            ],
            onChanged: (value) =>
                setState(() => _durationMinutes = value ?? _durationMinutes),
          ),
          const AppGap.sm(),
          Text(
            valid ? l10n.apptWillPublish(count) : l10n.apptEndBeforeStart,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: valid
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.error,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: count == 0
              ? null
              : () => Navigator.of(context).pop(
                    _TimeRange(
                      from: _fromDuration,
                      to: _toDuration,
                      durationMinutes: _durationMinutes,
                    ),
                  ),
          child: Text(l10n.apptPublish),
        ),
      ],
    );
  }
}

/// An open appointment with no slot behind it, from the old request-and-confirm
/// flow.
///
/// Kept so those are not stranded when the calendar cannot show them. A request
/// still gets an answer; one already confirmed can be marked done. No "suggest
/// another time": the patient side that accepted a counter-offer is gone, so
/// proposing one would be a message with nothing on the other end of it.
class _OffCalendarCard extends StatelessWidget {
  const _OffCalendarCard({
    required this.viewModel,
    required this.appointment,
  });

  final DoctorViewModel viewModel;
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppointmentHeader(
              time: formatAppointmentTime(appointment.effectiveTime),
              status: appointment.status,
            ),
            Text(
              appointment.patientDisplayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (appointment.patientNote != null) ...[
              const AppGap.xs(),
              Text(l10n.apptPatientNote, style: theme.textTheme.labelMedium),
              Text(appointment.patientNote!),
            ],
            const AppGap.sm(),
            if (appointment.status.needsDoctor)
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  FilledButton.icon(
                    onPressed: () => _answer(context, confirm: true),
                    icon: const Icon(Icons.check),
                    label: Text(l10n.apptConfirm),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _answer(context, confirm: false),
                    icon: const Icon(Icons.close),
                    label: Text(l10n.apptDecline),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      viewModel.markAppointmentCompleted(appointment.id),
                  icon: const Icon(Icons.done_all),
                  label: Text(l10n.apptMarkCompleted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _answer(BuildContext context, {required bool confirm}) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      if (confirm) {
        await viewModel.confirmAppointment(appointment.id);
      } else {
        await viewModel.declineAppointment(appointment.id);
      }
    } catch (e) {
      if (context.mounted) AppFeedback.error(context, '$e');
      return;
    }

    if (context.mounted) {
      AppFeedback.success(
        context,
        confirm ? l10n.apptConfirmedToast : l10n.apptDeclinedToast,
      );
    }
  }
}

/// The clock time, in the reader's own zone and their locale's convention.
String _formatTime(BuildContext context, DateTime when) =>
    TimeOfDay.fromDateTime(when.toLocal()).format(context);
