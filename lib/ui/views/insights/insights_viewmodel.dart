import 'package:stacked/stacked.dart';

import '../../../models/raison_result.dart';

/// Simple ViewModel that just holds the insight results.
class InsightsViewModel extends BaseViewModel {
  InsightsViewModel(this.results);

  final List<RaisonResult> results;
}
