import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../services/test_service.dart';
import '../../../services/authentication_service.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';

/// ViewModel responsible for saving questionnaire responses.
class QuestionnaireViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();

  Future<void> submitQuestionnaire(Map<String, dynamic> responses) async {
    setBusy(true);
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setBusy(false);
      return;
    }
    final result = TestResult(
      id: '',
      patientId: uid,
      type: TestType.questionnaire,
      performedAt: DateTime.now(),
      score: 0,
      data: responses,
    );
    await _tests.addResult(result);
    setBusy(false);
  }
}