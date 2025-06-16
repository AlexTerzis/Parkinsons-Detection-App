import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'doctor_viewmodel.dart';
import '../../../models/patient_report.dart';

class DoctorView extends StackedView<DoctorViewModel> {
  const DoctorView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    DoctorViewModel vm,
    Widget? child,
  ) {
    final ThemeData theme = Theme.of(context);

    if (vm.isBusy) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final patients = vm.reports.map((r) => r.patientId).toSet().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Dashboard')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: patients.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final pid = patients[index];
          final reports = vm.reports.where((r) => r.patientId == pid).toList();
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(vm.patientName(pid)),
              subtitle: Text('Reports: ${reports.length}'),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  itemBuilder: (context, rIndex) {
                    final rep = reports[rIndex];
                    return ListTile(
                      title: Text('Sent: ${rep.sentAt.toLocal()}'),
                      subtitle: Text('Tests: ${rep.results.length}'),
                      onTap: () => _showReportDialog(context, rep),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vm.noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Write notes for patient...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () async {
                      await vm.addNoteToReportForPatient(pid);
                    },
                    child: const Text('Add Note'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showReportDialog(BuildContext context, PatientReport report) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Report ${report.sentAt.toLocal()}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: report.results.map((r) {
                return ExpansionTile(
                  title: Text(r.type.name),
                  subtitle: Text('Score: ${(r.score * 100).round()}%'),
                  children: [
                    if (r.data.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No additional data'),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: r.data.entries.map((e) => Text('${e.key}: ${e.value}')).toList(),
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
              child: const Text('Close'),
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
