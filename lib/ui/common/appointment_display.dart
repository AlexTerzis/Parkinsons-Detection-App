import 'package:flutter/material.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../models/appointment.dart';
import 'app_semantic_colors.dart';
import 'app_tokens.dart';

/// Presentation helpers for appointments, shared by both sides.
///
/// Lives in the UI layer and takes [AppLocalizations], for the same reason
/// `testTypeLabel` does: the patient screen and the doctor screen must name a
/// status identically and in the user's language, and a status name built from
/// an English switch inside a view model is how the Greek app ended up with
/// English labels elsewhere.

/// The status of an appointment, in the reader's language.
String appointmentStatusLabel(AppLocalizations l10n, AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.requested:
      return l10n.apptStatusRequested;
    case AppointmentStatus.confirmed:
      return l10n.apptStatusConfirmed;
    case AppointmentStatus.declined:
      return l10n.apptStatusDeclined;
    case AppointmentStatus.cancelled:
      return l10n.apptStatusCancelled;
    case AppointmentStatus.completed:
      return l10n.apptStatusCompleted;
  }
}

/// The colour that carries an appointment's state.
///
/// Booking a published time confirms it outright — the doctor offered the slot,
/// so there is nothing left to agree to — and a confirmed appointment should
/// read as settled at a glance rather than looking the same as one that fell
/// through. Both sides resolve the colour here so a status never means green on
/// one screen and grey on the other.
Color appointmentStatusColor(BuildContext context, AppointmentStatus status) {
  final scheme = Theme.of(context).colorScheme;
  final semantic = AppSemanticColors.of(context);

  switch (status) {
    case AppointmentStatus.confirmed:
      return semantic.success;
    // Only reachable on appointments written under the old request-and-confirm
    // flow; nothing creates these any more.
    case AppointmentStatus.requested:
      return semantic.warning;
    case AppointmentStatus.declined:
    case AppointmentStatus.cancelled:
      return scheme.error;
    case AppointmentStatus.completed:
      return scheme.onSurfaceVariant;
  }
}

/// An appointment's status, coloured and named.
///
/// The label is always drawn, never replaced by the colour: red/green deficiency
/// is common enough that hue cannot be the only thing distinguishing "confirmed"
/// from "cancelled" on a medical screen. Same rule the concern bands follow in
/// `TestResultSummary`.
class AppointmentStatusChip extends StatelessWidget {
  const AppointmentStatusChip({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = appointmentStatusColor(context, status);

    return Chip(
      backgroundColor: color.withValues(alpha: 0.18),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
      label: Text(appointmentStatusLabel(l10n, status)),
    );
  }
}

/// The time an appointment is at, with its status beside it.
///
/// A [Wrap] rather than a `Row` with an `Expanded` time and the chip after it.
/// A Row lays its inflexible children out first at their natural width and
/// gives `Expanded` only what is left, so at the largest text size a long
/// translated status — "Επιβεβαιωμένο" — took the whole line and the Row
/// overflowed instead of reflowing. Wrapping drops the chip onto its own line
/// at the point where the two stop fitting.
///
/// Shared by both appointment lists on the doctor side and the one on the
/// patient side, which each had their own copy of the broken Row.
class AppointmentHeader extends StatelessWidget {
  const AppointmentHeader({
    super.key,
    required this.time,
    required this.status,
  });

  final String time;
  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(time, style: Theme.of(context).textTheme.titleMedium),
        AppointmentStatusChip(status: status),
      ],
    );
  }
}

/// `yyyy-mm-dd hh:mm` in the reader's own time zone.
///
/// Stored times are UTC-backed `Timestamp`s, so converting to local is what
/// makes "10:00" mean ten in the morning to whoever is reading it rather than
/// ten wherever the server happens to think it is.
String formatAppointmentTime(DateTime when) {
  final local = when.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
