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
}
