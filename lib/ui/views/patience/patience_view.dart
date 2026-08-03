import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import '../../common/widgets/widgets.dart';
import 'patience_viewmodel.dart';
import '../patience_view/tabs/profile_tab.dart';
import '../patience_view/tabs/tests_tab.dart';
import '../patience_view/tabs/results_tab.dart';
import '../patience_view/tabs/doctor_tab.dart';
import '../patience_view/tabs/insights_tab.dart';
import '../../../models/raison_result.dart';

class PatienceView extends StackedView<PatienceViewModel> {
  const PatienceView({super.key, this.initialTab = 0, this.resultsFuture});

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
    final l10n = AppLocalizations.of(context)!;

    if (viewModel.isBusy) {
      return const Scaffold(body: AppLoading());
    }

    // The Doctor tab is hidden for guests, who have no doctor relationship to
    // show. It is last, so dropping it leaves every other index unchanged for
    // callers that navigate to a specific tab.
    final tabs = <Tab>[
      Tab(text: l10n.tabProfile, icon: const Icon(Icons.person)),
      Tab(text: l10n.tabTests, icon: const Icon(Icons.science)),
      //Tab(text: 'History', icon: Icon(Icons.history)),
      Tab(text: l10n.tabResults, icon: const Icon(Icons.assessment)),
      Tab(text: l10n.insights, icon: const Icon(Icons.insights)),
      if (!viewModel.isGuest)
        Tab(text: l10n.doctor, icon: const Icon(Icons.medical_information)),
    ];

    final tabViews = <Widget>[
      ProfileTab(viewModel: viewModel),
      TestsTab(viewModel: viewModel),
      ResultsTab(viewModel: viewModel),
      InsightsTab(resultsFuture: resultsFuture),
      if (!viewModel.isGuest) DoctorTab(viewModel: viewModel),
    ];

    return DefaultTabController(
      length: tabs.length,
      // Clamped in case a caller asks for a tab this user does not have.
      initialIndex: initialTab.clamp(0, tabs.length - 1),
      // Builder so the PopScope callback sits below the controller and can
      // switch tabs when a guest chooses to create an account.
      child: Builder(
        builder: (tabContext) => PopScope(
          // Back from the patient home exits the app on Android. For a guest
          // that is the moment their results become reachable only from this
          // device, so it is the one place worth interrupting. Registered
          // users pop straight through, since they lose nothing by leaving.
          canPop: !viewModel.isGuest,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final leave = await _confirmGuestExit(tabContext);
            if (leave && tabContext.mounted) {
              Navigator.of(tabContext).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 0,
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: tabs,
              ),
            ),
            body: TabBarView(children: tabViews),
          ),
        ),
      ),
    );
  }

  /// Warns a guest that leaving keeps their results tied to this device.
  ///
  /// Returns true when the patient chose to leave anyway. Choosing to create an
  /// account sends them to the Profile tab, where the upgrade form lives,
  /// rather than dead-ending the dialog.
  Future<bool> _confirmGuestExit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.guestExitTitle),
        content: Text(l10n.guestExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.guestExitStay),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.guestExitLeave),
          ),
        ],
      ),
    );

    if (leave == false && context.mounted) {
      // Profile is index 0 and holds the account-upgrade card.
      DefaultTabController.of(context).animateTo(0);
    }
    return leave ?? false;
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
