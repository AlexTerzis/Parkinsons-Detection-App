import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../l10n/app_localizations.dart';
import '../../common/widgets/assessment_info_content.dart';
import '../../common/widgets/widgets.dart';
import 'fab_test_viewmodel.dart';

class FABTestView extends StatelessWidget {
  const FABTestView({super.key});

  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<FABTestViewModel>.reactive(
      viewModelBuilder: FABTestViewModel.new,
      builder: (context, model, child) {
        final title = AppLocalizations.of(context)!.fabTest;

        if (!model.hasStarted) {
          return AppScaffold(
            title: title,
            bottomAction: PrimaryAction(
              label: _t(context, 'Begin assessment', 'Έναρξη αξιολόγησης'),
              icon: Icons.play_arrow,
              onPressed: model.startTest,
            ),
            body: AssessmentIntroContent(
              icon: Icons.psychology_outlined,
              heading: _t(
                context,
                'Before you begin',
                'Πριν ξεκινήσετε',
              ),
              description: _t(
                context,
                'This assessment contains 5 short activities. Each activity gives clear instructions before you answer.',
                'Αυτή η αξιολόγηση περιλαμβάνει 5 σύντομες δραστηριότητες. Κάθε δραστηριότητα παρέχει σαφείς οδηγίες πριν απαντήσετε.',
              ),
              durationLabel: _t(context, 'Estimated time', 'Εκτιμώμενος χρόνος'),
              duration: _t(context, '8–12 minutes', '8–12 λεπτά'),
              measuresTitle:
                  _t(context, 'What it includes', 'Τι περιλαμβάνει'),
              measures: [
                _t(context, 'Attention and response control',
                    'Προσοχή και έλεγχος απόκρισης'),
                _t(context, 'Following and switching rules',
                    'Τήρηση και εναλλαγή κανόνων'),
                _t(context, 'Verbal fluency and abstract reasoning',
                    'Λεκτική ευχέρεια και αφηρημένη σκέψη'),
                _t(context, 'Gestures and motor planning',
                    'Χειρονομίες και κινητικός σχεδιασμός'),
              ],
              beforeTitle: _t(
                context,
                'Prepare for the assessment',
                'Προετοιμασία για την αξιολόγηση',
              ),
              beforeItems: [
                _t(context, 'Choose a quiet, well-lit place.',
                    'Επιλέξτε έναν ήσυχο χώρο με καλό φωτισμό.'),
                _t(context, 'Answer naturally without help from another person.',
                    'Απαντήστε φυσικά, χωρίς βοήθεια από άλλο άτομο.'),
                _t(context, 'Allow microphone and camera access when requested.',
                    'Επιτρέψτε την πρόσβαση στο μικρόφωνο και την κάμερα όταν ζητηθεί.'),
                _t(context, 'Complete the activities in one sitting if possible.',
                    'Ολοκληρώστε τις δραστηριότητες χωρίς διακοπή, αν είναι δυνατόν.'),
              ],
              note: _t(
                context,
                'This is a screening assessment, not a diagnosis. Your total score will be shown at the end and, when you are signed in, saved to your test history.',
                'Αυτή είναι μια αξιολόγηση προσυμπτωματικού ελέγχου και όχι διάγνωση. Η συνολική βαθμολογία θα εμφανιστεί στο τέλος και, όταν είστε συνδεδεμένοι, θα αποθηκευτεί στο ιστορικό των τεστ σας.',
              ),
            ),
          );
        }

        if (model.isFinishing) {
          return AppScaffold(
            title: title,
            showBackButton: false,
            body: AssessmentSavingContent(
              title: _t(context, 'Saving your result…',
                  'Αποθήκευση του αποτελέσματός σας…'),
              description: _t(
                context,
                'The assessment is complete. Keep this screen open for a moment.',
                'Η αξιολόγηση ολοκληρώθηκε. Κρατήστε αυτή την οθόνη ανοιχτή για λίγο.',
              ),
            ),
          );
        }

        if (model.showResults) {
          return AppScaffold(
            title: title,
            showBackButton: false,
            bottomAction: PrimaryAction(
              label: _t(context, 'Next', 'Επόμενο'),
              icon: Icons.arrow_forward,
              onPressed: () => model.continueToCompletion(),
            ),
            body: AssessmentResultContent(
              heading: _t(context, 'Assessment complete',
                  'Η αξιολόγηση ολοκληρώθηκε'),
              description: _t(
                context,
                'Review your result below. It will remain on screen until you press Next.',
                'Δείτε το αποτέλεσμά σας παρακάτω. Θα παραμείνει στην οθόνη μέχρι να πατήσετε Επόμενο.',
              ),
              scoreLabel: _t(context, 'Total FAB score',
                  'Συνολική βαθμολογία FAB'),
              score: model.scoreDetail,
              domainsTitle: _t(context, 'Activities completed',
                  'Δραστηριότητες που ολοκληρώθηκαν'),
              domains: [
                _t(context, 'Go / No-Go', 'Go / No-Go'),
                _t(context, 'Conflicting instructions',
                    'Αντικρουόμενες οδηγίες'),
                _t(context, 'Verbal fluency', 'Λεκτική ευχέρεια'),
                _t(context, 'Similarities', 'Ομοιότητες'),
                _t(context, 'Gestures', 'Χειρονομίες'),
              ],
              saved: model.resultSaved,
              savedText: _t(
                context,
                'Your score was saved to your account’s test history.',
                'Η βαθμολογία σας αποθηκεύτηκε στο ιστορικό των τεστ του λογαριασμού σας.',
              ),
              notSavedText: _t(
                context,
                'Your score could not be saved. You can still review it here and continue.',
                'Η βαθμολογία σας δεν μπόρεσε να αποθηκευτεί. Μπορείτε να τη δείτε εδώ και να συνεχίσετε.',
              ),
              note: _t(
                context,
                'The score summarises performance across these activities. It is a screening result, not a diagnosis, and should be interpreted with a healthcare professional.',
                'Η βαθμολογία συνοψίζει την επίδοση σε αυτές τις δραστηριότητες. Είναι αποτέλεσμα προσυμπτωματικού ελέγχου, όχι διάγνωση, και πρέπει να ερμηνεύεται μαζί με επαγγελματία υγείας.',
              ),
            ),
          );
        }

        return TestStepProgress(
          index: model.currentStepNumber,
          count: model.stepCount,
          child: model.currentStepWidget,
        );
      },
    );
  }
}
