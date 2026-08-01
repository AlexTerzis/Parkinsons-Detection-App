// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Parkinson AI Detector';

  @override
  String get editName => 'Edit Name';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get dobHint => 'yyyy-mm-dd';

  @override
  String get addMedication => 'Add Medication';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get logOut => 'LOG OUT';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get greek => 'Greek';

  @override
  String get welcome => 'Welcome';

  @override
  String get createAccount => 'Create Account';

  @override
  String get nameLabel => 'Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get iAmA => 'I am a';

  @override
  String get patient => 'Patient';

  @override
  String get doctor => 'Doctor';

  @override
  String get keepMeLoggedIn => 'Keep me logged in';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get passwordRecovery => 'Password Recovery';

  @override
  String get cancel => 'Cancel';

  @override
  String get send => 'Send';

  @override
  String get emailSent => 'If the email exists, a reset link has been sent.';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get savedSuccessfully => 'Saved successfully';

  @override
  String get gotIt => 'Got it';

  @override
  String get insights => 'Insights';

  @override
  String get noRecommendations => 'No recommendations returned';

  @override
  String get questionnaire => 'Questionnaire';

  @override
  String get submit => 'Submit';

  @override
  String get tapTest => 'Tap Test';

  @override
  String timeLeft(Object seconds) {
    return 'Time left: ${seconds}s';
  }

  @override
  String get tap => 'TAP';

  @override
  String get startTest => 'Start Test';

  @override
  String get stop => 'Stop';

  @override
  String get pressStart => 'Press start to begin';

  @override
  String get startingTest => 'Starting test...';

  @override
  String get tapRightHand => 'Tap with right hand';

  @override
  String get switchHands => 'Switch hands';

  @override
  String get tapLeftHand => 'Tap with left hand';

  @override
  String get testCompleted => 'Test completed';

  @override
  String get testStopped => 'Test stopped';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabTests => 'Tests';

  @override
  String get tabResults => 'Results';

  @override
  String get next => 'Next';

  @override
  String get finishAction => 'Finish';

  @override
  String get voiceTest => 'Voice Test';

  @override
  String get recording => 'Recording...';

  @override
  String get processing => 'Processing...';

  @override
  String get microphonePermissionDenied => 'Microphone permission denied';

  @override
  String possibleParkinson(Object percent) {
    return '⚠️ Possible Parkinson pattern ($percent%)';
  }

  @override
  String normalVoice(Object percent) {
    return '✅ Normal voice ($percent%)';
  }

  @override
  String get recordingFailed => 'Recording failed';

  @override
  String get noDoctorSelected =>
      'You haven\'t selected a doctor yet.\nClick to select';

  @override
  String get myDoctor => 'My Doctor';

  @override
  String get sendResults => 'Send Results';

  @override
  String get diagnoses => 'Diagnoses';

  @override
  String get bookAppointment => 'Book Appointment';

  @override
  String get getSecondOpinion => 'Get Second Opinion';

  @override
  String get secondOpinions => 'Second Opinions';

  @override
  String get close => 'Close';

  @override
  String get noDoctorFeedback => 'No doctor feedback yet.';

  @override
  String get noNotesYet => 'No notes yet.';

  @override
  String get completeOneTest => 'Please complete at least one test first.';

  @override
  String get selectDoctor => 'Select Doctor';

  @override
  String get searchDoctor => 'Search doctor...';

  @override
  String get noDoctorsFound => 'No doctors found';

  @override
  String resultsSentTo(Object name) {
    return 'Results sent to $name';
  }

  @override
  String get testResults => 'Test Results';

  @override
  String get summary => 'Summary';

  @override
  String get needThreeTests =>
      'Complete at least 3 different tests to view the summary chart.';

  @override
  String days(Object count) {
    return '$count days';
  }

  @override
  String get exportResults => 'Export Results';

  @override
  String get cameraDetectionTest => 'Camera Detection Test';

  @override
  String get tremorTest => 'Tremor Test';

  @override
  String get drawingTest => 'Drawing Test';

  @override
  String get neuropsychologicalTest => 'Neuropsychological Test';

  @override
  String get fabTest => 'Frontal Assessment Battery Test';

  @override
  String get sendResultsToDoctor => 'Send Results to Doctor';

  @override
  String get noHandsDetected => 'No hands detected. Try again.';

  @override
  String testCompletedMsg(Object test) {
    return '$test completed';
  }

  @override
  String get drawOnPhone => 'Draw on phone';

  @override
  String get takePicture => 'Take picture';

  @override
  String get uploadPicture => 'Upload picture';

  @override
  String get tabMyPatients => 'MyPatients';

  @override
  String get tabCommunity => 'Community';

  @override
  String get specialtyLabel => 'Specialty';

  @override
  String get locationLabel => 'Location';

  @override
  String get save => 'Save';

  @override
  String get noPatientReportsYet => 'No patient reports yet.';

  @override
  String reportsCountLabel(Object count) {
    return 'Reports: $count';
  }

  @override
  String sentAtLabel(Object date) {
    return 'Sent: $date';
  }

  @override
  String testsCountLabel(Object count) {
    return 'Tests: $count';
  }

  @override
  String get writeNotesHint => 'Write notes for patient...';

  @override
  String get addNote => 'Add Note';

  @override
  String get noPostsYet => 'No posts yet.';

  @override
  String reportTitle(Object date) {
    return 'Report $date';
  }

  @override
  String scorePercent(Object percent) {
    return 'Score: $percent%';
  }

  @override
  String get noAdditionalData => 'No additional data';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get authenticationError => 'Authentication error';

  @override
  String get unexpectedError => 'An unexpected error occurred.';

  @override
  String get enterEmailFirst => 'Please enter your email first.';

  @override
  String get failedToSendResetEmail => 'Failed to send reset email.';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmailAddress => 'Please enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get testingHand1 => 'Testing Hand 1...';

  @override
  String get testingHand2 => 'Testing Hand 2...';

  @override
  String get handOneLabel => 'Hand 1';

  @override
  String get handTwoLabel => 'Hand 2';

  @override
  String fftResultsTemplate(Object label, Object x, Object y, Object z) {
    return '$label Results (Accelerometer):\nX Peak Frequency: $x Hz\nY Peak Frequency: $y Hz\nZ Peak Frequency: $z Hz';
  }

  @override
  String get handOneFftSpectrum => 'Hand 1 FFT Spectrum';

  @override
  String get handTwoFftSpectrum => 'Hand 2 FFT Spectrum';

  @override
  String get insufficientSensorData =>
      'Insufficient sensor data to render spectrum.';

  @override
  String get xAxisLabel => 'X-axis';

  @override
  String get yAxisLabel => 'Y-axis';

  @override
  String get zAxisLabel => 'Z-axis';

  @override
  String accelerometerReadout(Object x, Object y, Object z) {
    return 'Accelerometer: X=$x Y=$y Z=$z';
  }

  @override
  String gyroscopeReadout(Object x, Object y, Object z) {
    return 'Live Gyroscope meter: X=$x  Y=$y  Z=$z';
  }

  @override
  String get rightHandLabel => 'Right hand';

  @override
  String get leftHandLabel => 'Left hand';

  @override
  String get predictionNotAvailable => 'Prediction not available';

  @override
  String get predictionFailed => 'Prediction failed';

  @override
  String tapParkinsonPattern(Object label, Object percent) {
    return '$label: ⚠️ Parkinson-like pattern ($percent%)';
  }

  @override
  String tapNormalPattern(Object label, Object percent) {
    return '$label: ✅ Normal tapping ($percent%)';
  }

  @override
  String get drawTitle => 'Draw';

  @override
  String get clearAction => 'Clear';

  @override
  String get aiSummaryTitle => 'Overall AI Summary';

  @override
  String get aiSummarySubtitle =>
      'Low risk – more advanced analytics will appear here.';

  @override
  String get testBreakdownTitle => 'Test-by-Test Breakdown';

  @override
  String get testBreakdownSubtitle =>
      'Charts of tapping, tremor and other tests will be added.';

  @override
  String get riskAlertsTitle => 'Risk Alerts or Anomalies';

  @override
  String get noAlertsSubtitle => 'No alerts detected recently.';

  @override
  String get argumentation => 'Argumentation';

  @override
  String get loadingReasoning => 'Loading reasoning...';

  @override
  String get takeQuestionnairePrompt =>
      'Take the questionnaire to see the results';

  @override
  String get noArgumentationYet =>
      'Cannot give clear argumentation yet from the questionnaire results. If you have any questions, please contact your doctor.';

  @override
  String get aiSuggestionsTitle => 'AI Test Suggestions';

  @override
  String get retakeTremorSuggestion =>
      'Please retake the Tremor Test – last result was inconclusive.';

  @override
  String get preferences => 'Preferences';

  @override
  String get textSize => 'Text size';

  @override
  String get textSizeSystemNote =>
      'This replaces your device\'s font size setting inside this app.';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeLarger => 'Larger';

  @override
  String get textSizeLargest => 'Largest';

  @override
  String get textSizePreviewTitle => 'Preview';

  @override
  String get textSizePreviewBody =>
      'Text throughout the app will look like this.';

  @override
  String get resetToDefault => 'Reset to default';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get guestAccountTitle => 'You are using a guest account';

  @override
  String get guestAccountBody =>
      'Your tests and results are saved to this device only. Create an account to keep them and to share results with a doctor.';

  @override
  String get keepMyResults => 'Create an account';

  @override
  String get guestSignOutTitle => 'Sign out of guest account?';

  @override
  String get guestSignOutBody =>
      'This guest account and every result in it will be permanently lost. Create an account first if you want to keep them.';

  @override
  String get signOutAnyway => 'Sign out anyway';

  @override
  String get accountCreatedKeptResults =>
      'Account created. Your results have been kept.';

  @override
  String get emailAlreadyInUse =>
      'That email already belongs to another account. Sign in to it instead, though your guest results will not carry over.';

  @override
  String get guestUpgradeFailed =>
      'Could not create the account. Please try again.';

  @override
  String get cameraTestTitle => 'Camera hand assessment';

  @override
  String get cameraSetupBody =>
      'You will be guided through a short series of hand movements, one hand at a time. Hold your phone steady, or prop it up, so the hand being tested stays in view.';

  @override
  String get cameraTestLength => 'Length';

  @override
  String get cameraModeFull => 'Full';

  @override
  String get cameraModeShort => 'Short';

  @override
  String get cameraModeShortNote =>
      'Short mode uses about half the time for each movement.';

  @override
  String cameraApproxDuration(Object seconds) {
    return 'About $seconds seconds';
  }

  @override
  String get cameraStart => 'Start';

  @override
  String get cameraExit => 'Exit';

  @override
  String get cameraHandLeft => 'Left hand';

  @override
  String get cameraHandRight => 'Right hand';

  @override
  String get cameraTaskRest => 'Rest';

  @override
  String get cameraTaskOpenClose => 'Open and close';

  @override
  String get cameraTaskFingerTap => 'Finger tapping';

  @override
  String get cameraTaskPronation => 'Palm up and down';

  @override
  String get cameraInstructionRest =>
      'Rest your hand still and relaxed, in view of the camera.';

  @override
  String get cameraInstructionOpenClose =>
      'Open your hand wide, then close it into a fist. Repeat as fully and as quickly as you can.';

  @override
  String get cameraInstructionFingerTap =>
      'Tap your thumb against your index finger. Make each tap as big and as fast as you can.';

  @override
  String get cameraInstructionPronation =>
      'Turn your palm up, then down, over and over. Make each turn as big and as fast as you can.';

  @override
  String cameraStepOf(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String cameraMdsItem(Object item) {
    return 'MDS-UPDRS item $item';
  }

  @override
  String cameraHandNotVisible(Object hand) {
    return 'Move your $hand into view';
  }

  @override
  String get cameraPause => 'Pause';

  @override
  String get cameraPausePending => 'Pausing after this movement';

  @override
  String get cameraCancelPause => 'Keep going';

  @override
  String get cameraPausedTitle => 'Paused';

  @override
  String get cameraPausedBody =>
      'Take as long as you need. The test continues from the next movement.';

  @override
  String cameraNextUp(Object task) {
    return 'Next: $task';
  }

  @override
  String get cameraResume => 'Resume';

  @override
  String get cameraFinishing => 'Saving your results';
}
