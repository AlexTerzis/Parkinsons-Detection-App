import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import 'patience_viewmodel.dart';
import '../patience_view/tabs/profile_tab.dart';
import '../patience_view/tabs/tests_tab.dart';
import '../patience_view/tabs/results_tab.dart';
import '../patience_view/tabs/doctor_tab.dart';
import '../patience_view/tabs/insights_tab.dart';
import '../../../models/raison_result.dart';

class PatienceView extends StackedView<PatienceViewModel> {
  const PatienceView({Key? key, this.initialTab = 0, this.resultsFuture})
      : super(key: key);

  /// Index of the tab to display when the view opens.
  final int initialTab;

  /// Future resolving to reasoning results; shown in the Insights tab.
  final Future<List<RaisonResult>>? resultsFuture;

  @override
  Widget builder(
    BuildContext context,
    PatienceViewModel viewModel,
    Widget? child,
  ) {
    final ThemeData theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (viewModel.isBusy) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 5,
      // Show the requested tab without waiting for computation
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.tabProfile, icon: const Icon(Icons.person)),
              Tab(text: l10n.tabTests, icon: const Icon(Icons.science)),
              //Tab(text: 'History', icon: Icon(Icons.history)),
              Tab(text: l10n.tabResults, icon: const Icon(Icons.assessment)),
              Tab(text: l10n.insights, icon: const Icon(Icons.insights)),
              Tab(
                text: l10n.doctor,
                icon: const Icon(Icons.medical_information),
              ),
            ],
          ),
        ),
        
        body: TabBarView(
          children: [
            ProfileTab(viewModel: viewModel),
            TestsTab(viewModel: viewModel),
            ResultsTab(viewModel: viewModel),
            InsightsTab(resultsFuture: resultsFuture),
            DoctorTab(viewModel: viewModel, theme: theme),
          ],
        ),
      ),
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


}
