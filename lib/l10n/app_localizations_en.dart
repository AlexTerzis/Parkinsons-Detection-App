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

  @override
  String stepOfSteps(Object current, Object total) {
    return 'Step $current of $total';
  }

  @override
  String get stepStart => 'Start';

  @override
  String get stepSubmit => 'Submit';

  @override
  String get stepFinish => 'Finish';

  @override
  String get stepDone => 'Done';

  @override
  String get stepContinue => 'Continue';

  @override
  String get stepHint => 'Hint';

  @override
  String get stepClear => 'Clear';

  @override
  String get stepDelete => 'Delete';

  @override
  String get stepAnswer => 'Answer';

  @override
  String get stepResults => 'Results';

  @override
  String get stepTimeRemaining => 'Time remaining';

  @override
  String stepTimeRemainingValue(Object seconds) {
    return 'Time remaining: $seconds';
  }

  @override
  String get stepTapMicToStart => 'Tap the microphone to start.';

  @override
  String get stepSayWithMic => 'Say the word into the microphone';

  @override
  String get stepSpokenIntoMic => 'Spoken into the microphone';

  @override
  String get stepTypeOrUseMic => 'You can type or use the microphone.';

  @override
  String get stepStartMic => 'Start microphone';

  @override
  String get stepMicProblem =>
      'There is a problem with the microphone. Tap it again to retry.';

  @override
  String get stepMicStopped =>
      'The microphone stopped. Tap it again to continue.';

  @override
  String get stepMicClosed =>
      'The microphone closed. Tap it again to continue.';

  @override
  String get stepSpeakNow =>
      'Speak now. Each word appears on screen straight away.';

  @override
  String get stepCorrectAnswer => 'Correct!';

  @override
  String get stepCorrectWithHint => 'Correct (hint used)';

  @override
  String get stepWrongOrder => 'Wrong order.';

  @override
  String get stepWrongLine => 'Wrong line';

  @override
  String get stepAllWordsFound => 'All the words have been found.';

  @override
  String stepTimeUpScore(Object score) {
    return 'Time is up.\nScore: $score/3.00';
  }

  @override
  String get stepCameraPermissionRequired =>
      'Camera access is required to continue.';

  @override
  String get stepCameraPermissionRecheck => 'Check permission again';

  @override
  String get stepCameraPermissionSettings =>
      'Check the app settings if the problem persists.';

  @override
  String get stepLocationDenied =>
      'Location access was not allowed.\nYour City and Country answers will be accepted as entered.';

  @override
  String get stepTitleSubtract => 'Subtract 7 from 100';

  @override
  String get stepTitleOrientation => 'Orientation';

  @override
  String get stepTitleNaming => 'Naming';

  @override
  String get stepTitleImmediateRecall => 'Immediate recall';

  @override
  String get stepTitleDelayedRecall => 'Delayed recall';

  @override
  String get stepTitleDigits => 'Working memory';

  @override
  String get stepTitleVigilance => 'Vigilance';

  @override
  String get stepTitleFluency => 'Verbal fluency';

  @override
  String get stepTitleSimilarities => 'Abstract thinking';

  @override
  String get stepTitleClock => 'Clock: hands';

  @override
  String get stepTitleTrails => 'Visuospatial tracking';

  @override
  String get stepTitleCube => 'Visuoconstructional skills';

  @override
  String get stepTitleRepeatSentences => 'Sentence repetition';

  @override
  String get stepTitleGestures => 'Gesture recognition';

  @override
  String get stepTitleConflicting => 'Conflicting instructions';

  @override
  String get stepTitleGoNoGo => 'Go / no-go';

  @override
  String get stepInstructionSubtract =>
      'Subtract 7 repeatedly, starting from 100 (five times):';

  @override
  String get stepInstructionDigitsMemorise =>
      'Try to memorise the numbers below.';

  @override
  String get stepInstructionDigitsForwardSoon =>
      'In a moment you will be asked to repeat them in the same order.';

  @override
  String get stepInstructionDigitsBackwardSoon =>
      'In a moment you will be asked to repeat them in reverse order.';

  @override
  String get stepInstructionDigitsForward =>
      'Repeat the numbers you saw, in the same order:';

  @override
  String get stepInstructionDigitsBackward =>
      'Repeat the numbers you saw, in reverse order:';

  @override
  String get stepInstructionWriteOrSayNumbers => 'Write or say the numbers';

  @override
  String get stepInstructionOrientation => 'Fill in the following:';

  @override
  String get stepInstructionOrientationDay => 'Day (e.g. Monday)';

  @override
  String get stepInstructionOrientationDate => 'Date (e.g. 01 / 01 / 2020)';

  @override
  String get stepInstructionOrientationCity => 'City';

  @override
  String get stepInstructionOrientationCountry => 'Country';

  @override
  String get stepHintCityExample => 'e.g. Athens';

  @override
  String get stepHintCountryExample => 'e.g. Greece';

  @override
  String get stepInstructionNaming =>
      'Name each animal by tapping the microphone on the right of its frame.';

  @override
  String get stepInstructionImmediateRecall =>
      'I will say 5 words. Try to memorise them, because you will be asked for them again shortly.';

  @override
  String get stepInstructionImmediateRecallPractice =>
      'To practise, you will first repeat them all together. Then you will try to repeat each word separately.';

  @override
  String stepInstructionSayWordsTogether(Object words) {
    return 'Say the words from the list (all together, in any order): $words';
  }

  @override
  String stepInstructionSayWordsSeparately(Object words) {
    return 'Say the words, one in each field. $words';
  }

  @override
  String get stepInstructionSayWords => 'Say the words';

  @override
  String get stepInstructionDelayedRecall =>
      'Say as many words as you remember (voice only; the order does not matter).';

  @override
  String get stepInstructionDelayedRecallHint =>
      'If you tap “Hint” for a word, you get half a point for it.';

  @override
  String get stepInstructionWhichWordWasInList =>
      'Which of the following words was in the list?';

  @override
  String get stepInstructionVigilance =>
      'This test measures your alertness and attention.';

  @override
  String get stepInstructionVigilanceLetters =>
      'A series of letters will appear, one at a time.';

  @override
  String get stepInstructionVigilanceTap =>
      'Press the button when you see the letter “Α”.';

  @override
  String get stepInstructionFluency =>
      'Verbal fluency: as many words as you can beginning with the letter “Χ”, without proper nouns or derived words, within 1 minute.';

  @override
  String get stepInstructionSimilarities =>
      'What do the following pairs have in common?';

  @override
  String get stepInstructionSimilaritiesExample =>
      'e.g. banana - orange = fruit';

  @override
  String get stepInstructionSimilaritiesHint =>
      'Tap “Hint” for example answers.';

  @override
  String get stepInstructionClock => 'Move the hands so that they show 11:10';

  @override
  String get stepInstructionTrails =>
      'Join the circles starting from 1, then Α, then 2, Β, 3, Γ… up to 5 and Ε.';

  @override
  String get stepInstructionTrailsRetry =>
      'If you make a mistake you can try again. If you are struggling, press “Next”. Time: 2 minutes.';

  @override
  String get stepInstructionDrawCube => 'Copy the cube you see below.';

  @override
  String get stepInstructionConnectCube =>
      'Copy the cube by joining the dots. Tap one dot first, then the next.';

  @override
  String get stepInstructionConnectCubeAlmost =>
      'Almost right — remove the red lines';

  @override
  String get stepInstructionRepeatSentence => 'Say the sentence…';

  @override
  String get stepInstructionGesturesIntro =>
      'When you press “Start”, the camera will turn on for 1 minute.\n\nYou need to perform the following movements:';

  @override
  String get stepInstructionGesturesPerformAll => 'Perform all the movements.';

  @override
  String stepGestureRecognised(Object gesture) {
    return '$gesture\nRecognised!';
  }

  @override
  String get stepGesturesAllDetected =>
      'Well done! All gestures were detected.\n\nScore: 3.00/3.00';

  @override
  String stepWordNumbered(Object number) {
    return 'Word $number';
  }

  @override
  String stepExampleAnswer(Object hint) {
    return 'Example: $hint';
  }

  @override
  String stepHintFor(Object hint) {
    return 'Hint: $hint';
  }

  @override
  String get stepHeardTargetLetter => 'I heard Α';

  @override
  String get stepStartTest => 'Start test';

  @override
  String stepSecondsValue(Object seconds) {
    return '$seconds s';
  }

  @override
  String stepMemoriseTimeLeft(Object seconds) {
    return 'Time to memorise: $seconds';
  }

  @override
  String get stepInstructionRepeatSentencesIntro =>
      'A sentence will appear for 20 seconds. Try to read it and memorise it. You will then be asked to repeat it back as accurately as you can.\n\nYou can see the sentence again for 3 seconds if you need to (Hint), and you can clear what the microphone heard (Clear). Press “Next” to move on, even if you have not answered.';

  @override
  String get stepInstructionRepeatBack =>
      'Repeat the sentence you read. Press the microphone to start; if it stops, press it again.';

  @override
  String get fabGoNoGoInstructions =>
      'The numbers 1 and 2 will appear one at a time.\n\nPress the “Tap” button when 1 appears. Do not press it when 2 appears.\n\nWe will run a short practice round first to explain the rules, then the real task.';

  @override
  String get fabGoNoGoRules => '“1” — tap\n“2” — do not tap';

  @override
  String get fabGoNoGoPracticeIntro =>
      'Practice round. Apply the rules. If you make a mistake you will see an explanation. Press “Start” to begin the practice.';

  @override
  String get fabGoNoGoTestIntro =>
      'Main task. Apply the rules. Press “Start” to begin.';

  @override
  String get fabTap => 'Tap';

  @override
  String get fabGoNoGoMissed => 'You should have tapped once, but did not tap.';

  @override
  String fabGoNoGoTooMany(Object count) {
    return 'You should have tapped once; you tapped $count times.';
  }

  @override
  String fabGoNoGoShouldNotTap(Object count) {
    return 'You should not have tapped; you tapped $count times.';
  }

  @override
  String fabScoreValue(Object score) {
    return 'Score: $score';
  }

  @override
  String get fabGoNoGoResultStreak =>
      'You gave the same answer at least 4 times in a row.';

  @override
  String get fabGoNoGoResultPerfect => 'You made no mistakes.';

  @override
  String get fabGoNoGoResultFew => 'You made 1 or 2 mistakes.';

  @override
  String get fabGoNoGoResultMany => 'You made more than 2 mistakes.';

  @override
  String get fabFluencyInstructions =>
      'Say as many words as you can beginning with the letter Κ, other than surnames and proper names.\n\nYou have 60 seconds.\n\nScoring: more than 10 words = 3 points, 6–10 = 2, 3–5 = 1, fewer than 3 = 0.';

  @override
  String get fabFluencyTitle => 'Verbal fluency';

  @override
  String get fabFluencyPrompt => 'Words beginning with “Κ”';

  @override
  String get fabFluencyResultMany => 'More than 10 words.';

  @override
  String fabFluencyResultCount(Object count) {
    return '$count words.';
  }

  @override
  String get fabFluencyResultFew => 'Fewer than 3 words.';

  @override
  String get fabSimilaritiesTitle => 'Similarities';

  @override
  String get fabSimilaritiesInstructions =>
      '“What do they have in common?”\n\nFor example: banana - orange = fruit.\n\nYou can type or use the microphone. Tap “Hint” on the first question if you would like help.\n\nScoring: 3 correct answers = 3 points, 2 = 2, 1 = 1, none = 0.';

  @override
  String fabQuestionOfCount(Object current, Object total) {
    return 'Question $current of $total';
  }

  @override
  String fabCorrectAnswersCount(Object count) {
    return '$count correct answers.';
  }

  @override
  String get fabNoCorrectAnswers => 'No correct answers.';

  @override
  String get fabConflictingInstructions =>
      'Tap once when I tap twice. Tap twice when I tap once.\n\nWe will run a short practice round first, then the real task.';

  @override
  String get fabExaminerTapsOnce => 'I tap once';

  @override
  String get fabExaminerTapsTwice => 'I tap twice';

  @override
  String get fabYourTurn => 'Your turn';

  @override
  String fabGesturesRemaining(Object gestures) {
    return 'Remaining: $gestures';
  }

  @override
  String get fabConflictingRules => '“1” — tap twice\n“2” — tap once';

  @override
  String get fabConflictingPracticeIntro =>
      'Practice round. Follow the rules so you get a feel for the task. Press “Start” to begin the practice.';

  @override
  String get fabConflictingTestIntro =>
      'Main task. Apply the rules. Press “Start” to begin.';

  @override
  String fabExpectedTapsOnce(Object count) {
    return 'You should have tapped once; you tapped $count times.';
  }

  @override
  String fabExpectedTapsTwice(Object count) {
    return 'You should have tapped twice; you tapped $count times.';
  }

  @override
  String get fabResultStreakStimulus =>
      'You matched the number shown at least 4 times in a row.';
}
