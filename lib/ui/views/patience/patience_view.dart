import 'package:flutter/material.dart';
import 'package:parkinsondetetion/ui/views/tremor_test/tremor_test_view.dart';
import 'package:parkinsondetetion/ui/views/tap_test/tap_test_view.dart';
import 'package:stacked/stacked.dart';

import 'patience_viewmodel.dart';
import '../../../models/test_type.dart';
import '../../../models/test_result.dart';
import '../camera_test/camera_test_view.dart';
import '../../../app/app.locator.dart';
import 'package:stacked_services/stacked_services.dart';

class PatienceView extends StackedView<PatienceViewModel> {
  const PatienceView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    PatienceViewModel viewModel,
    Widget? child,
  ) {
    final ThemeData theme = Theme.of(context);

    if (viewModel.isBusy) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Patient Dashboard'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Profile', icon: Icon(Icons.person)),
              Tab(text: 'Tests', icon: Icon(Icons.science)),
              Tab(text: 'History', icon: Icon(Icons.history)),
              Tab(text: 'Results', icon: Icon(Icons.assessment)),
              Tab(text: 'Doctor', icon: Icon(Icons.medical_information)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProfileTab(context, viewModel, theme),
            _buildTestsTab(context, viewModel, theme),
            _buildHistoryTab(viewModel, theme),
            _buildResultsTab(viewModel, theme),
            _buildDoctorTab(viewModel, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(
      BuildContext context, PatienceViewModel viewModel, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: const Icon(Icons.person, size: 48),
          ),
          const SizedBox(height: 16),
          Text(viewModel.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(viewModel.email, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          TextField(
            controller: viewModel.nameController,
            decoration: const InputDecoration(
              labelText: 'Edit Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: viewModel.isBusy
                ? null
                : () async {
                    await viewModel.saveName();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Name saved successfully')),
                      );
                    }
                  },
            icon: const Icon(Icons.save),
            label: const Text('Save Name'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsTab(
      BuildContext rootContext, PatienceViewModel viewModel, ThemeData theme) {
    final tests = [
      {
        'title': 'Camera Detection Test',
        'icon': Icons.camera_alt,
        'type': TestType.cameraDetection,
      },
      {
        'title': 'Tremor Test',
        'icon': Icons.vibration,  
        'type': TestType.tremor,
      },
      {
        'title': 'Tap Test',
        'icon': Icons.touch_app,
        'type': TestType.tap,  
      },
      {
        'title': 'Drawing Test',
        'icon': Icons.edit,
        'type': TestType.drawing,
      },
      {
        'title': 'Questionnaire',
        'icon': Icons.question_answer,
        'type': TestType.questionnaire,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: tests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final test = tests[index];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(test['icon'] as IconData,
                        color: theme.colorScheme.primary),
                    title: Text(test['title'] as String),
                    trailing:
                        _buildTestTrailing(viewModel, test['type'] as TestType),
                    onTap: () async {
                      final type = test['type'] as TestType;
                      if (type == TestType.cameraDetection) {
                        final success = await locator<NavigationService>()
                            .navigateToView(const CameraTestView());
                        if (rootContext.mounted && success == false) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(
                                content: Text('No hands detected. Try again.')),
                          );
                        }
                      } else if (type == TestType.tremor) {
                        await locator<NavigationService>()
                            .navigateToView(const TremorTestView());
                      } else if (type == TestType.tap) {
                        await locator<NavigationService>()
                            .navigateToView(const TapTestView());
                      } else {
                        await viewModel.recordDemoResult(type);
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          SnackBar(
                              content: Text('${test['title']} completed')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _onSendResultsPressed(rootContext, viewModel),
            icon: const Icon(Icons.send),
            label: const Text('Send Results to Doctor'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestTrailing(PatienceViewModel vm, TestType type) {
    final matched = vm.results.firstWhere(
      (r) => r.type == type,
      orElse: () => TestResult(
        id: '',
        patientId: '',
        type: type,
        performedAt: DateTime(0),
        score: 0,
      ),
    );

    if (matched.performedAt.year == 0) {
      return const Icon(Icons.chevron_right);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.green),
        Text(
          '${matched.performedAt.month}/${matched.performedAt.day}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(PatienceViewModel viewModel, ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.historyItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = viewModel.historyItems[index];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.history),
            title: Text(item['test'] ?? '-'),
            subtitle: Text(item['date'] ?? ''),
            trailing: Text(item['result'] ?? ''),
          ),
        );
      },
    );
  }

  Widget _buildResultsTab(PatienceViewModel viewModel, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Overall Scores', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          ...viewModel.resultsSummary.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(child: Text(entry.key)),
                  SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(
                      value: entry.value,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(entry.value * 100).round()}%'),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Export or share results
            },
            icon: const Icon(Icons.download),
            label: const Text('Export Results'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorTab(PatienceViewModel viewModel, ThemeData theme) {
    if (viewModel.reports.isEmpty) {
      return const Center(child: Text('No doctor feedback yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = viewModel.reports[index];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: const Icon(Icons.person_outline),
            title: Text(viewModel.doctorName(report.doctorId)),
            subtitle: Text(report.status.name.toUpperCase()),
            children: [
              if (report.notes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No notes yet.'),
                )
              else
                ...report.notes.map((n) => ListTile(
                      leading: const Icon(Icons.note),
                      title: Text(n.note),
                      subtitle:
                          Text(n.createdAt.toIso8601String().substring(0, 10)),
                    )),
            ],
          ),
        );
      },
    );
  }

  @override
  PatienceViewModel viewModelBuilder(BuildContext context) =>
      PatienceViewModel();

  @override
  void onViewModelReady(PatienceViewModel viewModel) {
    viewModel.init();
    super.onViewModelReady(viewModel);
  }

  void _onSendResultsPressed(BuildContext rootContext, PatienceViewModel vm) {
    if (vm.results.isEmpty) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
            content: Text('Please complete at least one test first.')),
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
            final combined = ('${d.name ?? ''} ${d.email}').toLowerCase();
            return combined.contains(q);
          }).toList();

          return AlertDialog(
            title: const Text('Select Doctor'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search doctor...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) => setState(() => query = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No doctors found'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final doc = filtered[index];
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(doc.name ?? doc.email),
                                subtitle: Text(doc.email),
                                onTap: () async {
                                  Navigator.of(ctx).pop();
                                  await vm.sendResultsToDoctor(doc.uid);
                                  if (rootContext.mounted) {
                                    ScaffoldMessenger.of(rootContext)
                                        .showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Results sent to ${doc.name ?? doc.email}')),
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
