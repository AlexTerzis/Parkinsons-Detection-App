import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../services/test_service.dart';
import '../../../services/authentication_service.dart';
import '../../../services/raison_api_service.dart';
import '../../../models/raison_result.dart';
import '../../../ui/views/insights/insights_view.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';

/// ViewModel responsible for processing and saving questionnaire responses.
class QuestionnaireViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();
  final RaisonApiService _raison = locator<RaisonApiService>();
  final NavigationService _nav = locator<NavigationService>();

  /// Submits and enriches the user responses before saving.
  Future<void> submitQuestionnaire(Map<String, dynamic> responses) async {
    setBusy(true);
    // Composite symptom flags:
    // assume `responses['AA']` is one of "AA1", "AA2", or "AA3"
    responses['AA1'] = responses['AA'] == 'AA1';
    responses['AA2'] = responses['AA'] == 'AA2';
    responses['AA3'] = responses['AA'] == 'AA3';
    // A4 = A1 && A2
    responses['A4'] = (responses['A1'] == true && responses['A2'] == true);

    // A5 = (A2 && A3) || (A1 && A3)
    responses['A5'] = ((responses['A2'] == true && responses['A3'] == true)
        || (responses['A1'] == true && responses['A3'] == true));

    //A6 (requires A5 and a REM sleep flag 'REM')
      responses['A6'] = (responses['A5'] == true && (responses['RBD_study_positive'] == true || responses['RBD_q'] == 'true'));
    //A7 = A5 && Memory_Disorder && Urgent_Urination
    responses['A7'] = (responses['A5'] == true &&
        responses['Memory_Disorder'] == true &&
        responses['Urgent_Urination'] == true);
    
    // A8 = Memory_Disorder && Exec_Language_Disorder && A5
    responses['A8'] = (responses['Memory_Disorder'] == true &&
        responses['Execute_Disorder'] == true );

    // Α9.δια/χη μνημης+/- δυσεπιτελ δυσλειτ+/- δια/χη λόγου  + συμπεριφορας
    responses['A9'] = (responses['Memory_Disorder'] == true &&
        (responses['Execute_Disorder'] == true ||
         responses['Language_Disorder'] == true) &&
        responses['Behavior_Change'] == true);

    // Α10. δια/χη μνημης+/- δυσεπιτελ δυσλειτ+/- δια/χη λόγου 
    responses['A10'] = (responses['Memory_Disorder'] == true &&
        (responses['Execute_Disorder'] == true ||
         responses['Language_Disorder'] == true));
    
    // Α11. ασταθεια +- πτωσεις
     responses['A11'] = (responses['Instability'] == true ||
        responses['Falls'] == true); 
    //Α12. ασταθεια +συνδυασμοι των 1-5
    responses['A12'] = (responses['Instability'] == true &&
        (responses['A1'] == true ||
         responses['A2'] == true ||
         responses['A3'] == true ||
         responses['A4'] == true ||
         responses['A5'] == true));
    // Α13.ασταθεια+δυσαρθρια+/-δυσκαταποσια
    responses['A13'] = (responses['Instability'] == true &&
        responses['Dysarthria'] == true &&
        responses['Dysphagia'] == true);
    //Α14.αδυναμια Α ή ΚΑ +δυσαρθρια+/-δυσκαταποσια +/- ατροφια  Α ή ΚΑ
    responses['A14'] = (responses['Limb_Weakness'] == true &&
        responses['Dysarthria'] == true &&
        responses['Dysphagia'] == true &&
        responses['Atrophy'] == true);
    //Α15.αδυναμια Α ή ΚΑ +δυσαρθρια+/-δυσκαταποσια+ δια/χη συμπεριφορας
    responses['A15'] = (responses['Limb_Weakness'] == true &&
        responses['Dysarthria'] == true &&
        responses['Dysphagia'] == true &&
        responses['Behavior_Change'] == true); 
    //--------------B section----------------
    //Β4.όχι για παρκινσονισμο + ναι για συνδυασμους 1-3
    responses['B4'] = (responses['B1'] == false &&
        (responses['B2'] == true &&
         responses['B3'] == true));
    //B5. όχι για ανοια + ναι για συνδυασμους 1-3
    responses['B5'] = (responses['B2'] == false &&
        (responses['B1'] == true &&
         responses['B3'] == true));
    //B6. όχι για ψυχιατρικη νοσο+ ναι για συνδυασμους 1-3
    responses['B6'] = (responses['B3'] == false &&
        (responses['B2'] == true &&
         responses['B1'] == true));
    //--------------C section----------------
    //G1i combination of G1a-u
    // G1i: true if more than two medication flags are ON
    final medFlagsG1 = [
      responses['G1a'] == true,
      responses['G1b'] == true,
      responses['G1c'] == true,
      responses['G1d'] == true,
      responses['G1e'] == true,
      responses['G1st'] == true,
      responses['G1h'] == true,
      responses['G1u'] == true,
    ];
    final takenCountG = medFlagsG1.where((flag) => flag).length;
    responses['G1i'] = (takenCountG > 1);

  //-----------D------ section----------------
  // D1d: combination of MRI results 
    final medFlagsD1 = [
      responses['D1a'] == true,
      responses['D1b'] == true,
      responses['D1c'] == true,
      responses['D1d'] == true,
    ];
    final takenCountD1 = medFlagsD1.where((flag) => flag).length;
    responses['D1e'] = (takenCountD1 > 1);     
  // D1d: combination of D results 
    final medFlagsD2 = [
      responses['D1a'] == true,
      responses['D1b'] == true,
      responses['D1c'] == true,
      responses['D1d'] == true,
      responses['D1e'] == true,
      responses['D1z'] == true,
      responses['D1h'] == true,
      responses['D1u'] == true,
    ];
    final takenCountD2 = medFlagsD2.where((flag) => flag).length;
    responses['D1i'] = (takenCountD2 > 1);     
    // --- GDS section: count all boolean “D1p3…” items ---
    final gdsKeys = [
      'D1p3i',  'D1p3ii', 'D1p3iii', 'D1p3iv', 'D1p3v',
      'D1p3vi', 'D1p3vii','D1p3viii','D1p3ix','D1p3x',
      'D1p3xi', 'D1p3xii','D1p3xiii','D1p3xiv','D1p3xv',
    ];
    final gdsCount = gdsKeys.where((k) => responses[k] == true).length;
    responses['D1p3tmp'] = gdsCount >= 7 ? 'D1p3a' : 'D1p3b';
    responses['D1p3a'] = responses['D1p3tmp'] == 'D1p3a';
    responses['D1p3b'] = responses['D1p3tmp'] == 'D1p3b';
    // --- QUIP composite flag: positive if more than 1.5 (i.e. ≥2) QUIP items are true ---
    final quipKeys = [
      'D1p4i',  'D1p4ii', 'D1p4iii', 'D1p4iv',
      'D1p4v',  'D1p4vi', 'D1p4vii','D1p4viii',
    ];
    final quipCount = quipKeys.where((k) => responses[k] == true).length;
    responses['D1p41IV'] = quipCount >= 2;

    // --- D1p5: RBD 
    // responses['D1p5x'] comes back as List<String>
    final selectedConds = (responses['D1p5x'] as List<dynamic>?)?.cast<String>() ?? [];

              // D1p5x_flag → true if they picked anything except "Κανένα"
    responses['D1p5x_flag'] =
    selectedConds.isNotEmpty && !selectedConds.contains('D1p5x_none');

    final rbdKeys = [
    'D1p5i','D1p5ii','D1p5iii','D1p5iv','D1p5v',
    'D1p5via','D1p5vib','D1p5vic','D1p5vid','D1p5vii',
    'D1p5viii','D1p5ix','D1p5x_flag',
    ];
    final rbdCount = rbdKeys.where((k) => responses[k] == true).length;
    // true if more than 6.5 yes answers, i.e. at least 7
    responses['D1p51V'] = rbdCount > 6;

    // --- SCOPA‑AUT scoring ---
    final scopaKeys = [
      'D1p6i','D1p6ii','D1p6iii','D1p6iv','D1p6v','D1p6vi','D1p6vii','D1p6viii',
      'D1p6ix','D1p6x','D1p6xi','D1p6xii','D1p6xiii','D1p6xiv','D1p6xv','D1p6xvi',
      'D1p6xvii','D1p6xviii','D1p6xix','D1p6xx','D1p6xxi',
      if (responses['W']=='W1') ...['D1p6xxii','D1p6xxiii','D1p6xxiv'],
      if (responses['W']=='W2') ...['D1p6xxv','D1p6xxvi']
    ];
    var scopaTotal = 0;
    for (final key in scopaKeys) {
      scopaTotal += int.tryParse(responses[key] as String? ?? '0')!;
    }
    responses['SCOPA_total'] = scopaTotal;
    responses['SCOPA>3'] = scopaTotal >= 3;

    // Authentication check
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setBusy(false);
      return;
    }

    // Build and save the TestResult
    final result = TestResult(
      id: '',
      patientId: uid,
      type: TestType.questionnaire,
      performedAt: DateTime.now(),
      score: 0,
      data: responses,
    );

    await _tests.setQuestionnaireResult(result);

    List<RaisonResult> solutions = [];
    try {
      final all = await _raison.submit(responses);
      solutions = all.where((r) => r.isSolution).toList();
    } catch (e) {
      // Log but don’t block the flow
      print('⚠️ [QVM] Raison API error: $e');
    }

    setBusy(false);
    
    print('🚀 [QVM] navigating to InsightsView with ${solutions.length} solutions');
    await _nav.navigateToView(InsightsView(results: solutions));
  }
}
