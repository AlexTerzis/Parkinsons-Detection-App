import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../../models/raison_result.dart';
import '../../../services/raison_plus_text.dart';
import 'insights_viewmodel.dart';

/// Displays solutions returned by the Raison API.
class InsightsView extends StackedView<InsightsViewModel> {
  const InsightsView({super.key, required this.results});

  final List<RaisonResult> results;

  @override
  Widget builder(
    BuildContext context, InsightsViewModel viewModel, Widget? child) {
    if (viewModel.results.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.insights)),
        body: Center(
            child: Text(AppLocalizations.of(context)!.noRecommendations)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.insights)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.results.length,
        itemBuilder: (_, index) {
          final item = viewModel.results[index];
          final greek = Localizations.localeOf(context).languageCode == 'el';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(RaisonPlusText.label(item.label, greek: greek),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...item.explanation.map(
                    (e) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(
                          child: Text(
                              RaisonPlusText.line(e, greek: greek))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  InsightsViewModel viewModelBuilder(BuildContext context) =>
      InsightsViewModel(results);
}
