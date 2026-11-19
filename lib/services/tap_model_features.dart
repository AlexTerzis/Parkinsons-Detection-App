import 'dart:math';

/// The seven features the tapping model was trained on, in training order.
///
/// Mirrors `extract_features` in `Parkinsons_ML/simulate_tapping_data.py`
/// exactly, because the model only means anything when fed what it was fitted
/// on:
///
/// 1. `tap_count` — number of taps, not of intervals
/// 2. `mean_interval` — milliseconds
/// 3. `std_interval` — milliseconds, numpy's population standard deviation
///    (`ddof = 0`, so divided by the interval count rather than count - 1)
/// 4. `var_interval` — milliseconds squared, likewise population
/// 5. `frequency` — `1000 / mean_interval`, derived from the mean interval and
///    *not* from tap count over elapsed time
/// 6. `first_half` — taps whose offset is before the halfway mark
/// 7. `second_half` — the rest
///
/// The model previously received average/variance/max/min/range/stddev in
/// *seconds*, which shares nothing with the training set but its length, so
/// the prediction bore no relation to the tapping.
///
/// [tapOffsetsMs] are tap-onset offsets from the start of the hand's run, in
/// milliseconds and in the order they were tapped. As in the training script,
/// the interval list comes from the gaps *between* taps, so the wait from the
/// start of the run to the first tap is not one of them.
///
/// Returns null when no meaningful vector exists — fewer than two taps, or a
/// mean interval of zero. The training script returns seven zeros for that
/// case; declining instead is what keeps a meaningless prediction from being
/// stored as a score of 0, which the history charts would read as a flawless
/// run.
List<double>? tapModelFeatures(
  List<double> tapOffsetsMs, {
  required double testDurationMs,
}) {
  if (tapOffsetsMs.length < 2) return null;

  final intervals = <double>[
    for (var i = 1; i < tapOffsetsMs.length; i++)
      tapOffsetsMs[i] - tapOffsetsMs[i - 1],
  ];
  final mean = intervals.reduce((a, b) => a + b) / intervals.length;
  if (mean <= 0) return null;

  final variance =
      intervals.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
          intervals.length;
  final firstHalf =
      tapOffsetsMs.where((offset) => offset < testDurationMs / 2).length;

  return [
    tapOffsetsMs.length.toDouble(),
    mean,
    sqrt(variance),
    variance,
    1000 / mean,
    firstHalf.toDouble(),
    (tapOffsetsMs.length - firstHalf).toDouble(),
  ];
}
