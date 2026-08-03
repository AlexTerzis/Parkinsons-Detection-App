import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../l10n/app_localizations.dart';
import '../../common/widgets/assessment_info_content.dart';
import '../../common/widgets/widgets.dart';
import 'neuro_test_viewmodel.dart';

class NeuroTestView extends StatelessWidget {
  const NeuroTestView({super.key});

  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<NeuroTestViewModel>.reactive(
      viewModelBuilder: NeuroTestViewModel.new,
      builder: (context, model, child) {
        final title = AppLocalizations.of(context)!.neuropsychologicalTest;

        if (!model.hasStarted) {
          return AppScaffold(
            title: title,
            bottomAction: PrimaryAction(
              label: _t(context, 'Begin assessment', 'Έναρξη αξιολόγησης'),
              icon: Icons.play_arrow,
              onPressed: model.startTest,
            ),
            body: AssessmentIntroContent(
              icon: Icons.memory_outlined,
              heading: _t(
                context,
                'Before you begin',
                'Πριν ξεκινήσετε',
              ),
              description: _t(
                context,
                'This assessment contains 15 guided activities. Read or listen to each instruction carefully before answering.',
                'Αυτή η αξιολόγηση περιλαμβάνει 15 καθοδηγούμενες δραστηριότητες. Διαβάστε ή ακούστε προσεκτικά κάθε οδηγία πριν απαντήσετε.',
              ),
              durationLabel: _t(context, 'Estimated time', 'Εκτιμώμενος χρόνος'),
              duration: _t(context, '15–20 minutes', '15–20 λεπτά'),
              measuresTitle:
                  _t(context, 'What it includes', 'Τι περιλαμβάνει'),
              measures: [
                _t(context, 'Memory and recall', 'Μνήμη και ανάκληση'),
                _t(context, 'Attention and calculation',
                    'Προσοχή και υπολογισμός'),
                _t(context, 'Language and verbal fluency',
                    'Γλώσσα και λεκτική ευχέρεια'),
                _t(context, 'Orientation and visual-spatial skills',
                    'Προσανατολισμός και οπτικοχωρικές δεξιότητες'),
                _t(context, 'Planning and abstract reasoning',
                    'Σχεδιασμός και αφηρημένη σκέψη'),
              ],
              beforeTitle: _t(
                context,
                'Prepare for the assessment',
                'Προετοιμασία για την αξιολόγηση',
              ),
              beforeItems: [
                _t(context, 'Choose a quiet place without interruptions.',
                    'Επιλέξτε έναν ήσυχο χώρο χωρίς διακοπές.'),
                _t(context, 'Use glasses or hearing aids if you normally need them.',
                    'Χρησιμοποιήστε γυαλιά ή ακουστικά βαρηκοΐας, αν τα χρειάζεστε συνήθως.'),
                _t(context, 'Answer without notes, searching, or help from another person.',
                    'Απαντήστε χωρίς σημειώσεις, αναζήτηση ή βοήθεια από άλλο άτομο.'),
                _t(context, 'Allow microphone and location access when requested.',
                    'Επιτρέψτε την πρόσβαση στο μικρόφωνο και την τοποθεσία όταν ζητηθεί.'),
              ],
              note: _t(
                context,
                'Some activities are timed, so follow the on-screen instructions. This is a screening assessment, not a diagnosis. Your score will be shown at the end and, when you are signed in, saved to your test history.',
                'Ορισμένες δραστηριότητες έχουν χρονικό όριο, επομένως ακολουθήστε τις οδηγίες στην οθόνη. Αυτή είναι μια αξιολόγηση προσυμπτωματικού ελέγχου και όχι διάγνωση. Η βαθμολογία σας θα εμφανιστεί στο τέλος και, όταν είστε συνδεδεμένοι, θα αποθηκευτεί στο ιστορικό των τεστ σας.',
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
              scoreLabel: _t(context, 'Total neuropsychological score',
                  'Συνολική νευροψυχολογική βαθμολογία'),
              score: model.scoreDetail,
              domainsTitle: _t(context, 'Areas assessed',
                  'Τομείς που αξιολογήθηκαν'),
              domains: [
                _t(context, 'Memory and delayed recall',
                    'Μνήμη και καθυστερημένη ανάκληση'),
                _t(context, 'Attention and calculation',
                    'Προσοχή και υπολογισμός'),
                _t(context, 'Language and verbal fluency',
                    'Γλώσσα και λεκτική ευχέρεια'),
                _t(context, 'Orientation', 'Προσανατολισμός'),
                _t(context, 'Visual-spatial and executive skills',
                    'Οπτικοχωρικές και εκτελεστικές δεξιότητες'),
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
                'The score summarises performance across the completed activities. It is a screening result, not a diagnosis, and can be affected by language, education, fatigue, hearing, and vision.',
                'Η βαθμολογία συνοψίζει την επίδοση στις δραστηριότητες που ολοκληρώθηκαν. Είναι αποτέλεσμα προσυμπτωματικού ελέγχου, όχι διάγνωση, και μπορεί να επηρεαστεί από τη γλώσσα, την εκπαίδευση, την κόπωση, την ακοή και την όραση.',
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
