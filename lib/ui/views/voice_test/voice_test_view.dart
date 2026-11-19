import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stacked/stacked.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/voice_api_service.dart';
import '../../common/widgets/widgets.dart';
import 'voice_test_viewmodel.dart';

class VoiceTestView extends StackedView<VoiceTestViewModel> {
  const VoiceTestView({super.key});

  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;

  @override
  Widget builder(
      BuildContext context, VoiceTestViewModel model, Widget? child) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.voiceTest,
      scrollable: !model.isRecording,
      bottomAction: _bottomAction(context, model, l10n),
      body: switch (model.status) {
        VoiceStatus.initial => _IntroductionBody(),
        VoiceStatus.permissionDenied => _MessageBody(
            icon: Icons.mic_off_outlined,
            title: _t(context, 'Microphone permission is needed',
                'Απαιτείται άδεια μικροφώνου'),
            body: _t(
                context,
                'Allow microphone access in Settings, then return and try again.',
                'Επιτρέψτε την πρόσβαση στο μικρόφωνο στις Ρυθμίσεις και δοκιμάστε ξανά.'),
            secondaryLabel:
                _t(context, 'Try microphone again', 'Δοκιμή μικροφώνου ξανά'),
            onSecondary: model.startTest,
          ),
        VoiceStatus.countdown => _CountdownBody(value: model.countdownValue),
        VoiceStatus.recording => _RecordingBody(model: model, l10n: l10n),
        VoiceStatus.review => _ReviewBody(model: model),
        VoiceStatus.processing => _MessageBody(
            loading: true,
            icon: Icons.analytics_outlined,
            title: model.isSavingResult
                ? _t(context, 'Saving your result…',
                    'Αποθήκευση του αποτελέσματος…')
                : _t(context, 'Analysing your recording…',
                    'Ανάλυση της εγγραφής σας…'),
            body: model.isSavingResult
                ? _t(
                    context,
                    'Analysis is complete. Saving the derived prototype metrics; the WAV will not be stored.',
                    'Η ανάλυση ολοκληρώθηκε. Αποθηκεύονται οι παράγωγες πειραματικές μετρήσεις· το WAV δεν θα αποθηκευτεί.')
                : _t(
                    context,
                    'The WAV is uploading temporarily while the server extracts acoustic features and runs the prototype model. Keep this screen open.',
                    'Το WAV μεταφορτώνεται προσωρινά ενώ ο διακομιστής εξάγει ακουστικά χαρακτηριστικά και εκτελεί το πρωτότυπο μοντέλο. Κρατήστε αυτή την οθόνη ανοιχτή.'),
          ),
        VoiceStatus.result => _ResultBody(model: model),
        VoiceStatus.recordingFailed => _MessageBody(
            icon: Icons.error_outline,
            title: _t(context, 'Recording failed', 'Η εγγραφή απέτυχε'),
            body: _t(
                context,
                'No usable audio file was created. Please try again.',
                'Δεν δημιουργήθηκε χρησιμοποιήσιμο αρχείο ήχου. Δοκιμάστε ξανά.'),
          ),
        VoiceStatus.processingFailed => _MessageBody(
            icon: Icons.cloud_off_outlined,
            title: _t(context, 'Analysis could not be completed',
                'Η ανάλυση δεν ολοκληρώθηκε'),
            body: _t(
                context,
                'Check your internet connection and retry. Your recording is still available.',
                'Ελέγξτε τη σύνδεση στο διαδίκτυο και δοκιμάστε ξανά. Η εγγραφή παραμένει διαθέσιμη.'),
          ),
      },
    );
  }

  Widget? _bottomAction(
      BuildContext context, VoiceTestViewModel model, AppLocalizations l10n) {
    return switch (model.status) {
      VoiceStatus.initial => PrimaryAction(
          label: _t(context, 'Begin voice test', 'Έναρξη τεστ φωνής'),
          icon: Icons.mic,
          onPressed: model.startTest,
        ),
      VoiceStatus.permissionDenied => PrimaryAction(
          label: _t(context, 'Open Settings', 'Άνοιγμα Ρυθμίσεων'),
          icon: Icons.settings,
          onPressed: openAppSettings,
        ),
      VoiceStatus.recording => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: model.stopRecording,
            icon: const Icon(Icons.stop),
            label: Text(l10n.stop),
          ),
        ),
      VoiceStatus.review => PrimaryAction(
          label: model.canUseRecording
              ? _t(context, 'Use this recording', 'Χρήση αυτής της εγγραφής')
              : _t(context, 'Record again', 'Νέα εγγραφή'),
          icon: model.canUseRecording ? Icons.check : Icons.replay,
          onPressed:
              model.canUseRecording ? model.useRecording : model.recordAgain,
        ),
      VoiceStatus.processingFailed => PrimaryAction(
          label: _t(context, 'Retry analysis', 'Επανάληψη ανάλυσης'),
          icon: Icons.refresh,
          onPressed: model.retryProcessing,
        ),
      VoiceStatus.recordingFailed => PrimaryAction(
          label: _t(context, 'Try again', 'Δοκιμή ξανά'),
          icon: Icons.replay,
          onPressed: model.recordAgain,
        ),
      VoiceStatus.result => PrimaryAction(
          label: _t(context, 'Next', 'Επόμενο'),
          icon: Icons.arrow_forward,
          busy: model.isSavingResult,
          onPressed: model.continueToCompletion,
        ),
      VoiceStatus.countdown || VoiceStatus.processing => null,
    };
  }

  @override
  VoiceTestViewModel viewModelBuilder(BuildContext context) =>
      VoiceTestViewModel();
}

class _IntroductionBody extends StatelessWidget {
  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Icon(Icons.graphic_eq,
                    size: 48, color: Theme.of(context).colorScheme.primary),
                const AppGap.md(),
                Text(
                    _t(context, 'Sustain one natural vowel',
                        'Κρατήστε ένα φυσικό φωνήεν'),
                    style: Theme.of(context).textTheme.headlineSmall),
                const AppGap.sm(),
                Text(_t(
                    context,
                    'After a 3-second countdown, take a comfortable breath and sustain “Aaaa” continuously for 5 seconds.',
                    'Μετά από αντίστροφη μέτρηση 3 δευτερολέπτων, πάρτε μια άνετη αναπνοή και κρατήστε συνεχόμενα το «Αααα» για 5 δευτερόλεπτα.')),
              ])),
          const AppGap.md(),
          _Instruction(
              icon: Icons.volume_off_outlined,
              text: _t(context, 'Choose a quiet room and silence other sounds.',
                  'Επιλέξτε ήσυχο χώρο και περιορίστε άλλους ήχους.')),
          _Instruction(
              icon: Icons.phone_android,
              text: _t(
                  context,
                  'Keep the phone about 15–20 cm from your mouth.',
                  'Κρατήστε το τηλέφωνο περίπου 15–20 εκ. από το στόμα.')),
          _Instruction(
              icon: Icons.record_voice_over_outlined,
              text: _t(
                  context,
                  'Use a comfortable pitch and volume. Do not whisper, shout, or sing.',
                  'Χρησιμοποιήστε άνετο τόνο και ένταση. Μην ψιθυρίζετε, φωνάζετε ή τραγουδάτε.')),
          const AppGap.md(),
          AppCard(
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.cloud_upload_outlined,
                color: Theme.of(context).colorScheme.primary),
            const AppGap.wide(AppSpacing.sm),
            Expanded(
                child: Text(_t(
                    context,
                    'After approval, the WAV is sent temporarily for server analysis. Only the derived prototype metrics are kept in Experimental voice history; the WAV is not stored.',
                    'Μετά την έγκριση, το WAV αποστέλλεται προσωρινά για ανάλυση στον διακομιστή. Μόνο οι παράγωγες πειραματικές μετρήσεις διατηρούνται στο πειραματικό ιστορικό φωνής· το WAV δεν αποθηκεύεται.'))),
          ])),
        ],
      );
}

class _Instruction extends StatelessWidget {
  const _Instruction({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const AppGap.wide(AppSpacing.sm),
          Expanded(child: Text(text)),
        ]),
      );
}

class _CountdownBody extends StatelessWidget {
  const _CountdownBody({required this.value});
  final int value;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: Theme.of(context).textTheme.displayLarge),
          const AppGap.md(),
          Text(Localizations.localeOf(context).languageCode == 'el'
              ? 'Πάρτε μια άνετη αναπνοή'
              : 'Take a comfortable breath'),
        ],
      ));
}

class _RecordingBody extends StatelessWidget {
  const _RecordingBody({required this.model, required this.l10n});
  final VoiceTestViewModel model;
  final AppLocalizations l10n;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('“Aaaa”',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          const AppGap.md(),
          Text(
              Localizations.localeOf(context).languageCode == 'el'
                  ? 'Κρατήστε τον ήχο σταθερά και φυσικά'
                  : 'Hold the sound steadily and naturally',
              textAlign: TextAlign.center),
          const AppGap.lg(),
          CountdownProgress(
              label: l10n.timeLeft(model.secondsLeft),
              progress: model.progress),
          const AppGap.lg(),
          SizedBox(
              height: 100,
              child: CustomPaint(
                  painter: _WaveformPainter(
                      values: List<double>.of(model.waveform),
                      color: Theme.of(context).colorScheme.primary))),
          const AppGap.md(),
          Text(
              Localizations.localeOf(context).languageCode == 'el'
                  ? 'Το μικρόφωνο ακούει τη φωνή σας'
                  : 'The microphone is hearing your voice',
              textAlign: TextAlign.center),
          const AppGap.xs(),
          LinearProgressIndicator(value: model.volumeLevel),
        ],
      );
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.model});
  final VoiceTestViewModel model;
  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;

  String _quality(BuildContext context) => switch (model.quality) {
        VoiceRecordingQuality.good =>
          _t(context, 'Good recording quality', 'Καλή ποιότητα εγγραφής'),
        VoiceRecordingQuality.tooShort => _t(context,
            'The recording was too short', 'Η εγγραφή ήταν πολύ σύντομη'),
        VoiceRecordingQuality.tooQuiet => _t(
            context,
            'The voice was too quiet or contained too much silence',
            'Η φωνή ήταν πολύ χαμηλή ή υπήρχε πολλή σιωπή'),
        VoiceRecordingQuality.clipped => _t(
            context,
            'The voice was too loud or too close to the microphone',
            'Η φωνή ήταν πολύ δυνατή ή πολύ κοντά στο μικρόφωνο'),
        VoiceRecordingQuality.unstable => _t(
            context,
            'The volume changed too much during the recording',
            'Η ένταση άλλαξε υπερβολικά κατά την εγγραφή'),
      };

  @override
  Widget build(BuildContext context) => Column(children: [
        AppCard(
            child: Column(children: [
          Icon(
              model.canUseRecording
                  ? Icons.check_circle_outline
                  : Icons.warning_amber,
              size: 52,
              color: model.canUseRecording
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error),
          const AppGap.md(),
          Text(_quality(context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const AppGap.sm(),
          Text(_t(
              context,
              'Duration: ${model.recordedDuration.toStringAsFixed(1)} seconds',
              'Διάρκεια: ${model.recordedDuration.toStringAsFixed(1)} δευτερόλεπτα')),
        ])),
        if (model.canUseRecording) ...[
          const AppGap.md(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
                onPressed: model.recordAgain,
                icon: const Icon(Icons.replay),
                label: Text(_t(context, 'Record again', 'Νέα εγγραφή'))),
          ),
        ],
      ]);
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.model});
  final VoiceTestViewModel model;
  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;

  String _inconclusiveReason(BuildContext context) =>
      switch (model.resultStatus) {
        'outside_reference_range' => _t(
            context,
            'The measurements were outside the range represented in the small research dataset. This can be caused by the voice, microphone, room acoustics, or recording conditions.',
            'Οι μετρήσεις ήταν εκτός του εύρους που αντιπροσωπεύεται στο μικρό ερευνητικό σύνολο δεδομένων. Αυτό μπορεί να οφείλεται στη φωνή, στο μικρόφωνο, στην ακουστική του χώρου ή στις συνθήκες εγγραφής.',
          ),
        'capture_quality_failed' => _t(
            context,
            'The server detected insufficient sustained voice, clipping, or an unsuitable recording duration.',
            'Ο διακομιστής εντόπισε ανεπαρκή συνεχή φώνηση, παραμόρφωση ή ακατάλληλη διάρκεια εγγραφής.',
          ),
        'research_model_not_validated' => _t(
            context,
            'The recording was analysed successfully, but this research model has not been independently validated on representative phone recordings. Its score is therefore disabled.',
            'Η εγγραφή αναλύθηκε επιτυχώς, αλλά αυτό το ερευνητικό μοντέλο δεν έχει επικυρωθεί ανεξάρτητα σε αντιπροσωπευτικές εγγραφές από τηλέφωνα. Για αυτόν τον λόγο η βαθμολογία του είναι απενεργοποιημένη.',
          ),
        'legacy_model' => _t(
            context,
            'The voice service is still using the previous model. Update the service before producing a new score.',
            'Η υπηρεσία φωνής χρησιμοποιεί ακόμη το προηγούμενο μοντέλο. Ενημερώστε την υπηρεσία πριν δημιουργηθεί νέα βαθμολογία.',
          ),
        _ => _t(
            context,
            'The recording could not be compared reliably with the research reference data.',
            'Η εγγραφή δεν μπόρεσε να συγκριθεί αξιόπιστα με τα ερευνητικά δεδομένα αναφοράς.',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final acoustic = model.acousticAnalysis;
    if (acoustic != null) {
      return _AcousticResultBody(
        model: model,
        analysis: acoustic,
      );
    }
    if (!model.resultConclusive) {
      final modelNotValidated =
          model.resultStatus == 'research_model_not_validated';
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.help_outline,
              size: 48, color: Theme.of(context).colorScheme.primary),
          const AppGap.md(),
          Text(
              modelNotValidated
                  ? _t(context, 'Voice model not ready for scoring',
                      'Το μοντέλο φωνής δεν είναι έτοιμο για βαθμολόγηση')
                  : _t(context, 'Analysis inconclusive', 'Μη οριστική ανάλυση'),
              style: Theme.of(context).textTheme.headlineSmall),
          const AppGap.sm(),
          Text(_inconclusiveReason(context)),
          const AppGap.md(),
          Text(
              _t(
                context,
                'No health classification or score was produced or saved.',
                'Δεν δημιουργήθηκε ούτε αποθηκεύτηκε ταξινόμηση υγείας ή βαθμολογία.',
              ),
              style: Theme.of(context).textTheme.titleSmall),
        ])),
        const AppGap.md(),
        AppCard(
            child: Text(modelNotValidated
                ? _t(
                    context,
                    'Nothing was necessarily wrong with your recording. The limitation is the current model and dataset, so repeating the test cannot make the score reliable.',
                    'Δεν υπήρχε απαραίτητα πρόβλημα με την εγγραφή σας. Ο περιορισμός αφορά το τρέχον μοντέλο και το σύνολο δεδομένων, επομένως η επανάληψη του τεστ δεν μπορεί να κάνει τη βαθμολογία αξιόπιστη.',
                  )
                : _t(
                    context,
                    'Try again in a quiet room, keep the phone 15–20 cm from your mouth, and sustain “Aaaa” at a comfortable, steady volume.',
                    'Δοκιμάστε ξανά σε ήσυχο χώρο, κρατήστε το τηλέφωνο 15–20 εκ. από το στόμα και διατηρήστε το «Αααα» σε άνετη και σταθερή ένταση.',
                  ))),
        if (!modelNotValidated) ...[
          const AppGap.md(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
                onPressed: model.recordAgain,
                icon: const Icon(Icons.replay),
                label: Text(_t(context, 'Record again', 'Νέα εγγραφή'))),
          ),
        ],
      ]);
    }

    final elevated = model.resultScore >= model.resultDecisionThreshold;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_t(context, 'Voice results', 'Αποτελέσματα φωνής'),
            style: Theme.of(context).textTheme.titleMedium),
        const AppGap.md(),
        Text(
            elevated
                ? _t(context, 'Above the research comparison threshold',
                    'Πάνω από το όριο ερευνητικής σύγκρισης')
                : _t(context, 'Below the research comparison threshold',
                    'Κάτω από το όριο ερευνητικής σύγκρισης'),
            style: Theme.of(context).textTheme.headlineSmall),
        const AppGap.xs(),
        Text(_t(
            context,
            'Research comparison score: ${(model.resultScore * 100).toStringAsFixed(1)}%',
            'Βαθμολογία ερευνητικής σύγκρισης: ${(model.resultScore * 100).toStringAsFixed(1)}%')),
        const AppGap.sm(),
        Text(model.resultSaved
            ? _t(context, 'The recording and result were saved.',
                'Η εγγραφή και το αποτέλεσμα αποθηκεύτηκαν.')
            : _t(context, 'The result could not be saved.',
                'Το αποτέλεσμα δεν αποθηκεύτηκε.')),
      ])),
      const AppGap.md(),
      AppCard(
          child: Text(_t(
              context,
              'This score compares acoustic measurements with a small research dataset. It is not a probability of Parkinson’s disease or a diagnosis. Voice is also affected by fatigue, illness, medication, microphones, and room acoustics.',
              'Αυτή η βαθμολογία συγκρίνει ακουστικές μετρήσεις με ένα μικρό ερευνητικό σύνολο δεδομένων. Δεν είναι πιθανότητα νόσου Πάρκινσον ούτε διάγνωση. Η φωνή επηρεάζεται επίσης από κόπωση, ασθένεια, φάρμακα, μικρόφωνα και την ακουστική του χώρου.'))),
      const AppGap.md(),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
            onPressed: model.recordAgain,
            icon: const Icon(Icons.replay),
            label: Text(_t(context, 'Record again', 'Νέα εγγραφή'))),
      ),
    ]);
  }
}

class _AcousticResultBody extends StatelessWidget {
  const _AcousticResultBody({required this.model, required this.analysis});

  final VoiceTestViewModel model;
  final VoiceAcousticAnalysis analysis;

  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final components = <String, double>{
      _t(context, 'Pitch', 'Τόνος'): analysis.pitchSteadiness,
      _t(context, 'Amplitude', 'Ένταση'): analysis.amplitudeSteadiness,
      _t(context, 'Clarity', 'Καθαρότητα'): analysis.tonalClarity,
      _t(context, 'Sustain', 'Διάρκεια'): analysis.sustainQuality,
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        child: Row(children: [
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: analysis.overallScore,
                  strokeWidth: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: primary,
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  '${(analysis.overallScore * 100).round()}',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text('/ 100', style: theme.textTheme.labelSmall),
              ]),
            ]),
          ),
          const AppGap.wide(AppSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _t(context, 'Acoustic stability index',
                    'Δείκτης ακουστικής σταθερότητας'),
                style: theme.textTheme.titleLarge,
              ),
              const AppGap.xs(),
              Text(_t(
                context,
                'A descriptive summary of how steady and clear this “Aaaa” recording was.',
                'Μια περιγραφική σύνοψη του πόσο σταθερή και καθαρή ήταν αυτή η εγγραφή «Αααα».',
              )),
            ]),
          ),
        ]),
      ),
      if (model.experimentalModelScore case final experimentalScore?) ...[
        const AppGap.md(),
        AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.science_outlined, color: primary),
              const AppGap.wide(AppSpacing.sm),
              Expanded(
                child: Text(
                  _t(context, 'Experimental ML demonstration',
                      'Πειραματική επίδειξη ML'),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                '${(experimentalScore * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]),
            const AppGap.sm(),
            Text(
              model.experimentalAboveThreshold
                  ? _t(context, 'Above the prototype research threshold',
                      'Πάνω από το πειραματικό ερευνητικό όριο')
                  : _t(context, 'Below the prototype research threshold',
                      'Κάτω από το πειραματικό ερευνητικό όριο'),
              style: theme.textTheme.titleSmall,
            ),
            const AppGap.sm(),
            _ExperimentalGauge(
              value: experimentalScore,
              threshold: model.resultDecisionThreshold,
            ),
            const AppGap.sm(),
            Text(_t(
              context,
              'This is the raw output of the current prototype classifier. It demonstrates how a future model result could be presented, but it is not a Parkinson’s probability or a validated health estimate.',
              'Αυτή είναι η ακατέργαστη έξοδος του τρέχοντος πρωτοτύπου ταξινομητή. Δείχνει πώς θα μπορούσε να παρουσιαστεί ένα μελλοντικό αποτέλεσμα μοντέλου, αλλά δεν αποτελεί πιθανότητα νόσου Πάρκινσον ούτε επικυρωμένη εκτίμηση υγείας.',
            )),
            const AppGap.xs(),
            Text(
              model.resultSaved
                  ? _t(
                      context,
                      'Derived metrics saved to Experimental voice history. The WAV was not stored.',
                      'Οι παράγωγες μετρήσεις αποθηκεύτηκαν στο πειραματικό ιστορικό φωνής. Το WAV δεν αποθηκεύτηκε.',
                    )
                  : _t(
                      context,
                      'The derived metrics could not be saved to history.',
                      'Οι παράγωγες μετρήσεις δεν μπόρεσαν να αποθηκευτούν στο ιστορικό.',
                    ),
              style: theme.textTheme.labelMedium,
            ),
            if (model.resultStatus == 'outside_reference_range') ...[
              const AppGap.sm(),
              Text(
                _t(
                  context,
                  'Low reliability: this recording is outside the model’s small reference range.',
                  'Χαμηλή αξιοπιστία: αυτή η εγγραφή βρίσκεται εκτός του μικρού εύρους αναφοράς του μοντέλου.',
                ),
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
          ]),
        ),
      ],
      const AppGap.md(),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(_t(context, 'Acoustic profile', 'Ακουστικό προφίλ'),
                  style: theme.textTheme.titleMedium),
            ),
            AppInfoButton(
              title: _t(context, 'How this index is calculated',
                  'Πώς υπολογίζεται αυτός ο δείκτης'),
              body: _t(
                context,
                'The index combines pitch steadiness (30%), amplitude steadiness (30%), tonal clarity (25%), and sustained voice quality (15%). The visual scale uses the small research dataset only as a reference and is not a health threshold.',
                'Ο δείκτης συνδυάζει τη σταθερότητα του τόνου (30%), τη σταθερότητα της έντασης (30%), την καθαρότητα του ήχου (25%) και την ποιότητα συνεχούς φώνησης (15%). Η οπτική κλίμακα χρησιμοποιεί το μικρό ερευνητικό σύνολο δεδομένων μόνο ως αναφορά και δεν αποτελεί όριο υγείας.',
              ),
            ),
          ]),
          const AppGap.sm(),
          SizedBox(
            height: 230,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      fillColor: primary.withValues(alpha: .24),
                      borderColor: primary,
                      entryRadius: 4,
                      dataEntries: components.values
                          .map((value) => RadarEntry(value: value))
                          .toList(),
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  radarBorderData: const BorderSide(color: Colors.transparent),
                  tickCount: 5,
                  ticksTextStyle: theme.textTheme.labelSmall,
                  tickBorderData:
                      BorderSide(color: theme.colorScheme.outlineVariant),
                  titleTextStyle: theme.textTheme.labelMedium,
                  getTitle: (index, angle) => RadarChartTitle(
                    text: components.keys.elementAt(index),
                    angle: angle,
                  ),
                ),
              ),
            ),
          ),
          const AppGap.sm(),
          for (final component in components.entries)
            _AcousticBar(label: component.key, value: component.value),
        ]),
      ),
      const AppGap.md(),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t(context, 'Voice measurements', 'Μετρήσεις φωνής'),
              style: theme.textTheme.titleMedium),
          const AppGap.sm(),
          Row(children: [
            Expanded(
                child: _AcousticMetric(
              label: _t(context, 'Mean pitch', 'Μέσος τόνος'),
              value: '${analysis.meanPitchHz.toStringAsFixed(1)} Hz',
            )),
            const AppGap.wide(AppSpacing.sm),
            Expanded(
                child: _AcousticMetric(
              label: 'Jitter',
              value: '${analysis.jitterPercent.toStringAsFixed(2)}%',
            )),
          ]),
          const AppGap.sm(),
          Row(children: [
            Expanded(
                child: _AcousticMetric(
              label: 'Shimmer',
              value: '${analysis.shimmerPercent.toStringAsFixed(2)}%',
            )),
            const AppGap.wide(AppSpacing.sm),
            Expanded(
                child: _AcousticMetric(
              label: 'HNR',
              value: '${analysis.hnrDb.toStringAsFixed(1)} dB',
            )),
          ]),
        ]),
      ),
      if (model.resultStatus == 'outside_reference_range') ...[
        const AppGap.md(),
        AppCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, color: primary),
            const AppGap.wide(AppSpacing.sm),
            Expanded(
              child: Text(_t(
                context,
                'Some measurements were outside the small research reference range. The graphs still describe this recording, but comparisons with that dataset are limited.',
                'Ορισμένες μετρήσεις ήταν εκτός του μικρού ερευνητικού εύρους αναφοράς. Τα γραφήματα εξακολουθούν να περιγράφουν αυτή την εγγραφή, αλλά η σύγκριση με το σύνολο δεδομένων είναι περιορισμένη.',
              )),
            ),
          ]),
        ),
      ],
      const AppGap.md(),
      AppCard(
        child: Text(_t(
          context,
          'This index describes acoustic steadiness and recording clarity. It is not a Parkinson’s estimate, probability, screening result, or diagnosis. Prototype history is kept separate from health summaries.',
          'Αυτός ο δείκτης περιγράφει την ακουστική σταθερότητα και την καθαρότητα της εγγραφής. Δεν αποτελεί εκτίμηση, πιθανότητα, αποτέλεσμα προσυμπτωματικού ελέγχου ή διάγνωση για τη νόσο Πάρκινσον. Το πειραματικό ιστορικό διατηρείται χωριστά από τις συνόψεις υγείας.',
        )),
      ),
      const AppGap.md(),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: model.recordAgain,
          icon: const Icon(Icons.replay),
          label: Text(_t(context, 'Record again', 'Νέα εγγραφή')),
        ),
      ),
    ]);
  }
}

class _AcousticBar extends StatelessWidget {
  const _AcousticBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(children: [
          SizedBox(
            width: 88,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(value: value, minHeight: 10),
            ),
          ),
          const AppGap.wide(AppSpacing.sm),
          SizedBox(
            width: 38,
            child: Text('${(value * 100).round()}', textAlign: TextAlign.end),
          ),
        ]),
      );
}

class _ExperimentalGauge extends StatelessWidget {
  const _ExperimentalGauge({required this.value, required this.threshold});

  final double value;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boundedValue = value.clamp(0.0, 1.0).toDouble();
    final boundedThreshold = threshold.clamp(0.0, 1.0).toDouble();
    return Column(children: [
      SizedBox(
        height: 22,
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: constraints.maxWidth * boundedValue,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            Positioned(
              left: constraints.maxWidth * boundedThreshold - 1.5,
              top: -3,
              bottom: -3,
              child: Container(
                width: 3,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ]);
        }),
      ),
      const AppGap.xs(),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('0'),
        Text(
          Localizations.localeOf(context).languageCode == 'el'
              ? 'Πειραματικό όριο ${(boundedThreshold * 100).round()}'
              : 'Prototype threshold ${(boundedThreshold * 100).round()}',
          style: theme.textTheme.labelSmall,
        ),
        const Text('100'),
      ]),
    ]);
  }
}

class _AcousticMetric extends StatelessWidget {
  const _AcousticMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const AppGap.xs(),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ]),
      );
}

class _MessageBody extends StatelessWidget {
  const _MessageBody(
      {required this.icon,
      required this.title,
      required this.body,
      this.loading = false,
      this.secondaryLabel,
      this.onSecondary});
  final IconData icon;
  final String title;
  final String body;
  final bool loading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  @override
  Widget build(BuildContext context) => Center(
          child: AppCard(
              child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const CircularProgressIndicator()
          else
            Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
          const AppGap.md(),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const AppGap.sm(),
          Text(body, textAlign: TextAlign.center),
          if (onSecondary != null) ...[
            const AppGap.md(),
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          ],
        ],
      )));
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.values, required this.color});
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (values.isEmpty) {
      canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), paint);
      return;
    }
    final spacing = size.width / values.length;
    for (var i = 0; i < values.length; i++) {
      final height = values[i] * size.height * .8;
      final x = (i + .5) * spacing;
      canvas.drawLine(Offset(x, baseline - height / 2),
          Offset(x, baseline + height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      values != oldDelegate.values || color != oldDelegate.color;
}
