import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../services/test_service.dart';
import '../../../services/authentication_service.dart';
import '../../../models/test_result.dart';
import '../../../models/test_type.dart';

/// ViewModel responsible for processing and saving questionnaire responses.
class QuestionnaireViewModel extends BaseViewModel {
  final TestService _tests = locator<TestService>();
  final AuthenticationService _auth = locator<AuthenticationService>();

  /// Submits and enriches the user responses before saving.
  Future<void> submitQuestionnaire(Map<String, dynamic> responses) async {
    setBusy(true);

    // Make a mutable copy to add derived flags
    final computed = Map<String, dynamic>.from(responses);

    // Composite symptom flags:
    // A4 = A1 && A2
    computed['A4'] = (responses['A1'] == true && responses['A2'] == true);

    // A5 = (A2 && A3) || (A1 && A3)
    computed['A5'] = ((responses['A2'] == true && responses['A3'] == true)
        || (responses['A1'] == true && responses['A3'] == true));

    //A6 (requires A5 and a REM sleep flag 'REM')
      computed['A6'] = (computed['A5'] == true && (responses['RBD_study_positive'] == true || responses['RBD_q'] == 'true'));
    //A7 = A5 && Memory_Disorder && Urgent_Urination
    computed['A7'] = (computed['A5'] == true &&
        responses['Memory_Disorder'] == true &&
        responses['Urgent_Urination'] == true);
    
    // A8 = Memory_Disorder && Exec_Language_Disorder && A5
    computed['A8'] = (responses['Memory_Disorder'] == true &&
        responses['Execute_Disorder'] == true );

    // Α9.δια/χη μνημης+/- δυσεπιτελ δυσλειτ+/- δια/χη λόγου  + συμπεριφορας
    computed['A9'] = (responses['Memory_Disorder'] == true &&
        (responses['Execute_Disorder'] == true ||
         responses['Language_Disorder'] == true) &&
        responses['Behavior_Change'] == true);

    // Α10. δια/χη μνημης+/- δυσεπιτελ δυσλειτ+/- δια/χη λόγου 
    computed['A10'] = (responses['Memory_Disorder'] == true &&
        (responses['Execute_Disorder'] == true ||
         responses['Language_Disorder'] == true));
    
    // Α11. ασταθεια +- πτωσεις
     computed['A11'] = (responses['Instability'] == true ||
        responses['Falls'] == true); 
    //Α12. ασταθεια +συνδυασμοι των 1-5
    computed['A12'] = (responses['Instability'] == true &&
        (responses['A1'] == true ||
         responses['A2'] == true ||
         responses['A3'] == true ||
         computed['A4'] == true ||
         computed['A5'] == true));
    // Α13.ασταθεια+δυσαρθρια+/-δυσκαταποσια
    computed['A13'] = (responses['Instability'] == true &&
        responses['Dysarthria'] == true &&
        responses['Dysphagia'] == true);
    //Α14.αδυναμια Α ή ΚΑ +δυσαρθρια+/-δυσκαταποσια +/- ατροφια  Α ή ΚΑ
    computed['A14'] = (responses['Limb_Weakness'] == true &&
        responses['Dysarthria'] == true &&
        responses['Dysphagia'] == true &&
        responses['Atrophy'] == true);
    //Α15.αδυναμια Α ή ΚΑ +δυσαρθρια+/-δυσκαταποσια+ δια/χη συμπεριφορας
    computed['A15'] = (responses['Limb_Weakness'] == true &&
        responses['Dysarthria'] == true &&
        responses['Dysphagia'] == true &&
        responses['Behavior_Change'] == true); 
    //--------------B section----------------
    //Β4.όχι για παρκινσονισμο + ναι για συνδυασμους 1-3
    computed['B4'] = (responses['B1'] == false &&
        (responses['B2'] == true &&
         responses['B3'] == true));
    //B5. όχι για ανοια + ναι για συνδυασμους 1-3
    computed['B5'] = (responses['B2'] == false &&
        (responses['B1'] == true &&
         responses['B3'] == true));
    //B6. όχι για ψυχιατρικη νοσο+ ναι για συνδυασμους 1-3
    computed['B6'] = (responses['B3'] == false &&
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
    computed['G1i'] = (takenCountG > 1);

  //-----------D------ section----------------
  // D1d: combination of MRI results 
    final medFlagsD1 = [
      responses['D1a'] == true,
      responses['D1b'] == true,
      responses['D1c'] == true,
      responses['D1d'] == true,
    ];
    final takenCountD1 = medFlagsD1.where((flag) => flag).length;
    computed['D1e'] = (takenCountD1 > 1);     
  // D1d: combination of D results 
    final medFlagsD2 = [
      responses['D1a'] == true,
      responses['D1b'] == true,
      responses['D1c'] == true,
      responses['D1d'] == true,
      computed['D1e'] == true,
      responses['D1z'] == true,
      responses['D1h'] == true,
      responses['D1u'] == true,
    ];
    final takenCountD2 = medFlagsD2.where((flag) => flag).length;
    computed['D1i'] = (takenCountD2 > 1);     
    
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
      data: computed,
    );

    await _tests.setQuestionnaireResult(result);
    setBusy(false);
  }
}
