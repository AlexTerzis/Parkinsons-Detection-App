import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../l10n/app_localizations.dart';
import '../../common/app_tokens.dart';
import '../../common/widgets/widgets.dart';
import 'fft_chart_combined.dart';
import 'tremor_test_viewmodel.dart';

/// Measures tremor from the device's accelerometer and gyroscope.
class TremorTestView extends StatelessWidget {
  const TremorTestView({super.key});

  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TremorTestViewModel>.reactive(
      viewModelBuilder: () => TremorTestViewModel(),
      builder: (context, model, child) {
        final theme = Theme.of(context);
        final l10n = AppLocalizations.of(context)!;
        final hasResults =
            model.resultHand1.isNotEmpty || model.resultHand2.isNotEmpty;
        final hasCompleteResults =
            model.firstResult != null && model.secondResult != null;
        final showIntro = !model.isTesting && !hasResults;

        return AppScaffold(
          title: l10n.tremorTest,
          bottomAction: model.isTesting
              ? null
              : PrimaryAction(
                  label: hasCompleteResults
                      ? _t(context, 'Next', 'Επόμενο')
                      : _t(context, 'Begin test', 'Έναρξη τεστ'),
                  icon: hasCompleteResults
                      ? Icons.arrow_forward
                      : Icons.play_arrow,
                  busy: model.isSavingResult,
                  onPressed: hasCompleteResults
                      ? () => model.continueToCompletion()
                      : () => model.startTest(l10n),
                ),
          body: showIntro
              ? _buildIntroduction(context, model)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      model.isTesting && model.phase != 1
                          ? _t(
                              context,
                              'Recording ${model.activeHandKey} hand',
                              'Καταγραφή ${model.activeHandKey == 'left' ? 'αριστερού' : 'δεξιού'} χεριού',
                            )
                          : model.tremorStatus,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (model.isTesting) ...[
                      const AppGap.md(),
                      CountdownProgress(
                        label: l10n.timeLeft(model.secondsLeft),
                        progress: model.progress,
                      ),
                      const AppGap.md(),
                      if (model.phase == 1)
                        _SwitchHandsCard(
                          title: _t(context, 'Switch hands', 'Αλλάξτε χέρι'),
                          body: _t(
                            context,
                            'Place the phone securely in your other hand. The next recording starts automatically.',
                            'Τοποθετήστε το τηλέφωνο με ασφάλεια στο άλλο χέρι. Η επόμενη καταγραφή ξεκινά αυτόματα.',
                          ),
                        )
                      else
                        _LiveMotionPanel(
                          motionX: model.motionX,
                          motionY: model.motionY,
                          acceleration: model.accelerationLevel,
                          accelerationValue: model.movementAcceleration,
                          instruction: _t(
                            context,
                            'Hold the phone comfortably and keep your arm relaxed. Do not try to keep the marker centred.',
                            'Κρατήστε το τηλέφωνο άνετα και το χέρι χαλαρό. Μην προσπαθείτε να κρατήσετε τον δείκτη στο κέντρο.',
                          ),
                          motionLabel: _t(context, 'Rotation', 'Περιστροφή'),
                          accelerationLabel:
                              _t(context, 'Movement acceleration', 'Επιτάχυνση κίνησης'),
                        ),
                    ],
                    if (hasCompleteResults) ...[
                      const AppGap.lg(),
                      _ResultsHeader(
                        title: _t(context, 'Measurement complete', 'Η μέτρηση ολοκληρώθηκε'),
                        body: _t(
                          context,
                          'The charts show the frequency content recorded for each hand. They are measurements, not a diagnosis.',
                          'Τα γραφήματα δείχνουν το συχνοτικό περιεχόμενο που καταγράφηκε για κάθε χέρι. Αποτελούν μετρήσεις και όχι διάγνωση.',
                        ),
                      ),
                      const AppGap.md(),
                      _ResultMetrics(
                        first: model.firstResult!,
                        second: model.secondResult!,
                        asymmetry: model.asymmetry ?? 0,
                        isGreek: Localizations.localeOf(context).languageCode == 'el',
                      ),
                    ],
                    if (!model.isTesting && model.firstResult != null) ...[
                      const AppGap.lg(),
                      Text(model.resultHand1,
                          style: theme.textTheme.bodyMedium),
                      const AppGap.sm(),
                      FFTChartCombined(
                        label: _t(
                          context,
                          '${model.firstResult!.hand == 'left' ? 'Left' : 'Right'} hand FFT spectrum',
                          'Φάσμα FFT ${model.firstResult!.hand == 'left' ? 'αριστερού' : 'δεξιού'} χεριού',
                        ),
                        spectrumX: model.spectrumX1,
                        spectrumY: model.spectrumY1,
                        spectrumZ: model.spectrumZ1,
                        binWidthHz: model.firstResult!.binWidthHz,
                      ),
                    ],
                    if (!model.isTesting && model.secondResult != null) ...[
                      const AppGap.lg(),
                      Text(model.resultHand2,
                          style: theme.textTheme.bodyMedium),
                      const AppGap.sm(),
                      FFTChartCombined(
                        label: _t(
                          context,
                          '${model.secondResult!.hand == 'left' ? 'Left' : 'Right'} hand FFT spectrum',
                          'Φάσμα FFT ${model.secondResult!.hand == 'left' ? 'αριστερού' : 'δεξιού'} χεριού',
                        ),
                        spectrumX: model.spectrumX2,
                        spectrumY: model.spectrumY2,
                        spectrumZ: model.spectrumZ2,
                        binWidthHz: model.secondResult!.binWidthHz,
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildIntroduction(
          BuildContext context, TremorTestViewModel model) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.vibration,
                    size: 44, color: Theme.of(context).colorScheme.primary),
                const AppGap.md(),
                Text(
                  _t(context, 'How the tremor test works', 'Πώς λειτουργεί το τεστ τρόμου'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const AppGap.sm(),
                Text(_t(
                  context,
                  'The phone uses its motion sensors to record small movements from each hand. The recording takes 10 seconds per hand, with a 5-second pause to switch hands.',
                  'Το τηλέφωνο χρησιμοποιεί τους αισθητήρες κίνησης για να καταγράψει μικρές κινήσεις από κάθε χέρι. Η καταγραφή διαρκεί 10 δευτερόλεπτα ανά χέρι, με παύση 5 δευτερολέπτων για αλλαγή χεριού.',
                )),
              ],
            ),
          ),
          const AppGap.md(),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t(context, 'Test options', 'Επιλογές τεστ'),
                    style: Theme.of(context).textTheme.titleMedium),
                const AppGap.sm(),
                Text(_t(context, 'Which hand will go first?',
                    'Ποιο χέρι θα εξεταστεί πρώτο;')),
                const AppGap.xs(),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: Text(_t(context, 'Left hand', 'Αριστερό χέρι')),
                      selected: model.leftFirst,
                      onSelected: (_) => model.setLeftFirst(true),
                    ),
                    ChoiceChip(
                      label: Text(_t(context, 'Right hand', 'Δεξί χέρι')),
                      selected: !model.leftFirst,
                      onSelected: (_) => model.setLeftFirst(false),
                    ),
                  ],
                ),
                const AppGap.sm(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_t(context, 'Spoken instructions', 'Φωνητικές οδηγίες')),
                  value: model.spokenCues,
                  onChanged: model.setSpokenCues,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_t(context, 'Vibration cues', 'Ειδοποιήσεις δόνησης')),
                  value: model.hapticCues,
                  onChanged: model.setHapticCues,
                ),
              ],
            ),
          ),
          const AppGap.md(),
          _InstructionRow(
            number: '1',
            text: _t(context, 'Sit comfortably and rest your forearm.',
                'Καθίστε άνετα και στηρίξτε το αντιβράχιό σας.'),
          ),
          _InstructionRow(
            number: '2',
            text: _t(context, 'Hold the phone securely but without squeezing it.',
                'Κρατήστε το τηλέφωνο με ασφάλεια, χωρίς να το σφίγγετε.'),
          ),
          _InstructionRow(
            number: '3',
            text: _t(context, 'Stay relaxed and breathe normally. Natural movement is expected.',
                'Μείνετε χαλαροί και αναπνεύστε φυσιολογικά. Η φυσική κίνηση είναι αναμενόμενη.'),
          ),
          const AppGap.md(),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary),
                const AppGap.wide(AppSpacing.sm),
                Expanded(
                  child: Text(_t(
                    context,
                    'During recording, the moving marker and acceleration bar confirm that the sensors are working. Do not try to control them.',
                    'Κατά την καταγραφή, ο κινούμενος δείκτης και η μπάρα επιτάχυνσης επιβεβαιώνουν ότι οι αισθητήρες λειτουργούν. Μην προσπαθείτε να τα ελέγξετε.',
                  )),
                ),
              ],
            ),
          ),
        ],
      );
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(radius: 18, child: Text(number)),
            const AppGap.wide(AppSpacing.sm),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _ResultMetrics extends StatelessWidget {
  const _ResultMetrics({required this.first, required this.second,
    required this.asymmetry, required this.isGreek});
  final TremorHandResult first;
  final TremorHandResult second;
  final double asymmetry;
  final bool isGreek;

  String _hand(String hand) => hand == 'left'
      ? (isGreek ? 'Αριστερό χέρι' : 'Left hand')
      : (isGreek ? 'Δεξί χέρι' : 'Right hand');
  String _quality(TremorRecordingQuality quality) => switch (quality) {
    TremorRecordingQuality.good => isGreek ? 'Καλή καταγραφή' : 'Good recording',
    TremorRecordingQuality.excessiveMovement => isGreek
        ? 'Υπερβολική εκούσια κίνηση — συνιστάται επανάληψη'
        : 'Too much voluntary movement — retry recommended',
    TremorRecordingQuality.insufficientData => isGreek
        ? 'Ανεπαρκή δεδομένα αισθητήρα — συνιστάται επανάληψη'
        : 'Insufficient sensor data — retry recommended',
  };

  @override
  Widget build(BuildContext context) => Column(children: [
    _HandMetricCard(title: _hand(first.hand), result: first,
      quality: _quality(first.quality), isGreek: isGreek),
    const AppGap.sm(),
    _HandMetricCard(title: _hand(second.hand), result: second,
      quality: _quality(second.quality), isGreek: isGreek),
    const AppGap.sm(),
    AppCard(child: Row(children: [
      const Icon(Icons.compare_arrows),
      const AppGap.wide(AppSpacing.sm),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isGreek ? 'Ασυμμετρία χεριών' : 'Hand asymmetry',
          style: Theme.of(context).textTheme.titleMedium),
        Text('${(asymmetry * 100).round()}%'),
        const AppGap.xs(),
        LinearProgressIndicator(value: asymmetry),
      ])),
    ])),
  ]);
}

class _HandMetricCard extends StatelessWidget {
  const _HandMetricCard({required this.title, required this.result,
    required this.quality, required this.isGreek});
  final String title;
  final TremorHandResult result;
  final String quality;
  final bool isGreek;

  @override
  Widget build(BuildContext context) => AppCard(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(result.retryRecommended ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          color: result.retryRecommended
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary),
        const AppGap.wide(AppSpacing.sm),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
      ]),
      const AppGap.sm(),
      Text(quality),
      const AppGap.sm(),
      Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.sm, children: [
        _MetricText(label: isGreek ? 'Κυρίαρχη συχνότητα' : 'Dominant frequency',
          value: '${result.dominantFrequencyHz.toStringAsFixed(2)} Hz'),
        _MetricText(label: isGreek ? 'Εμπιστοσύνη κορυφής' : 'Peak confidence',
          value: '${(result.confidence * 100).round()}%'),
        _MetricText(label: isGreek ? 'Ρυθμός δειγματοληψίας' : 'Sample rate',
          value: '${result.sampleRateHz.toStringAsFixed(1)} Hz'),
      ]),
    ],
  ));
}

class _MetricText extends StatelessWidget {
  const _MetricText({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class _SwitchHandsCard extends StatelessWidget {
  const _SwitchHandsCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(
          children: [
            Icon(Icons.swap_horiz,
                size: 42, color: Theme.of(context).colorScheme.primary),
            const AppGap.wide(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const AppGap.xxs(),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LiveMotionPanel extends StatelessWidget {
  const _LiveMotionPanel({
    required this.motionX,
    required this.motionY,
    required this.acceleration,
    required this.accelerationValue,
    required this.instruction,
    required this.motionLabel,
    required this.accelerationLabel,
  });
  final double motionX;
  final double motionY;
  final double acceleration;
  final double accelerationValue;
  final String instruction;
  final String motionLabel;
  final String accelerationLabel;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(instruction),
            const AppGap.md(),
            Text(motionLabel, style: Theme.of(context).textTheme.titleSmall),
            const AppGap.sm(),
            Center(
              child: Semantics(
                label: motionLabel,
                child: CustomPaint(
                  size: const Size.square(180),
                  painter: _MotionCompassPainter(
                    x: motionX,
                    y: motionY,
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                ),
              ),
            ),
            const AppGap.md(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(accelerationLabel,
                    style: Theme.of(context).textTheme.titleSmall),
                Text('${accelerationValue.toStringAsFixed(2)} m/s²'),
              ],
            ),
            const AppGap.xs(),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: acceleration,
                minHeight: 16,
              ),
            ),
          ],
        ),
      );
}

class _MotionCompassPainter extends CustomPainter {
  const _MotionCompassPainter({
    required this.x,
    required this.y,
    required this.colorScheme,
  });
  final double x;
  final double y;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height).toDouble() / 2;
    final guide = Paint()
      ..color = colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 2, guide);
    canvas.drawCircle(center, radius * .5, guide);
    canvas.drawLine(Offset(center.dx, 8), Offset(center.dx, size.height - 8), guide);
    canvas.drawLine(Offset(8, center.dy), Offset(size.width - 8, center.dy), guide);

    final marker = Offset(
      center.dx + x * radius * .72,
      center.dy + y * radius * .72,
    );
    canvas.drawLine(center, marker,
        Paint()..color = colorScheme.primary.withValues(alpha: .35)..strokeWidth = 4);
    canvas.drawCircle(marker, 14, Paint()..color = colorScheme.primary);
    canvas.drawCircle(marker, 5, Paint()..color = colorScheme.onPrimary);
  }

  @override
  bool shouldRepaint(covariant _MotionCompassPainter oldDelegate) =>
      x != oldDelegate.x || y != oldDelegate.y || colorScheme != oldDelegate.colorScheme;
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.primary),
            const AppGap.wide(AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const AppGap.xxs(),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      );
}
