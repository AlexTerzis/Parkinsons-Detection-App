import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../l10n/app_localizations.dart';
import '../../common/widgets/widgets.dart';
import 'tap_test_viewmodel.dart';

class TapTestView extends StackedView<TapTestViewModel> {
  const TapTestView({super.key});

  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;

  @override
  Widget builder(BuildContext context, TapTestViewModel model, Widget? child) {
    final l10n = AppLocalizations.of(context)!;
    final complete = model.rightMetrics != null && model.leftMetrics != null;

    return AppScaffold(
      title: l10n.tapTest,
      scrollable: !model.isTesting,
      bottomAction: model.isTesting
          ? SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: model.stopTest,
                icon: const Icon(Icons.stop),
                label: Text(l10n.stop),
              ),
            )
          : PrimaryAction(
              label: complete
                  ? _t(context, 'Next', 'Επόμενο')
                  : _t(context, 'Begin test', 'Έναρξη τεστ'),
              icon: complete ? Icons.arrow_forward : Icons.play_arrow,
              busy: model.isSavingResult,
              onPressed: complete
                  ? () => model.continueToCompletion()
                  : () => model.startTest(l10n),
            ),
      body: model.isTesting
          ? _TestingBody(model: model, l10n: l10n)
          : complete
              ? _ResultsBody(model: model)
              : _IntroductionBody(l10n: l10n),
    );
  }

  @override
  TapTestViewModel viewModelBuilder(BuildContext context) => TapTestViewModel();

  @override
  void onViewModelReady(TapTestViewModel viewModel) {
    viewModel.loadModel();
    super.onViewModelReady(viewModel);
  }
}

class _IntroductionBody extends StatelessWidget {
  const _IntroductionBody({required this.l10n});
  final AppLocalizations l10n;

  bool _greek(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'el';
  String _t(BuildContext context, String en, String el) =>
      _greek(context) ? el : en;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 48, color: Theme.of(context).colorScheme.primary),
                const AppGap.md(),
                Text(_t(context, 'How the tap test works',
                        'Πώς λειτουργεί το τεστ πατήματος'),
                    style: Theme.of(context).textTheme.headlineSmall),
                const AppGap.sm(),
                Text(_t(
                  context,
                  'You will tap a large button as quickly and regularly as you comfortably can. The right hand is recorded for 10 seconds, followed by a 5-second pause, then the left hand for 10 seconds.',
                  'Θα πατάτε ένα μεγάλο κουμπί όσο πιο γρήγορα και σταθερά μπορείτε με άνεση. Καταγράφεται το δεξί χέρι για 10 δευτερόλεπτα, ακολουθεί παύση 5 δευτερολέπτων και μετά το αριστερό χέρι για 10 δευτερόλεπτα.',
                )),
              ],
            ),
          ),
          const AppGap.md(),
          _Step(number: '1', text: _t(context,
              'Place the phone on a stable surface.',
              'Τοποθετήστε το τηλέφωνο σε σταθερή επιφάνεια.')),
          _Step(number: '2', text: _t(context,
              'Use only the index finger of the requested hand.',
              'Χρησιμοποιήστε μόνο τον δείκτη του χεριού που ζητείται.')),
          _Step(number: '3', text: _t(context,
              'Tap naturally. Accuracy matters more than forcing maximum speed.',
              'Πατήστε φυσικά. Η σωστή εκτέλεση είναι σημαντικότερη από την υπερβολική ταχύτητα.')),
          const AppGap.md(),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_outlined,
                    color: Theme.of(context).colorScheme.primary),
                const AppGap.wide(AppSpacing.sm),
                Expanded(child: Text(_t(
                  context,
                  'Tap count, speed, and timing consistency are direct measurements. The current pattern classification is preliminary until the final clinical dataset is available.',
                  'Ο αριθμός, η ταχύτητα και η σταθερότητα των πατημάτων είναι άμεσες μετρήσεις. Η τρέχουσα ταξινόμηση προτύπου είναι προκαταρκτική μέχρι να είναι διαθέσιμο το τελικό κλινικό σύνολο δεδομένων.',
                ))),
              ],
            ),
          ),
        ],
      );
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(children: [
          CircleAvatar(radius: 18, child: Text(number)),
          const AppGap.wide(AppSpacing.sm),
          Expanded(child: Text(text)),
        ]),
      );
}

class _TestingBody extends StatelessWidget {
  const _TestingBody({required this.model, required this.l10n});
  final TapTestViewModel model;
  final AppLocalizations l10n;

  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;

  @override
  Widget build(BuildContext context) {
    final switching = model.status == TapTestStatus.switchHands;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(model.statusText(l10n), textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall),
        const AppGap.lg(),
        CountdownProgress(
          label: l10n.timeLeft(model.secondsLeft),
          progress: model.progress,
        ),
        const AppGap.xl(),
        if (switching)
          AppCard(
            child: Column(children: [
              Icon(Icons.swap_horiz, size: 56,
                  color: Theme.of(context).colorScheme.primary),
              const AppGap.sm(),
              Text(_t(context,
                'Get your left index finger ready. The next recording starts automatically.',
                'Ετοιμάστε τον αριστερό δείκτη. Η επόμενη καταγραφή ξεκινά αυτόματα.'),
                textAlign: TextAlign.center),
            ]),
          )
        else ...[
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _LiveMetric(label: _t(context, 'Taps', 'Πατήματα'),
                value: '${model.currentTapCount}'),
            _LiveMetric(label: _t(context, 'Taps/second', 'Πατήματα/δευτ.'),
                value: model.currentTapsPerSecond.toStringAsFixed(1)),
          ]),
          const AppGap.lg(),
          Center(
            child: Semantics(
              button: true,
              label: l10n.tap,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => model.onTapDown(),
                onTapUp: (_) => model.onTapUp(),
                onTapCancel: model.onTapUp,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 70),
                  width: model.isPadPressed ? 188 : 200,
                  height: model.isPadPressed ? 188 : 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    boxShadow: [BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: .25),
                      blurRadius: 20,
                      spreadRadius: 6,
                    )],
                  ),
                  child: Center(child: Text(l10n.tap,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary))),
                ),
              ),
            ),
          ),
          const AppGap.lg(),
          Text(_t(context, 'Live timing consistency', 'Ζωντανή σταθερότητα ρυθμού')),
          const AppGap.xs(),
          LinearProgressIndicator(value: model.currentConsistency),
        ],
      ],
    );
  }
}

class _LiveMetric extends StatelessWidget {
  const _LiveMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: Theme.of(context).textTheme.headlineSmall),
    Text(label, style: Theme.of(context).textTheme.bodySmall),
  ]);
}

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({required this.model});
  final TapTestViewModel model;
  String _t(BuildContext context, String en, String el) =>
      Localizations.localeOf(context).languageCode == 'el' ? el : en;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary),
        const AppGap.wide(AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_t(context, 'Tapping complete', 'Το τεστ πατήματος ολοκληρώθηκε'),
              style: Theme.of(context).textTheme.titleMedium),
          const AppGap.xxs(),
          Text(_t(context,
            'Review the measurements below. They will remain here until you press Next.',
            'Ελέγξτε τις παρακάτω μετρήσεις. Θα παραμείνουν εδώ μέχρι να πατήσετε Επόμενο.')),
        ])),
      ])),
      const AppGap.md(),
      _TapResultCard(title: _t(context, 'Right hand', 'Δεξί χέρι'),
          metrics: model.rightMetrics!, isGreek: Localizations.localeOf(context).languageCode == 'el'),
      const AppGap.md(),
      _TapResultCard(title: _t(context, 'Left hand', 'Αριστερό χέρι'),
          metrics: model.leftMetrics!, isGreek: Localizations.localeOf(context).languageCode == 'el'),
      const AppGap.md(),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_t(context, 'Preliminary model output', 'Προκαταρκτικό αποτέλεσμα μοντέλου'),
            style: Theme.of(context).textTheme.titleMedium),
        const AppGap.sm(),
        Text(model.resultHand1),
        if (model.resultHand2.isNotEmpty) Text(model.resultHand2),
        const AppGap.sm(),
        Text(_t(context,
          'This classification currently uses provisional model data and must not be treated as a diagnosis.',
          'Αυτή η ταξινόμηση χρησιμοποιεί προσωρινά δεδομένα μοντέλου και δεν πρέπει να θεωρείται διάγνωση.'),
          style: Theme.of(context).textTheme.bodySmall),
      ])),
    ],
  );
}

class _TapResultCard extends StatelessWidget {
  const _TapResultCard({required this.title, required this.metrics, required this.isGreek});
  final String title;
  final TapHandMetrics metrics;
  final bool isGreek;
  @override
  Widget build(BuildContext context) => AppCard(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const AppGap.sm(),
      Wrap(spacing: AppSpacing.xl, runSpacing: AppSpacing.md, children: [
        _ResultMetric(label: isGreek ? 'Πατήματα' : 'Taps', value: '${metrics.tapCount}'),
        _ResultMetric(label: isGreek ? 'Ανά δευτερόλεπτο' : 'Per second',
            value: metrics.tapsPerSecond.toStringAsFixed(1)),
        _ResultMetric(label: isGreek ? 'Μέσο διάστημα' : 'Average interval',
            value: '${(metrics.averageInterval * 1000).round()} ms'),
        _ResultMetric(label: isGreek ? 'Σταθερότητα' : 'Consistency',
            value: '${(metrics.consistency * 100).round()}%'),
      ]),
    ],
  ));
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(value, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}
