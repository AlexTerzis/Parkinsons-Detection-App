import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/app_user.dart';
import '../../../../models/availability_slot.dart';
import '../../../../services/availability_service.dart';
import '../../../common/widgets/widgets.dart';
import '../../patience/patience_viewmodel.dart';

/// Shows the doctor's calendar and lets the patient take a time off it.
///
/// The patient no longer proposes a time and waits to hear back. They see when
/// the doctor is actually free and book it, and it is booked the moment they
/// tap — there is nothing to confirm, because the doctor offered the time in
/// the first place. The old direction left every booking sitting unanswered
/// until the doctor happened to look, and gave the patient no idea whether the
/// time they picked stood a chance.
Future<void> showAppointmentSheet(
  BuildContext context,
  PatienceViewModel viewModel,
  AppUser doctor,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AppointmentSheet(viewModel: viewModel, doctor: doctor),
  );
}

class _AppointmentSheet extends StatefulWidget {
  const _AppointmentSheet({required this.viewModel, required this.doctor});

  final PatienceViewModel viewModel;
  final AppUser doctor;

  @override
  State<_AppointmentSheet> createState() => _AppointmentSheetState();
}

class _AppointmentSheetState extends State<_AppointmentSheet> {
  final TextEditingController _reason = TextEditingController();

  /// Held for the life of the sheet rather than rebuilt in `build`: a fresh
  /// stream on every rebuild would re-subscribe on each keystroke in the reason
  /// field, and the calendar would flash back to its loading state each time.
  late final Stream<List<AvailabilitySlot>> _slots =
      widget.viewModel.openSlotsFor(widget.doctor.uid);

  /// Null until the patient moves the calendar themselves, at which point it
  /// takes over. Left null it follows the first day with times on it, so a
  /// doctor whose next opening is two months out does not present an empty
  /// current month with nothing to say why.
  DateTime? _month;
  DateTime? _selectedDay;
  String? _bookingSlotId;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _book(AvailabilitySlot slot) async {
    final l10n = AppLocalizations.of(context)!;
    final note = _reason.text.trim();

    setState(() => _bookingSlotId = slot.id);
    try {
      await widget.viewModel.bookSlot(
        slot,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      AppFeedback.success(
        context,
        l10n.apptBooked(
          widget.doctor.name ?? widget.doctor.email,
          _formatSlot(context, slot),
        ),
      );
    } on SlotUnavailableException catch (e) {
      // Stay on the sheet. The stream is already dropping the slot that went,
      // so the patient sees what is left and can take another.
      if (!mounted) return;
      setState(() => _bookingSlotId = null);
      AppFeedback.error(
        context,
        e.alreadyBooked ? l10n.apptSlotTaken : l10n.apptSlotWithdrawn,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _bookingSlotId = null);
      AppFeedback.error(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: StreamBuilder<List<AvailabilitySlot>>(
              stream: _slots,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AppErrorState(message: '${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const AppLoading();
                }

                final open = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(l10n.apptPickSlotTitle),
                    Text(
                      widget.doctor.name ?? widget.doctor.email,
                      style: theme.textTheme.titleMedium,
                    ),
                    const AppGap.sm(),
                    Expanded(
                      child: open.isEmpty
                          ? AppEmptyState(
                              icon: Icons.event_busy,
                              title: l10n.apptNoOpenSlots,
                            )
                          : _calendarAndTimes(context, open),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendarAndTimes(
    BuildContext context,
    List<AvailabilitySlot> open,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final byDay = AvailabilityService.groupByDay(open);

    // Opens on the first day with something on it, so the patient is not left
    // hunting through months for the dot. Only done while nothing is selected,
    // so it does not fight them once they start tapping.
    //
    // `open` arrives ordered by start, so the first entry is the soonest.
    final firstDay = open.first.day;
    final selected = _selectedDay ?? firstDay;
    final onSelectedDay = byDay[selected] ?? const <AvailabilitySlot>[];

    return ListView(
      children: [
        MonthCalendar(
          month: _month ?? selected,
          selectedDay: selected,
          firstMonth: DateTime.now(),
          onMonthChanged: (value) => setState(() => _month = value),
          onSelectDay: (day) => setState(() => _selectedDay = day),
          markerCount: (day) => (byDay[day] ?? const []).length,
          // A day with no free times is not worth a tap — there is nothing
          // behind it to show.
          isSelectable: (day) => byDay.containsKey(day),
        ),
        const AppGap.md(),
        SectionHeader(l10n.apptFreeTimesOn),
        if (onSelectedDay.isEmpty)
          AppEmptyState(
            icon: Icons.schedule,
            title: l10n.apptPickDayWithTimes,
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final slot in onSelectedDay)
                _SlotChip(
                  label: _formatTime(context, slot.start),
                  busy: _bookingSlotId == slot.id,
                  // One at a time: a second tap while the transaction is in
                  // flight would try to book two slots for one visit.
                  onTap: _bookingSlotId == null ? () => _book(slot) : null,
                ),
            ],
          ),
        const AppGap.md(),
        TextField(
          controller: _reason,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: l10n.apptReason),
        ),
        const AppGap.md(),
      ],
    );
  }
}

/// One bookable time.
class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return ActionChip(
      avatar: const Icon(Icons.schedule, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

/// The clock time, in the reader's own zone and their locale's 12- or 24-hour
/// convention.
String _formatTime(BuildContext context, DateTime when) =>
    TimeOfDay.fromDateTime(when.toLocal()).format(context);

/// Date and time together, for the confirmation.
String _formatSlot(BuildContext context, AvailabilitySlot slot) {
  final localizations = MaterialLocalizations.of(context);
  final local = slot.start.toLocal();
  return '${localizations.formatMediumDate(local)} '
      '${_formatTime(context, local)}';
}
