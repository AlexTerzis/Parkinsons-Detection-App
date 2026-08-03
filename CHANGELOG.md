# Changelog

## 2.0.0 — 2026-08-01

Everything below is the difference between this release and the previous
version on GitHub (`main` at `04b755b`, "Fiedx the option to change language
GR-En"). It is a large release: the camera test was rebuilt around a clinical
protocol, the scoring behind it was rewritten, the whole app was given a real
theme and component layer, and a set of crash and data-loss bugs were fixed.

The app is a screening aid. Nothing here is diagnostic, and the scoring ranges
described below are provisional and not yet calibrated against labelled data.

---

### 1. Stability and data-loss fixes

These came first because several of them made the app unusable.

**Crashes**

- `PatienceView` declared 6 tabs but supplied 5 `TabBarView` children, throwing
  whenever the Community tab was opened. The orphan tab was removed.
- `TapTestViewModel.stopTest()` cast a `String` to `TapTestStatus` and threw on
  every Stop press. It now has a proper `stopped` enum value, and the button is
  enabled only while a test is running.
- `CameraTestViewModel` never cancelled its countdown timer and force-unwrapped
  `currentUser`, so backing out early called `notifyListeners()` on a disposed
  model. It now has `dispose()`, a post-await disposed guard, and a null-safe
  uid.
- `FFTChartCombined._getPeak` indexed `data[2]` unconditionally and threw a
  `RangeError` when too few samples had been collected. It now guards and shows
  an "insufficient data" fallback.

**Results that were silently thrown away**

- Neuro (MoCA) and FAB results were computed and then discarded — neither view
  model called `TestService`, and `addResult()` threw `UnimplementedError` for
  both types. Both now persist, and the user is navigated away on completion.
- `TestResult._typeFromString` did not recognise `'neuro'` or `'fab'`, so a
  saved result round-tripped back as `cameraDetection`.
- The verbal-fluency step re-ran its scoring every second after the timer
  expired, silently inflating the total. It is now idempotent.

**The home screen that hung after login**

`PatienceViewModel.init()` called `setBusy(true)` and then awaited
`ReportsService.fetchAllDoctors()` with no error handling. That is a collection
query over `users`, which the Firestore rules cannot satisfy for a non-doctor
account (they require `request.auth.uid == userId`, which a list query can
never satisfy), so it threw `PERMISSION_DENIED` and `setBusy(false)` was never
reached — the home screen spun forever right after a successful sign-in.

`setBusy(false)` now runs in a `finally`, and the two optional lookups (profile
fields, doctor preload) swallow their own errors so neither can take down
initialisation. The neuro and FAB completion handlers were made resilient the
same way: the result write is best-effort and navigation is unconditional, so a
rejected write no longer strands the user on the final step.

### 2. The camera test is now a guided MDS-UPDRS task sequence

Previously: a single undifferentiated 29-second capture with one instruction
("Place both hands in view"), producing one merged blob of landmarks and
leaving the patient to guess what to do.

Now: a guided sequence, one hand at a time, following the hand items of the
MDS-UPDRS Part III motor examination.

| Task | MDS-UPDRS item | Duration (full) |
| --- | --- | --- |
| Rest baseline | — | 3 s |
| Open / close | 3.5 | 10 s |
| Thumb–index tapping | 3.4 | 10 s |
| Pronation / supination | 3.6 | 10 s |

A **short mode** runs roughly half those durations for patients who cannot
sustain the full protocol.

- Each task shows its own instruction, a countdown, per-task and overall
  progress, and advances automatically.
- Pausing is honoured at the next task boundary rather than immediately, so no
  task is left half-recorded — and the UI says that is what it is doing.
- Frames are captured into one segment per task, filtered to the hand under
  examination; every frame carries its own `taskId` and `hand`.
- Segments upload as separate files keyed by task id instead of one blob.
- FPS is derived from the frame timestamps rather than assumed, because the
  variance metrics treat consecutive frames as evenly spaced and a reviewer
  needs to see when they were not.

Backwards compatibility was deliberate: the `ParkinsonConfig` weights and the
weighted formula are byte-identical, and every key the result document used to
carry is still written. The aggregate is now computed over the movement tasks
only (rest frames would drag every variance metric toward zero); rest is
reported separately as `rest_tremor_left` / `rest_tremor_right`. New keys
(`protocol_version`, `mode`, `tasks`, `mean_fps`) are additive, so existing
readers and stored documents are unaffected.

### 3. Tremor measured as a residual instead of raw movement

`HandMetrics.tremorAll` measures the standard deviation of raw landmark
position. During an open/close task most of that position change *is the
movement the patient was asked to make*, so a healthy person moving vigorously
scored as severe tremor. The metric cannot tell shaking from doing the task.

`TremorAnalysisService` estimates the voluntary component with a low-pass
filter and takes tremor to be what is left:

```
residual(t) = raw(t) - smoothed(t)
```

Voluntary movement stays below roughly 2–3 Hz even when performed as fast as
possible, while parkinsonian rest tremor runs 4–6 Hz, so the two separate in
frequency. From the residual it reports RMS, a robust peak-to-peak amplitude,
and consistency (one minus the coefficient of variation of per-window RMS),
which is what distinguishes a sustained tremor from a single flinch.

Implementation notes that matter:

- A 4th-order Butterworth applied **forward and backward**, not the moving
  average tried first — at a window that preserves 5 Hz tremor, a moving
  average still leaks about a quarter of a 2 Hz voluntary movement into the
  residual, enough for vigorous open/close to outscore real tremor. Running the
  filter in both directions cancels the phase shift, which matters because lag
  in the smoothed estimate would appear in the subtraction as oscillation that
  is not there.
- The signal is extended by odd reflection at the edges, so a steady drift does
  not produce an edge transient the metrics would read as tremor.
- Everything is resampled onto a uniform grid first, since both the filter and
  the FFT assume even spacing and camera frames do not arrive that way.
- Dominant frequency is reported **only above 15 fps**. Nyquist at 15 fps is
  7.5 Hz, barely above the band of interest, so faster tremor would alias into
  it and be reported as a plausible-looking but wrong number. Below that the
  field is null with a machine-readable rejection reason and a logged
  explanation.

`tremorAll` is left in place and unchanged.

### 4. A multi-feature heuristic scorer, alongside the existing one

The camera test's scoring had not caught up with the two changes above. It
averaged six positional-variance metrics across both hands with fixed
`ParkinsonConfig` weights — ignoring the task structure entirely (it could not
tell tapping from rotation) and ignoring the tremor work. The signs MDS-UPDRS
items 3.4–3.6 actually look for — decrementing amplitude and speed, irregular
rhythm, hesitations, delayed initiation — were not measured at all.

`HeuristicScorer` measures them. `MovementCycleAnalyzer` reduces each task to
the 1-D signal that captures its movement:

| Task | Signal |
| --- | --- |
| Thumb–index tapping | thumb-to-index distance |
| Open / close | wrist-to-fingertip aperture |
| Pronation / supination | knuckle offset |

Each is divided by palm size so distance from the camera cancels out, and
cycles are detected by midline crossings with hysteresis — chosen over
peak-picking, which starts inventing and dropping peaks exactly when the
movement is most abnormal.

Ten features are normalised to 0–1 and weighted, with every range and its
reasoning recorded in `EnhancedScoringConfig`. The output carries a likelihood,
a confidence computed from actual data quality, and a per-feature breakdown of
raw, normalised and weighted values. Features that cannot be measured say so
and their weight is redistributed, so a partial recording is not silently
scored as healthy on the half that is missing.

Two defects were found by probing the synthetic fixtures and fixed:

- **Log dimensionless jerk was measuring rate, not smoothness.** For a
  sustained rhythmic task it grows as `(T·f)^4`, so it was collinear with tap
  rate and inverted — a fast healthy tapper scored *less* smooth than a slow
  impaired one. It is now normalised per cycle, which cancels the rate
  dependence.
- **Tremor was contaminated by fast tapping.** Tapping at 5 taps/second sits in
  the 4–6 Hz parkinsonian band, so a healthy fast tapper outscored a patient
  with a real tremor. Tremor is now read from the rest tasks only, matching the
  clinical reading. Pure action tremor is consequently not captured.

Nothing about the existing path changes. `ParkinsonConfig` is untouched,
`_analyzeFrames` still produces every legacy key, and `useEnhancedScoring`
defaults to `false`, so the legacy likelihood still populates
`TestResult.score`. Both scorers run on every recording behind a shared
`CameraScorer` interface and both verdicts are stored under a new `scoring`
key — which is what will make the provisional ranges calibratable. A trained
model can later implement the same interface with no other change.

`camera_task_protocol.dart` moved to `lib/models/` so the scoring services do
not import from `lib/ui/`. Pure Dart, no behaviour change.

### 5. Guest access

Firebase anonymous sign-in behind a "Continue as guest" button, so the app can
be evaluated without creating an account. Guests get a real auth uid, so the
existing security rules and every `users/{uid}/...` path keep working
untouched — the distinction only governs what the UI offers.

- Guests can take every test and see their own results, but not the doctor
  features, which assume a relationship they do not have. The gating hangs off
  a single `isGuest` getter and covers four places: the Doctor tab is dropped
  from the tab bar (it is last, so no other tab index shifts), the reports
  subscription and the doctor preload are skipped during initialisation, and —
  easy to miss — the second "Send results to doctor" button at the bottom of
  the Tests tab, an independent entry point into the same flow.
- **Upgrading keeps the data.** It uses `linkWithCredential` rather than
  sign-up, so the uid survives and every result recorded as a guest stays
  attached. `signUp`'s profile write had to become a merge: as a whole-document
  `set()` it would have wiped date of birth, medication and the chosen doctor
  on upgrade. The email is taken from the form rather than `user.email`, which
  is still null immediately after linking.
- Results carry an `isGuest` flag, applied inside `TestService` where both
  write paths funnel through one serializer, rather than at the ten call sites
  that could forget it. It is stored top-level, not in the free-form `data` map
  that each test replaces wholesale.
- Signing out as a guest now asks first — an anonymous account cannot be signed
  back into, so it is the one sign-out that permanently destroys data.

Two supporting fixes: guests would have hit a crash saving their profile,
because that path used `update()`, which throws when the document does not
exist. It is now a merge, and the guest document is created up front at sign-in.

> **Deployment note:** anonymous sign-in must be enabled in the Firebase
> console. Guests are still able to create report documents at the rules level;
> the gating here is UI-only, as agreed.

### 6. Accessibility: an app-wide, persisted text size

The app had no accessibility text handling at all — no `textScaler`, no
`Semantics`, and `MediaQuery` was only ever read for `.size`. For an audience
of older adults with reduced vision that is a real gap, and the platform font
size setting alone does not help much, because several screens were built
around fixed heights.

`TextScaleService` mirrors `LocalizationService`: a `ChangeNotifier` read from
the locator, initialised before `runApp` so the first frame is already correct,
and persisted through `shared_preferences`.

- **Four discrete sizes, not a slider.** A slider needs a sustained, precise
  drag — the worst possible control for someone with hand tremor. Four chips
  are one tap each, and a mis-tap lands on a neighbouring size. The range stops
  at 1.5, because past that the remaining fixed-height constructs break rather
  than reflow, and never goes below 1.0.
- The `MediaQuery` override sits in `MaterialApp.builder`, not above
  `MaterialApp`. `MediaQuery.of` depends on the entire `MediaQueryData`, so an
  override higher up would rebuild the whole `Navigator` every time the
  keyboard animates — which happens constantly here.
- Tab labels get their own tighter clamp: Flutter sizes a tab with both icon
  and text from a compile-time constant that ignores the text scaler, and both
  tab bars run with `toolbarHeight: 0`, so the tab bar *is* the app bar and an
  overflow there is unmissable. The doctor tab bar is now scrollable too, since
  the longer Greek labels would otherwise overflow sideways.
- On first run only, the service adopts the OS font scale, so someone who has
  already asked their device for larger type does not have it taken away — the
  override replaces the platform scaler rather than composing with it.
- The control lives in a shared `AppPreferencesSection` used by both profile
  tabs, which also gives doctors a language picker for the first time; the
  patient tab had one and the doctor tab never did.
- The three fixed-height charts clamp their own scaling, since `fl_chart`
  reserves fixed axis space and its labels would collide.

### 7. A Material 3 design system

The whole app theme was six lines: a seed colour and `useMaterial3`. Nothing
else was themed, so 38 of 65 UI files styled themselves with raw literals —
~176 colour literals across 38 distinct values, 139 inline `TextStyle`s across
22 font sizes, and 14 different corner radii. Only 12 files consulted
`Theme.of(context)` at all.

Three new foundation files:

- `app_tokens.dart` — the clinical teal palette, a 4-point spacing scale, four
  radii, and the minimum tap target. It also isolates the colours that are not
  styling at all: the drawing canvas is a *model input* (the classifier is
  trained on black ink on white paper), the camera overlay must stay legible
  over a live preview, and the splash colour is pinned to `pubspec`.
- `app_semantic_colors.dart` — a `ThemeExtension` for success/warning, which
  Material 3's `ColorScheme` has no slot for. Resolved through a null-safe
  `of()` so it cannot throw under a foreign `ThemeData`.
- `app_theme.dart` — the `ColorScheme`, a `TextTheme` mapping the 22 ad-hoc
  sizes onto Material roles, and component themes.

The `ColorScheme` is built explicitly rather than from a seed: `fromSeed` runs
tonal derivation that does not preserve the chosen hexes, and seeding then
`copyWith`-ing is worse, because containers and `surfaceTint` stay derived at a
different chroma — cards end up a different teal than buttons.

Two palette values moved for contrast: `#BFD0CD` is 1.6:1 on white, well under
the 3:1 floor for input borders, so it now only draws decorative hairlines and
a darker outline carries interactive borders; the secondary teal is 3.3:1, so
`onSecondary` is dark rather than white.

Button, icon-button, list-tile and input themes carry a 50 px minimum target,
which lifts roughly 160 of the app's ~190 interactive elements without touching
them individually. Selection controls stay capped at 48 — the framework does
not allow more.

Also removed: a second `MaterialApp` seeded `deepPurple` sitting dead inside
`hand_landmarker_screen.dart`, which would have silently overridden the theme
for anything below it, plus three unused Stacked template files.

### 8. A shared component layer, adopted across every screen

The theme alone does not stop the next screen being built from literals, so the
recurring patterns are now widgets in `lib/ui/common/widgets/`, exported
through one barrel (`widgets.dart`) — views carry one design-system import
rather than eight. Everything there resolves colour and type from
`Theme.of(context)` and spacing from `AppSpacing`; nothing holds state or talks
to a service.

- `app_scaffold.dart`, `app_section.dart`, `app_card.dart`,
  `app_list_tile_card.dart` — page, section and card structure.
- `app_metric.dart`, `app_state_views.dart`, `app_feedback.dart` — score
  displays, empty/error/loading states, and feedback. Correctness is marked
  with an icon, never colour alone.
- `test_step_scaffold.dart` — the shared chrome every neuro/FAB test step was
  reimplementing.
- `speech_text_field.dart` — the dictation-backed input used by the
  speech-driven steps, with the mic disabled while already listening.
- `digit_span_step.dart` — the forward and backward digit-span steps were
  near-duplicates and are now one parameterised step.
- `test_catalogue.dart`, `score_charts.dart`, `doctor_picker_sheet.dart` — the
  tests tab, results charts and doctor selection, extracted from the tabs that
  had grown to hold them inline.

Every view, test step and tab was migrated onto these. Eight lint rules were
added in `analysis_options.yaml` to stop the design system being bypassed by
accident; each targets a habit the pre-refactor code had actually accumulated.

### 9. Localization

App chrome was migrated to `AppLocalizations` — tab bars, doctor dashboard,
login errors and validator messages, tremor test, tap test result strings,
signature canvas, and the insights tab — with ~135 new lines of strings in each
of `app_en.arb` and `app_el.arb`.

### 10. Tests

The suite grew from a handful of metric tests to 107, covering the new
scoring stack against synthetic recordings and the component layer against text
scaling:

- `test/services/scoring/` — `heuristic_scorer_test.dart`,
  `movement_cycle_analyzer_test.dart`, `camera_scoring_service_test.dart`, and
  `synthetic_recording.dart`, which generates healthy and impaired recordings
  with known properties.
- `test/services/tremor_analysis_service_test.dart`,
  `test/services/camera_task_protocol_test.dart`.
- `test/ui/widgets/` — component library behaviour and text-scale regression
  tests.

**Known failure:** `test/services/hand_metrics_test.dart` → "tremor detects
oscillation" expects `tremorAll > 0.2` and gets `0.1666…`. This test and the
code under it predate this release and were not touched by it; the metric it
asserts on is the raw-position tremor that section 3 supersedes. It is left
failing rather than silently adjusted.

---

### Upgrade notes

1. Enable **anonymous sign-in** in the Firebase console, or "Continue as guest"
   will fail.
2. The Firestore rules allow-list does not include the `FAB` subcollection, so
   FAB scores still will not persist until that list is updated. The app no
   longer breaks when the write is denied.
3. Run `flutter gen-l10n` after pulling (or let the build do it) — the
   generated `app_localizations*.dart` files are regenerated from the `.arb`
   sources.

## 1.0.0

The state of `main` before this release: the five tests (tremor, tap, voice,
drawing, camera), the MoCA-style neuro battery and the FAB battery, Firebase
auth and storage, and the Greek/English language switch.
