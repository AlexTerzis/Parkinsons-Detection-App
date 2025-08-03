import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../../../app/app.locator.dart';
import '../../patience/patience_viewmodel.dart';
import '../../../../models/app_user.dart';

/// Tab allowing the patient to manage doctors and view reports.
class DoctorTab extends StatelessWidget {
  final PatienceViewModel viewModel;
  final ThemeData theme;
  const DoctorTab({super.key, required this.viewModel, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (viewModel.primaryDoctor == null)
            ElevatedButton(
              onPressed: () => _showDoctorSelectionDialog(
                context,
                viewModel,
                onSelect: (doc) => viewModel.setPrimaryDoctor(doc.uid),
              ),
              child: Text(
                AppLocalizations.of(context)!.noDoctorSelected,
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title:
                    Text(viewModel.primaryDoctor!.name ?? viewModel.primaryDoctor!.email),
                subtitle: Text(
                  '${viewModel.primaryDoctor!.specialty ?? ''} ${viewModel.primaryDoctor!.location != null ? '• ${viewModel.primaryDoctor!.location}' : ''}',
                ),
                trailing:
                    Chip(label: Text(AppLocalizations.of(context)!.myDoctor)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: viewModel.sendResultsToPrimaryDoctor,
              icon: const Icon(Icons.send),
              label: Text(AppLocalizations.of(context)!.sendResults),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showDiagnosesDialog(context, viewModel, theme),
              icon: const Icon(Icons.receipt),
              label: Text(AppLocalizations.of(context)!.diagnoses),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_today),
              label: Text(AppLocalizations.of(context)!.bookAppointment),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showDoctorSelectionDialog(
                context,
                viewModel,
                excludePrimary: true,
                onSelect: (doc) => viewModel.sendResultsToDoctor(doc.uid),
              ),
              icon: const Icon(Icons.group),
              label: Text(AppLocalizations.of(context)!.getSecondOpinion),
            ),
          ],
          const SizedBox(height: 24),
          _buildSecondOpinions(context, viewModel, theme),
        ],
      ),
    );
  }

  Widget _buildSecondOpinions(
      BuildContext context, PatienceViewModel vm, ThemeData theme) {
    final ids = vm.secondOpinionDoctorIds;
    if (ids.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.secondOpinions,
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...ids.map((id) {
          final doc = vm.doctorById(id);
          final reports = vm.reports.where((r) => r.doctorId == id).toList();
          return Card(
            child: ExpansionTile(
              title: Text(doc?.name ?? id),
              children: reports.map((rep) {
                return ListTile(
                  title: Text(rep.status.name.toUpperCase()),
                  subtitle: Text(rep.sentAt.toLocal().toString()),
                );
              }).toList(),
            ),
          );
        })
      ],
    );
  }

  void _showDiagnosesDialog(
      BuildContext context, PatienceViewModel vm, ThemeData theme) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.diagnoses),
          content: SizedBox(
            width: double.maxFinite,
            child: _diagnosesList(context, vm),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context)!.close),
            )
          ],
        );
      },
    );
  }

  Widget _diagnosesList(BuildContext context, PatienceViewModel vm) {
    if (vm.reports.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noDoctorFeedback));
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: vm.reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = vm.reports[index];
        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.person_outline),
            title: Text(vm.doctorName(report.doctorId)),
            subtitle: Text(report.status.name.toUpperCase()),
            children: [
              if (report.notes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(AppLocalizations.of(context)!.noNotesYet),
                )
              else
                ...report.notes.map(
                  (n) => ListTile(
                    leading: const Icon(Icons.note),
                    title: Text(n.note),
                    subtitle:
                        Text(n.createdAt.toIso8601String().substring(0, 10)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDoctorSelectionDialog(
    BuildContext rootContext,
    PatienceViewModel vm, {
    required void Function(AppUser doc) onSelect,
    bool excludePrimary = false,
  }) {
    if (vm.results.isEmpty && onSelect != vm.setPrimaryDoctor) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(rootContext)!.completeOneTest)),
      );
      return;
    }

    showDialog<void>(
      context: rootContext,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(builder: (ctx, setState) {
          final String q = query.toLowerCase();
          final filtered = vm.doctors.where((d) {
            if (excludePrimary && d.uid == vm.primaryDoctorId) return false;
            final combined = ('${d.name ?? ''} ${d.email}').toLowerCase();
            return combined.contains(q);
          }).toList();

          return AlertDialog(
            title: Text(AppLocalizations.of(rootContext)!.selectDoctor),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(rootContext)!.searchDoctor,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (val) => setState(() => query = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text(AppLocalizations.of(rootContext)!.noDoctorsFound))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final doc = filtered[index];
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(doc.name ?? doc.email),
                                subtitle: Text(
                                  '${doc.specialty ?? ''} ${doc.location != null ? '• ${doc.location}' : ''}',
                                ),
                                onTap: () async {
                                  Navigator.of(ctx).pop();
                                  onSelect(doc);
                                  if (rootContext.mounted &&
                                      onSelect != vm.setPrimaryDoctor) {
                                    ScaffoldMessenger.of(rootContext).showSnackBar(
                                      SnackBar(
                                        content: Text(AppLocalizations.of(rootContext)!
                                            .resultsSentTo(doc.name ?? doc.email)),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
