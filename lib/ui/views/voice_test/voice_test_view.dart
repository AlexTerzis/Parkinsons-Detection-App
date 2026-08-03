import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stacked/stacked.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/test_type.dart';
import '../../common/app_tokens.dart';
import '../../common/widgets/widgets.dart';
import '../test_complete/test_complete_view.dart';
import 'voice_test_viewmodel.dart';

class VoiceTestView extends StackedView<VoiceTestViewModel> {
  const VoiceTestView({super.key});

  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;

  @override
  Widget builder(BuildContext context, VoiceTestViewModel model, Widget? child) {
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
            body: _t(context,
                'Allow microphone access in Settings, then return and try again.',
                'Επιτρέψτε την πρόσβαση στο μικρόφωνο στις Ρυθμίσεις και δοκιμάστε ξανά.'),
            secondaryLabel: _t(context, 'Try microphone again',
                'Δοκιμή μικροφώνου ξανά'),
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
                ? _t(context,
                    'Analysis is complete. Please wait while the result and recording are saved.',
                    'Η ανάλυση ολοκληρώθηκε. Περιμένετε όσο αποθηκεύονται το αποτέλεσμα και η εγγραφή.')
                : _t(context,
                    'Keep this screen open. This can take a few moments.',
                    'Κρατήστε αυτή την οθόνη ανοιχτή. Η διαδικασία μπορεί να διαρκέσει λίγο.'),
          ),
        VoiceStatus.result => _ResultBody(model: model),
        VoiceStatus.recordingFailed => _MessageBody(
            icon: Icons.error_outline,
            title: _t(context, 'Recording failed', 'Η εγγραφή απέτυχε'),
            body: _t(context, 'No usable audio file was created. Please try again.',
                'Δεν δημιουργήθηκε χρησιμοποιήσιμο αρχείο ήχου. Δοκιμάστε ξανά.'),
          ),
        VoiceStatus.processingFailed => _MessageBody(
            icon: Icons.cloud_off_outlined,
            title: _t(context, 'Analysis could not be completed',
                'Η ανάλυση δεν ολοκληρώθηκε'),
            body: _t(context,
                'Check your internet connection and retry. Your recording is still available.',
                'Ελέγξτε τη σύνδεση στο διαδίκτυο και δοκιμάστε ξανά. Η εγγραφή παραμένει διαθέσιμη.'),
          ),
      },
    );
  }

  Widget? _bottomAction(BuildContext context, VoiceTestViewModel model,
      AppLocalizations l10n) {
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
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => TestCompleteView(
                type: TestType.voice,
                concern: model.resultScore.clamp(0, 1).toDouble(),
                saved: model.resultSaved,
              ),
            ),
          ),
        ),
      VoiceStatus.countdown || VoiceStatus.processing => null,
    };
  }

  @override
  VoiceTestViewModel viewModelBuilder(BuildContext context) => VoiceTestViewModel();
}

class _IntroductionBody extends StatelessWidget {
  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.graphic_eq, size: 48,
            color: Theme.of(context).colorScheme.primary),
        const AppGap.md(),
        Text(_t(context, 'Sustain one natural vowel',
            'Κρατήστε ένα φυσικό φωνήεν'),
            style: Theme.of(context).textTheme.headlineSmall),
        const AppGap.sm(),
        Text(_t(context,
          'After a 3-second countdown, take a comfortable breath and sustain “Aaaa” continuously for 5 seconds.',
          'Μετά από αντίστροφη μέτρηση 3 δευτερολέπτων, πάρτε μια άνετη αναπνοή και κρατήστε συνεχόμενα το «Αααα» για 5 δευτερόλεπτα.')),
      ])),
      const AppGap.md(),
      _Instruction(icon: Icons.volume_off_outlined,
          text: _t(context, 'Choose a quiet room and silence other sounds.',
              'Επιλέξτε ήσυχο χώρο και περιορίστε άλλους ήχους.')),
      _Instruction(icon: Icons.phone_android,
          text: _t(context, 'Keep the phone about 15–20 cm from your mouth.',
              'Κρατήστε το τηλέφωνο περίπου 15–20 εκ. από το στόμα.')),
      _Instruction(icon: Icons.record_voice_over_outlined,
          text: _t(context, 'Use a comfortable pitch and volume. Do not whisper, shout, or sing.',
              'Χρησιμοποιήστε άνετο τόνο και ένταση. Μην ψιθυρίζετε, φωνάζετε ή τραγουδάτε.')),
      const AppGap.md(),
      AppCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.cloud_upload_outlined,
            color: Theme.of(context).colorScheme.primary),
        const AppGap.wide(AppSpacing.sm),
        Expanded(child: Text(_t(context,
          'After you approve the recording, it is sent to the voice prediction service and saved with your account result.',
          'Αφού εγκρίνετε την εγγραφή, αποστέλλεται στην υπηρεσία πρόβλεψης φωνής και αποθηκεύεται μαζί με το αποτέλεσμα του λογαριασμού σας.'))),
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
  Widget build(BuildContext context) => Center(child: Column(
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
      Text('“Aaaa”', textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary)),
      const AppGap.md(),
      Text(Localizations.localeOf(context).languageCode == 'el'
          ? 'Κρατήστε τον ήχο σταθερά και φυσικά'
          : 'Hold the sound steadily and naturally', textAlign: TextAlign.center),
      const AppGap.lg(),
      CountdownProgress(label: l10n.timeLeft(model.secondsLeft),
          progress: model.progress),
      const AppGap.lg(),
      SizedBox(height: 100, child: CustomPaint(
        painter: _WaveformPainter(values: List<double>.of(model.waveform),
            color: Theme.of(context).colorScheme.primary))),
      const AppGap.md(),
      Text(Localizations.localeOf(context).languageCode == 'el'
          ? 'Το μικρόφωνο ακούει τη φωνή σας'
          : 'The microphone is hearing your voice', textAlign: TextAlign.center),
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
    VoiceRecordingQuality.good => _t(context, 'Good recording quality', 'Καλή ποιότητα εγγραφής'),
    VoiceRecordingQuality.tooShort => _t(context, 'The recording was too short', 'Η εγγραφή ήταν πολύ σύντομη'),
    VoiceRecordingQuality.tooQuiet => _t(context, 'The voice was too quiet or contained too much silence', 'Η φωνή ήταν πολύ χαμηλή ή υπήρχε πολλή σιωπή'),
    VoiceRecordingQuality.clipped => _t(context, 'The voice was too loud or too close to the microphone', 'Η φωνή ήταν πολύ δυνατή ή πολύ κοντά στο μικρόφωνο'),
    VoiceRecordingQuality.unstable => _t(context, 'The volume changed too much during the recording', 'Η ένταση άλλαξε υπερβολικά κατά την εγγραφή'),
  };

  @override
  Widget build(BuildContext context) => Column(children: [
    AppCard(child: Column(children: [
      Icon(model.canUseRecording ? Icons.check_circle_outline : Icons.warning_amber,
          size: 52, color: model.canUseRecording
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error),
      const AppGap.md(),
      Text(_quality(context), textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge),
      const AppGap.sm(),
      Text(_t(context,
        'Duration: ${model.recordedDuration.toStringAsFixed(1)} seconds',
        'Διάρκεια: ${model.recordedDuration.toStringAsFixed(1)} δευτερόλεπτα')),
    ])),
    if (model.canUseRecording) ...[
      const AppGap.md(),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(onPressed: model.recordAgain,
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
  @override
  Widget build(BuildContext context) {
    final concerning = model.resultScore >= .5;
    final confidence = concerning ? model.resultScore : 1 - model.resultScore;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_t(context, 'Voice results', 'Αποτελέσματα φωνής'),
            style: Theme.of(context).textTheme.titleMedium),
        const AppGap.md(),
        Text(concerning
            ? _t(context, 'Concerning voice pattern', 'Πρότυπο φωνής που χρειάζεται προσοχή')
            : _t(context, 'Healthy voice pattern', 'Υγιές πρότυπο φωνής'),
            style: Theme.of(context).textTheme.headlineSmall),
        const AppGap.xs(),
        Text(_t(context,
          'Model confidence: ${(confidence * 100).toStringAsFixed(1)}%',
          'Βεβαιότητα μοντέλου: ${(confidence * 100).toStringAsFixed(1)}%')),
        const AppGap.sm(),
        Text(model.resultSaved
            ? _t(context, 'The recording and result were saved.', 'Η εγγραφή και το αποτέλεσμα αποθηκεύτηκαν.')
            : _t(context, 'The result could not be saved.', 'Το αποτέλεσμα δεν αποθηκεύτηκε.')),
      ])),
      const AppGap.md(),
      AppCard(child: Text(_t(context,
        'This is a screening result, not a diagnosis. Voice can also be affected by fatigue, illness, medication, and recording conditions.',
        'Αυτό είναι αποτέλεσμα προσυμπτωματικού ελέγχου και όχι διάγνωση. Η φωνή επηρεάζεται επίσης από κόπωση, ασθένεια, φάρμακα και συνθήκες εγγραφής.'))),
      const AppGap.md(),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(onPressed: model.recordAgain,
            icon: const Icon(Icons.replay),
            label: Text(_t(context, 'Record again', 'Νέα εγγραφή'))),
      ),
    ]);
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.icon, required this.title,
    required this.body, this.loading = false, this.secondaryLabel,
    this.onSecondary});
  final IconData icon;
  final String title;
  final String body;
  final bool loading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  @override
  Widget build(BuildContext context) => Center(child: AppCard(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (loading) const CircularProgressIndicator() else Icon(icon, size: 52,
          color: Theme.of(context).colorScheme.primary),
      const AppGap.md(),
      Text(title, textAlign: TextAlign.center,
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
    final paint = Paint()..color = color..strokeWidth = 3..strokeCap = StrokeCap.round;
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
