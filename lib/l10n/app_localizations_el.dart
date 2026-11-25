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
  String get apptBookTitle => 'Αίτημα για ραντεβού';

  @override
  String get apptPickDate => 'Προτιμώμενη ημερομηνία';

  @override
  String get apptPickTime => 'Προτιμώμενη ώρα';

  @override
  String get apptReason => 'Λόγος επίσκεψης (προαιρετικό)';

  @override
  String get apptSendRequest => 'Αποστολή αιτήματος';

  @override
  String apptRequested(Object doctor) {
    return 'Το αίτημα στάλθηκε στον/στην $doctor';
  }

  @override
  String get apptUpcoming => 'Ραντεβού';

  @override
  String get apptTabTitle => 'Ραντεβού';

  @override
  String get apptPending => 'Αναμένουν απάντησή σας';

  @override
  String get apptConfirmedSection => 'Επιβεβαιωμένα';

  @override
  String get apptClosedSection => 'Παλαιότερα και ακυρωμένα';

  @override
  String get apptNonePending => 'Δεν υπάρχουν αιτήματα για ραντεβού.';

  @override
  String get apptConfirm => 'Επιβεβαίωση';

  @override
  String get apptDecline => 'Απόρριψη';

  @override
  String get apptProposeAnother => 'Πρόταση άλλης ώρας';

  @override
  String get apptReplyOptional => 'Μήνυμα προς τον ασθενή (προαιρετικό)';

  @override
  String apptRequestedOn(Object when) {
    return 'Ζητήθηκε $when';
  }

  @override
  String get apptMarkCompleted => 'Σήμανση ως ολοκληρωμένο';

  @override
  String get apptConfirmedToast => 'Το ραντεβού επιβεβαιώθηκε';

  @override
  String get apptDeclinedToast => 'Το ραντεβού απορρίφθηκε';

  @override
  String get apptPatientNote => 'Σημείωση ασθενούς';

  @override
  String get apptNone => 'Δεν υπάρχουν ραντεβού ακόμη.';

  @override
  String get apptStatusRequested => 'Αναμονή επιβεβαίωσης';

  @override
  String get apptStatusConfirmed => 'Επιβεβαιωμένο';

  @override
  String get apptStatusDeclined => 'Απορρίφθηκε';

  @override
  String get apptStatusCancelled => 'Ακυρώθηκε';

  @override
  String get apptStatusCompleted => 'Ολοκληρώθηκε';

  @override
  String get apptCancel => 'Ακύρωση ραντεβού';

  @override
  String get apptCancelConfirmTitle => 'Ακύρωση του ραντεβού;';

  @override
  String get apptCancelConfirmBody =>
      'Ο γιατρός σας θα ενημερωθεί ότι δεν χρειάζεται πλέον.';

  @override
  String apptProposedTime(Object when) {
    return 'Ο γιατρός σας πρότεινε $when αντ\' αυτού';
  }

  @override
  String get apptAcceptProposed => 'Αποδοχή αυτής της ώρας';

  @override
  String get apptDoctorMessage => 'Μήνυμα από τον γιατρό σας';

  @override
  String get apptPastTimeError => 'Επιλέξτε ώρα στο μέλλον.';

  @override
  String get apptPickSlotTitle => 'Επιλέξτε ώρα';

  @override
  String get apptNoOpenSlots =>
      'Αυτός ο γιατρός δεν έχει δημοσιεύσει ακόμη ελεύθερες ώρες.';

  @override
  String get apptFreeTimesOn => 'Ελεύθερες ώρες';

  @override
  String get apptPickDayWithTimes => 'Επιλέξτε μια ημέρα με τελεία από κάτω.';

  @override
  String apptBooked(Object doctor, Object when) {
    return 'Κλείστηκε ραντεβού με $doctor για $when';
  }

  @override
  String get apptSlotTaken =>
      'Κάποιος άλλος μόλις έκλεισε αυτή την ώρα. Επιλέξτε άλλη.';

  @override
  String get apptSlotWithdrawn => 'Αυτή η ώρα δεν προσφέρεται πλέον.';

  @override
  String get apptCancelledToast => 'Το ραντεβού ακυρώθηκε';

  @override
  String get apptCancelBookingBody =>
      'Ο ασθενής θα ενημερωθεί και η ώρα επιστρέφει στο ημερολόγιό σας.';

  @override
  String get apptCalendar => 'Το ημερολόγιό μου';

  @override
  String get apptCalendarError =>
      'Δεν ήταν δυνατή η φόρτωση του ημερολογίου σας. Ελέγξτε τη σύνδεσή σας και δοκιμάστε ξανά.';

  @override
  String get apptAddTimes => 'Προσθήκη ελεύθερων ωρών';

  @override
  String get apptAddTimesTitle => 'Δημοσίευση ελεύθερων ωρών';

  @override
  String get apptFrom => 'Από';

  @override
  String get apptTo => 'Έως';

  @override
  String get apptSlotLength => 'Κάθε ραντεβού διαρκεί';

  @override
  String apptMinutes(Object count) {
    return '$count λεπτά';
  }

  @override
  String apptWillPublish(Object count) {
    return 'Προστίθενται $count ώρες ραντεβού.';
  }

  @override
  String get apptEndBeforeStart =>
      'Η ώρα λήξης πρέπει να είναι μετά την ώρα έναρξης.';

  @override
  String get apptPublish => 'Δημοσίευση';

  @override
  String apptPublished(Object count) {
    return 'Προστέθηκαν $count ώρες στο ημερολόγιό σας';
  }

  @override
  String get apptNothingToPublish =>
      'Αυτές οι ώρες υπάρχουν ήδη στο ημερολόγιό σας.';

  @override
  String get apptNoSlotsOnDay =>
      'Δεν έχει δημοσιευτεί τίποτα για αυτή την ημέρα.';

  @override
  String get apptSlotOpen => 'Ελεύθερη';

  @override
  String get apptSlotBooked => 'Κλεισμένη';

  @override
  String get apptRemoveSlot => 'Αφαίρεση αυτής της ώρας';

  @override
  String get apptSlotRemoved => 'Η ώρα αφαιρέθηκε από το ημερολόγιό σας';

  @override
  String get reportsLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση των ασθενών σας. Ελέγξτε τη σύνδεσή σας και δοκιμάστε ξανά.';

  @override
  String get reportSnapshotTitle => 'Επισκόπηση';

  @override
  String get reportConcernExplainer =>
      'Υψηλότερο σημαίνει μεγαλύτερη ανησυχία. Το 0% είναι το καλύτερο δυνατό αποτέλεσμα.';

  @override
  String get reportBatteriesTitle => 'Γνωστικός έλεγχος';

  @override
  String get reportQuestionnaireTitle => 'Αναφερόμενα συμπτώματα';

  @override
  String get reportNoSymptomsReported => 'Δεν αναφέρθηκαν συμπτώματα.';

  @override
  String get reportPerTestTitle => 'Ανά δοκιμασία';

  @override
  String get reportBaselineTitle => 'Αρχική αξιολόγηση';

  @override
  String get reportBaselineExplainer =>
      'Γίνεται μία φορά. Το MoCA και το FAB βαθμολογούνται με δημοσιευμένα όρια.';

  @override
  String reportRepeatWarning(Object count) {
    return 'Προσπάθεια $count της ίδιας φόρμας — η βαθμολογία μπορεί να είναι αυξημένη λόγω εξοικείωσης.';
  }

  @override
  String get reportRepeatedTitle => 'Επαναλαμβανόμενες μετρήσεις';

  @override
  String get reportRepeatedExplainer =>
      'Οι δοκιμασίες αισθητήρων της εφαρμογής, συνοψισμένες σε όλες τις συνεδρίες. Αυτά τα όρια είναι προσωρινά και δεν αποτελούν επικυρωμένο εργαλείο.';

  @override
  String seriesSittings(Object count) {
    return '$count συνεδρίες';
  }

  @override
  String get seriesImproving => 'βελτίωση';

  @override
  String get seriesWorsening => 'επιδείνωση';

  @override
  String get seriesStable => 'σταθερό';

  @override
  String get seriesTooFew => 'πολύ λίγες για συμπέρασμα';

  @override
  String repeatTestTitle(Object test) {
    return 'Επανάληψη $test;';
  }

  @override
  String repeatTestTakenOn(Object date) {
    return 'Την κάνατε τελευταία φορά στις $date.';
  }

  @override
  String get repeatBatteryBody =>
      'Είναι η ίδια φόρμα με την προηγούμενη φορά. Η ανάμνηση των λέξεων και των δοκιμασιών συνήθως ανεβάζει τη βαθμολογία, οπότε η επανάληψη δύσκολα συγκρίνεται με το πρώτο σας αποτέλεσμα. Αξίζει αν έχει περάσει αρκετός καιρός ή αν η προηγούμενη προσπάθεια διακόπηκε.';

  @override
  String get repeatQuestionnaireBody =>
      'Αφορά το ιστορικό των συμπτωμάτων σας, το οποίο συνήθως δεν αλλάζει από εβδομάδα σε εβδομάδα. Αξίζει να επαναληφθεί αν κάτι έχει πραγματικά αλλάξει.';

  @override
  String get repeatTestConfirm => 'Επανάληψη';

  @override
  String reportQuestionnaireCompleted(Object answered, Object reported) {
    return 'Ολοκληρώθηκε — $answered ερωτήσεις απαντήθηκαν, $reported αναφέρθηκαν ως παρόντα.';
  }

  @override
  String reportSectionAnswered(Object answered, Object reported) {
    return '$answered απαντήθηκαν · $reported αναφέρθηκαν';
  }

  @override
  String reportOverallVerdict(Object band) {
    return 'Συνολικά: $band';
  }

  @override
  String reportOverallDetail(Object percent, Object tests) {
    return 'Διάμεσος $percent% σε $tests επαναλαμβανόμενες δοκιμασίες';
  }

  @override
  String get reportGapsTitle =>
      'Τι δεν μπόρεσε να μετρηθεί σε αυτή την αξιολόγηση';

  @override
  String get reasoningUnavailable =>
      'Δεν ήταν δυνατή η επικοινωνία με την υπηρεσία συλλογιστικής, οπότε δεν εμφανίζονται συμπεράσματα.';

  @override
  String get gapNotTaken => 'δεν έγινε';

  @override
  String get gapNothingMeasured => 'καταγράφηκε, αλλά δεν μετρήθηκε τίποτα';

  @override
  String gapPartlyRecorded(Object missing, Object total) {
    return '$missing από $total μέρη δεν καταγράφηκαν';
  }

  @override
  String gapLowQuality(Object percent) {
    return 'ποιότητα καταγραφής μόλις $percent%';
  }

  @override
  String get leaveDoctor => 'Αποχώρηση από αυτόν τον γιατρό';

  @override
  String leaveDoctorConfirmTitle(Object doctor) {
    return 'Αποχώρηση από $doctor;';
  }

  @override
  String get leaveDoctorConfirmBody =>
      'Θα σταματήσετε να μοιράζεστε νέα αποτελέσματα και κάθε ραντεβού που δεν έχει γίνει ακόμη θα ακυρωθεί. Οι αναφορές που έχετε ήδη στείλει παραμένουν σε αυτόν.';

  @override
  String get leaveDoctorConfirm => 'Αποχώρηση';

  @override
  String leftDoctor(Object doctor) {
    return 'Αποχωρήσατε από $doctor';
  }

  @override
  String get changeDoctor => 'Αλλαγή γιατρού';

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
  String get doctorsLoadFailed =>
      'Δεν ήταν δυνατή η φόρτωση της λίστας γιατρών. Ελέγξτε τη σύνδεσή σας και δοκιμάστε ξανά.';

  @override
  String get retryAction => 'Δοκιμή ξανά';

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
  String get doctorNotes => 'Σημειώσεις';

  @override
  String get openPatient => 'Άνοιγμα ασθενούς';

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

  @override
  String get preferences => 'Προτιμήσεις';

  @override
  String get textSize => 'Μέγεθος κειμένου';

  @override
  String get textSizeSystemNote =>
      'Αντικαθιστά τη ρύθμιση μεγέθους γραμματοσειράς της συσκευής σας μέσα σε αυτή την εφαρμογή.';

  @override
  String get textSizeNormal => 'Κανονικό';

  @override
  String get textSizeLarge => 'Μεγάλο';

  @override
  String get textSizeLarger => 'Μεγαλύτερο';

  @override
  String get textSizeLargest => 'Μέγιστο';

  @override
  String get textSizePreviewTitle => 'Προεπισκόπηση';

  @override
  String get textSizePreviewBody =>
      'Το κείμενο σε όλη την εφαρμογή θα φαίνεται έτσι.';

  @override
  String get resetToDefault => 'Επαναφορά προεπιλογής';

  @override
  String get continueAsGuest => 'Συνέχεια ως επισκέπτης';

  @override
  String get guestAccountTitle => 'Χρησιμοποιείτε λογαριασμό επισκέπτη';

  @override
  String get guestAccountBody =>
      'Τα τεστ και τα αποτελέσματά σας αποθηκεύονται μόνο σε αυτή τη συσκευή. Δημιουργήστε λογαριασμό για να τα διατηρήσετε και να τα μοιραστείτε με γιατρό.';

  @override
  String get keepMyResults => 'Δημιουργία λογαριασμού';

  @override
  String get guestSignOutTitle => 'Αποσύνδεση από τον λογαριασμό επισκέπτη;';

  @override
  String get guestSignOutBody =>
      'Αυτός ο λογαριασμός επισκέπτη και όλα τα αποτελέσματά του θα χαθούν οριστικά. Δημιουργήστε πρώτα λογαριασμό αν θέλετε να τα κρατήσετε.';

  @override
  String get signOutAnyway => 'Αποσύνδεση ούτως ή άλλως';

  @override
  String get accountCreatedKeptResults =>
      'Ο λογαριασμός δημιουργήθηκε. Τα αποτελέσματά σας διατηρήθηκαν.';

  @override
  String get emailAlreadyInUse =>
      'Αυτό το email ανήκει ήδη σε άλλον λογαριασμό. Συνδεθείτε σε αυτόν, αλλά τα αποτελέσματα του επισκέπτη δεν θα μεταφερθούν.';

  @override
  String get guestUpgradeFailed =>
      'Δεν ήταν δυνατή η δημιουργία του λογαριασμού. Δοκιμάστε ξανά.';

  @override
  String get cameraTestTitle => 'Αξιολόγηση χεριών με κάμερα';

  @override
  String get cameraSetupBody =>
      'Θα καθοδηγηθείτε σε μια σύντομη σειρά κινήσεων, ένα χέρι κάθε φορά. Κρατήστε το κινητό σταθερό ή στηρίξτε το, ώστε το χέρι που εξετάζεται να παραμένει ορατό.';

  @override
  String get cameraTestLength => 'Διάρκεια';

  @override
  String get cameraModeFull => 'Πλήρης';

  @override
  String get cameraModeShort => 'Σύντομη';

  @override
  String get cameraModeShortNote =>
      'Καταγράφονται και τα δύο χέρια μαζί, άρα το τεστ έχει τα μισά βήματα. Κάθε χέρι φαίνεται μικρότερο και τα χέρια μπορεί να κρύβουν το ένα το άλλο, οπότε οι μετρήσεις είναι λιγότερο ακριβείς από ό,τι με ένα χέρι κάθε φορά.';

  @override
  String cameraApproxDuration(Object seconds) {
    return 'Περίπου $seconds δευτερόλεπτα';
  }

  @override
  String get cameraStart => 'Έναρξη';

  @override
  String get cameraExit => 'Έξοδος';

  @override
  String get cameraHandLeft => 'Αριστερό χέρι';

  @override
  String get cameraHandRight => 'Δεξί χέρι';

  @override
  String get cameraTaskRest => 'Ηρεμία';

  @override
  String get cameraTaskOpenClose => 'Άνοιγμα και κλείσιμο';

  @override
  String get cameraTaskFingerTap => 'Χτύπημα δακτύλων';

  @override
  String get cameraTaskPronation => 'Παλάμη πάνω και κάτω';

  @override
  String get cameraInstructionRest =>
      'Αφήστε το χέρι σας ακίνητο και χαλαρό, μπροστά στην κάμερα.';

  @override
  String get cameraInstructionOpenClose =>
      'Ανοίξτε την παλάμη σας διάπλατα και κλείστε τη σε γροθιά. Επαναλάβετε όσο πιο πλήρως και γρήγορα μπορείτε.';

  @override
  String get cameraInstructionFingerTap =>
      'Χτυπήστε τον αντίχειρα με τον δείκτη. Κάντε κάθε χτύπημα όσο πιο μεγάλο και γρήγορο μπορείτε.';

  @override
  String get cameraInstructionPronation =>
      'Γυρίστε την παλάμη σας πάνω και μετά κάτω, ξανά και ξανά. Κάντε κάθε στροφή όσο πιο μεγάλη και γρήγορη μπορείτε.';

  @override
  String cameraStepOf(Object current, Object total) {
    return 'Βήμα $current από $total';
  }

  @override
  String cameraMdsItem(Object item) {
    return 'Στοιχείο MDS-UPDRS $item';
  }

  @override
  String cameraHandNotVisible(Object hand) {
    return 'Φέρτε το $hand μπροστά στην κάμερα';
  }

  @override
  String get cameraPause => 'Παύση';

  @override
  String get cameraPausePending => 'Παύση μετά από αυτή την κίνηση';

  @override
  String get cameraCancelPause => 'Συνέχεια';

  @override
  String get cameraPausedTitle => 'Σε παύση';

  @override
  String get cameraPausedBody =>
      'Πάρτε όσο χρόνο χρειάζεστε. Το τεστ συνεχίζει από την επόμενη κίνηση.';

  @override
  String cameraNextUp(Object task) {
    return 'Επόμενο: $task';
  }

  @override
  String get cameraResume => 'Συνέχεια';

  @override
  String get cameraFinishing => 'Αποθήκευση των αποτελεσμάτων σας';

  @override
  String get postureTest => 'Τεστ στάσεων χεριού';

  @override
  String get testNamePosture => 'Στάσεις';

  @override
  String get postureIntroTitle => 'Αντιγραφή στάσεων χεριού';

  @override
  String get postureIntroBody =>
      'Θα σας δείξουμε εννέα σχήματα χεριού, ένα κάθε φορά. Αντιγράψτε το καθένα με όποιο χέρι θέλετε και κρατήστε το μπροστά στην κάμερα μέχρι να αναγνωριστεί.';

  @override
  String get postureIntroNote =>
      'Καταγράφει πόσο καλά αντιγράφονται τα σχήματα του χεριού. Δεν αποτελεί διάγνωση και δεν μπορεί να δείξει αν έχετε κάποια πάθηση.';

  @override
  String get postureStart => 'Έναρξη';

  @override
  String get postureExit => 'Έξοδος';

  @override
  String postureStepOf(Object current, Object total) {
    return 'Σχήμα $current από $total';
  }

  @override
  String get postureCopyThis => 'Αντιγράψτε αυτό το σχήμα';

  @override
  String get postureSecondTry => 'Ας το δοκιμάσουμε ξανά';

  @override
  String get postureReady => 'Είμαι έτοιμος';

  @override
  String get postureHoldIt => 'Κρατήστε το εκεί';

  @override
  String get postureSkip => 'Παράλειψη σχήματος';

  @override
  String get postureHandNotVisible => 'Φέρτε το χέρι σας μπροστά στην κάμερα';

  @override
  String postureSecondsLeft(Object seconds) {
    return '$secondsδ';
  }

  @override
  String get postureResultsTitle => 'Στάσεις χεριού';

  @override
  String postureScore(Object points, Object total) {
    return '$points από $total';
  }

  @override
  String get postureCopiedFirst => 'Αντιγράφηκε με την πρώτη';

  @override
  String get postureCopiedSecond => 'Αντιγράφηκε με τη δεύτερη';

  @override
  String get postureNotCopied => 'Δεν αντιγράφηκε';

  @override
  String get postureNotRecorded => 'Το χέρι δεν φάνηκε';

  @override
  String get postureQuality => 'Ποιότητα καταγραφής';

  @override
  String get postureNothingRecorded =>
      'Η κάμερα δεν είδε καθαρά το χέρι σας, γι\' αυτό η δοκιμή δεν αποθηκεύτηκε. Συνήθως βοηθά να δοκιμάσετε ξανά με καλύτερο φωτισμό.';

  @override
  String get postureSaved => 'Αποθηκεύτηκε στα αποτελέσματά σας.';

  @override
  String get postureNotSaved => 'Αυτό το αποτέλεσμα δεν αποθηκεύτηκε.';

  @override
  String get postureRepeat => 'Επανάληψη τεστ';

  @override
  String get postureNext => 'Επόμενο';

  @override
  String postureUnrecordedNote(Object count) {
    return '$count σχήμα(τα) δεν φάνηκαν αρκετά καλά ώστε να κριθούν. Δεν μετρούν ως λάθη.';
  }

  @override
  String get cameraHandBoth => 'Και τα δύο χέρια';

  @override
  String get cameraPacingLabel => 'Ρυθμός';

  @override
  String get cameraPacingSelf => 'Θα πατήσω όταν είμαι έτοιμος';

  @override
  String get cameraPacingTimed => 'Αυτόματα';

  @override
  String get cameraPacingSelfNote =>
      'Αφιερώστε όσο χρόνο θέλετε σε κάθε οδηγία. Χρονομετρείται μόνο η ίδια η κίνηση.';

  @override
  String get cameraPacingTimedNote =>
      'Κάθε βήμα ξεκινά μόνο του μετά από σύντομη αντίστροφη μέτρηση. Χρήσιμο αν το τηλέφωνο είναι μακριά.';

  @override
  String get cameraStepReady => 'Όταν είστε έτοιμοι, ξεκινήστε αυτό το βήμα.';

  @override
  String get cameraStartStep => 'Έναρξη βήματος';

  @override
  String get cameraGetReady => 'Ετοιμαστείτε…';

  @override
  String get cameraShowHandToBegin =>
      'Δείξτε το χέρι σας στην κάμερα για να ξεκινήσετε';

  @override
  String cameraApproxDurationRange(Object high, Object low) {
    return 'Περίπου $low-$high λεπτά';
  }

  @override
  String get cameraRetryTitle => 'Ας καταγράψουμε ξανά αυτό το βήμα';

  @override
  String cameraRetryBody(Object task) {
    return 'Η καταγραφή «$task» δεν ήταν αρκετά καθαρή για μέτρηση. Δεν χάνεται τίποτα από όσα έχετε ήδη ολοκληρώσει.';
  }

  @override
  String get cameraRetryAgain => 'Επανάληψη του βήματος';

  @override
  String get cameraRetryKeep => 'Συνέχεια ούτως ή άλλως';

  @override
  String cameraRetryAttempt(Object current, Object total) {
    return 'Προσπάθεια $current από $total';
  }

  @override
  String cameraRetryExhausted(Object count) {
    return 'Αυτό το βήμα καταγράφηκε $count φορές. Μπορείτε να συνεχίσετε χωρίς αυτό.';
  }

  @override
  String get cameraQualityUsableFrames =>
      'Το χέρι δεν ήταν ορατό για αρκετό μέρος της καταγραφής. Κρατήστε το μπροστά στην κάμερα καθ\' όλο το βήμα.';

  @override
  String get cameraQualityHandInFrame =>
      'Μέρος του χεριού έβγαινε από το κάδρο. Απομακρύνετε λίγο το τηλέφωνο ώστε να χωράει όλο το χέρι.';

  @override
  String get cameraQualityHandedness =>
      'Το άλλο χέρι ήταν ορατό για μεγάλο μέρος του βήματος. Δείξτε μόνο το χέρι που εξετάζεται.';

  @override
  String get cameraQualityContinuity =>
      'Το χέρι εξαφανίστηκε από το κάδρο στη μέση του βήματος. Κρατήστε το σταθερά μπροστά στην κάμερα.';

  @override
  String get cameraQualityFps =>
      'Η κάμερα δεν πρόλαβε σε αυτό το βήμα. Συνήθως βοηθά να κλείσετε άλλες εφαρμογές και να δοκιμάσετε ξανά.';

  @override
  String get cameraQualityDuration =>
      'Καταγράφηκε πολύ μικρό μέρος αυτού του βήματος.';

  @override
  String get cameraQualityLandmarks =>
      'Δεν εντοπιζόταν πάντα ολόκληρο το χέρι. Κρατήστε τα δάχτυλα ανοιχτά και την παλάμη προς την κάμερα.';

  @override
  String get cameraQualityHandSize =>
      'Η απόσταση του χεριού από την κάμερα άλλαξε κατά τη διάρκεια του βήματος. Κρατήστε το τηλέφωνο σταθερό και το χέρι στην ίδια απόσταση.';

  @override
  String get cameraResultsTitle => 'Μετρήσεις κίνησης';

  @override
  String get cameraMetricPeakSpeed => 'Μέγιστη ταχύτητα';

  @override
  String get cameraMetricRecordedTime => 'Χρόνος καταγραφής';

  @override
  String cameraUnitPalmWidthsPerSecond(Object value) {
    return '$value πλάτη παλάμης/δευτ.';
  }

  @override
  String get cameraOverallMovement => 'Συνολική κίνηση';

  @override
  String get cameraOverallMovementNote =>
      'Μετρήθηκε σε όλη την καταγραφή. Είναι διαθέσιμα όποτε καταγράφηκαν καρέ, γι\' αυτό εμφανίζονται ακόμη κι όταν οι μετρήσεις ανά βήμα δεν είναι.';

  @override
  String get cameraMetricSpeedVariation => 'Μεταβλητότητα ταχύτητας';

  @override
  String get cameraMetricAccelVariation => 'Μεταβλητότητα επιτάχυνσης';

  @override
  String get cameraMetricJerkVariation => 'Μεταβλητότητα απότομων κινήσεων';

  @override
  String get cameraMetricFingerSpread => 'Άνοιγμα δακτύλων';

  @override
  String get cameraMetricTremorLevel => 'Κίνηση σε ακινησία';

  @override
  String get cameraMetricHandDifference => 'Διαφορά μεταξύ των χεριών';

  @override
  String get cameraDiagnosticsTitle => 'Τεχνικές λεπτομέρειες';

  @override
  String get cameraDiagFramesLabel => 'Καρέ (αξιοποιήσιμα / σύνολο)';

  @override
  String get cameraDiagFpsLabel => 'Καρέ ανά δευτερόλεπτο';

  @override
  String get cameraDiagCyclesLabel => 'Κινήσεις που εντοπίστηκαν';

  @override
  String get cameraDiagSignalLabel => 'Εύρος κίνησης';

  @override
  String get cameraDiagErrorLabel => 'Σφάλμα ανάλυσης';

  @override
  String get cameraAnalysisFailed =>
      'Η αναλυτική επεξεργασία δεν ολοκληρώθηκε, γι\' αυτό εμφανίζονται μόνο οι συνολικές μετρήσεις.';

  @override
  String get cameraResultsIntro =>
      'Αυτές είναι μετρήσεις του πώς κινήθηκαν τα χέρια σας κατά την καταγραφή. Δεν αποτελούν διάγνωση και δεν μπορούν να δείξουν αν έχετε κάποια πάθηση.';

  @override
  String get cameraResultsQuality => 'Ποιότητα καταγραφής';

  @override
  String get cameraResultsOverallConfidence => 'Συνολικά';

  @override
  String cameraResultsTasksDone(Object done, Object total) {
    return 'Μετρήθηκαν $done από $total βήματα';
  }

  @override
  String cameraResultsRetries(Object count) {
    return '$count βήμα(τα) καταγράφηκαν πάνω από μία φορά';
  }

  @override
  String get cameraResultsNotSaved => 'Αυτό το αποτέλεσμα δεν αποθηκεύτηκε.';

  @override
  String get cameraResultsSaved => 'Αποθηκεύτηκε στα αποτελέσματά σας.';

  @override
  String get cameraResultsNothing =>
      'Δεν ήταν δυνατή καμία μέτρηση από αυτή την καταγραφή, γι\' αυτό δεν αποθηκεύτηκε. Συνήθως βοηθά να επαναλάβετε το τεστ.';

  @override
  String get cameraResultsInsufficient => 'Ανεπαρκή δεδομένα';

  @override
  String get cameraResultsNotRecorded =>
      'Αυτό το βήμα δεν καταγράφηκε αρκετά καλά για να μετρηθεί.';

  @override
  String get cameraResultsTooFewMovements =>
      'Εντοπίστηκαν πολύ λίγες κινήσεις για να υπολογιστεί αυτό.';

  @override
  String get cameraResultsDifference => 'Διαφορά μεταξύ των χεριών';

  @override
  String get cameraResultsNoComparison =>
      'Χρειάζονται και τα δύο χέρια για σύγκριση.';

  @override
  String get cameraResultsTechnical => 'Τεχνικές λεπτομέρειες';

  @override
  String get cameraResultsRepeat => 'Επανάληψη τεστ';

  @override
  String get cameraResultsNext => 'Επόμενο';

  @override
  String get cameraMetricTapsPerSecond => 'Χτυπήματα ανά δευτερόλεπτο';

  @override
  String get cameraMetricMovementsPerSecond => 'Κινήσεις ανά δευτερόλεπτο';

  @override
  String get cameraMetricTurnsPerSecond => 'Στροφές ανά δευτερόλεπτο';

  @override
  String get cameraMetricAmplitude => 'Μέγεθος κίνησης';

  @override
  String get cameraMetricRhythm => 'Μεταβλητότητα ρυθμού';

  @override
  String get cameraMetricAmplitudeDecrement => 'Μεταβολή μεγέθους στο βήμα';

  @override
  String get cameraMetricSpeedDecrement => 'Μεταβολή ταχύτητας στο βήμα';

  @override
  String get cameraMetricPauses => 'Παύσεις';

  @override
  String get cameraMetricSpeed => 'Μέση ταχύτητα';

  @override
  String get cameraMetricTremorAmplitude => 'Κίνηση σε ηρεμία';

  @override
  String get cameraMetricTremorFrequency => 'Ρυθμός αυτής της κίνησης';

  @override
  String get cameraMetricRestDuration => 'Αξιοποιήσιμη καταγραφή';

  @override
  String get cameraMetricCycles => 'Κινήσεις που εντοπίστηκαν';

  @override
  String cameraUnitPerSecond(Object value) {
    return '$value/δευτ.';
  }

  @override
  String cameraUnitHertz(Object value) {
    return '$value Hz';
  }

  @override
  String cameraUnitSeconds(Object value) {
    return '$value δευτ.';
  }

  @override
  String cameraUnitPalmWidths(Object value) {
    return '$value πλάτη παλάμης';
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
    return 'Βήμα $current από $total';
  }

  @override
  String get stepStart => 'Έναρξη';

  @override
  String get stepSubmit => 'Υποβολή';

  @override
  String get stepFinish => 'Τερματισμός';

  @override
  String get stepDone => 'Ολοκλήρωση';

  @override
  String get stepContinue => 'Συνέχεια';

  @override
  String get stepHint => 'Υπόδειξη';

  @override
  String get stepClear => 'Καθαρισμός';

  @override
  String get stepDelete => 'Διαγραφή';

  @override
  String get stepAnswer => 'Απάντηση';

  @override
  String get stepResults => 'Αποτελέσματα';

  @override
  String get stepTimeRemaining => 'Χρόνος που απομένει';

  @override
  String stepTimeRemainingValue(Object seconds) {
    return 'Χρόνος που απομένει: $seconds';
  }

  @override
  String get stepTapMicToStart => 'Πάτα το μικρόφωνο για να ξεκινήσεις.';

  @override
  String get stepSayWithMic => 'Πείτε τη λέξη με το μικρόφωνο';

  @override
  String get stepSpokenIntoMic => 'Λέγεται στο μικρόφωνο';

  @override
  String get stepTypeOrUseMic =>
      'Μπορείτε να γράψετε ή να χρησιμοποιήσετε το μικρόφωνο.';

  @override
  String get stepStartMic => 'Εκκίνηση μικροφώνου';

  @override
  String get stepMicProblem =>
      'Πρόβλημα με το μικρόφωνο. Πάτα πάλι το μικρόφωνο για να ξαναδοκιμάσεις.';

  @override
  String get stepMicStopped =>
      'Το μικρόφωνο σταμάτησε. Πάτησε το μικρόφωνο για να συνεχίσεις.';

  @override
  String get stepMicClosed =>
      'Το μικρόφωνο έκλεισε. Πάτησε ξανά το μικρόφωνο για να συνεχίσεις.';

  @override
  String get stepSpeakNow =>
      'Μιλήστε τώρα! Κάθε λέξη εμφανίζεται αμέσως στην οθόνη.';

  @override
  String get stepCorrectAnswer => 'Σωστή απάντηση!';

  @override
  String get stepCorrectWithHint => 'Σωστό! (Χρησιμοποιήθηκε υπόδειξη)';

  @override
  String get stepWrongOrder => 'Λάθος σειρά.';

  @override
  String get stepWrongLine => 'Λάθος γραμμή';

  @override
  String get stepAllWordsFound => 'Όλες οι λέξεις έχουν βρεθεί!';

  @override
  String stepTimeUpScore(Object score) {
    return 'Ολοκληρώθηκε ο χρόνος.\nΣκορ: $score/3.00';
  }

  @override
  String get stepCameraPermissionRequired =>
      'Απαιτείται πρόσβαση στην κάμερα για να συνεχίσετε.';

  @override
  String get stepCameraPermissionRecheck => 'Επανέλεγχος άδειας';

  @override
  String get stepCameraPermissionSettings =>
      'Ελέγξτε τις ρυθμίσεις της εφαρμογής αν το πρόβλημα παραμείνει.';

  @override
  String get stepLocationDenied =>
      'Δεν επιτράπηκε η πρόσβαση στην τοποθεσία.\nΟι απαντήσεις στην Πόλη/Χώρα θα γίνουν δεκτές όπως είναι.';

  @override
  String get stepTitleSubtract => 'Αφαίρεση 7 από το 100';

  @override
  String get stepTitleOrientation => 'Προσανατολισμός';

  @override
  String get stepTitleNaming => 'Κατονομασία';

  @override
  String get stepTitleImmediateRecall => 'Άμεση Ανάκληση';

  @override
  String get stepTitleDelayedRecall => 'Καθυστερημένη Ανάκληση';

  @override
  String get stepTitleDigits => 'Εργαζόμενη μνήμη';

  @override
  String get stepTitleVigilance => 'Εγρήγορση';

  @override
  String get stepTitleFluency => 'Λεκτική ευχέρεια';

  @override
  String get stepTitleSimilarities => 'Αφαιρετική σκέψη';

  @override
  String get stepTitleClock => 'Ρολόι: δείκτες';

  @override
  String get stepTitleTrails => 'Οπτικο-Νοητική Ιχνηλάτηση';

  @override
  String get stepTitleCube => 'Οπτικο-Κατασκευαστικές Ικανότητες';

  @override
  String get stepTitleRepeatSentences => 'Επανάληψη προτάσεων';

  @override
  String get stepTitleGestures => 'Αναγνώριση Χειρονομιών';

  @override
  String get stepTitleConflicting => 'Εναντιούμενα παραγγέλματα';

  @override
  String get stepTitleGoNoGo => 'Πάτημα';

  @override
  String get stepInstructionSubtract =>
      'Αφαιρέστε διαδοχικά 7 ξεκινώντας από το 100 (πέντε φορές):';

  @override
  String get stepInstructionDigitsMemorise =>
      'Προσπαθήστε να απομνημονεύσετε τα παρακάτω νούμερα.';

  @override
  String get stepInstructionDigitsForwardSoon =>
      'Σε λίγο θα σας ζητηθεί να τα επαναλάβετε με τη σωστή σειρά.';

  @override
  String get stepInstructionDigitsBackwardSoon =>
      'Σε λίγο θα σας ζητηθεί να τα επαναλάβετε με την αντίστροφη σειρά.';

  @override
  String get stepInstructionDigitsForward =>
      'Επαναλάβετε με τη σωστή σειρά τους αριθμούς που είδατε:';

  @override
  String get stepInstructionDigitsBackward =>
      'Επαναλάβετε με την αντίστροφη σειρά τους αριθμούς που είδατε:';

  @override
  String get stepInstructionWriteOrSayNumbers => 'Γράψτε ή πείτε τους αριθμούς';

  @override
  String get stepInstructionOrientation => 'Συμπληρώστε τα παρακάτω:';

  @override
  String get stepInstructionOrientationDay => 'Ημέρα (π.χ. Δευτέρα)';

  @override
  String get stepInstructionOrientationDate =>
      'Ημερομηνία (π.χ. 01 / 01 / 2020)';

  @override
  String get stepInstructionOrientationCity => 'Πόλη';

  @override
  String get stepInstructionOrientationCountry => 'Χώρα';

  @override
  String get stepHintCityExample => 'π.χ. Αθήνα';

  @override
  String get stepHintCountryExample => 'π.χ. Ελλάδα';

  @override
  String get stepInstructionNaming =>
      'Κατονομάστε κάθε ζώο πατώντας το μικρόφωνο στη δεξιά πλευρά του πλαισίου.';

  @override
  String get stepInstructionImmediateRecall =>
      'Θα σας πω 5 λέξεις. Προσπαθήστε να τις απομνημονεύσετε γιατί λίγο αργότερα θα σας ζητηθούν ξανά.';

  @override
  String get stepInstructionImmediateRecallPractice =>
      'Για εξάσκηση πρώτα θα τις επαναλάβετε όλες μαζί. Μετά, θα προσπαθήσετε να επαναλάβετε κάθε λέξη ξεχωριστά.';

  @override
  String stepInstructionSayWordsTogether(Object words) {
    return 'Πείτε τις λέξεις από τη λίστα (όλες μαζί, με όποια σειρά θέλετε): $words';
  }

  @override
  String stepInstructionSayWordsSeparately(Object words) {
    return 'Πείτε τις λέξεις, μία σε κάθε πεδίο. $words';
  }

  @override
  String get stepInstructionSayWords => 'Πείτε τις λέξεις';

  @override
  String get stepInstructionDelayedRecall =>
      'Πείτε όσες από τις 5 λέξεις που απομνημονεύσατε στην αρχή του τεστ θυμάστε (μόνο με φωνή, η σειρά δεν μετράει).';

  @override
  String get stepInstructionDelayedRecallHint =>
      'Αν πατήσετε “Υπόδειξη” για κάποιο, παίρνετε μισό βαθμό για αυτό.';

  @override
  String get stepInstructionWhichWordWasInList =>
      'Ποια από τις παρακάτω λέξεις ήταν στη λίστα;';

  @override
  String get stepInstructionVigilance =>
      'Αυτό το τεστ μετρά την εγρήγορση και την προσοχή σας.';

  @override
  String get stepInstructionVigilanceLetters =>
      'Θα εμφανιστεί μία σειρά από γράμματα, ένα κάθε φορά.';

  @override
  String get stepInstructionVigilanceTap =>
      'Πατήστε το κουμπί όταν βλέπετε το γράμμα “Α”.';

  @override
  String get stepInstructionFluency =>
      'Λεκτική ευχέρεια: όσες περισσότερες λέξεις μπορείς που να αρχίζουν από το γράμμα “Χ”, χωρίς να πεις κύρια ονόματα ή παράγωγες λέξεις, μέσα σε 1 λεπτό.';

  @override
  String get stepInstructionSimilarities => 'Τι κοινό έχουν τα παρακάτω ζεύγη;';

  @override
  String get stepInstructionSimilaritiesExample =>
      'π.χ. μπανάνα - πορτοκάλι = φρούτα';

  @override
  String get stepInstructionSimilaritiesHint =>
      'Πατήστε “Υπόδειξη” για παραδείγματα απαντήσεων.';

  @override
  String get stepInstructionClock =>
      'Μετακινήστε τους δείκτες ώστε να δείχνουν 11:10';

  @override
  String get stepInstructionTrails =>
      'Συνδέστε τα κυκλάκια ξεκινώντας από το 1, έπειτα το Α, μετά το 2, Β, 3, Γ… έως το 5 και Ε.';

  @override
  String get stepInstructionTrailsRetry =>
      'Αν κάνετε λάθος, μπορείτε να προσπαθήσετε ξανά. Αν δυσκολεύεστε, πατήστε “Επόμενο”. Χρόνος 2 λεπτά.';

  @override
  String get stepInstructionDrawCube =>
      'Αντιγράψτε τον κύβο που βλέπετε παρακάτω.';

  @override
  String get stepInstructionConnectCube =>
      'Αντιγράψτε τον κύβο συνδέοντας τις τελείες. Πατήστε πρώτα μία τελεία και μετά την επόμενη.';

  @override
  String get stepInstructionConnectCubeAlmost =>
      'Σχεδόν σωστό—διαγράψτε τις κόκκινες γραμμές';

  @override
  String get stepInstructionRepeatSentence => 'Πείτε την πρόταση…';

  @override
  String get stepInstructionGesturesIntro =>
      'Όταν πατήσετε “Έναρξη”, θα ενεργοποιηθεί η κάμερα για 1 λεπτό.\n\nΠρέπει να πραγματοποιήσετε τις εξής κινήσεις:';

  @override
  String get stepInstructionGesturesPerformAll =>
      'Εκτελέστε όλες τις κινήσεις.';

  @override
  String stepGestureRecognised(Object gesture) {
    return '$gesture\nΑναγνωρίστηκε!';
  }

  @override
  String get stepGesturesAllDetected =>
      'Συγχαρητήρια! Εντοπίστηκαν όλα τα gestures.\n\nΣκορ: 3.00/3.00';

  @override
  String stepWordNumbered(Object number) {
    return 'Λέξη $number';
  }

  @override
  String stepExampleAnswer(Object hint) {
    return 'Υπόδειγμα: $hint';
  }

  @override
  String stepHintFor(Object hint) {
    return 'Υπόδειξη: $hint';
  }

  @override
  String get stepHeardTargetLetter => 'Άκουσα Α';

  @override
  String get stepStartTest => 'Έναρξη Τεστ';

  @override
  String stepSecondsValue(Object seconds) {
    return '$seconds δευτ.';
  }

  @override
  String stepMemoriseTimeLeft(Object seconds) {
    return 'Χρόνος απομνημόνευσης: $seconds';
  }

  @override
  String get stepInstructionRepeatSentencesIntro =>
      'Θα εμφανιστεί μια πρόταση για 20 δευτερόλεπτα. Προσπάθησε να τη διαβάσεις και να την απομνημονεύσεις. Στη συνέχεια θα σου ζητηθεί να την επαναλάβεις όσο πιο σωστά μπορείς.\n\nΘα έχεις τη δυνατότητα να δεις ξανά την πρόταση για 3 δευτερόλεπτα αν χρειαστεί (Υπόδειξη) και μπορείς να καθαρίσεις ό,τι έχει πει το μικρόφωνο (Καθαρισμός). Πάτα “Επόμενο” για να προχωρήσεις, ακόμα κι αν δεν έχεις απαντήσει.';

  @override
  String get stepInstructionRepeatBack =>
      'Επανάλαβε την πρόταση που διάβασες. Πάτησε το μικρόφωνο για να ξεκινήσεις. Αν σταματήσει, πάτησέ το ξανά.';

  @override
  String get fabGoNoGoInstructions =>
      'Σε αυτή τη δοκιμασία θα εμφανίζονται αριθμοί 1 και 2.\n\nΠατήστε το κουμπί “Πάτημα” όταν εμφανίζεται ο αριθμός 1. Μην πατάτε το κουμπί όταν εμφανίζεται ο αριθμός 2.\n\nΘα δοκιμάσουμε πρώτα με μια δοκιμαστική σειρά για να εξηγήσουμε τους κανόνες, και μετά θα προχωρήσουμε στην κύρια δοκιμασία.';

  @override
  String get fabGoNoGoRules => '“1” — Πατάω\n“2” — ΔΕΝ Πατάω';

  @override
  String get fabGoNoGoPracticeIntro =>
      'Δοκιμαστική σειρά. Εφαρμόστε τους κανόνες. Σε περίπτωση λάθους, θα δείτε μια εξήγηση. Πατήστε “Έναρξη” για να ξεκινήσετε την εκπαίδευση.';

  @override
  String get fabGoNoGoTestIntro =>
      'Κύρια δοκιμασία. Εφαρμόστε τους κανόνες. Πατήστε “Έναρξη” για να ξεκινήσετε.';

  @override
  String get fabTap => 'Πάτημα';

  @override
  String get fabGoNoGoMissed => 'Έπρεπε να πατήσετε 1 φορά, αλλά δεν πατήσατε.';

  @override
  String fabGoNoGoTooMany(Object count) {
    return 'Έπρεπε να πατήσετε 1 φορά, πατήσατε $count.';
  }

  @override
  String fabGoNoGoShouldNotTap(Object count) {
    return 'Δεν έπρεπε να πατήσετε, αλλά πατήσατε $count.';
  }

  @override
  String fabScoreValue(Object score) {
    return 'Σκορ: $score';
  }

  @override
  String get fabGoNoGoResultStreak =>
      'Απάντησες ίδιο αριθμό τουλάχιστον 4 φορές συνεχόμενα.';

  @override
  String get fabGoNoGoResultPerfect => 'Δεν έκανες κανένα λάθος!';

  @override
  String get fabGoNoGoResultFew => 'Έκανες 1 ή 2 λάθη.';

  @override
  String get fabGoNoGoResultMany => 'Έκανες περισσότερα από 2 λάθη.';

  @override
  String get fabFluencyInstructions =>
      '«Πείτε όσες περισσότερες λέξεις μπορείτε που να αρχίζουν από το γράμμα Κ, εκτός από επώνυμα και κύρια ονόματα».\n\nΟ επιτρεπόμενος χρόνος είναι 60 δευτερόλεπτα.\n\nΒαθμολόγηση: περισσότερες από 10 λέξεις = 3 βαθμοί, 6 έως 10 = 2, 3 έως 5 = 1, λιγότερες από 3 = 0.';

  @override
  String get fabFluencyTitle => 'Λεκτική ευφράδεια';

  @override
  String get fabFluencyPrompt => 'Λέξεις που ξεκινούν με “Κ”';

  @override
  String get fabFluencyResultMany => 'Περισσότερες από 10 λέξεις.';

  @override
  String fabFluencyResultCount(Object count) {
    return '$count λέξεις.';
  }

  @override
  String get fabFluencyResultFew => 'Λιγότερες από 3 λέξεις.';

  @override
  String get fabSimilaritiesTitle => 'Ομοιότητες';

  @override
  String get fabSimilaritiesInstructions =>
      '«Τι κοινό έχουν;»\n\nΠαράδειγμα: μπανάνα - πορτοκάλι = φρούτα.\n\nΜπορείτε να πληκτρολογήσετε ή να χρησιμοποιήσετε το μικρόφωνο. Πατήστε “Υπόδειξη” μόνο στην 1η ερώτηση αν θέλετε βοήθεια.\n\nΒαθμολόγηση: 3 σωστές απαντήσεις = 3 βαθμοί, 2 = 2, 1 = 1, καμία = 0.';

  @override
  String fabQuestionOfCount(Object current, Object total) {
    return 'Ερώτηση $current από $total';
  }

  @override
  String fabCorrectAnswersCount(Object count) {
    return '$count σωστές απαντήσεις.';
  }

  @override
  String get fabNoCorrectAnswers => 'Καμία σωστή απάντηση.';

  @override
  String get fabConflictingInstructions =>
      'Χτυπήστε μία φορά όταν χτυπήσω δύο φορές. Χτυπήστε δύο φορές όταν χτυπήσω μία φορά.\n\nΘα κάνουμε πρώτα μια δοκιμαστική σειρά και μετά την κύρια δοκιμασία.';

  @override
  String get fabExaminerTapsOnce => 'Χτυπάω μία φορά';

  @override
  String get fabExaminerTapsTwice => 'Χτυπάω δύο φορές';

  @override
  String get fabYourTurn => 'Η σειρά σας';

  @override
  String fabGesturesRemaining(Object gestures) {
    return 'Απομένουν: $gestures';
  }

  @override
  String get fabConflictingRules => '“1” — Πατάω 2 φορές\n“2” — Πατάω 1 φορά';

  @override
  String get fabConflictingPracticeIntro =>
      'Δοκιμαστική σειρά. Ακολουθήστε τις οδηγίες για να καταλάβετε τη λογική του τεστ. Πατήστε “Έναρξη” για να ξεκινήσετε την εκπαίδευση.';

  @override
  String get fabConflictingTestIntro =>
      'Κύρια δοκιμασία. Εφαρμόστε τους κανόνες. Πατήστε “Έναρξη” για να ξεκινήσετε.';

  @override
  String fabExpectedTapsOnce(Object count) {
    return 'Έπρεπε να πατήσετε 1 φορά, πατήσατε $count.';
  }

  @override
  String fabExpectedTapsTwice(Object count) {
    return 'Έπρεπε να πατήσετε 2 φορές, πατήσατε $count.';
  }

  @override
  String get fabResultStreakStimulus =>
      'Απαντήσατε ίδιο αριθμό με το ερέθισμα τουλάχιστον 4 συνεχόμενες φορές.';

  @override
  String get testCompleteTitle => 'Η δοκιμασία ολοκληρώθηκε';

  @override
  String get testCompleteSaved => 'Το αποτέλεσμά σας αποθηκεύτηκε.';

  @override
  String get testCompleteNotSaved =>
      'Το αποτέλεσμα δεν μπόρεσε να αποθηκευτεί, αλλά ορίστε.';

  @override
  String get testCompleteScore => 'Βαθμολογία';

  @override
  String get testCompleteDone => 'Τέλος';

  @override
  String get testCompleteViewAll => 'Δείτε όλα τα αποτελέσματά μου';

  @override
  String get bandReassuringWorse =>
      'Δεν προέκυψε κάτι αξιοσημείωτο σε αυτή τη δοκιμασία.';

  @override
  String get bandBorderlineWorse =>
      'Το αποτέλεσμα βρίσκεται στο μεσαίο εύρος. Επαναλαμβάνοντας τη δοκιμασία άλλη μέρα θα έχετε σαφέστερη εικόνα.';

  @override
  String get bandNotableWorse =>
      'Αξίζει να αναφέρετε αυτό το αποτέλεσμα στον γιατρό σας. Πρόκειται για έλεγχο ανίχνευσης, όχι για διάγνωση.';

  @override
  String get bandReassuringBetter =>
      'Το αποτέλεσμα βρίσκεται στο αναμενόμενο εύρος.';

  @override
  String get bandBorderlineBetter =>
      'Το αποτέλεσμα είναι ελαφρώς κάτω από το αναμενόμενο εύρος. Επαναλαμβάνοντάς το άλλη μέρα θα έχετε σαφέστερη εικόνα.';

  @override
  String get bandNotableBetter =>
      'Το αποτέλεσμα είναι κάτω από το αναμενόμενο εύρος και αξίζει να το αναφέρετε στον γιατρό σας. Πρόκειται για έλεγχο ανίχνευσης, όχι για διάγνωση.';

  @override
  String get screeningDisclaimer =>
      'Η εφαρμογή είναι βοήθημα ανίχνευσης. Δεν μπορεί να διαγνώσει τη νόσο του Πάρκινσον και μόνο κλινικός ιατρός μπορεί να ερμηνεύσει αυτά τα αποτελέσματα.';

  @override
  String get guestKeepResultsTitle => 'Κρατήστε αυτά τα αποτελέσματα';

  @override
  String get guestKeepResultsBody =>
      'Χρησιμοποιείτε λογαριασμό επισκέπτη. Δημιουργήστε λογαριασμό για να κρατήσετε τα αποτελέσματά σας και να τα μοιραστείτε με γιατρό.';

  @override
  String get guestExitTitle => 'Αποχώρηση χωρίς λογαριασμό;';

  @override
  String get guestExitBody =>
      'Τα αποτελέσματά σας συνδέονται με αυτή τη συνεδρία επισκέπτη σε αυτή τη συσκευή. Αν χαθεί, χάνονται και αυτά. Δημιουργώντας λογαριασμό κρατάτε ό,τι έχετε κάνει μέχρι τώρα.';

  @override
  String get guestExitStay => 'Δημιουργία λογαριασμού';

  @override
  String get guestExitLeave => 'Αποχώρηση ούτως ή άλλως';

  @override
  String get guestSignInDisabled =>
      'Η είσοδος ως επισκέπτης δεν είναι ακόμη ενεργοποιημένη. Δημιουργήστε λογαριασμό ή δοκιμάστε αργότερα.';

  @override
  String get testNameDrawing => 'Σχέδιο';

  @override
  String get testNameQuestionnaire => 'Ερωτηματολόγιο';

  @override
  String get testNameTremor => 'Τρόμος';

  @override
  String get testNameTap => 'Χτυπήματα';

  @override
  String get testNameVoice => 'Φωνή';

  @override
  String get testNameCamera => 'Κάμερα';

  @override
  String get testNameNeuro => 'Μνήμη';

  @override
  String get testNameFab => 'Συλλογιστική';

  @override
  String get bandLabelReassuring => 'Καθησυχαστικό';

  @override
  String get bandLabelBorderline => 'Οριακό';

  @override
  String get bandLabelNotable => 'Αξιοσημείωτο';

  @override
  String get resultsInfoTitle => 'Σχετικά με αυτές τις βαθμολογίες';

  @override
  String get resultsInfoBody =>
      'Κάθε μπάρα δείχνει το πιο πρόσφατο αποτέλεσμα της αντίστοιχης δοκιμασίας, ως επίπεδο ανησυχίας από 0% έως 100%. Το υψηλότερο σημαίνει πάντα ότι αξίζει μεγαλύτερη προσοχή, από όποια δοκιμασία κι αν προέρχεται.\n\nΑυτό χρειάζεται διευκρίνιση, γιατί οι δοκιμασίες δεν μετρούν όλες με τον ίδιο τρόπο. Στις δοκιμασίες χτυπημάτων ή τρόμου, υψηλή αρχική βαθμολογία σημαίνει περισσότερες ενδείξεις τρόμου· στις δοκιμασίες μνήμης και συλλογιστικής, υψηλή αρχική βαθμολογία σημαίνει ότι τα πήγατε καλά. Και οι δύο μετατρέπονται εδώ, ώστε η χαμηλή μπάρα να είναι πάντα η πιο καθησυχαστική.\n\nΟι τρεις ζώνες — καθησυχαστικό, οριακό και αξιοσημείωτο — είναι προσωρινά όρια, όχι κλινικά κατώφλια. Ένα μεμονωμένο αξιοσημείωτο αποτέλεσμα μία μέρα σημαίνει πολύ λιγότερα από το ίδιο αποτέλεσμα που επαναλαμβάνεται επί εβδομάδες.\n\nΠατήστε μια δοκιμασία για να δείτε πώς έχει μεταβληθεί με τον χρόνο.';

  @override
  String get overallTrend => 'Συνολική τάση';

  @override
  String get trendInfoTitle => 'Σχετικά με την τάση';

  @override
  String get trendInfoBody =>
      'Ένα σημείο για κάθε μέρα που κάνατε τουλάχιστον μία δοκιμασία, ως μέσος όρος όλων των δοκιμασιών εκείνης της ημέρας.\n\nΧρησιμοποιήστε το για να δείτε κατεύθυνση και όχι λεπτομέρεια: μια γραμμή που ανεβαίνει σταθερά επί εβδομάδες αξίζει να αναφερθεί στον γιατρό σας, ενώ μια μεμονωμένη κορύφωση συνήθως οφείλεται σε κουρασμένο χέρι, βιαστική προσπάθεια ή θορυβώδη χώρο και όχι στην υγεία σας.\n\nΟι μέρες χωρίς δοκιμασίες απλώς λείπουν από τη γραμμή, οπότε ένα διάστημα δραστηριότητας ακολουθούμενο από κενό θα φαίνεται σαν ένα μεγάλο βήμα. Αν κάνετε τις δοκιμασίες περίπου την ίδια ώρα της ημέρας, η σύγκριση γίνεται δικαιότερη.';

  @override
  String get trendWindowLabel => 'Μέσος όρος για';

  @override
  String trendWindowLast(int count) {
    return 'Τελευταίες $count ημέρες';
  }

  @override
  String get trendNeedsMoreDays =>
      'Δεν υπάρχουν αρκετές δοκιμασίες σε αυτό το διάστημα για να σχεδιαστεί τάση. Επιλέξτε μεγαλύτερο διάστημα ή κάντε μια δοκιμασία άλλη μέρα.';

  @override
  String get summaryInfoTitle => 'Σχετικά με τη σύνοψη';

  @override
  String get summaryInfoBody =>
      'Κάθε ακτίνα αντιστοιχεί σε μία δοκιμασία και η απόσταση από το κέντρο είναι το μέσο επίπεδο ανησυχίας για αυτήν, σε όλες σας τις προσπάθειες.\n\nΈνα μικρό, ομοιόμορφο σχήμα σημαίνει ότι τίποτα δεν ξεχωρίζει. Ένα σχήμα τεντωμένο προς μία ακτίνα σημαίνει ότι η συγκεκριμένη δοκιμασία διαφέρει από τις υπόλοιπες — και αυτό ακριβώς αξίζει να δείξετε σε κλινικό ιατρό, καθώς η νόσος του Πάρκινσον σπάνια επηρεάζει τα πάντα εξίσου στην αρχή.\n\nΕπειδή πρόκειται για μέσους όρους όλων των προσπαθειών, το σχήμα μεταβάλλεται αργά και τα πρώτα αποτελέσματα συνεχίζουν να το επηρεάζουν για πολύ καιρό.';

  @override
  String appVersion(String version) {
    return 'Έκδοση $version';
  }

  @override
  String get medicalDisclaimer => 'Ιατρική δήλωση αποποίησης';

  @override
  String get medicalDisclaimerBody =>
      'Η εφαρμογή δεν είναι ιατρική συσκευή και δεν παρέχει διάγνωση.\n\nΟι δοκιμασίες εδώ είναι βοηθήματα ανίχνευσης. Αναζητούν μοτίβα που είναι συνήθη στη νόσο του Πάρκινσον, όμως πολλοί άλλοι παράγοντες — κόπωση, καφεΐνη, φάρμακα, άγχος, κάποια άσχετη πάθηση ή απλώς ένα άβολο κράτημα του κινητού — δημιουργούν τα ίδια μοτίβα. Ένα ανησυχητικό αποτέλεσμα δεν σημαίνει ότι έχετε νόσο του Πάρκινσον, ούτε ένα καθησυχαστικό αποτέλεσμα την αποκλείει.\n\nΜόνο ειδικευμένος κλινικός ιατρός μπορεί να διαγνώσει τη νόσο του Πάρκινσον, και μόνο έπειτα από εξέταση με φυσική παρουσία. Αναφέρετε στον γιατρό σας κάθε αποτέλεσμα που σας ανησυχεί και μην ξεκινάτε, σταματάτε ή αλλάζετε ποτέ κάποια φαρμακευτική αγωγή με βάση όσα δείχνει η εφαρμογή.\n\nΑν έχετε αιφνίδια ή σοβαρά συμπτώματα, ζητήστε αμέσως ιατρική βοήθεια αντί να κάνετε κάποια δοκιμασία.';

  @override
  String get privacyPolicy => 'Πολιτική απορρήτου';

  @override
  String get termsOfService => 'Όροι χρήσης';

  @override
  String get legalDocumentPlaceholder =>
      'Το κείμενο αυτό δεν έχει δημοσιευτεί ακόμη.\n\nΜέχρι τότε, να τι κάνει στην πράξη η εφαρμογή με τα δεδομένα σας: τα αποτελέσματα των δοκιμασιών, οι απαντήσεις στα ερωτηματολόγια και οι ηχογραφήσεις φωνής αποθηκεύονται στον λογαριασμό σας και είναι ορατά σε εσάς και σε όποιον γιατρό επιλέξετε να τα μοιραστείτε. Τίποτα δεν κοινοποιείται σε κανέναν άλλον.\n\nΕπικοινωνήστε με τον πάροχο της εφαρμογής αν χρειάζεστε το πλήρες κείμενο πριν γίνει διαθέσιμο εδώ.';

  @override
  String get cameraSetupTitle => 'Ρύθμιση κάμερας';

  @override
  String get cameraSetupStep1 => 'Γυρίστε το κινητό οριζόντια (στο πλάι).';

  @override
  String get cameraSetupStep2 =>
      'Στηρίξτε το σε ένα τραπέζι, πάνω σε κάτι σταθερό, με την οθόνη προς εσάς και γερμένο ώστε η κάμερα να βλέπει τα χέρια σας.';

  @override
  String get cameraSetupStep3 =>
      'Καθίστε περίπου 50–70 εκ. μακριά — περίπου όσο το μήκος του χεριού σας — με τους αγκώνες στο τραπέζι.';

  @override
  String get cameraSetupStep4 =>
      'Χρησιμοποιήστε ένα καλά φωτισμένο δωμάτιο, με το φως μπροστά σας και όχι πίσω σας.';

  @override
  String get cameraSetupStep5 =>
      'Σηκώστε και τα δύο χέρια. Όταν ο έλεγχος παρακάτω δείξει «έτοιμο», πατήστε Έναρξη. Δεν θα χρειαστεί να αγγίξετε ξανά το κινητό — απλώς ακολουθήστε τη φωνή.';

  @override
  String get cameraSetupHintNoHands =>
      'Σηκώστε και τα δύο χέρια μπροστά στην κάμερα';

  @override
  String get cameraSetupHintOneHand =>
      'Φαίνεται μόνο ένα χέρι — δείξτε και τα δύο';

  @override
  String get cameraSetupHintTooFar =>
      'Τα χέρια σας φαίνονται μικρά — πλησιάστε λίγο';

  @override
  String get cameraSetupHintTooClose =>
      'Τα χέρια σας κόβονται — απομακρυνθείτε λίγο';

  @override
  String get cameraSetupHintReady => 'Φαίνονται και τα δύο χέρια — έτοιμο';

  @override
  String get cameraSetupWaitingCamera => 'Η κάμερα ξεκινά…';

  @override
  String cameraSetupFps(Object fps) {
    return 'Ταχύτητα κάμερας: $fps καρέ ανά δευτερόλεπτο';
  }

  @override
  String get cameraSetupSlow =>
      'Η κάμερα λειτουργεί αργά. Συνήθως βοηθά περισσότερο φως και το κλείσιμο άλλων εφαρμογών.';

  @override
  String cameraSetupDuration(Object minutes, Object steps) {
    return 'Περίπου $minutes λεπτά: $steps βήματα των 10 δευτερολέπτων.';
  }

  @override
  String get cameraTaskPosture => 'Τεντωμένα χέρια';

  @override
  String get cameraInstructionRestBoth =>
      'Ακουμπήστε και τους δύο πήχεις στο τραπέζι, με τα χέρια χαλαρά και ακίνητα, μπροστά στην κάμερα.';

  @override
  String get cameraInstructionPosture =>
      'Τεντώστε και τα δύο χέρια μπροστά σας, με τις παλάμες προς τα κάτω και τα δάχτυλα ανοιχτά. Κρατήστε τα όσο πιο ακίνητα μπορείτε.';

  @override
  String get cameraShowHandsToBegin => 'Δείξτε και τα δύο χέρια στην κάμερα';

  @override
  String cameraSwitchHands(Object hand) {
    return 'Τώρα χρησιμοποιήστε το $hand. Αφήστε το άλλο χέρι κάτω στο τραπέζι.';
  }

  @override
  String get cameraRetryNotice => 'Ας κάνουμε αυτό το βήμα άλλη μία φορά.';

  @override
  String get cameraRecording => 'Καταγραφή';

  @override
  String get cameraSayGo => 'Πάμε.';

  @override
  String get cameraSayStop => 'Σταματήστε. Χαλαρώστε.';

  @override
  String get cameraSayFinished => 'Μπράβο. Η δοκιμασία τελείωσε.';

  @override
  String get cameraSayRetry => 'Ας το κάνουμε άλλη μία φορά.';

  @override
  String get cameraResultsScoreTitle => 'Το αποτέλεσμά σας';

  @override
  String cameraResultsScoreValue(Object score) {
    return '$score / 100';
  }

  @override
  String get cameraResultsScoreNote =>
      'Η βαθμολογία υπολογίζεται αυτόματα από το βίντεο, με κανόνες που βασίζονται στον τρόπο που οι γιατροί βαθμολογούν αυτές τις κινήσεις (0 = φυσιολογικό, 4 = σοβαρό). Δεν έχει ακόμη ελεγχθεί σε σύγκριση με βαθμολογίες γιατρών και δεν αποτελεί διάγνωση. Μοιραστείτε τη με τον γιατρό σας.';

  @override
  String get cameraResultsRatingsTitle => 'Βαθμολογία ανά κίνηση';

  @override
  String get cameraResultsRatingsScale =>
      '0 φυσιολογικό · 1 ελαφρύ · 2 ήπιο · 3 μέτριο · 4 σοβαρό';

  @override
  String get cameraResultsBradykinesia => 'Βραδύτητα κίνησης';

  @override
  String get cameraResultsTremor => 'Τρόμος';

  @override
  String get cameraResultsAsymmetry => 'Διαφορά μεταξύ χεριών';

  @override
  String cameraResultsWorseHand(Object hand) {
    return 'Το $hand κινήθηκε λιγότερο καλά.';
  }

  @override
  String get cameraResultsNotRated => 'Δεν βαθμολογήθηκε';

  @override
  String get cameraResultsNoScore =>
      'Καμία κίνηση δεν μπόρεσε να βαθμολογηθεί από αυτή την καταγραφή, οπότε δεν αποθηκεύτηκε βαθμολογία.';

  @override
  String get cameraGrade0 => 'Φυσιολογικό';

  @override
  String get cameraGrade1 => 'Ελαφρύ';

  @override
  String get cameraGrade2 => 'Ήπιο';

  @override
  String get cameraGrade3 => 'Μέτριο';

  @override
  String get cameraGrade4 => 'Σοβαρό';

  @override
  String cameraRatingValue(Object grade, Object rating) {
    return '$rating · $grade';
  }
}
