/// Lower and upper edge of the Parkinsonian tremor band, in Hz.
///
/// Rest and postural tremor sit at 4-6 Hz. Outside 3.5-7.5 Hz a spectral peak
/// is far more likely to be voluntary movement or sensor noise.
const double tremorBandLowHz = 3.5;
const double tremorBandHighHz = 7.5;

/// Width of the taper either side of the band, in Hz. A peak just outside the
/// band is discounted rather than discarded, so the score does not jump at the
/// edge.
const double tremorBandTaperHz = 2.5;

/// How much a peak at [hz] counts: 1 inside the tremor band, tapering linearly
/// to 0 across [tremorBandTaperHz] either side.
double tremorBandWeight(double hz) {
  if (hz >= tremorBandLowHz && hz <= tremorBandHighHz) return 1;
  final distance =
      hz < tremorBandLowHz ? tremorBandLowHz - hz : hz - tremorBandHighHz;
  return (1 - distance / tremorBandTaperHz).clamp(0, 1).toDouble();
}

/// Severity for one hand: how far the dominant spectral peak stands above the
/// rest of the band ([prominence], 0-1), weighted by whether that peak sits at
/// a tremor frequency.
///
/// The score used to be `dominantFrequencyHz / 20`, which rose with frequency
/// rather than with tremor: random noise peaking at 12 Hz scored 0.6 while a
/// textbook 5 Hz tremor scored 0.25, and a perfectly still hand whose spectrum
/// happened to peak high scored worse than a shaking one. Prominence is what
/// separates a real tremor from a flat spectrum, so it carries the score and
/// the frequency only decides how much of it counts.
///
/// Returns 0 when no frequency could be measured.
double tremorSeverityScore({
  required double prominence,
  required double dominantFrequencyHz,
}) {
  if (dominantFrequencyHz <= 0) return 0;
  return (prominence * tremorBandWeight(dominantFrequencyHz))
      .clamp(0, 1)
      .toDouble();
}
