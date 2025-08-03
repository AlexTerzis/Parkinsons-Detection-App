import 'package:flutter/material.dart';
import 'package:parkinsondetetion/ui/views/fab_test/fab_test_view.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../../app/app.locator.dart';
import '../../patience/patience_viewmodel.dart';
import '../widgets/drawing_options_sheet.dart';
import '../../camera_test/camera_test_view.dart';
import '../../tremor_test/tremor_test_view.dart';
import '../../tap_test/tap_test_view.dart';
import '../../questionnaire/questionnaire_view.dart';
import '../../voice_test/voice_test_view.dart';
import '../../neuro_test/neuro_test_view.dart';
import '../../../../models/test_type.dart';
import '../../../../models/test_result.dart';

/// TestsTab lists available tests and actions for sending results.
class TestsTab extends StatelessWidget {
  final PatienceViewModel viewModel;
  const TestsTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rootContext = context;
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
      {
        'title': 'Voice Test',
        'icon': Icons.mic,
        'type': TestType.voice,
      },
      {
        'title': 'Neuropsychological Test',
        'icon': Icons.psychology,
        'type': TestType.neuro,
      },
      {
        'title': 'Frontal Assessment Battery Test',
        'icon': Icons.psychology_alt_outlined,
        'type': TestType.fab,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      test['icon'] as IconData,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(test['title'] as String),
                    trailing: _buildTestTrailing(
                        viewModel, test['type'] as TestType),
                    onTap: () async {
                      final type = test['type'] as TestType;
                      if (type == TestType.cameraDetection) {
                        final success = await locator<NavigationService>()
                            .navigateToView(const CameraTestView());
                        if (rootContext.mounted && success == false) {
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('No hands detected. Try again.')),
                          );
                        }
                      } else if (type == TestType.tremor) {
                        await locator<NavigationService>()
                            .navigateToView(const TremorTestView());
                      } else if (type == TestType.tap) {
                        await locator<NavigationService>()
                            .navigateToView(const TapTestView());
                      } else if (type == TestType.questionnaire) {
                        await locator<NavigationService>()
                            .navigateToView(const QuestionnaireView());
                      } else if (type == TestType.drawing) {
                        showDrawingOptions(rootContext, viewModel);
                      } else if (type == TestType.voice) {
                        await locator<NavigationService>()
                            .navigateToView(const VoiceTestView());
                      } else if (type == TestType.neuro) {
                        await locator<NavigationService>()
                            .navigateToView(const NeuroTestView());
                      }else if (type == TestType.fab) {
                        await locator<NavigationService>()
                            .navigateToView(const FABTestView());
                      } else {
                        await viewModel.recordDemoResult(type);
                        ScaffoldMessenger.of(rootContext).showSnackBar(
                          SnackBar(content: Text('${test['title']} completed')),
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

  void _onSendResultsPressed(BuildContext rootContext, PatienceViewModel vm) {
    if (vm.results.isEmpty) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(content: Text('Please complete at least one test first.')),
      );
      return;
    }

    showDialog<void>(
      context: rootContext,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setState) {
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
                                      ScaffoldMessenger.of(rootContext).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Results sent to ${doc.name ?? doc.email}',
                                          ),
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
          },
        );
      },
    );
  }
}
