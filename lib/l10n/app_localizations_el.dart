// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'Ανιχνευτής Πάρκινσον AI';

  @override
  String get editName => 'Επεξεργασία ονόματος';

  @override
  String get dateOfBirth => 'Ημερομηνία γέννησης';

  @override
  String get dobHint => 'εεεε-μμ-ηη';

  @override
  String get addMedication => 'Προσθήκη φαρμάκου';

  @override
  String get profileSaved => 'Το προφίλ αποθηκεύτηκε';

  @override
  String get saveProfile => 'Αποθήκευση προφίλ';

  @override
  String get saveChanges => 'Αποθήκευση αλλαγών';

  @override
  String get logOut => 'ΑΠΟΣΥΝΔΕΣΗ';

  @override
  String get language => 'Γλώσσα';

  @override
  String get english => 'Αγγλικά';

  @override
  String get greek => 'Ελληνικά';

  @override
  String get welcome => 'Καλώς ήρθατε';

  @override
  String get createAccount => 'Δημιουργία λογαριασμού';

  @override
  String get nameLabel => 'Όνομα';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Κωδικός';

  @override
  String get confirmPasswordLabel => 'Επιβεβαίωση κωδικού';

  @override
  String get iAmA => 'Είμαι';

  @override
  String get patient => 'Ασθενής';

  @override
  String get doctor => 'Γιατρός';

  @override
  String get keepMeLoggedIn => 'Να παραμείνω συνδεδεμένος';

  @override
  String get login => 'Σύνδεση';

  @override
  String get signUp => 'Εγγραφή';

  @override
  String get forgotPassword => 'Ξεχάσατε τον κωδικό;';

  @override
  String get passwordRecovery => 'Ανάκτηση κωδικού';

  @override
  String get cancel => 'Ακύρωση';

  @override
  String get send => 'Αποστολή';

  @override
  String get emailSent => 'Αν το email υπάρχει, στάλθηκε σύνδεσμος επαναφοράς.';

  @override
  String get dontHaveAccount => 'Δεν έχετε λογαριασμό; Εγγραφείτε';

  @override
  String get alreadyHaveAccount => 'Έχετε ήδη λογαριασμό; Συνδεθείτε';

  @override
  String get savedSuccessfully => 'Αποθηκεύτηκε με επιτυχία';

  @override
  String get gotIt => 'Το κατάλαβα';

  @override
  String get insights => 'Συμβουλές';

  @override
  String get noRecommendations => 'Δεν επιστράφηκαν προτάσεις';

  @override
  String get questionnaire => 'Ερωτηματολόγιο';

  @override
  String get submit => 'Υποβολή';

  @override
  String get tapTest => 'Τεστ χτυπήματος';

  @override
  String timeLeft(Object seconds) {
    return 'Χρόνος που απομένει: ${seconds}s';
  }

  @override
  String get tap => 'ΧΤΥΠΑ';

  @override
  String get startTest => 'Έναρξη τεστ';

  @override
  String get stop => 'Διακοπή';

  @override
  String get pressStart => 'Πατήστε έναρξη για να ξεκινήσετε';

  @override
  String get startingTest => 'Εκκίνηση τεστ...';

  @override
  String get tapRightHand => 'Χτυπήστε με το δεξί χέρι';

  @override
  String get switchHands => 'Αλλάξτε χέρια';

  @override
  String get tapLeftHand => 'Χτυπήστε με το αριστερό χέρι';

  @override
  String get testCompleted => 'Το τεστ ολοκληρώθηκε';

  @override
  String get testStopped => 'Το τεστ διακόπηκε';

  @override
  String get tabProfile => 'Προφίλ';

  @override
  String get tabTests => 'Τεστ';

  @override
  String get tabResults => 'Αποτελέσματα';

  @override
  String get next => 'Επόμενο';

  @override
  String get finishAction => 'Τερματισμός';

  @override
  String get voiceTest => 'Τεστ φωνής';

  @override
  String get recording => 'Εγγραφή...';

  @override
  String get processing => 'Επεξεργασία...';

  @override
  String get microphonePermissionDenied => 'Δεν δόθηκε άδεια μικροφώνου';

  @override
  String possibleParkinson(Object percent) {
    return '⚠️ Πιθανό μοτίβο Πάρκινσον ($percent%)';
  }

  @override
  String normalVoice(Object percent) {
    return '✅ Κανονική φωνή ($percent%)';
  }

  @override
  String get recordingFailed => 'Η εγγραφή απέτυχε';

  @override
  String get noDoctorSelected =>
      'Δεν έχετε επιλέξει γιατρό.\nΚάντε κλικ για επιλογή';

  @override
  String get myDoctor => 'Ο γιατρός μου';

  @override
  String get sendResults => 'Αποστολή αποτελεσμάτων';

  @override
  String get diagnoses => 'Διαγνώσεις';

  @override
  String get bookAppointment => 'Κράτηση ραντεβού';

  @override
  String get getSecondOpinion => 'Λήψη δεύτερης γνώμης';

  @override
  String get secondOpinions => 'Δεύτερες γνώμες';

  @override
  String get close => 'Κλείσιμο';

  @override
  String get noDoctorFeedback => 'Δεν υπάρχουν ακόμη σχόλια γιατρού.';

  @override
  String get noNotesYet => 'Δεν υπάρχουν σημειώσεις.';

  @override
  String get completeOneTest =>
      'Παρακαλώ ολοκληρώστε τουλάχιστον ένα τεστ πρώτα.';

  @override
  String get selectDoctor => 'Επιλέξτε γιατρό';

  @override
  String get searchDoctor => 'Αναζήτηση γιατρού...';

  @override
  String get noDoctorsFound => 'Δεν βρέθηκαν γιατροί';

  @override
  String resultsSentTo(Object name) {
    return 'Αποτελέσματα στάλθηκαν στον/στην $name';
  }

  @override
  String get testResults => 'Αποτελέσματα τεστ';

  @override
  String get summary => 'Περίληψη';

  @override
  String get needThreeTests =>
      'Ολοκληρώστε τουλάχιστον 3 διαφορετικά τεστ για να δείτε το διάγραμμα περίληψης.';

  @override
  String days(Object count) {
    return '$count ημέρες';
  }

  @override
  String get exportResults => 'Εξαγωγή αποτελεσμάτων';

  @override
  String get cameraDetectionTest => 'Τεστ ανίχνευσης κάμερας';

  @override
  String get tremorTest => 'Τεστ τρόμου';

  @override
  String get drawingTest => 'Τεστ σχεδίασης';

  @override
  String get neuropsychologicalTest => 'Νευροψυχολογικό τεστ';

  @override
  String get fabTest => 'Τεστ Frontal Assessment Battery';

  @override
  String get sendResultsToDoctor => 'Αποστολή αποτελεσμάτων στον γιατρό';

  @override
  String get noHandsDetected => 'Δεν εντοπίστηκαν χέρια. Προσπαθήστε ξανά.';

  @override
  String testCompletedMsg(Object test) {
    return 'Το $test ολοκληρώθηκε';
  }

  @override
  String get drawOnPhone => 'Σχεδίαση στο τηλέφωνο';

  @override
  String get takePicture => 'Λήψη φωτογραφίας';

  @override
  String get uploadPicture => 'Μεταφόρτωση φωτογραφίας';

  @override
  String get tabMyPatients => 'Οι Ασθενείς μου';

  @override
  String get tabCommunity => 'Κοινότητα';

  @override
  String get specialtyLabel => 'Ειδικότητα';

  @override
  String get locationLabel => 'Τοποθεσία';

  @override
  String get save => 'Αποθήκευση';

  @override
  String get noPatientReportsYet => 'Δεν υπάρχουν ακόμη αναφορές ασθενών.';

  @override
  String reportsCountLabel(Object count) {
    return 'Αναφορές: $count';
  }

  @override
  String sentAtLabel(Object date) {
    return 'Στάλθηκε: $date';
  }

  @override
  String testsCountLabel(Object count) {
    return 'Τεστ: $count';
  }

  @override
  String get writeNotesHint => 'Γράψτε σημειώσεις για τον ασθενή...';

  @override
  String get addNote => 'Προσθήκη σημείωσης';

  @override
  String get noPostsYet => 'Δεν υπάρχουν αναρτήσεις ακόμη.';

  @override
  String reportTitle(Object date) {
    return 'Αναφορά $date';
  }

  @override
  String scorePercent(Object percent) {
    return 'Βαθμολογία: $percent%';
  }

  @override
  String get noAdditionalData => 'Δεν υπάρχουν επιπλέον δεδομένα';

  @override
  String get passwordsDoNotMatch => 'Οι κωδικοί δεν ταιριάζουν.';

  @override
  String get authenticationError => 'Σφάλμα ελέγχου ταυτότητας';

  @override
  String get unexpectedError => 'Παρουσιάστηκε ένα μη αναμενόμενο σφάλμα.';

  @override
  String get enterEmailFirst => 'Παρακαλώ εισάγετε πρώτα το email σας.';

  @override
  String get failedToSendResetEmail => 'Αποτυχία αποστολής email επαναφοράς.';

  @override
  String get emailRequired => 'Το email είναι υποχρεωτικό';

  @override
  String get invalidEmailAddress =>
      'Παρακαλώ εισάγετε μια έγκυρη διεύθυνση email';

  @override
  String get passwordRequired => 'Ο κωδικός είναι υποχρεωτικός';

  @override
  String get passwordTooShort =>
      'Ο κωδικός πρέπει να έχει τουλάχιστον 6 χαρακτήρες';

  @override
  String get confirmPasswordRequired => 'Παρακαλώ επιβεβαιώστε τον κωδικό σας';

  @override
  String get nameRequired => 'Το όνομα είναι υποχρεωτικό';

  @override
  String get testingHand1 => 'Δοκιμή Χεριού 1...';

  @override
  String get testingHand2 => 'Δοκιμή Χεριού 2...';

  @override
  String get handOneLabel => 'Χέρι 1';

  @override
  String get handTwoLabel => 'Χέρι 2';

  @override
  String fftResultsTemplate(Object label, Object x, Object y, Object z) {
    return '$label Αποτελέσματα (Επιταχυνσιόμετρο):\nΚορυφή Συχνότητας X: $x Hz\nΚορυφή Συχνότητας Y: $y Hz\nΚορυφή Συχνότητας Z: $z Hz';
  }

  @override
  String get handOneFftSpectrum => 'Φάσμα FFT Χεριού 1';

  @override
  String get handTwoFftSpectrum => 'Φάσμα FFT Χεριού 2';

  @override
  String get insufficientSensorData =>
      'Ανεπαρκή δεδομένα αισθητήρα για την απεικόνιση του φάσματος.';

  @override
  String get xAxisLabel => 'Άξονας X';

  @override
  String get yAxisLabel => 'Άξονας Y';

  @override
  String get zAxisLabel => 'Άξονας Z';

  @override
  String accelerometerReadout(Object x, Object y, Object z) {
    return 'Επιταχυνσιόμετρο: X=$x Y=$y Z=$z';
  }

  @override
  String gyroscopeReadout(Object x, Object y, Object z) {
    return 'Ζωντανό γυροσκόπιο: X=$x  Y=$y  Z=$z';
  }

  @override
  String get rightHandLabel => 'Δεξί χέρι';

  @override
  String get leftHandLabel => 'Αριστερό χέρι';

  @override
  String get predictionNotAvailable => 'Η πρόβλεψη δεν είναι διαθέσιμη';

  @override
  String get predictionFailed => 'Η πρόβλεψη απέτυχε';

  @override
  String tapParkinsonPattern(Object label, Object percent) {
    return '$label: ⚠️ Μοτίβο τύπου Πάρκινσον ($percent%)';
  }

  @override
  String tapNormalPattern(Object label, Object percent) {
    return '$label: ✅ Φυσιολογικό χτύπημα ($percent%)';
  }

  @override
  String get drawTitle => 'Σχεδίαση';

  @override
  String get clearAction => 'Καθαρισμός';

  @override
  String get aiSummaryTitle => 'Συνολική Σύνοψη AI';

  @override
  String get aiSummarySubtitle =>
      'Χαμηλός κίνδυνος – πιο προηγμένη ανάλυση θα εμφανιστεί εδώ.';

  @override
  String get testBreakdownTitle => 'Ανάλυση ανά Τεστ';

  @override
  String get testBreakdownSubtitle =>
      'Θα προστεθούν διαγράμματα για τα τεστ χτυπήματος, τρόμου και άλλα.';

  @override
  String get riskAlertsTitle => 'Ειδοποιήσεις Κινδύνου ή Ανωμαλίες';

  @override
  String get noAlertsSubtitle => 'Δεν εντοπίστηκαν πρόσφατες ειδοποιήσεις.';

  @override
  String get argumentation => 'Επιχειρηματολογία';

  @override
  String get loadingReasoning => 'Φόρτωση συλλογισμού...';

  @override
  String get takeQuestionnairePrompt =>
      'Συμπληρώστε το ερωτηματολόγιο για να δείτε τα αποτελέσματα';

  @override
  String get noArgumentationYet =>
      'Δεν είναι ακόμη δυνατή η σαφής επιχειρηματολογία από τα αποτελέσματα του ερωτηματολογίου. Αν έχετε ερωτήσεις, επικοινωνήστε με τον γιατρό σας.';

  @override
  String get aiSuggestionsTitle => 'Προτάσεις Τεστ από AI';

  @override
  String get retakeTremorSuggestion =>
      'Παρακαλώ επαναλάβετε το Τεστ Τρόμου – το τελευταίο αποτέλεσμα ήταν ασαφές.';
}
