import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('el'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Parkinson AI Detector'**
  String get appTitle;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @dobHint.
  ///
  /// In en, this message translates to:
  /// **'yyyy-mm-dd'**
  String get dobHint;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'LOG OUT'**
  String get logOut;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @greek.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get greek;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @iAmA.
  ///
  /// In en, this message translates to:
  /// **'I am a'**
  String get iAmA;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @keepMeLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Keep me logged in'**
  String get keepMeLoggedIn;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @passwordRecovery.
  ///
  /// In en, this message translates to:
  /// **'Password Recovery'**
  String get passwordRecovery;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @emailSent.
  ///
  /// In en, this message translates to:
  /// **'If the email exists, a reset link has been sent.'**
  String get emailSent;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @noRecommendations.
  ///
  /// In en, this message translates to:
  /// **'No recommendations returned'**
  String get noRecommendations;

  /// No description provided for @questionnaire.
  ///
  /// In en, this message translates to:
  /// **'Questionnaire'**
  String get questionnaire;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @tapTest.
  ///
  /// In en, this message translates to:
  /// **'Tap Test'**
  String get tapTest;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time left: {seconds}s'**
  String timeLeft(Object seconds);

  /// No description provided for @tap.
  ///
  /// In en, this message translates to:
  /// **'TAP'**
  String get tap;

  /// No description provided for @startTest.
  ///
  /// In en, this message translates to:
  /// **'Start Test'**
  String get startTest;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @pressStart.
  ///
  /// In en, this message translates to:
  /// **'Press start to begin'**
  String get pressStart;

  /// No description provided for @startingTest.
  ///
  /// In en, this message translates to:
  /// **'Starting test...'**
  String get startingTest;

  /// No description provided for @tapRightHand.
  ///
  /// In en, this message translates to:
  /// **'Tap with right hand'**
  String get tapRightHand;

  /// No description provided for @switchHands.
  ///
  /// In en, this message translates to:
  /// **'Switch hands'**
  String get switchHands;

  /// No description provided for @tapLeftHand.
  ///
  /// In en, this message translates to:
  /// **'Tap with left hand'**
  String get tapLeftHand;

  /// No description provided for @testCompleted.
  ///
  /// In en, this message translates to:
  /// **'Test completed'**
  String get testCompleted;

  /// No description provided for @testStopped.
  ///
  /// In en, this message translates to:
  /// **'Test stopped'**
  String get testStopped;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @tabTests.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get tabTests;

  /// No description provided for @tabResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get tabResults;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finishAction.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishAction;

  /// No description provided for @voiceTest.
  ///
  /// In en, this message translates to:
  /// **'Voice Test'**
  String get voiceTest;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @microphonePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get microphonePermissionDenied;

  /// No description provided for @possibleParkinson.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Possible Parkinson pattern ({percent}%)'**
  String possibleParkinson(Object percent);

  /// No description provided for @normalVoice.
  ///
  /// In en, this message translates to:
  /// **'✅ Normal voice ({percent}%)'**
  String normalVoice(Object percent);

  /// No description provided for @recordingFailed.
  ///
  /// In en, this message translates to:
  /// **'Recording failed'**
  String get recordingFailed;

  /// No description provided for @noDoctorSelected.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t selected a doctor yet.\nClick to select'**
  String get noDoctorSelected;

  /// No description provided for @myDoctor.
  ///
  /// In en, this message translates to:
  /// **'My Doctor'**
  String get myDoctor;

  /// No description provided for @sendResults.
  ///
  /// In en, this message translates to:
  /// **'Send Results'**
  String get sendResults;

  /// No description provided for @diagnoses.
  ///
  /// In en, this message translates to:
  /// **'Diagnoses'**
  String get diagnoses;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @apptBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Request an appointment'**
  String get apptBookTitle;

  /// No description provided for @apptPickDate.
  ///
  /// In en, this message translates to:
  /// **'Preferred date'**
  String get apptPickDate;

  /// No description provided for @apptPickTime.
  ///
  /// In en, this message translates to:
  /// **'Preferred time'**
  String get apptPickTime;

  /// No description provided for @apptReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for the visit (optional)'**
  String get apptReason;

  /// No description provided for @apptSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get apptSendRequest;

  /// No description provided for @apptRequested.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {doctor}'**
  String apptRequested(Object doctor);

  /// No description provided for @apptUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get apptUpcoming;

  /// No description provided for @apptTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get apptTabTitle;

  /// No description provided for @apptPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your answer'**
  String get apptPending;

  /// No description provided for @apptConfirmedSection.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get apptConfirmedSection;

  /// No description provided for @apptClosedSection.
  ///
  /// In en, this message translates to:
  /// **'Past and cancelled'**
  String get apptClosedSection;

  /// No description provided for @apptNonePending.
  ///
  /// In en, this message translates to:
  /// **'No appointment requests.'**
  String get apptNonePending;

  /// No description provided for @apptConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get apptConfirm;

  /// No description provided for @apptDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get apptDecline;

  /// No description provided for @apptProposeAnother.
  ///
  /// In en, this message translates to:
  /// **'Suggest another time'**
  String get apptProposeAnother;

  /// No description provided for @apptReplyOptional.
  ///
  /// In en, this message translates to:
  /// **'Message to the patient (optional)'**
  String get apptReplyOptional;

  /// No description provided for @apptRequestedOn.
  ///
  /// In en, this message translates to:
  /// **'Requested {when}'**
  String apptRequestedOn(Object when);

  /// No description provided for @apptMarkCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get apptMarkCompleted;

  /// No description provided for @apptConfirmedToast.
  ///
  /// In en, this message translates to:
  /// **'Appointment confirmed'**
  String get apptConfirmedToast;

  /// No description provided for @apptDeclinedToast.
  ///
  /// In en, this message translates to:
  /// **'Appointment declined'**
  String get apptDeclinedToast;

  /// No description provided for @apptPatientNote.
  ///
  /// In en, this message translates to:
  /// **'Patient\'s note'**
  String get apptPatientNote;

  /// No description provided for @apptNone.
  ///
  /// In en, this message translates to:
  /// **'No appointments yet.'**
  String get apptNone;

  /// No description provided for @apptStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get apptStatusRequested;

  /// No description provided for @apptStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get apptStatusConfirmed;

  /// No description provided for @apptStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get apptStatusDeclined;

  /// No description provided for @apptStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get apptStatusCancelled;

  /// No description provided for @apptStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get apptStatusCompleted;

  /// No description provided for @apptCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel appointment'**
  String get apptCancel;

  /// No description provided for @apptCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this appointment?'**
  String get apptCancelConfirmTitle;

  /// No description provided for @apptCancelConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your doctor will be told it is no longer needed.'**
  String get apptCancelConfirmBody;

  /// No description provided for @apptProposedTime.
  ///
  /// In en, this message translates to:
  /// **'Your doctor suggested {when} instead'**
  String apptProposedTime(Object when);

  /// No description provided for @apptAcceptProposed.
  ///
  /// In en, this message translates to:
  /// **'Accept this time'**
  String get apptAcceptProposed;

  /// No description provided for @apptDoctorMessage.
  ///
  /// In en, this message translates to:
  /// **'Message from your doctor'**
  String get apptDoctorMessage;

  /// No description provided for @apptPastTimeError.
  ///
  /// In en, this message translates to:
  /// **'Choose a time in the future.'**
  String get apptPastTimeError;

  /// No description provided for @apptPickSlotTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get apptPickSlotTitle;

  /// No description provided for @apptNoOpenSlots.
  ///
  /// In en, this message translates to:
  /// **'This doctor has not published any free times yet.'**
  String get apptNoOpenSlots;

  /// No description provided for @apptFreeTimesOn.
  ///
  /// In en, this message translates to:
  /// **'Free times'**
  String get apptFreeTimesOn;

  /// No description provided for @apptPickDayWithTimes.
  ///
  /// In en, this message translates to:
  /// **'Pick a day with a dot under it.'**
  String get apptPickDayWithTimes;

  /// No description provided for @apptBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked with {doctor} for {when}'**
  String apptBooked(Object doctor, Object when);

  /// No description provided for @apptSlotTaken.
  ///
  /// In en, this message translates to:
  /// **'Someone else has just taken that time. Please pick another.'**
  String get apptSlotTaken;

  /// No description provided for @apptSlotWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'That time is no longer offered.'**
  String get apptSlotWithdrawn;

  /// No description provided for @apptCancelledToast.
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled'**
  String get apptCancelledToast;

  /// No description provided for @apptCancelBookingBody.
  ///
  /// In en, this message translates to:
  /// **'The patient will be told, and the time goes back on your calendar.'**
  String get apptCancelBookingBody;

  /// No description provided for @apptCalendar.
  ///
  /// In en, this message translates to:
  /// **'My calendar'**
  String get apptCalendar;

  /// No description provided for @apptCalendarError.
  ///
  /// In en, this message translates to:
  /// **'Your calendar could not be loaded. Check your connection and try again.'**
  String get apptCalendarError;

  /// No description provided for @apptAddTimes.
  ///
  /// In en, this message translates to:
  /// **'Add free times'**
  String get apptAddTimes;

  /// No description provided for @apptAddTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish free times'**
  String get apptAddTimesTitle;

  /// No description provided for @apptFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get apptFrom;

  /// No description provided for @apptTo.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get apptTo;

  /// No description provided for @apptSlotLength.
  ///
  /// In en, this message translates to:
  /// **'Each appointment lasts'**
  String get apptSlotLength;

  /// No description provided for @apptMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String apptMinutes(Object count);

  /// No description provided for @apptWillPublish.
  ///
  /// In en, this message translates to:
  /// **'This adds {count} appointment times.'**
  String apptWillPublish(Object count);

  /// No description provided for @apptEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The end time must be after the start time.'**
  String get apptEndBeforeStart;

  /// No description provided for @apptPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get apptPublish;

  /// No description provided for @apptPublished.
  ///
  /// In en, this message translates to:
  /// **'{count} times added to your calendar'**
  String apptPublished(Object count);

  /// No description provided for @apptNothingToPublish.
  ///
  /// In en, this message translates to:
  /// **'Those times are already on your calendar.'**
  String get apptNothingToPublish;

  /// No description provided for @apptNoSlotsOnDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing published for this day.'**
  String get apptNoSlotsOnDay;

  /// No description provided for @apptSlotOpen.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get apptSlotOpen;

  /// No description provided for @apptSlotBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get apptSlotBooked;

  /// No description provided for @apptRemoveSlot.
  ///
  /// In en, this message translates to:
  /// **'Remove this time'**
  String get apptRemoveSlot;

  /// No description provided for @apptSlotRemoved.
  ///
  /// In en, this message translates to:
  /// **'Time removed from your calendar'**
  String get apptSlotRemoved;

  /// No description provided for @reportsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your patients could not be loaded. Check your connection and try again.'**
  String get reportsLoadFailed;

  /// No description provided for @reportSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get reportSnapshotTitle;

  /// No description provided for @reportConcernExplainer.
  ///
  /// In en, this message translates to:
  /// **'Higher means more concerning. 0% is the best possible result.'**
  String get reportConcernExplainer;

  /// No description provided for @reportBatteriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cognitive screening'**
  String get reportBatteriesTitle;

  /// No description provided for @reportQuestionnaireTitle.
  ///
  /// In en, this message translates to:
  /// **'Reported symptoms'**
  String get reportQuestionnaireTitle;

  /// No description provided for @reportNoSymptomsReported.
  ///
  /// In en, this message translates to:
  /// **'No symptoms were reported.'**
  String get reportNoSymptomsReported;

  /// No description provided for @reportPerTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Test by test'**
  String get reportPerTestTitle;

  /// No description provided for @reportBaselineTitle.
  ///
  /// In en, this message translates to:
  /// **'Baseline assessment'**
  String get reportBaselineTitle;

  /// No description provided for @reportBaselineExplainer.
  ///
  /// In en, this message translates to:
  /// **'Taken once. MoCA and FAB are scored against published cut-offs.'**
  String get reportBaselineExplainer;

  /// No description provided for @reportRepeatWarning.
  ///
  /// In en, this message translates to:
  /// **'Attempt {count} of the same form — the score may be inflated by familiarity.'**
  String reportRepeatWarning(Object count);

  /// No description provided for @reportRepeatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeated measures'**
  String get reportRepeatedTitle;

  /// No description provided for @reportRepeatedExplainer.
  ///
  /// In en, this message translates to:
  /// **'This app\'s own sensor tests, summarised across every sitting. These bands are provisional and are not a validated instrument.'**
  String get reportRepeatedExplainer;

  /// No description provided for @seriesSittings.
  ///
  /// In en, this message translates to:
  /// **'{count} sittings'**
  String seriesSittings(Object count);

  /// No description provided for @seriesImproving.
  ///
  /// In en, this message translates to:
  /// **'improving'**
  String get seriesImproving;

  /// No description provided for @seriesWorsening.
  ///
  /// In en, this message translates to:
  /// **'worsening'**
  String get seriesWorsening;

  /// No description provided for @seriesStable.
  ///
  /// In en, this message translates to:
  /// **'stable'**
  String get seriesStable;

  /// No description provided for @seriesTooFew.
  ///
  /// In en, this message translates to:
  /// **'too few to judge a trend'**
  String get seriesTooFew;

  /// No description provided for @repeatTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Take {test} again?'**
  String repeatTestTitle(Object test);

  /// No description provided for @repeatTestTakenOn.
  ///
  /// In en, this message translates to:
  /// **'You last did this on {date}.'**
  String repeatTestTakenOn(Object date);

  /// No description provided for @repeatBatteryBody.
  ///
  /// In en, this message translates to:
  /// **'This is the same form as last time. Remembering the words and tasks from before tends to raise the score, so a repeat is harder to compare against your first result. Worth doing if a lot of time has passed or the last attempt was interrupted.'**
  String get repeatBatteryBody;

  /// No description provided for @repeatQuestionnaireBody.
  ///
  /// In en, this message translates to:
  /// **'This asks about your symptom history, which does not usually change from week to week. Worth doing again if something has genuinely changed.'**
  String get repeatQuestionnaireBody;

  /// No description provided for @repeatTestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Take it again'**
  String get repeatTestConfirm;

  /// No description provided for @reportQuestionnaireCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed — {answered} questions answered, {reported} reported as present.'**
  String reportQuestionnaireCompleted(Object answered, Object reported);

  /// No description provided for @reportSectionAnswered.
  ///
  /// In en, this message translates to:
  /// **'{answered} answered · {reported} reported'**
  String reportSectionAnswered(Object answered, Object reported);

  /// No description provided for @reportOverallVerdict.
  ///
  /// In en, this message translates to:
  /// **'Overall: {band}'**
  String reportOverallVerdict(Object band);

  /// No description provided for @reportOverallDetail.
  ///
  /// In en, this message translates to:
  /// **'Median {percent}% across {tests} repeated tests'**
  String reportOverallDetail(Object percent, Object tests);

  /// No description provided for @reportGapsTitle.
  ///
  /// In en, this message translates to:
  /// **'What this assessment could not measure'**
  String get reportGapsTitle;

  /// No description provided for @reasoningUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The reasoning service could not be reached, so no conclusions are shown.'**
  String get reasoningUnavailable;

  /// No description provided for @gapNotTaken.
  ///
  /// In en, this message translates to:
  /// **'not taken'**
  String get gapNotTaken;

  /// No description provided for @gapNothingMeasured.
  ///
  /// In en, this message translates to:
  /// **'recorded, but nothing could be measured'**
  String get gapNothingMeasured;

  /// No description provided for @gapPartlyRecorded.
  ///
  /// In en, this message translates to:
  /// **'{missing} of {total} parts not recorded'**
  String gapPartlyRecorded(Object missing, Object total);

  /// No description provided for @gapLowQuality.
  ///
  /// In en, this message translates to:
  /// **'recording quality only {percent}%'**
  String gapLowQuality(Object percent);

  /// No description provided for @leaveDoctor.
  ///
  /// In en, this message translates to:
  /// **'Leave this doctor'**
  String get leaveDoctor;

  /// No description provided for @leaveDoctorConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {doctor}?'**
  String leaveDoctorConfirmTitle(Object doctor);

  /// No description provided for @leaveDoctorConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will stop sharing new results with them, and any appointment not yet held will be cancelled. Reports you have already sent stay with them.'**
  String get leaveDoctorConfirmBody;

  /// No description provided for @leaveDoctorConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveDoctorConfirm;

  /// No description provided for @leftDoctor.
  ///
  /// In en, this message translates to:
  /// **'You have left {doctor}'**
  String leftDoctor(Object doctor);

  /// No description provided for @changeDoctor.
  ///
  /// In en, this message translates to:
  /// **'Change doctor'**
  String get changeDoctor;

  /// No description provided for @getSecondOpinion.
  ///
  /// In en, this message translates to:
  /// **'Get Second Opinion'**
  String get getSecondOpinion;

  /// No description provided for @secondOpinions.
  ///
  /// In en, this message translates to:
  /// **'Second Opinions'**
  String get secondOpinions;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noDoctorFeedback.
  ///
  /// In en, this message translates to:
  /// **'No doctor feedback yet.'**
  String get noDoctorFeedback;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotesYet;

  /// No description provided for @completeOneTest.
  ///
  /// In en, this message translates to:
  /// **'Please complete at least one test first.'**
  String get completeOneTest;

  /// No description provided for @selectDoctor.
  ///
  /// In en, this message translates to:
  /// **'Select Doctor'**
  String get selectDoctor;

  /// No description provided for @searchDoctor.
  ///
  /// In en, this message translates to:
  /// **'Search doctor...'**
  String get searchDoctor;

  /// No description provided for @noDoctorsFound.
  ///
  /// In en, this message translates to:
  /// **'No doctors found'**
  String get noDoctorsFound;

  /// No description provided for @doctorsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The list of doctors could not be loaded. Check your connection and try again.'**
  String get doctorsLoadFailed;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryAction;

  /// No description provided for @resultsSentTo.
  ///
  /// In en, this message translates to:
  /// **'Results sent to {name}'**
  String resultsSentTo(Object name);

  /// No description provided for @testResults.
  ///
  /// In en, this message translates to:
  /// **'Test Results'**
  String get testResults;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @needThreeTests.
  ///
  /// In en, this message translates to:
  /// **'Complete at least 3 different tests to view the summary chart.'**
  String get needThreeTests;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String days(Object count);

  /// No description provided for @exportResults.
  ///
  /// In en, this message translates to:
  /// **'Export Results'**
  String get exportResults;

  /// No description provided for @cameraDetectionTest.
  ///
  /// In en, this message translates to:
  /// **'Camera Detection Test'**
  String get cameraDetectionTest;

  /// No description provided for @tremorTest.
  ///
  /// In en, this message translates to:
  /// **'Tremor Test'**
  String get tremorTest;

  /// No description provided for @drawingTest.
  ///
  /// In en, this message translates to:
  /// **'Drawing Test'**
  String get drawingTest;

  /// No description provided for @neuropsychologicalTest.
  ///
  /// In en, this message translates to:
  /// **'Neuropsychological Test'**
  String get neuropsychologicalTest;

  /// No description provided for @fabTest.
  ///
  /// In en, this message translates to:
  /// **'Frontal Assessment Battery Test'**
  String get fabTest;

  /// No description provided for @sendResultsToDoctor.
  ///
  /// In en, this message translates to:
  /// **'Send Results to Doctor'**
  String get sendResultsToDoctor;

  /// No description provided for @noHandsDetected.
  ///
  /// In en, this message translates to:
  /// **'No hands detected. Try again.'**
  String get noHandsDetected;

  /// No description provided for @testCompletedMsg.
  ///
  /// In en, this message translates to:
  /// **'{test} completed'**
  String testCompletedMsg(Object test);

  /// No description provided for @drawOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Draw on phone'**
  String get drawOnPhone;

  /// No description provided for @takePicture.
  ///
  /// In en, this message translates to:
  /// **'Take picture'**
  String get takePicture;

  /// No description provided for @uploadPicture.
  ///
  /// In en, this message translates to:
  /// **'Upload picture'**
  String get uploadPicture;

  /// No description provided for @tabMyPatients.
  ///
  /// In en, this message translates to:
  /// **'MyPatients'**
  String get tabMyPatients;

  /// No description provided for @tabCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get tabCommunity;

  /// No description provided for @specialtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialtyLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @noPatientReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No patient reports yet.'**
  String get noPatientReportsYet;

  /// No description provided for @reportsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Reports: {count}'**
  String reportsCountLabel(Object count);

  /// No description provided for @sentAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent: {date}'**
  String sentAtLabel(Object date);

  /// No description provided for @testsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Tests: {count}'**
  String testsCountLabel(Object count);

  /// No description provided for @writeNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Write notes for patient...'**
  String get writeNotesHint;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @doctorNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get doctorNotes;

  /// No description provided for @openPatient.
  ///
  /// In en, this message translates to:
  /// **'Open patient'**
  String get openPatient;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get noPostsYet;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {date}'**
  String reportTitle(Object date);

  /// No description provided for @scorePercent.
  ///
  /// In en, this message translates to:
  /// **'Score: {percent}%'**
  String scorePercent(Object percent);

  /// No description provided for @noAdditionalData.
  ///
  /// In en, this message translates to:
  /// **'No additional data'**
  String get noAdditionalData;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error'**
  String get authenticationError;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get unexpectedError;

  /// No description provided for @enterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email first.'**
  String get enterEmailFirst;

  /// No description provided for @failedToSendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email.'**
  String get failedToSendResetEmail;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailAddress;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @testingHand1.
  ///
  /// In en, this message translates to:
  /// **'Testing Hand 1...'**
  String get testingHand1;

  /// No description provided for @testingHand2.
  ///
  /// In en, this message translates to:
  /// **'Testing Hand 2...'**
  String get testingHand2;

  /// No description provided for @handOneLabel.
  ///
  /// In en, this message translates to:
  /// **'Hand 1'**
  String get handOneLabel;

  /// No description provided for @handTwoLabel.
  ///
  /// In en, this message translates to:
  /// **'Hand 2'**
  String get handTwoLabel;

  /// No description provided for @fftResultsTemplate.
  ///
  /// In en, this message translates to:
  /// **'{label} Results (Accelerometer):\nX Peak Frequency: {x} Hz\nY Peak Frequency: {y} Hz\nZ Peak Frequency: {z} Hz'**
  String fftResultsTemplate(Object label, Object x, Object y, Object z);

  /// No description provided for @handOneFftSpectrum.
  ///
  /// In en, this message translates to:
  /// **'Hand 1 FFT Spectrum'**
  String get handOneFftSpectrum;

  /// No description provided for @handTwoFftSpectrum.
  ///
  /// In en, this message translates to:
  /// **'Hand 2 FFT Spectrum'**
  String get handTwoFftSpectrum;

  /// No description provided for @insufficientSensorData.
  ///
  /// In en, this message translates to:
  /// **'Insufficient sensor data to render spectrum.'**
  String get insufficientSensorData;

  /// No description provided for @xAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'X-axis'**
  String get xAxisLabel;

  /// No description provided for @yAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'Y-axis'**
  String get yAxisLabel;

  /// No description provided for @zAxisLabel.
  ///
  /// In en, this message translates to:
  /// **'Z-axis'**
  String get zAxisLabel;

  /// No description provided for @accelerometerReadout.
  ///
  /// In en, this message translates to:
  /// **'Accelerometer: X={x} Y={y} Z={z}'**
  String accelerometerReadout(Object x, Object y, Object z);

  /// No description provided for @gyroscopeReadout.
  ///
  /// In en, this message translates to:
  /// **'Live Gyroscope meter: X={x}  Y={y}  Z={z}'**
  String gyroscopeReadout(Object x, Object y, Object z);

  /// No description provided for @rightHandLabel.
  ///
  /// In en, this message translates to:
  /// **'Right hand'**
  String get rightHandLabel;

  /// No description provided for @leftHandLabel.
  ///
  /// In en, this message translates to:
  /// **'Left hand'**
  String get leftHandLabel;

  /// No description provided for @predictionNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Prediction not available'**
  String get predictionNotAvailable;

  /// No description provided for @predictionFailed.
  ///
  /// In en, this message translates to:
  /// **'Prediction failed'**
  String get predictionFailed;

  /// No description provided for @tapParkinsonPattern.
  ///
  /// In en, this message translates to:
  /// **'{label}: ⚠️ Parkinson-like pattern ({percent}%)'**
  String tapParkinsonPattern(Object label, Object percent);

  /// No description provided for @tapNormalPattern.
  ///
  /// In en, this message translates to:
  /// **'{label}: ✅ Normal tapping ({percent}%)'**
  String tapNormalPattern(Object label, Object percent);

  /// No description provided for @drawTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get drawTitle;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @aiSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Overall AI Summary'**
  String get aiSummaryTitle;

  /// No description provided for @aiSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Low risk – more advanced analytics will appear here.'**
  String get aiSummarySubtitle;

  /// No description provided for @testBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Test-by-Test Breakdown'**
  String get testBreakdownTitle;

  /// No description provided for @testBreakdownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Charts of tapping, tremor and other tests will be added.'**
  String get testBreakdownSubtitle;

  /// No description provided for @riskAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk Alerts or Anomalies'**
  String get riskAlertsTitle;

  /// No description provided for @noAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No alerts detected recently.'**
  String get noAlertsSubtitle;

  /// No description provided for @argumentation.
  ///
  /// In en, this message translates to:
  /// **'Argumentation'**
  String get argumentation;

  /// No description provided for @loadingReasoning.
  ///
  /// In en, this message translates to:
  /// **'Loading reasoning...'**
  String get loadingReasoning;

  /// No description provided for @takeQuestionnairePrompt.
  ///
  /// In en, this message translates to:
  /// **'Take the questionnaire to see the results'**
  String get takeQuestionnairePrompt;

  /// No description provided for @noArgumentationYet.
  ///
  /// In en, this message translates to:
  /// **'Cannot give clear argumentation yet from the questionnaire results. If you have any questions, please contact your doctor.'**
  String get noArgumentationYet;

  /// No description provided for @aiSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Test Suggestions'**
  String get aiSuggestionsTitle;

  /// No description provided for @retakeTremorSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Please retake the Tremor Test – last result was inconclusive.'**
  String get retakeTremorSuggestion;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textSizeSystemNote.
  ///
  /// In en, this message translates to:
  /// **'This replaces your device\'s font size setting inside this app.'**
  String get textSizeSystemNote;

  /// No description provided for @textSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textSizeNormal;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @textSizeLarger.
  ///
  /// In en, this message translates to:
  /// **'Larger'**
  String get textSizeLarger;

  /// No description provided for @textSizeLargest.
  ///
  /// In en, this message translates to:
  /// **'Largest'**
  String get textSizeLargest;

  /// No description provided for @textSizePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get textSizePreviewTitle;

  /// No description provided for @textSizePreviewBody.
  ///
  /// In en, this message translates to:
  /// **'Text throughout the app will look like this.'**
  String get textSizePreviewBody;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @guestAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'You are using a guest account'**
  String get guestAccountTitle;

  /// No description provided for @guestAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your tests and results are saved to this device only. Create an account to keep them and to share results with a doctor.'**
  String get guestAccountBody;

  /// No description provided for @keepMyResults.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get keepMyResults;

  /// No description provided for @guestSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of guest account?'**
  String get guestSignOutTitle;

  /// No description provided for @guestSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'This guest account and every result in it will be permanently lost. Create an account first if you want to keep them.'**
  String get guestSignOutBody;

  /// No description provided for @signOutAnyway.
  ///
  /// In en, this message translates to:
  /// **'Sign out anyway'**
  String get signOutAnyway;

  /// No description provided for @accountCreatedKeptResults.
  ///
  /// In en, this message translates to:
  /// **'Account created. Your results have been kept.'**
  String get accountCreatedKeptResults;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'That email already belongs to another account. Sign in to it instead, though your guest results will not carry over.'**
  String get emailAlreadyInUse;

  /// No description provided for @guestUpgradeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the account. Please try again.'**
  String get guestUpgradeFailed;

  /// No description provided for @cameraTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera hand assessment'**
  String get cameraTestTitle;

  /// No description provided for @cameraSetupBody.
  ///
  /// In en, this message translates to:
  /// **'You will be guided through a short series of hand movements, one hand at a time. Hold your phone steady, or prop it up, so the hand being tested stays in view.'**
  String get cameraSetupBody;

  /// No description provided for @cameraTestLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get cameraTestLength;

  /// No description provided for @cameraModeFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get cameraModeFull;

  /// No description provided for @cameraModeShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get cameraModeShort;

  /// No description provided for @cameraModeShortNote.
  ///
  /// In en, this message translates to:
  /// **'Both hands are recorded together, so the test is half as many steps. Each hand is smaller in the picture and the hands can hide one another, so the measurements are less precise than testing one hand at a time.'**
  String get cameraModeShortNote;

  /// No description provided for @cameraApproxDuration.
  ///
  /// In en, this message translates to:
  /// **'About {seconds} seconds'**
  String cameraApproxDuration(Object seconds);

  /// No description provided for @cameraStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get cameraStart;

  /// No description provided for @cameraExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get cameraExit;

  /// No description provided for @cameraHandLeft.
  ///
  /// In en, this message translates to:
  /// **'Left hand'**
  String get cameraHandLeft;

  /// No description provided for @cameraHandRight.
  ///
  /// In en, this message translates to:
  /// **'Right hand'**
  String get cameraHandRight;

  /// No description provided for @cameraTaskRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get cameraTaskRest;

  /// No description provided for @cameraTaskOpenClose.
  ///
  /// In en, this message translates to:
  /// **'Open and close'**
  String get cameraTaskOpenClose;

  /// No description provided for @cameraTaskFingerTap.
  ///
  /// In en, this message translates to:
  /// **'Finger tapping'**
  String get cameraTaskFingerTap;

  /// No description provided for @cameraTaskPronation.
  ///
  /// In en, this message translates to:
  /// **'Palm up and down'**
  String get cameraTaskPronation;

  /// No description provided for @cameraInstructionRest.
  ///
  /// In en, this message translates to:
  /// **'Rest your hand still and relaxed, in view of the camera.'**
  String get cameraInstructionRest;

  /// No description provided for @cameraInstructionOpenClose.
  ///
  /// In en, this message translates to:
  /// **'Open your hand wide, then close it into a fist. Repeat as fully and as quickly as you can.'**
  String get cameraInstructionOpenClose;

  /// No description provided for @cameraInstructionFingerTap.
  ///
  /// In en, this message translates to:
  /// **'Tap your thumb against your index finger. Make each tap as big and as fast as you can.'**
  String get cameraInstructionFingerTap;

  /// No description provided for @cameraInstructionPronation.
  ///
  /// In en, this message translates to:
  /// **'Turn your palm up, then down, over and over. Make each turn as big and as fast as you can.'**
  String get cameraInstructionPronation;

  /// No description provided for @cameraStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String cameraStepOf(Object current, Object total);

  /// No description provided for @cameraMdsItem.
  ///
  /// In en, this message translates to:
  /// **'MDS-UPDRS item {item}'**
  String cameraMdsItem(Object item);

  /// No description provided for @cameraHandNotVisible.
  ///
  /// In en, this message translates to:
  /// **'Move your {hand} into view'**
  String cameraHandNotVisible(Object hand);

  /// No description provided for @cameraPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get cameraPause;

  /// No description provided for @cameraPausePending.
  ///
  /// In en, this message translates to:
  /// **'Pausing after this movement'**
  String get cameraPausePending;

  /// No description provided for @cameraCancelPause.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get cameraCancelPause;

  /// No description provided for @cameraPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get cameraPausedTitle;

  /// No description provided for @cameraPausedBody.
  ///
  /// In en, this message translates to:
  /// **'Take as long as you need. The test continues from the next movement.'**
  String get cameraPausedBody;

  /// No description provided for @cameraNextUp.
  ///
  /// In en, this message translates to:
  /// **'Next: {task}'**
  String cameraNextUp(Object task);

  /// No description provided for @cameraResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get cameraResume;

  /// No description provided for @cameraFinishing.
  ///
  /// In en, this message translates to:
  /// **'Saving your results'**
  String get cameraFinishing;

  /// No description provided for @postureTest.
  ///
  /// In en, this message translates to:
  /// **'Hand posture test'**
  String get postureTest;

  /// No description provided for @testNamePosture.
  ///
  /// In en, this message translates to:
  /// **'Postures'**
  String get testNamePosture;

  /// No description provided for @postureIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Copying hand postures'**
  String get postureIntroTitle;

  /// No description provided for @postureIntroBody.
  ///
  /// In en, this message translates to:
  /// **'You will be shown ten hand shapes, one at a time. Copy each one with either hand and hold it in front of the camera until it is recognised.'**
  String get postureIntroBody;

  /// No description provided for @postureIntroNote.
  ///
  /// In en, this message translates to:
  /// **'This records how well hand shapes are copied. It is not a diagnosis and cannot say whether you have any condition.'**
  String get postureIntroNote;

  /// No description provided for @postureStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get postureStart;

  /// No description provided for @postureExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get postureExit;

  /// No description provided for @postureStepOf.
  ///
  /// In en, this message translates to:
  /// **'Shape {current} of {total}'**
  String postureStepOf(Object current, Object total);

  /// No description provided for @postureCopyThis.
  ///
  /// In en, this message translates to:
  /// **'Copy this shape'**
  String get postureCopyThis;

  /// No description provided for @postureSecondTry.
  ///
  /// In en, this message translates to:
  /// **'Let\'s try that one again'**
  String get postureSecondTry;

  /// No description provided for @postureReady.
  ///
  /// In en, this message translates to:
  /// **'Show me'**
  String get postureReady;

  /// No description provided for @postureHoldIt.
  ///
  /// In en, this message translates to:
  /// **'Hold it there'**
  String get postureHoldIt;

  /// No description provided for @postureSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip this shape'**
  String get postureSkip;

  /// No description provided for @postureHandNotVisible.
  ///
  /// In en, this message translates to:
  /// **'Move your hand into view'**
  String get postureHandNotVisible;

  /// No description provided for @postureSecondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String postureSecondsLeft(Object seconds);

  /// No description provided for @postureResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hand postures'**
  String get postureResultsTitle;

  /// No description provided for @postureScore.
  ///
  /// In en, this message translates to:
  /// **'{points} of {total}'**
  String postureScore(Object points, Object total);

  /// No description provided for @postureCopiedFirst.
  ///
  /// In en, this message translates to:
  /// **'Copied first time'**
  String get postureCopiedFirst;

  /// No description provided for @postureCopiedSecond.
  ///
  /// In en, this message translates to:
  /// **'Copied on the second try'**
  String get postureCopiedSecond;

  /// No description provided for @postureNotCopied.
  ///
  /// In en, this message translates to:
  /// **'Not copied'**
  String get postureNotCopied;

  /// No description provided for @postureNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Hand not seen'**
  String get postureNotRecorded;

  /// No description provided for @postureQuality.
  ///
  /// In en, this message translates to:
  /// **'Recording quality'**
  String get postureQuality;

  /// No description provided for @postureNothingRecorded.
  ///
  /// In en, this message translates to:
  /// **'The camera did not get a usable view of your hand, so this run was not saved. Trying again in better light usually helps.'**
  String get postureNothingRecorded;

  /// No description provided for @postureSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your results.'**
  String get postureSaved;

  /// No description provided for @postureNotSaved.
  ///
  /// In en, this message translates to:
  /// **'This result was not saved.'**
  String get postureNotSaved;

  /// No description provided for @postureRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat test'**
  String get postureRepeat;

  /// No description provided for @postureNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get postureNext;

  /// No description provided for @postureUnrecordedNote.
  ///
  /// In en, this message translates to:
  /// **'{count} shape(s) could not be seen well enough to judge. Those are not counted as mistakes.'**
  String postureUnrecordedNote(Object count);

  /// No description provided for @cameraHandBoth.
  ///
  /// In en, this message translates to:
  /// **'Both hands'**
  String get cameraHandBoth;

  /// No description provided for @cameraPacingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get cameraPacingLabel;

  /// No description provided for @cameraPacingSelf.
  ///
  /// In en, this message translates to:
  /// **'I\'ll tap when ready'**
  String get cameraPacingSelf;

  /// No description provided for @cameraPacingTimed.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get cameraPacingTimed;

  /// No description provided for @cameraPacingSelfNote.
  ///
  /// In en, this message translates to:
  /// **'Take as long as you like reading each instruction. Only the movement itself is timed.'**
  String get cameraPacingSelfNote;

  /// No description provided for @cameraPacingTimedNote.
  ///
  /// In en, this message translates to:
  /// **'Each step starts on its own after a short countdown. Useful if the phone is out of reach.'**
  String get cameraPacingTimedNote;

  /// No description provided for @cameraStepReady.
  ///
  /// In en, this message translates to:
  /// **'When you are ready, start this step.'**
  String get cameraStepReady;

  /// No description provided for @cameraStartStep.
  ///
  /// In en, this message translates to:
  /// **'Start this step'**
  String get cameraStartStep;

  /// No description provided for @cameraGetReady.
  ///
  /// In en, this message translates to:
  /// **'Get ready…'**
  String get cameraGetReady;

  /// No description provided for @cameraShowHandToBegin.
  ///
  /// In en, this message translates to:
  /// **'Show your hand to the camera to begin'**
  String get cameraShowHandToBegin;

  /// No description provided for @cameraApproxDurationRange.
  ///
  /// In en, this message translates to:
  /// **'About {low}-{high} minutes'**
  String cameraApproxDurationRange(Object high, Object low);

  /// No description provided for @cameraRetryTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s record that step again'**
  String get cameraRetryTitle;

  /// No description provided for @cameraRetryBody.
  ///
  /// In en, this message translates to:
  /// **'The recording of {task} was not clear enough to measure. Nothing you have already completed is lost.'**
  String cameraRetryBody(Object task);

  /// No description provided for @cameraRetryAgain.
  ///
  /// In en, this message translates to:
  /// **'Repeat this step'**
  String get cameraRetryAgain;

  /// No description provided for @cameraRetryKeep.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get cameraRetryKeep;

  /// No description provided for @cameraRetryAttempt.
  ///
  /// In en, this message translates to:
  /// **'Attempt {current} of {total}'**
  String cameraRetryAttempt(Object current, Object total);

  /// No description provided for @cameraRetryExhausted.
  ///
  /// In en, this message translates to:
  /// **'This step has been recorded {count} times. You can continue without it.'**
  String cameraRetryExhausted(Object count);

  /// No description provided for @cameraQualityUsableFrames.
  ///
  /// In en, this message translates to:
  /// **'The hand was not visible for enough of the recording. Keep it in view of the camera for the whole step.'**
  String get cameraQualityUsableFrames;

  /// No description provided for @cameraQualityHandInFrame.
  ///
  /// In en, this message translates to:
  /// **'Part of the hand kept leaving the picture. Move the phone a little farther away so the whole hand fits.'**
  String get cameraQualityHandInFrame;

  /// No description provided for @cameraQualityHandedness.
  ///
  /// In en, this message translates to:
  /// **'The other hand was in view for much of this step. Show only the hand being tested.'**
  String get cameraQualityHandedness;

  /// No description provided for @cameraQualityContinuity.
  ///
  /// In en, this message translates to:
  /// **'The hand disappeared from view partway through. Keep it steady in front of the camera.'**
  String get cameraQualityContinuity;

  /// No description provided for @cameraQualityFps.
  ///
  /// In en, this message translates to:
  /// **'The camera could not keep up during this step. Closing other apps and trying again usually helps.'**
  String get cameraQualityFps;

  /// No description provided for @cameraQualityDuration.
  ///
  /// In en, this message translates to:
  /// **'Too little of this step was recorded.'**
  String get cameraQualityDuration;

  /// No description provided for @cameraQualityLandmarks.
  ///
  /// In en, this message translates to:
  /// **'The whole hand was not always detected. Keep your fingers spread and your palm facing the camera.'**
  String get cameraQualityLandmarks;

  /// No description provided for @cameraQualityHandSize.
  ///
  /// In en, this message translates to:
  /// **'The distance between your hand and the camera changed during this step. Hold the phone still and keep your hand at the same distance.'**
  String get cameraQualityHandSize;

  /// No description provided for @cameraResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Movement measurements'**
  String get cameraResultsTitle;

  /// No description provided for @cameraMetricPeakSpeed.
  ///
  /// In en, this message translates to:
  /// **'Fastest speed'**
  String get cameraMetricPeakSpeed;

  /// No description provided for @cameraMetricRecordedTime.
  ///
  /// In en, this message translates to:
  /// **'Recorded time'**
  String get cameraMetricRecordedTime;

  /// No description provided for @cameraUnitPalmWidthsPerSecond.
  ///
  /// In en, this message translates to:
  /// **'{value} palm widths/s'**
  String cameraUnitPalmWidthsPerSecond(Object value);

  /// No description provided for @cameraOverallMovement.
  ///
  /// In en, this message translates to:
  /// **'Overall movement'**
  String get cameraOverallMovement;

  /// No description provided for @cameraOverallMovementNote.
  ///
  /// In en, this message translates to:
  /// **'Measured across the whole recording. These are available whenever any frames were captured, so they are shown even when the step-by-step measurements are not.'**
  String get cameraOverallMovementNote;

  /// No description provided for @cameraMetricSpeedVariation.
  ///
  /// In en, this message translates to:
  /// **'Speed variation'**
  String get cameraMetricSpeedVariation;

  /// No description provided for @cameraMetricAccelVariation.
  ///
  /// In en, this message translates to:
  /// **'Acceleration variation'**
  String get cameraMetricAccelVariation;

  /// No description provided for @cameraMetricJerkVariation.
  ///
  /// In en, this message translates to:
  /// **'Jerk variation'**
  String get cameraMetricJerkVariation;

  /// No description provided for @cameraMetricFingerSpread.
  ///
  /// In en, this message translates to:
  /// **'Finger spread'**
  String get cameraMetricFingerSpread;

  /// No description provided for @cameraMetricTremorLevel.
  ///
  /// In en, this message translates to:
  /// **'Movement while still'**
  String get cameraMetricTremorLevel;

  /// No description provided for @cameraMetricHandDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference between hands'**
  String get cameraMetricHandDifference;

  /// No description provided for @cameraDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get cameraDiagnosticsTitle;

  /// No description provided for @cameraDiagFramesLabel.
  ///
  /// In en, this message translates to:
  /// **'Frames (usable / total)'**
  String get cameraDiagFramesLabel;

  /// No description provided for @cameraDiagFpsLabel.
  ///
  /// In en, this message translates to:
  /// **'Frames per second'**
  String get cameraDiagFpsLabel;

  /// No description provided for @cameraDiagCyclesLabel.
  ///
  /// In en, this message translates to:
  /// **'Movements detected'**
  String get cameraDiagCyclesLabel;

  /// No description provided for @cameraDiagSignalLabel.
  ///
  /// In en, this message translates to:
  /// **'Movement range'**
  String get cameraDiagSignalLabel;

  /// No description provided for @cameraDiagErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Analysis error'**
  String get cameraDiagErrorLabel;

  /// No description provided for @cameraAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'The detailed analysis could not be completed, so only the overall measurements are shown.'**
  String get cameraAnalysisFailed;

  /// No description provided for @cameraResultsIntro.
  ///
  /// In en, this message translates to:
  /// **'These are measurements of how your hands moved during the recording. They are not a diagnosis and cannot say whether you have any condition.'**
  String get cameraResultsIntro;

  /// No description provided for @cameraResultsQuality.
  ///
  /// In en, this message translates to:
  /// **'Recording quality'**
  String get cameraResultsQuality;

  /// No description provided for @cameraResultsOverallConfidence.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get cameraResultsOverallConfidence;

  /// No description provided for @cameraResultsTasksDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} steps measured'**
  String cameraResultsTasksDone(Object done, Object total);

  /// No description provided for @cameraResultsRetries.
  ///
  /// In en, this message translates to:
  /// **'{count} step(s) recorded more than once'**
  String cameraResultsRetries(Object count);

  /// No description provided for @cameraResultsNotSaved.
  ///
  /// In en, this message translates to:
  /// **'This result was not saved.'**
  String get cameraResultsNotSaved;

  /// No description provided for @cameraResultsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your results.'**
  String get cameraResultsSaved;

  /// No description provided for @cameraResultsNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing could be measured from this recording, so it was not saved. Recording the test again usually helps.'**
  String get cameraResultsNothing;

  /// No description provided for @cameraResultsInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Insufficient data'**
  String get cameraResultsInsufficient;

  /// No description provided for @cameraResultsNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'This step was not recorded well enough to measure.'**
  String get cameraResultsNotRecorded;

  /// No description provided for @cameraResultsTooFewMovements.
  ///
  /// In en, this message translates to:
  /// **'Too few movements were detected to work this out.'**
  String get cameraResultsTooFewMovements;

  /// No description provided for @cameraResultsDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference between hands'**
  String get cameraResultsDifference;

  /// No description provided for @cameraResultsNoComparison.
  ///
  /// In en, this message translates to:
  /// **'Both hands are needed for a comparison.'**
  String get cameraResultsNoComparison;

  /// No description provided for @cameraResultsTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get cameraResultsTechnical;

  /// No description provided for @cameraResultsRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat test'**
  String get cameraResultsRepeat;

  /// No description provided for @cameraResultsNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get cameraResultsNext;

  /// No description provided for @cameraMetricTapsPerSecond.
  ///
  /// In en, this message translates to:
  /// **'Taps per second'**
  String get cameraMetricTapsPerSecond;

  /// No description provided for @cameraMetricMovementsPerSecond.
  ///
  /// In en, this message translates to:
  /// **'Movements per second'**
  String get cameraMetricMovementsPerSecond;

  /// No description provided for @cameraMetricTurnsPerSecond.
  ///
  /// In en, this message translates to:
  /// **'Turns per second'**
  String get cameraMetricTurnsPerSecond;

  /// No description provided for @cameraMetricAmplitude.
  ///
  /// In en, this message translates to:
  /// **'Movement size'**
  String get cameraMetricAmplitude;

  /// No description provided for @cameraMetricRhythm.
  ///
  /// In en, this message translates to:
  /// **'Rhythm variability'**
  String get cameraMetricRhythm;

  /// No description provided for @cameraMetricAmplitudeDecrement.
  ///
  /// In en, this message translates to:
  /// **'Change in size over the step'**
  String get cameraMetricAmplitudeDecrement;

  /// No description provided for @cameraMetricSpeedDecrement.
  ///
  /// In en, this message translates to:
  /// **'Change in speed over the step'**
  String get cameraMetricSpeedDecrement;

  /// No description provided for @cameraMetricPauses.
  ///
  /// In en, this message translates to:
  /// **'Pauses'**
  String get cameraMetricPauses;

  /// No description provided for @cameraMetricSpeed.
  ///
  /// In en, this message translates to:
  /// **'Average speed'**
  String get cameraMetricSpeed;

  /// No description provided for @cameraMetricTremorAmplitude.
  ///
  /// In en, this message translates to:
  /// **'Movement while at rest'**
  String get cameraMetricTremorAmplitude;

  /// No description provided for @cameraMetricTremorFrequency.
  ///
  /// In en, this message translates to:
  /// **'Rate of that movement'**
  String get cameraMetricTremorFrequency;

  /// No description provided for @cameraMetricRestDuration.
  ///
  /// In en, this message translates to:
  /// **'Usable recording'**
  String get cameraMetricRestDuration;

  /// No description provided for @cameraMetricCycles.
  ///
  /// In en, this message translates to:
  /// **'Movements detected'**
  String get cameraMetricCycles;

  /// No description provided for @cameraUnitPerSecond.
  ///
  /// In en, this message translates to:
  /// **'{value}/s'**
  String cameraUnitPerSecond(Object value);

  /// No description provided for @cameraUnitHertz.
  ///
  /// In en, this message translates to:
  /// **'{value} Hz'**
  String cameraUnitHertz(Object value);

  /// No description provided for @cameraUnitSeconds.
  ///
  /// In en, this message translates to:
  /// **'{value} s'**
  String cameraUnitSeconds(Object value);

  /// No description provided for @cameraUnitPalmWidths.
  ///
  /// In en, this message translates to:
  /// **'{value} palm widths'**
  String cameraUnitPalmWidths(Object value);

  /// No description provided for @cameraUnitPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String cameraUnitPercent(Object value);

  /// No description provided for @cameraUnitCount.
  ///
  /// In en, this message translates to:
  /// **'{value}'**
  String cameraUnitCount(Object value);

  /// No description provided for @stepOfSteps.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOfSteps(Object current, Object total);

  /// No description provided for @stepStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get stepStart;

  /// No description provided for @stepSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get stepSubmit;

  /// No description provided for @stepFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get stepFinish;

  /// No description provided for @stepDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stepDone;

  /// No description provided for @stepContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get stepContinue;

  /// No description provided for @stepHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get stepHint;

  /// No description provided for @stepClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get stepClear;

  /// No description provided for @stepDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get stepDelete;

  /// No description provided for @stepAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get stepAnswer;

  /// No description provided for @stepResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get stepResults;

  /// No description provided for @stepTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get stepTimeRemaining;

  /// No description provided for @stepTimeRemainingValue.
  ///
  /// In en, this message translates to:
  /// **'Time remaining: {seconds}'**
  String stepTimeRemainingValue(Object seconds);

  /// No description provided for @stepTapMicToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone to start.'**
  String get stepTapMicToStart;

  /// No description provided for @stepSayWithMic.
  ///
  /// In en, this message translates to:
  /// **'Say the word into the microphone'**
  String get stepSayWithMic;

  /// No description provided for @stepSpokenIntoMic.
  ///
  /// In en, this message translates to:
  /// **'Spoken into the microphone'**
  String get stepSpokenIntoMic;

  /// No description provided for @stepTypeOrUseMic.
  ///
  /// In en, this message translates to:
  /// **'You can type or use the microphone.'**
  String get stepTypeOrUseMic;

  /// No description provided for @stepStartMic.
  ///
  /// In en, this message translates to:
  /// **'Start microphone'**
  String get stepStartMic;

  /// No description provided for @stepMicProblem.
  ///
  /// In en, this message translates to:
  /// **'There is a problem with the microphone. Tap it again to retry.'**
  String get stepMicProblem;

  /// No description provided for @stepMicStopped.
  ///
  /// In en, this message translates to:
  /// **'The microphone stopped. Tap it again to continue.'**
  String get stepMicStopped;

  /// No description provided for @stepMicClosed.
  ///
  /// In en, this message translates to:
  /// **'The microphone closed. Tap it again to continue.'**
  String get stepMicClosed;

  /// No description provided for @stepSpeakNow.
  ///
  /// In en, this message translates to:
  /// **'Speak now. Each word appears on screen straight away.'**
  String get stepSpeakNow;

  /// No description provided for @stepCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get stepCorrectAnswer;

  /// No description provided for @stepCorrectWithHint.
  ///
  /// In en, this message translates to:
  /// **'Correct (hint used)'**
  String get stepCorrectWithHint;

  /// No description provided for @stepWrongOrder.
  ///
  /// In en, this message translates to:
  /// **'Wrong order.'**
  String get stepWrongOrder;

  /// No description provided for @stepWrongLine.
  ///
  /// In en, this message translates to:
  /// **'Wrong line'**
  String get stepWrongLine;

  /// No description provided for @stepAllWordsFound.
  ///
  /// In en, this message translates to:
  /// **'All the words have been found.'**
  String get stepAllWordsFound;

  /// No description provided for @stepTimeUpScore.
  ///
  /// In en, this message translates to:
  /// **'Time is up.\nScore: {score}/3.00'**
  String stepTimeUpScore(Object score);

  /// No description provided for @stepCameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera access is required to continue.'**
  String get stepCameraPermissionRequired;

  /// No description provided for @stepCameraPermissionRecheck.
  ///
  /// In en, this message translates to:
  /// **'Check permission again'**
  String get stepCameraPermissionRecheck;

  /// No description provided for @stepCameraPermissionSettings.
  ///
  /// In en, this message translates to:
  /// **'Check the app settings if the problem persists.'**
  String get stepCameraPermissionSettings;

  /// No description provided for @stepLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access was not allowed.\nYour City and Country answers will be accepted as entered.'**
  String get stepLocationDenied;

  /// No description provided for @stepTitleSubtract.
  ///
  /// In en, this message translates to:
  /// **'Subtract 7 from 100'**
  String get stepTitleSubtract;

  /// No description provided for @stepTitleOrientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get stepTitleOrientation;

  /// No description provided for @stepTitleNaming.
  ///
  /// In en, this message translates to:
  /// **'Naming'**
  String get stepTitleNaming;

  /// No description provided for @stepTitleImmediateRecall.
  ///
  /// In en, this message translates to:
  /// **'Immediate recall'**
  String get stepTitleImmediateRecall;

  /// No description provided for @stepTitleDelayedRecall.
  ///
  /// In en, this message translates to:
  /// **'Delayed recall'**
  String get stepTitleDelayedRecall;

  /// No description provided for @stepTitleDigits.
  ///
  /// In en, this message translates to:
  /// **'Working memory'**
  String get stepTitleDigits;

  /// No description provided for @stepTitleVigilance.
  ///
  /// In en, this message translates to:
  /// **'Vigilance'**
  String get stepTitleVigilance;

  /// No description provided for @stepTitleFluency.
  ///
  /// In en, this message translates to:
  /// **'Verbal fluency'**
  String get stepTitleFluency;

  /// No description provided for @stepTitleSimilarities.
  ///
  /// In en, this message translates to:
  /// **'Abstract thinking'**
  String get stepTitleSimilarities;

  /// No description provided for @stepTitleClock.
  ///
  /// In en, this message translates to:
  /// **'Clock: hands'**
  String get stepTitleClock;

  /// No description provided for @stepTitleTrails.
  ///
  /// In en, this message translates to:
  /// **'Visuospatial tracking'**
  String get stepTitleTrails;

  /// No description provided for @stepTitleCube.
  ///
  /// In en, this message translates to:
  /// **'Visuoconstructional skills'**
  String get stepTitleCube;

  /// No description provided for @stepTitleRepeatSentences.
  ///
  /// In en, this message translates to:
  /// **'Sentence repetition'**
  String get stepTitleRepeatSentences;

  /// No description provided for @stepTitleGestures.
  ///
  /// In en, this message translates to:
  /// **'Gesture recognition'**
  String get stepTitleGestures;

  /// No description provided for @stepTitleConflicting.
  ///
  /// In en, this message translates to:
  /// **'Conflicting instructions'**
  String get stepTitleConflicting;

  /// No description provided for @stepTitleGoNoGo.
  ///
  /// In en, this message translates to:
  /// **'Go / no-go'**
  String get stepTitleGoNoGo;

  /// No description provided for @stepInstructionSubtract.
  ///
  /// In en, this message translates to:
  /// **'Subtract 7 repeatedly, starting from 100 (five times):'**
  String get stepInstructionSubtract;

  /// No description provided for @stepInstructionDigitsMemorise.
  ///
  /// In en, this message translates to:
  /// **'Try to memorise the numbers below.'**
  String get stepInstructionDigitsMemorise;

  /// No description provided for @stepInstructionDigitsForwardSoon.
  ///
  /// In en, this message translates to:
  /// **'In a moment you will be asked to repeat them in the same order.'**
  String get stepInstructionDigitsForwardSoon;

  /// No description provided for @stepInstructionDigitsBackwardSoon.
  ///
  /// In en, this message translates to:
  /// **'In a moment you will be asked to repeat them in reverse order.'**
  String get stepInstructionDigitsBackwardSoon;

  /// No description provided for @stepInstructionDigitsForward.
  ///
  /// In en, this message translates to:
  /// **'Repeat the numbers you saw, in the same order:'**
  String get stepInstructionDigitsForward;

  /// No description provided for @stepInstructionDigitsBackward.
  ///
  /// In en, this message translates to:
  /// **'Repeat the numbers you saw, in reverse order:'**
  String get stepInstructionDigitsBackward;

  /// No description provided for @stepInstructionWriteOrSayNumbers.
  ///
  /// In en, this message translates to:
  /// **'Write or say the numbers'**
  String get stepInstructionWriteOrSayNumbers;

  /// No description provided for @stepInstructionOrientation.
  ///
  /// In en, this message translates to:
  /// **'Fill in the following:'**
  String get stepInstructionOrientation;

  /// No description provided for @stepInstructionOrientationDay.
  ///
  /// In en, this message translates to:
  /// **'Day (e.g. Monday)'**
  String get stepInstructionOrientationDay;

  /// No description provided for @stepInstructionOrientationDate.
  ///
  /// In en, this message translates to:
  /// **'Date (e.g. 01 / 01 / 2020)'**
  String get stepInstructionOrientationDate;

  /// No description provided for @stepInstructionOrientationCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get stepInstructionOrientationCity;

  /// No description provided for @stepInstructionOrientationCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get stepInstructionOrientationCountry;

  /// No description provided for @stepHintCityExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Athens'**
  String get stepHintCityExample;

  /// No description provided for @stepHintCountryExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Greece'**
  String get stepHintCountryExample;

  /// No description provided for @stepInstructionNaming.
  ///
  /// In en, this message translates to:
  /// **'Name each animal by tapping the microphone on the right of its frame.'**
  String get stepInstructionNaming;

  /// No description provided for @stepInstructionImmediateRecall.
  ///
  /// In en, this message translates to:
  /// **'I will say 5 words. Try to memorise them, because you will be asked for them again shortly.'**
  String get stepInstructionImmediateRecall;

  /// No description provided for @stepInstructionImmediateRecallPractice.
  ///
  /// In en, this message translates to:
  /// **'To practise, you will first repeat them all together. Then you will try to repeat each word separately.'**
  String get stepInstructionImmediateRecallPractice;

  /// No description provided for @stepInstructionSayWordsTogether.
  ///
  /// In en, this message translates to:
  /// **'Say the words from the list (all together, in any order): {words}'**
  String stepInstructionSayWordsTogether(Object words);

  /// No description provided for @stepInstructionSayWordsSeparately.
  ///
  /// In en, this message translates to:
  /// **'Say the words, one in each field. {words}'**
  String stepInstructionSayWordsSeparately(Object words);

  /// No description provided for @stepInstructionSayWords.
  ///
  /// In en, this message translates to:
  /// **'Say the words'**
  String get stepInstructionSayWords;

  /// No description provided for @stepInstructionDelayedRecall.
  ///
  /// In en, this message translates to:
  /// **'Say as many words as you remember (voice only; the order does not matter).'**
  String get stepInstructionDelayedRecall;

  /// No description provided for @stepInstructionDelayedRecallHint.
  ///
  /// In en, this message translates to:
  /// **'If you tap “Hint” for a word, you get half a point for it.'**
  String get stepInstructionDelayedRecallHint;

  /// No description provided for @stepInstructionWhichWordWasInList.
  ///
  /// In en, this message translates to:
  /// **'Which of the following words was in the list?'**
  String get stepInstructionWhichWordWasInList;

  /// No description provided for @stepInstructionVigilance.
  ///
  /// In en, this message translates to:
  /// **'This test measures your alertness and attention.'**
  String get stepInstructionVigilance;

  /// No description provided for @stepInstructionVigilanceLetters.
  ///
  /// In en, this message translates to:
  /// **'A series of letters will appear, one at a time.'**
  String get stepInstructionVigilanceLetters;

  /// No description provided for @stepInstructionVigilanceTap.
  ///
  /// In en, this message translates to:
  /// **'Press the button when you see the letter “Α”.'**
  String get stepInstructionVigilanceTap;

  /// No description provided for @stepInstructionFluency.
  ///
  /// In en, this message translates to:
  /// **'Verbal fluency: as many words as you can beginning with the letter “Χ”, without proper nouns or derived words, within 1 minute.'**
  String get stepInstructionFluency;

  /// No description provided for @stepInstructionSimilarities.
  ///
  /// In en, this message translates to:
  /// **'What do the following pairs have in common?'**
  String get stepInstructionSimilarities;

  /// No description provided for @stepInstructionSimilaritiesExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. banana - orange = fruit'**
  String get stepInstructionSimilaritiesExample;

  /// No description provided for @stepInstructionSimilaritiesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap “Hint” for example answers.'**
  String get stepInstructionSimilaritiesHint;

  /// No description provided for @stepInstructionClock.
  ///
  /// In en, this message translates to:
  /// **'Move the hands so that they show 11:10'**
  String get stepInstructionClock;

  /// No description provided for @stepInstructionTrails.
  ///
  /// In en, this message translates to:
  /// **'Join the circles starting from 1, then Α, then 2, Β, 3, Γ… up to 5 and Ε.'**
  String get stepInstructionTrails;

  /// No description provided for @stepInstructionTrailsRetry.
  ///
  /// In en, this message translates to:
  /// **'If you make a mistake you can try again. If you are struggling, press “Next”. Time: 2 minutes.'**
  String get stepInstructionTrailsRetry;

  /// No description provided for @stepInstructionDrawCube.
  ///
  /// In en, this message translates to:
  /// **'Copy the cube you see below.'**
  String get stepInstructionDrawCube;

  /// No description provided for @stepInstructionConnectCube.
  ///
  /// In en, this message translates to:
  /// **'Copy the cube by joining the dots. Tap one dot first, then the next.'**
  String get stepInstructionConnectCube;

  /// No description provided for @stepInstructionConnectCubeAlmost.
  ///
  /// In en, this message translates to:
  /// **'Almost right — remove the red lines'**
  String get stepInstructionConnectCubeAlmost;

  /// No description provided for @stepInstructionRepeatSentence.
  ///
  /// In en, this message translates to:
  /// **'Say the sentence…'**
  String get stepInstructionRepeatSentence;

  /// No description provided for @stepInstructionGesturesIntro.
  ///
  /// In en, this message translates to:
  /// **'When you press “Start”, the camera will turn on for 1 minute.\n\nYou need to perform the following movements:'**
  String get stepInstructionGesturesIntro;

  /// No description provided for @stepInstructionGesturesPerformAll.
  ///
  /// In en, this message translates to:
  /// **'Perform all the movements.'**
  String get stepInstructionGesturesPerformAll;

  /// No description provided for @stepGestureRecognised.
  ///
  /// In en, this message translates to:
  /// **'{gesture}\nRecognised!'**
  String stepGestureRecognised(Object gesture);

  /// No description provided for @stepGesturesAllDetected.
  ///
  /// In en, this message translates to:
  /// **'Well done! All gestures were detected.\n\nScore: 3.00/3.00'**
  String get stepGesturesAllDetected;

  /// No description provided for @stepWordNumbered.
  ///
  /// In en, this message translates to:
  /// **'Word {number}'**
  String stepWordNumbered(Object number);

  /// No description provided for @stepExampleAnswer.
  ///
  /// In en, this message translates to:
  /// **'Example: {hint}'**
  String stepExampleAnswer(Object hint);

  /// No description provided for @stepHintFor.
  ///
  /// In en, this message translates to:
  /// **'Hint: {hint}'**
  String stepHintFor(Object hint);

  /// No description provided for @stepHeardTargetLetter.
  ///
  /// In en, this message translates to:
  /// **'I heard Α'**
  String get stepHeardTargetLetter;

  /// No description provided for @stepStartTest.
  ///
  /// In en, this message translates to:
  /// **'Start test'**
  String get stepStartTest;

  /// No description provided for @stepSecondsValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String stepSecondsValue(Object seconds);

  /// No description provided for @stepMemoriseTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time to memorise: {seconds}'**
  String stepMemoriseTimeLeft(Object seconds);

  /// No description provided for @stepInstructionRepeatSentencesIntro.
  ///
  /// In en, this message translates to:
  /// **'A sentence will appear for 20 seconds. Try to read it and memorise it. You will then be asked to repeat it back as accurately as you can.\n\nYou can see the sentence again for 3 seconds if you need to (Hint), and you can clear what the microphone heard (Clear). Press “Next” to move on, even if you have not answered.'**
  String get stepInstructionRepeatSentencesIntro;

  /// No description provided for @stepInstructionRepeatBack.
  ///
  /// In en, this message translates to:
  /// **'Repeat the sentence you read. Press the microphone to start; if it stops, press it again.'**
  String get stepInstructionRepeatBack;

  /// No description provided for @fabGoNoGoInstructions.
  ///
  /// In en, this message translates to:
  /// **'The numbers 1 and 2 will appear one at a time.\n\nPress the “Tap” button when 1 appears. Do not press it when 2 appears.\n\nWe will run a short practice round first to explain the rules, then the real task.'**
  String get fabGoNoGoInstructions;

  /// No description provided for @fabGoNoGoRules.
  ///
  /// In en, this message translates to:
  /// **'“1” — tap\n“2” — do not tap'**
  String get fabGoNoGoRules;

  /// No description provided for @fabGoNoGoPracticeIntro.
  ///
  /// In en, this message translates to:
  /// **'Practice round. Apply the rules. If you make a mistake you will see an explanation. Press “Start” to begin the practice.'**
  String get fabGoNoGoPracticeIntro;

  /// No description provided for @fabGoNoGoTestIntro.
  ///
  /// In en, this message translates to:
  /// **'Main task. Apply the rules. Press “Start” to begin.'**
  String get fabGoNoGoTestIntro;

  /// No description provided for @fabTap.
  ///
  /// In en, this message translates to:
  /// **'Tap'**
  String get fabTap;

  /// No description provided for @fabGoNoGoMissed.
  ///
  /// In en, this message translates to:
  /// **'You should have tapped once, but did not tap.'**
  String get fabGoNoGoMissed;

  /// No description provided for @fabGoNoGoTooMany.
  ///
  /// In en, this message translates to:
  /// **'You should have tapped once; you tapped {count} times.'**
  String fabGoNoGoTooMany(Object count);

  /// No description provided for @fabGoNoGoShouldNotTap.
  ///
  /// In en, this message translates to:
  /// **'You should not have tapped; you tapped {count} times.'**
  String fabGoNoGoShouldNotTap(Object count);

  /// No description provided for @fabScoreValue.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String fabScoreValue(Object score);

  /// No description provided for @fabGoNoGoResultStreak.
  ///
  /// In en, this message translates to:
  /// **'You gave the same answer at least 4 times in a row.'**
  String get fabGoNoGoResultStreak;

  /// No description provided for @fabGoNoGoResultPerfect.
  ///
  /// In en, this message translates to:
  /// **'You made no mistakes.'**
  String get fabGoNoGoResultPerfect;

  /// No description provided for @fabGoNoGoResultFew.
  ///
  /// In en, this message translates to:
  /// **'You made 1 or 2 mistakes.'**
  String get fabGoNoGoResultFew;

  /// No description provided for @fabGoNoGoResultMany.
  ///
  /// In en, this message translates to:
  /// **'You made more than 2 mistakes.'**
  String get fabGoNoGoResultMany;

  /// No description provided for @fabFluencyInstructions.
  ///
  /// In en, this message translates to:
  /// **'Say as many words as you can beginning with the letter Κ, other than surnames and proper names.\n\nYou have 60 seconds.\n\nScoring: more than 10 words = 3 points, 6–10 = 2, 3–5 = 1, fewer than 3 = 0.'**
  String get fabFluencyInstructions;

  /// No description provided for @fabFluencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verbal fluency'**
  String get fabFluencyTitle;

  /// No description provided for @fabFluencyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Words beginning with “Κ”'**
  String get fabFluencyPrompt;

  /// No description provided for @fabFluencyResultMany.
  ///
  /// In en, this message translates to:
  /// **'More than 10 words.'**
  String get fabFluencyResultMany;

  /// No description provided for @fabFluencyResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words.'**
  String fabFluencyResultCount(Object count);

  /// No description provided for @fabFluencyResultFew.
  ///
  /// In en, this message translates to:
  /// **'Fewer than 3 words.'**
  String get fabFluencyResultFew;

  /// No description provided for @fabSimilaritiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Similarities'**
  String get fabSimilaritiesTitle;

  /// No description provided for @fabSimilaritiesInstructions.
  ///
  /// In en, this message translates to:
  /// **'“What do they have in common?”\n\nFor example: banana - orange = fruit.\n\nYou can type or use the microphone. Tap “Hint” on the first question if you would like help.\n\nScoring: 3 correct answers = 3 points, 2 = 2, 1 = 1, none = 0.'**
  String get fabSimilaritiesInstructions;

  /// No description provided for @fabQuestionOfCount.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String fabQuestionOfCount(Object current, Object total);

  /// No description provided for @fabCorrectAnswersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} correct answers.'**
  String fabCorrectAnswersCount(Object count);

  /// No description provided for @fabNoCorrectAnswers.
  ///
  /// In en, this message translates to:
  /// **'No correct answers.'**
  String get fabNoCorrectAnswers;

  /// No description provided for @fabConflictingInstructions.
  ///
  /// In en, this message translates to:
  /// **'Tap once when I tap twice. Tap twice when I tap once.\n\nWe will run a short practice round first, then the real task.'**
  String get fabConflictingInstructions;

  /// No description provided for @fabExaminerTapsOnce.
  ///
  /// In en, this message translates to:
  /// **'I tap once'**
  String get fabExaminerTapsOnce;

  /// No description provided for @fabExaminerTapsTwice.
  ///
  /// In en, this message translates to:
  /// **'I tap twice'**
  String get fabExaminerTapsTwice;

  /// No description provided for @fabYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get fabYourTurn;

  /// No description provided for @fabGesturesRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {gestures}'**
  String fabGesturesRemaining(Object gestures);

  /// No description provided for @fabConflictingRules.
  ///
  /// In en, this message translates to:
  /// **'“1” — tap twice\n“2” — tap once'**
  String get fabConflictingRules;

  /// No description provided for @fabConflictingPracticeIntro.
  ///
  /// In en, this message translates to:
  /// **'Practice round. Follow the rules so you get a feel for the task. Press “Start” to begin the practice.'**
  String get fabConflictingPracticeIntro;

  /// No description provided for @fabConflictingTestIntro.
  ///
  /// In en, this message translates to:
  /// **'Main task. Apply the rules. Press “Start” to begin.'**
  String get fabConflictingTestIntro;

  /// No description provided for @fabExpectedTapsOnce.
  ///
  /// In en, this message translates to:
  /// **'You should have tapped once; you tapped {count} times.'**
  String fabExpectedTapsOnce(Object count);

  /// No description provided for @fabExpectedTapsTwice.
  ///
  /// In en, this message translates to:
  /// **'You should have tapped twice; you tapped {count} times.'**
  String fabExpectedTapsTwice(Object count);

  /// No description provided for @fabResultStreakStimulus.
  ///
  /// In en, this message translates to:
  /// **'You matched the number shown at least 4 times in a row.'**
  String get fabResultStreakStimulus;

  /// No description provided for @testCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Test complete'**
  String get testCompleteTitle;

  /// No description provided for @testCompleteSaved.
  ///
  /// In en, this message translates to:
  /// **'Your result has been saved.'**
  String get testCompleteSaved;

  /// No description provided for @testCompleteNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Your result could not be saved, but here it is.'**
  String get testCompleteNotSaved;

  /// No description provided for @testCompleteScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get testCompleteScore;

  /// No description provided for @testCompleteDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get testCompleteDone;

  /// No description provided for @testCompleteViewAll.
  ///
  /// In en, this message translates to:
  /// **'See all my results'**
  String get testCompleteViewAll;

  /// No description provided for @bandReassuringWorse.
  ///
  /// In en, this message translates to:
  /// **'Nothing notable came up in this test.'**
  String get bandReassuringWorse;

  /// No description provided for @bandBorderlineWorse.
  ///
  /// In en, this message translates to:
  /// **'This result sits in the middle range. Repeating the test on another day gives a clearer picture.'**
  String get bandBorderlineWorse;

  /// No description provided for @bandNotableWorse.
  ///
  /// In en, this message translates to:
  /// **'This result is worth mentioning to your doctor. It is a screening check, not a diagnosis.'**
  String get bandNotableWorse;

  /// No description provided for @bandReassuringBetter.
  ///
  /// In en, this message translates to:
  /// **'This result is in the expected range.'**
  String get bandReassuringBetter;

  /// No description provided for @bandBorderlineBetter.
  ///
  /// In en, this message translates to:
  /// **'This result is slightly below the expected range. Repeating it on another day gives a clearer picture.'**
  String get bandBorderlineBetter;

  /// No description provided for @bandNotableBetter.
  ///
  /// In en, this message translates to:
  /// **'This result is below the expected range and is worth mentioning to your doctor. It is a screening check, not a diagnosis.'**
  String get bandNotableBetter;

  /// No description provided for @screeningDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This app is a screening aid. It cannot diagnose Parkinson\'s disease, and only a clinician can interpret these results.'**
  String get screeningDisclaimer;

  /// No description provided for @guestKeepResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep these results'**
  String get guestKeepResultsTitle;

  /// No description provided for @guestKeepResultsBody.
  ///
  /// In en, this message translates to:
  /// **'You are using a guest account. Create an account to keep your results and share them with a doctor.'**
  String get guestKeepResultsBody;

  /// No description provided for @guestExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without an account?'**
  String get guestExitTitle;

  /// No description provided for @guestExitBody.
  ///
  /// In en, this message translates to:
  /// **'Your results are tied to this guest session on this device. If it is lost, so are they. Creating an account keeps everything you have done so far.'**
  String get guestExitBody;

  /// No description provided for @guestExitStay.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get guestExitStay;

  /// No description provided for @guestExitLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave anyway'**
  String get guestExitLeave;

  /// No description provided for @guestSignInDisabled.
  ///
  /// In en, this message translates to:
  /// **'Guest sign-in is not enabled for this app yet. Please create an account, or try again later.'**
  String get guestSignInDisabled;

  /// No description provided for @testNameDrawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get testNameDrawing;

  /// No description provided for @testNameQuestionnaire.
  ///
  /// In en, this message translates to:
  /// **'Questionnaire'**
  String get testNameQuestionnaire;

  /// No description provided for @testNameTremor.
  ///
  /// In en, this message translates to:
  /// **'Tremor'**
  String get testNameTremor;

  /// No description provided for @testNameTap.
  ///
  /// In en, this message translates to:
  /// **'Tapping'**
  String get testNameTap;

  /// No description provided for @testNameVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get testNameVoice;

  /// No description provided for @testNameCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get testNameCamera;

  /// No description provided for @testNameNeuro.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get testNameNeuro;

  /// No description provided for @testNameFab.
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get testNameFab;

  /// No description provided for @bandLabelReassuring.
  ///
  /// In en, this message translates to:
  /// **'Reassuring'**
  String get bandLabelReassuring;

  /// No description provided for @bandLabelBorderline.
  ///
  /// In en, this message translates to:
  /// **'Borderline'**
  String get bandLabelBorderline;

  /// No description provided for @bandLabelNotable.
  ///
  /// In en, this message translates to:
  /// **'Notable'**
  String get bandLabelNotable;

  /// No description provided for @resultsInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About these scores'**
  String get resultsInfoTitle;

  /// No description provided for @resultsInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Each bar is the most recent result for that test, shown as a level of concern from 0% to 100%. Higher always means more worth looking at, whichever test it came from.\n\nThat needs saying because the tests do not all count the same way. On the tapping or tremor tests a high raw score means more sign of tremor; on the memory and reasoning batteries a high raw score means you did well. Both are converted here, so a low bar is always the calmer one.\n\nThe three bands — reassuring, borderline and notable — are provisional cut-offs, not clinical thresholds. A single notable result on one day means far less than the same result appearing again and again across weeks.\n\nTap a test to see how it has changed over time.'**
  String get resultsInfoBody;

  /// No description provided for @overallTrend.
  ///
  /// In en, this message translates to:
  /// **'Overall trend'**
  String get overallTrend;

  /// No description provided for @trendInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About the trend'**
  String get trendInfoTitle;

  /// No description provided for @trendInfoBody.
  ///
  /// In en, this message translates to:
  /// **'One point per day on which you took at least one test, averaged across every test you took that day.\n\nUse it to see direction rather than detail: a line drifting upwards over several weeks is worth mentioning to your doctor, while a single spike usually says more about a tired hand, a rushed attempt or a noisy room than about your health.\n\nDays with no tests are simply missing from the line, so a stretch of activity followed by a gap will look like one long step. Taking tests at roughly the same time of day makes the comparison fairer.'**
  String get trendInfoBody;

  /// No description provided for @trendWindowLabel.
  ///
  /// In en, this message translates to:
  /// **'Averaged over'**
  String get trendWindowLabel;

  /// No description provided for @trendWindowLast.
  ///
  /// In en, this message translates to:
  /// **'Last {count} days'**
  String trendWindowLast(int count);

  /// No description provided for @trendNeedsMoreDays.
  ///
  /// In en, this message translates to:
  /// **'Not enough tests in this period to draw a trend. Choose a longer period, or take a test on another day.'**
  String get trendNeedsMoreDays;

  /// No description provided for @summaryInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About the summary'**
  String get summaryInfoTitle;

  /// No description provided for @summaryInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Each spoke is one test, and the distance from the centre is your average level of concern for it across every attempt.\n\nA small, even shape means nothing stands out. A shape stretched towards one spoke means that one test reads differently from the rest — which is the thing actually worth showing a clinician, since Parkinson\'s rarely affects everything equally at first.\n\nBecause these are averages over all your attempts, the shape moves slowly and early results keep pulling on it for a long time.'**
  String get summaryInfoBody;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @medicalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Medical disclaimer'**
  String get medicalDisclaimer;

  /// No description provided for @medicalDisclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'This app is not a medical device and does not provide a diagnosis.\n\nThe tests here are screening aids. They look for patterns that are common in Parkinson\'s disease, but many other things — tiredness, caffeine, medication, anxiety, an unrelated condition, or simply an awkward grip on the phone — produce the same patterns. A concerning score does not mean you have Parkinson\'s disease, and a reassuring score does not rule it out.\n\nOnly a qualified clinician can diagnose Parkinson\'s disease, and only after an in-person examination. Take any result that worries you to your doctor, and never start, stop or change a medication based on what this app shows you.\n\nIf you have sudden or severe symptoms, seek medical help immediately rather than taking a test.'**
  String get medicalDisclaimerBody;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfService;

  /// No description provided for @legalDocumentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'This document has not been published yet.\n\nUntil it is, here is what the app actually does with your data: your test results, questionnaire answers and voice recordings are stored in your account and are visible to you and to any doctor you choose to share them with. Nothing is shared with anyone else.\n\nPlease contact the app\'s provider if you need the full document before it is available here.'**
  String get legalDocumentPlaceholder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['el', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
