import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/app_user.dart';
import '../../../common/widgets/widgets.dart';
import '../../patience/patience_viewmodel.dart';

/// Lets the patient pick a doctor from a searchable list.
///
/// A bottom sheet rather than the `AlertDialog` this replaced: the list can be
/// long and is searchable, and a sheet gets real height for it instead of a
/// dialog's cramped `SizedBox(width: double.maxFinite)`.
///
/// Replaces two near-identical inline dialogs — one assembled inside
/// `TestsTab.build`, one inside `DoctorTab` — which had drifted apart in what
/// they showed as a subtitle and which confirmation they raised.
///
/// [onSelect] receives the chosen doctor. When [confirmationMessage] is given,
/// it is shown as a success snack bar afterwards.
Future<void> showDoctorPicker(
  BuildContext context,
  PatienceViewModel viewModel, {
  required void Function(AppUser doctor) onSelect,
  bool excludePrimary = false,
  String Function(AppUser doctor)? confirmationMessage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _DoctorPickerSheet(
      viewModel: viewModel,
      onSelect: onSelect,
      excludePrimary: excludePrimary,
      confirmationMessage: confirmationMessage,
    ),
  );
}

class _DoctorPickerSheet extends StatefulWidget {
  const _DoctorPickerSheet({
    required this.viewModel,
    required this.onSelect,
    required this.excludePrimary,
    required this.confirmationMessage,
  });

  final PatienceViewModel viewModel;
  final void Function(AppUser doctor) onSelect;
  final bool excludePrimary;
  final String Function(AppUser doctor)? confirmationMessage;

  @override
  State<_DoctorPickerSheet> createState() => _DoctorPickerSheetState();
}

class _DoctorPickerSheetState extends State<_DoctorPickerSheet> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Specialty and location, joined only where both exist, so a doctor with
  /// neither does not get a subtitle made of a stray bullet.
  String? _subtitle(AppUser doctor) {
    final parts = [doctor.specialty, doctor.location]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _search.text.trim().toLowerCase();

    final filtered = widget.viewModel.doctors.where((d) {
      if (widget.excludePrimary &&
          d.uid == widget.viewModel.primaryDoctorId) {
        return false;
      }
      return '${d.name ?? ''} ${d.email}'.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      child: Padding(
        // Lifts the sheet clear of the keyboard while the field has focus.
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(l10n.selectDoctor),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: l10n.searchDoctor,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const AppGap.md(),
                Expanded(
                  child: filtered.isEmpty
                      ? AppEmptyState(
                          icon: Icons.person_search,
                          title: l10n.noDoctorsFound,
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const AppGap.xs(),
                          itemBuilder: (context, index) {
                            final doctor = filtered[index];
                            return AppTileCard(
                              icon: Icons.person,
                              title: doctor.name ?? doctor.email,
                              subtitle: _subtitle(doctor),
                              onTap: () => _choose(doctor),
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

  void _choose(AppUser doctor) {
    // The sheet's own context dies with the pop, so any confirmation is raised
    // against the messenger that outlives it.
    final messengerContext = Navigator.of(context).context;
    final message = widget.confirmationMessage?.call(doctor);

    Navigator.of(context).pop();
    widget.onSelect(doctor);

    if (message != null && messengerContext.mounted) {
      AppFeedback.success(messengerContext, message);
    }
  }
}
