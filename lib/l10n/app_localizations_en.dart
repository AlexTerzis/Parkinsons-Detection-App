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
  String get apptBookTitle => 'Request an appointment';

  @override
  String get apptPickDate => 'Preferred date';

  @override
  String get apptPickTime => 'Preferred time';

  @override
  String get apptReason => 'Reason for the visit (optional)';

  @override
  String get apptSendRequest => 'Send request';

  @override
  String apptRequested(Object doctor) {
    return 'Request sent to $doctor';
  }

  @override
  String get apptUpcoming => 'Appointments';

  @override
  String get apptTabTitle => 'Appointments';

  @override
  String get apptPending => 'Awaiting your answer';

  @override
  String get apptConfirmedSection => 'Confirmed';

  @override
  String get apptClosedSection => 'Past and cancelled';

  @override
  String get apptNonePending => 'No appointment requests.';

  @override
  String get apptConfirm => 'Confirm';

  @override
  String get apptDecline => 'Decline';

  @override
  String get apptProposeAnother => 'Suggest another time';

  @override
  String get apptReplyOptional => 'Message to the patient (optional)';

  @override
  String apptRequestedOn(Object when) {
    return 'Requested $when';
  }

  @override
  String get apptMarkCompleted => 'Mark as done';

  @override
  String get apptConfirmedToast => 'Appointment confirmed';

  @override
  String get apptDeclinedToast => 'Appointment declined';

  @override
  String get apptPatientNote => 'Patient\'s note';

  @override
  String get apptNone => 'No appointments yet.';

  @override
  String get apptStatusRequested => 'Awaiting confirmation';

  @override
  String get apptStatusConfirmed => 'Confirmed';

  @override
  String get apptStatusDeclined => 'Declined';

  @override
  String get apptStatusCancelled => 'Cancelled';

  @override
  String get apptStatusCompleted => 'Completed';

  @override
  String get apptCancel => 'Cancel appointment';

  @override
  String get apptCancelConfirmTitle => 'Cancel this appointment?';

  @override
  String get apptCancelConfirmBody =>
      'Your doctor will be told it is no longer needed.';

  @override
  String apptProposedTime(Object when) {
    return 'Your doctor suggested $when instead';
  }

  @override
  String get apptAcceptProposed => 'Accept this time';

  @override
  String get apptDoctorMessage => 'Message from your doctor';

  @override
  String get apptPastTimeError => 'Choose a time in the future.';

  @override
  String get apptPickSlotTitle => 'Choose a time';

  @override
  String get apptNoOpenSlots =>
      'This doctor has not published any free times yet.';

  @override
  String get apptFreeTimesOn => 'Free times';

  @override
  String get apptPickDayWithTimes => 'Pick a day with a dot under it.';

  @override
  String apptBooked(Object doctor, Object when) {
    return 'Booked with $doctor for $when';
  }

  @override
  String get apptSlotTaken =>
      'Someone else has just taken that time. Please pick another.';

  @override
  String get apptSlotWithdrawn => 'That time is no longer offered.';

  @override
  String get apptCancelledToast => 'Appointment cancelled';

  @override
  String get apptCancelBookingBody =>
      'The patient will be told, and the time goes back on your calendar.';

  @override
  String get apptCalendar => 'My calendar';

  @override
  String get apptCalendarError =>
      'Your calendar could not be loaded. Check your connection and try again.';

  @override
  String get apptAddTimes => 'Add free times';

  @override
  String get apptAddTimesTitle => 'Publish free times';

  @override
  String get apptFrom => 'From';

  @override
  String get apptTo => 'Until';

  @override
  String get apptSlotLength => 'Each appointment lasts';

  @override
  String apptMinutes(Object count) {
    return '$count minutes';
  }

  @override
  String apptWillPublish(Object count) {
    return 'This adds $count appointment times.';
  }

  @override
  String get apptEndBeforeStart => 'The end time must be after the start time.';

  @override
  String get apptPublish => 'Publish';

  @override
  String apptPublished(Object count) {
    return '$count times added to your calendar';
  }

  @override
  String get apptNothingToPublish =>
      'Those times are already on your calendar.';

  @override
  String get apptNoSlotsOnDay => 'Nothing published for this day.';

  @override
  String get apptSlotOpen => 'Free';

  @override
  String get apptSlotBooked => 'Booked';

  @override
  String get apptRemoveSlot => 'Remove this time';

  @override
  String get apptSlotRemoved => 'Time removed from your calendar';

  @override
  String get reportsLoadFailed =>
      'Your patients could not be loaded. Check your connection and try again.';

  @override
  String get reportSnapshotTitle => 'Overview';

  @override
  String get reportConcernExplainer =>
      'Higher means more concerning. 0% is the best possible result.';

  @override
  String get reportBatteriesTitle => 'Cognitive screening';

  @override
  String get reportQuestionnaireTitle => 'Reported symptoms';

  @override
  String get reportNoSymptomsReported => 'No symptoms were reported.';

  @override
  String get reportPerTestTitle => 'Test by test';

  @override
  String get reportBaselineTitle => 'Baseline assessment';

  @override
  String get reportBaselineExplainer =>
      'Taken once. MoCA and FAB are scored against published cut-offs.';

  @override
  String reportRepeatWarning(Object count) {
    return 'Attempt $count of the same form — the score may be inflated by familiarity.';
  }

  @override
  String get reportRepeatedTitle => 'Repeated measures';

  @override
  String get reportRepeatedExplainer =>
      'This app\'s own sensor tests, summarised across every sitting. These bands are provisional and are not a validated instrument.';

  @override
  String seriesSittings(Object count) {
    return '$count sittings';
  }

  @override
  String get seriesImproving => 'improving';

  @override
  String get seriesWorsening => 'worsening';

  @override
  String get seriesStable => 'stable';

  @override
  String get seriesTooFew => 'too few to judge a trend';

  @override
  String repeatTestTitle(Object test) {
    return 'Take $test again?';
  }

  @override
  String repeatTestTakenOn(Object date) {
    return 'You last did this on $date.';
  }

  @override
  String get repeatBatteryBody =>
      'This is the same form as last time. Remembering the words and tasks from before tends to raise the score, so a repeat is harder to compare against your first result. Worth doing if a lot of time has passed or the last attempt was interrupted.';

  @override
  String get repeatQuestionnaireBody =>
      'This asks about your symptom history, which does not usually change from week to week. Worth doing again if something has genuinely changed.';

  @override
  String get repeatTestConfirm => 'Take it again';

  @override
  String reportQuestionnaireCompleted(Object answered, Object reported) {
    return 'Completed — $answered questions answered, $reported reported as present.';
  }

  @override
  String reportSectionAnswered(Object answered, Object reported) {
    return '$answered answered · $reported reported';
  }

  @override
  String reportOverallVerdict(Object band) {
    return 'Overall: $band';
  }

  @override
  String reportOverallDetail(Object percent, Object tests) {
    return 'Median $percent% across $tests repeated tests';
  }

  @override
  String get reportGapsTitle => 'What this assessment could not measure';

  @override
  String get reasoningUnavailable =>
      'The reasoning service could not be reached, so no conclusions are shown.';

  @override
  String get gapNotTaken => 'not taken';

  @override
  String get gapNothingMeasured => 'recorded, but nothing could be measured';

  @override
  String gapPartlyRecorded(Object missing, Object total) {
    return '$missing of $total parts not recorded';
  }

  @override
  String gapLowQuality(Object percent) {
    return 'recording quality only $percent%';
  }

  @override
  String get leaveDoctor => 'Leave this doctor';

  @override
  String leaveDoctorConfirmTitle(Object doctor) {
    return 'Leave $doctor?';
  }

  @override
  String get leaveDoctorConfirmBody =>
      'You will stop sharing new results with them, and any appointment not yet held will be cancelled. Reports you have already sent stay with them.';

  @override
  String get leaveDoctorConfirm => 'Leave';

  @override
  String leftDoctor(Object doctor) {
    return 'You have left $doctor';
  }

  @override
  String get changeDoctor => 'Change doctor';

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
  String get doctorsLoadFailed =>
      'The list of doctors could not be loaded. Check your connection and try again.';

  @override
  String get retryAction => 'Try again';

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
  String get doctorNotes => 'Notes';

  @override
  String get openPatient => 'Open patient';

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
      'Both hands are recorded together, so the test is half as many steps. Each hand is smaller in the picture and the hands can hide one another, so the measurements are less precise than testing one hand at a time.';

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
      'Elbow on the table, hand up, palm facing the camera. Open your hand wide, then make a tight fist, as fully and as fast as you can.';

  @override
  String get cameraInstructionFingerTap =>
      'Elbow on the table, hand up, palm facing the camera. Tap your thumb and index finger together, as big and as fast as you can.';

  @override
  String get cameraInstructionPronation =>
      'Elbow on the table, hand up, fingers to the ceiling. Turn your hand so the palm faces the camera, then the back of the hand, over and over, as fully and as fast as you can.';

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
  String get postureTest => 'Hand posture test';

  @override
  String get testNamePosture => 'Postures';

  @override
  String get postureIntroTitle => 'Copying hand postures';

  @override
  String get postureIntroBody =>
      'You will be shown nine hand shapes, one at a time. Copy each one with either hand and hold it in front of the camera until it is recognised.';

  @override
  String get postureIntroNote =>
      'This records how well hand shapes are copied. It is not a diagnosis and cannot say whether you have any condition.';

  @override
  String get postureStart => 'Start';

  @override
  String get postureExit => 'Exit';

  @override
  String postureStepOf(Object current, Object total) {
    return 'Shape $current of $total';
  }

  @override
  String get postureCopyThis => 'Copy this shape';

  @override
  String get postureSecondTry => 'Let\'s try that one again';

  @override
  String get postureReady => 'Show me';

  @override
  String get postureHoldIt => 'Hold it there';

  @override
  String get postureSkip => 'Skip this shape';

  @override
  String get postureHandNotVisible => 'Move your hand into view';

  @override
  String postureSecondsLeft(Object seconds) {
    return '${seconds}s';
  }

  @override
  String get postureResultsTitle => 'Hand postures';

  @override
  String postureScore(Object points, Object total) {
    return '$points of $total';
  }

  @override
  String get postureCopiedFirst => 'Copied first time';

  @override
  String get postureCopiedSecond => 'Copied on the second try';

  @override
  String get postureNotCopied => 'Not copied';

  @override
  String get postureNotRecorded => 'Hand not seen';

  @override
  String get postureQuality => 'Recording quality';

  @override
  String get postureNothingRecorded =>
      'The camera did not get a usable view of your hand, so this run was not saved. Trying again in better light usually helps.';

  @override
  String get postureSaved => 'Saved to your results.';

  @override
  String get postureNotSaved => 'This result was not saved.';

  @override
  String get postureRepeat => 'Repeat test';

  @override
  String get postureNext => 'Next';

  @override
  String postureUnrecordedNote(Object count) {
    return '$count shape(s) could not be seen well enough to judge. Those are not counted as mistakes.';
  }

  @override
  String get cameraHandBoth => 'Both hands';

  @override
  String get cameraPacingLabel => 'Pace';

  @override
  String get cameraPacingSelf => 'I\'ll tap when ready';

  @override
  String get cameraPacingTimed => 'Automatic';

  @override
  String get cameraPacingSelfNote =>
      'Take as long as you like reading each instruction. Only the movement itself is timed.';

  @override
  String get cameraPacingTimedNote =>
      'Each step starts on its own after a short countdown. Useful if the phone is out of reach.';

  @override
  String get cameraStepReady => 'When you are ready, start this step.';

  @override
  String get cameraStartStep => 'Start this step';

  @override
  String get cameraGetReady => 'Get ready…';

  @override
  String get cameraShowHandToBegin => 'Show your hand to the camera to begin';

  @override
  String cameraApproxDurationRange(Object high, Object low) {
    return 'About $low-$high minutes';
  }

  @override
  String get cameraRetryTitle => 'Let\'s record that step again';

  @override
  String cameraRetryBody(Object task) {
    return 'The recording of $task was not clear enough to measure. Nothing you have already completed is lost.';
  }

  @override
  String get cameraRetryAgain => 'Repeat this step';

  @override
  String get cameraRetryKeep => 'Continue anyway';

  @override
  String cameraRetryAttempt(Object current, Object total) {
    return 'Attempt $current of $total';
  }

  @override
  String cameraRetryExhausted(Object count) {
    return 'This step has been recorded $count times. You can continue without it.';
  }

  @override
  String get cameraQualityUsableFrames =>
      'The hand was not visible for enough of the recording. Keep it in view of the camera for the whole step.';

  @override
  String get cameraQualityHandInFrame =>
      'Part of the hand kept leaving the picture. Move the phone a little farther away so the whole hand fits.';

  @override
  String get cameraQualityHandedness =>
      'The other hand was in view for much of this step. Show only the hand being tested.';

  @override
  String get cameraQualityContinuity =>
      'The hand disappeared from view partway through. Keep it steady in front of the camera.';

  @override
  String get cameraQualityFps =>
      'The camera could not keep up during this step. Closing other apps and trying again usually helps.';

  @override
  String get cameraQualityDuration => 'Too little of this step was recorded.';

  @override
  String get cameraQualityLandmarks =>
      'The whole hand was not always detected. Keep your fingers spread and your palm facing the camera.';

  @override
  String get cameraQualityHandSize =>
      'The distance between your hand and the camera changed during this step. Hold the phone still and keep your hand at the same distance.';

  @override
  String get cameraResultsTitle => 'Movement measurements';

  @override
  String get cameraMetricPeakSpeed => 'Fastest speed';

  @override
  String get cameraMetricRecordedTime => 'Recorded time';

  @override
  String cameraUnitPalmWidthsPerSecond(Object value) {
    return '$value palm widths/s';
  }

  @override
  String get cameraOverallMovement => 'Overall movement';

  @override
  String get cameraOverallMovementNote =>
      'Measured across the whole recording. These are available whenever any frames were captured, so they are shown even when the step-by-step measurements are not.';

  @override
  String get cameraMetricSpeedVariation => 'Speed variation';

  @override
  String get cameraMetricAccelVariation => 'Acceleration variation';

  @override
  String get cameraMetricJerkVariation => 'Jerk variation';

  @override
  String get cameraMetricFingerSpread => 'Finger spread';

  @override
  String get cameraMetricTremorLevel => 'Movement while still';

  @override
  String get cameraMetricHandDifference => 'Difference between hands';

  @override
  String get cameraDiagnosticsTitle => 'Technical details';

  @override
  String get cameraDiagFramesLabel => 'Frames (usable / total)';

  @override
  String get cameraDiagFpsLabel => 'Frames per second';

  @override
  String get cameraDiagCyclesLabel => 'Movements detected';

  @override
  String get cameraDiagSignalLabel => 'Movement range';

  @override
  String get cameraDiagErrorLabel => 'Analysis error';

  @override
  String get cameraAnalysisFailed =>
      'The detailed analysis could not be completed, so only the overall measurements are shown.';

  @override
  String get cameraResultsIntro =>
      'These are measurements of how your hands moved during the recording. They are not a diagnosis and cannot say whether you have any condition.';

  @override
  String get cameraResultsQuality => 'Recording quality';

  @override
  String get cameraResultsOverallConfidence => 'Overall';

  @override
  String cameraResultsTasksDone(Object done, Object total) {
    return '$done of $total steps measured';
  }

  @override
  String cameraResultsRetries(Object count) {
    return '$count step(s) recorded more than once';
  }

  @override
  String get cameraResultsNotSaved => 'This result was not saved.';

  @override
  String get cameraResultsSaved => 'Saved to your results.';

  @override
  String get cameraResultsNothing =>
      'Nothing could be measured from this recording, so it was not saved. Recording the test again usually helps.';

  @override
  String get cameraResultsInsufficient => 'Insufficient data';

  @override
  String get cameraResultsNotRecorded =>
      'This step was not recorded well enough to measure.';

  @override
  String get cameraResultsTooFewMovements =>
      'Too few movements were detected to work this out.';

  @override
  String get cameraResultsDifference => 'Difference between hands';

  @override
  String get cameraResultsNoComparison =>
      'Both hands are needed for a comparison.';

  @override
  String get cameraResultsTechnical => 'Technical details';

  @override
  String get cameraResultsRepeat => 'Repeat test';

  @override
  String get cameraResultsNext => 'Next';

  @override
  String get cameraMetricTapsPerSecond => 'Taps per second';

  @override
  String get cameraMetricMovementsPerSecond => 'Movements per second';

  @override
  String get cameraMetricTurnsPerSecond => 'Turns per second';

  @override
  String get cameraMetricAmplitude => 'Movement size';

  @override
  String get cameraMetricRhythm => 'Rhythm variability';

  @override
  String get cameraMetricAmplitudeDecrement => 'Change in size over the step';

  @override
  String get cameraMetricSpeedDecrement => 'Change in speed over the step';

  @override
  String get cameraMetricPauses => 'Pauses';

  @override
  String get cameraMetricSpeed => 'Average speed';

  @override
  String get cameraMetricTremorAmplitude => 'Movement while at rest';

  @override
  String get cameraMetricTremorFrequency => 'Rate of that movement';

  @override
  String get cameraMetricRestDuration => 'Usable recording';

  @override
  String get cameraMetricCycles => 'Movements detected';

  @override
  String cameraUnitPerSecond(Object value) {
    return '$value/s';
  }

  @override
  String cameraUnitHertz(Object value) {
    return '$value Hz';
  }

  @override
  String cameraUnitSeconds(Object value) {
    return '$value s';
  }

  @override
  String cameraUnitPalmWidths(Object value) {
    return '$value palm widths';
  }

  @override
  String cameraUnitPercent(Object value) {
    return '$value%';
  }

  @override
  String cameraUnitCount(Object value) {
    return '$value';
  }

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
      'Say as many of the 5 words you memorised at the start of the test as you can remember (voice only; the order does not matter).';

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

  @override
  String get testCompleteTitle => 'Test complete';

  @override
  String get testCompleteSaved => 'Your result has been saved.';

  @override
  String get testCompleteNotSaved =>
      'Your result could not be saved, but here it is.';

  @override
  String get testCompleteScore => 'Score';

  @override
  String get testCompleteDone => 'Done';

  @override
  String get testCompleteViewAll => 'See all my results';

  @override
  String get bandReassuringWorse => 'Nothing notable came up in this test.';

  @override
  String get bandBorderlineWorse =>
      'This result sits in the middle range. Repeating the test on another day gives a clearer picture.';

  @override
  String get bandNotableWorse =>
      'This result is worth mentioning to your doctor. It is a screening check, not a diagnosis.';

  @override
  String get bandReassuringBetter => 'This result is in the expected range.';

  @override
  String get bandBorderlineBetter =>
      'This result is slightly below the expected range. Repeating it on another day gives a clearer picture.';

  @override
  String get bandNotableBetter =>
      'This result is below the expected range and is worth mentioning to your doctor. It is a screening check, not a diagnosis.';

  @override
  String get screeningDisclaimer =>
      'This app is a screening aid. It cannot diagnose Parkinson\'s disease, and only a clinician can interpret these results.';

  @override
  String get guestKeepResultsTitle => 'Keep these results';

  @override
  String get guestKeepResultsBody =>
      'You are using a guest account. Create an account to keep your results and share them with a doctor.';

  @override
  String get guestExitTitle => 'Leave without an account?';

  @override
  String get guestExitBody =>
      'Your results are tied to this guest session on this device. If it is lost, so are they. Creating an account keeps everything you have done so far.';

  @override
  String get guestExitStay => 'Create an account';

  @override
  String get guestExitLeave => 'Leave anyway';

  @override
  String get guestSignInDisabled =>
      'Guest sign-in is not enabled for this app yet. Please create an account, or try again later.';

  @override
  String get testNameDrawing => 'Drawing';

  @override
  String get testNameQuestionnaire => 'Questionnaire';

  @override
  String get testNameTremor => 'Tremor';

  @override
  String get testNameTap => 'Tapping';

  @override
  String get testNameVoice => 'Voice';

  @override
  String get testNameCamera => 'Camera';

  @override
  String get testNameNeuro => 'Memory';

  @override
  String get testNameFab => 'Reasoning';

  @override
  String get bandLabelReassuring => 'Reassuring';

  @override
  String get bandLabelBorderline => 'Borderline';

  @override
  String get bandLabelNotable => 'Notable';

  @override
  String get resultsInfoTitle => 'About these scores';

  @override
  String get resultsInfoBody =>
      'Each bar is the most recent result for that test, shown as a level of concern from 0% to 100%. Higher always means more worth looking at, whichever test it came from.\n\nThat needs saying because the tests do not all count the same way. On the tapping or tremor tests a high raw score means more sign of tremor; on the memory and reasoning batteries a high raw score means you did well. Both are converted here, so a low bar is always the calmer one.\n\nThe three bands — reassuring, borderline and notable — are provisional cut-offs, not clinical thresholds. A single notable result on one day means far less than the same result appearing again and again across weeks.\n\nTap a test to see how it has changed over time.';

  @override
  String get overallTrend => 'Overall trend';

  @override
  String get trendInfoTitle => 'About the trend';

  @override
  String get trendInfoBody =>
      'One point per day on which you took at least one test, averaged across every test you took that day.\n\nUse it to see direction rather than detail: a line drifting upwards over several weeks is worth mentioning to your doctor, while a single spike usually says more about a tired hand, a rushed attempt or a noisy room than about your health.\n\nDays with no tests are simply missing from the line, so a stretch of activity followed by a gap will look like one long step. Taking tests at roughly the same time of day makes the comparison fairer.';

  @override
  String get trendWindowLabel => 'Averaged over';

  @override
  String trendWindowLast(int count) {
    return 'Last $count days';
  }

  @override
  String get trendNeedsMoreDays =>
      'Not enough tests in this period to draw a trend. Choose a longer period, or take a test on another day.';

  @override
  String get summaryInfoTitle => 'About the summary';

  @override
  String get summaryInfoBody =>
      'Each spoke is one test, and the distance from the centre is your average level of concern for it across every attempt.\n\nA small, even shape means nothing stands out. A shape stretched towards one spoke means that one test reads differently from the rest — which is the thing actually worth showing a clinician, since Parkinson\'s rarely affects everything equally at first.\n\nBecause these are averages over all your attempts, the shape moves slowly and early results keep pulling on it for a long time.';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get medicalDisclaimer => 'Medical disclaimer';

  @override
  String get medicalDisclaimerBody =>
      'This app is not a medical device and does not provide a diagnosis.\n\nThe tests here are screening aids. They look for patterns that are common in Parkinson\'s disease, but many other things — tiredness, caffeine, medication, anxiety, an unrelated condition, or simply an awkward grip on the phone — produce the same patterns. A concerning score does not mean you have Parkinson\'s disease, and a reassuring score does not rule it out.\n\nOnly a qualified clinician can diagnose Parkinson\'s disease, and only after an in-person examination. Take any result that worries you to your doctor, and never start, stop or change a medication based on what this app shows you.\n\nIf you have sudden or severe symptoms, seek medical help immediately rather than taking a test.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfService => 'Terms of use';

  @override
  String get legalDocumentPlaceholder =>
      'This document has not been published yet.\n\nUntil it is, here is what the app actually does with your data: your test results, questionnaire answers and voice recordings are stored in your account and are visible to you and to any doctor you choose to share them with. Nothing is shared with anyone else.\n\nPlease contact the app\'s provider if you need the full document before it is available here.';

  @override
  String get cameraSetupTitle => 'Set up the camera';

  @override
  String get cameraSetupStep1 => 'Turn your phone on its side (landscape).';

  @override
  String get cameraSetupStep2 =>
      'Prop it up on a table against something steady, screen facing you, tilted so the camera points at your hands.';

  @override
  String get cameraSetupStep3 =>
      'Sit about 50–70 cm away — roughly an arm\'s length — with your elbows on the table.';

  @override
  String get cameraSetupStep4 =>
      'Use a well-lit room, with the light in front of you rather than behind you.';

  @override
  String get cameraSetupStep5 =>
      'Raise both hands. When the check below says ready, tap Start. You won\'t need to touch the phone again — just follow the voice.';

  @override
  String get cameraSetupHintNoHands =>
      'Raise both hands in front of the camera';

  @override
  String get cameraSetupHintOneHand => 'Only one hand is visible — show both';

  @override
  String get cameraSetupHintTooFar =>
      'Your hands look small — move a little closer';

  @override
  String get cameraSetupHintTooClose =>
      'Your hands are cut off — move back a little';

  @override
  String get cameraSetupHintReady => 'Both hands visible — ready to start';

  @override
  String get cameraSetupWaitingCamera => 'Starting the camera…';

  @override
  String cameraSetupFps(Object fps) {
    return 'Camera speed: $fps frames per second';
  }

  @override
  String get cameraSetupSlow =>
      'The camera is running slowly. More light usually helps, and closing other apps.';

  @override
  String cameraSetupDuration(Object minutes, Object steps) {
    return 'About $minutes minutes: $steps steps of 10 seconds each.';
  }

  @override
  String get cameraTaskPosture => 'Arms held out';

  @override
  String get cameraInstructionRestBoth =>
      'Rest both forearms on the table, palms down, hands relaxed and still, in view of the camera.';

  @override
  String get cameraInstructionPosture =>
      'Lift both hands up in front of you, palms facing the camera, fingers spread, elbows off the table. Hold them as still as you can.';

  @override
  String get cameraShowHandsToBegin => 'Show both hands to the camera';

  @override
  String cameraSwitchHands(Object hand) {
    return 'Now use your $hand. Put the other hand down on the table.';
  }

  @override
  String get cameraRetryNotice => 'Let\'s do this step once more.';

  @override
  String get cameraRecording => 'Recording';

  @override
  String get cameraSayGo => 'Go.';

  @override
  String get cameraSayStop => 'Stop. Relax.';

  @override
  String get cameraSayFinished => 'Well done. The test is finished.';

  @override
  String get cameraSayRetry => 'Let\'s do that once more.';

  @override
  String get cameraResultsScoreTitle => 'Your result';

  @override
  String cameraResultsScoreValue(Object score) {
    return '$score / 100';
  }

  @override
  String get cameraResultsScoreNote =>
      'This score is worked out automatically from the video, using rules modelled on how doctors rate these movements (0 = normal, 4 = severe). It has not yet been checked against doctors\' ratings and it is not a diagnosis. Share it with your doctor.';

  @override
  String get cameraResultsRatingsTitle => 'Rating per movement';

  @override
  String get cameraResultsRatingsScale =>
      '0 normal · 1 slight · 2 mild · 3 moderate · 4 severe';

  @override
  String get cameraResultsBradykinesia => 'Slowness of movement';

  @override
  String get cameraResultsTremor => 'Tremor';

  @override
  String get cameraResultsAsymmetry => 'Difference between hands';

  @override
  String cameraResultsWorseHand(Object hand) {
    return 'The $hand moved less well.';
  }

  @override
  String get cameraResultsNotRated => 'Not rated';

  @override
  String get cameraResultsNoScore =>
      'No movement step could be rated from this recording, so no score was saved.';

  @override
  String get cameraGrade0 => 'Normal';

  @override
  String get cameraGrade1 => 'Slight';

  @override
  String get cameraGrade2 => 'Mild';

  @override
  String get cameraGrade3 => 'Moderate';

  @override
  String get cameraGrade4 => 'Severe';

  @override
  String cameraRatingValue(Object grade, Object rating) {
    return '$rating · $grade';
  }
}
