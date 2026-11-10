# Parkinsons-Detection-App

**Version 2.0.0**

A Flutter app that guides a person through a battery of motor, speech and
cognitive tasks on a phone, scores them, and lets them share the results with a
doctor. It is a **screening aid, not a diagnostic tool** — every score it
produces is provisional and uncalibrated.

See [CHANGELOG.md](CHANGELOG.md) for the full account of what changed in 2.0.

## What it does

**Motor**

- **Camera test** — a guided MDS-UPDRS Part III hand sequence, one hand at a
  time: rest baseline, open/close (item 3.5), thumb–index tapping (3.4) and
  pronation/supination (3.6). A short mode halves the durations for patients
  who cannot sustain the full protocol.
- **Tremor test** — accelerometer capture with an FFT readout.
- **Tap test** — tapping rate and rhythm.
- **Drawing test** — spiral/handwriting capture scored by an on-device model.

**Speech** — voice recording scored by an on-device model.

**Cognitive** — a MoCA-style neuro battery and the Frontal Assessment Battery
(FAB), both fully localized (English / Greek).

**Roles** — patients take tests and see their own history; doctors see the
patients who have shared results with them. The app can also be used as a
**guest**, with no account, and upgraded to a real account later without losing
any results.

## Architecture

```
lib/
  models/       protocol + result models (pure Dart, no Flutter imports)
  services/     auth, storage, tests, localization, text scale
    scoring/    the camera scoring stack
  ui/
    common/     app_tokens, app_theme, app_semantic_colors
      widgets/  the shared component layer, exported via widgets.dart
    views/      one folder per screen, Stacked view + view model
  l10n/         .arb sources; the .dart files are generated
```

State management is [Stacked](https://pub.dev/packages/stacked) (view + view
model + a service locator). Firebase provides auth, Firestore and Storage. Hand
tracking is a Kotlin PlatformView running CameraX and MediaPipe, which pushes
landmarks to Dart over a method channel.

📐 **See [ARCHITECTURE.md](ARCHITECTURE.md)** for the full model: layer map, the
test pipeline end to end, the camera scoring stack, the Firestore schema and
security rules, and a checklist for adding a new test type.

## Design system

`app_tokens.dart` holds the palette, a 4-point spacing scale, radii and the
minimum tap target; `app_theme.dart` builds an explicit Material 3
`ColorScheme` and component themes; `app_semantic_colors.dart` adds the
success/warning slots Material has none for. Screens compose the widgets in
`lib/ui/common/widgets/` and read colour and type from `Theme.of(context)` —
raw literals are what 2.0 removed, and the lint rules in
`analysis_options.yaml` exist to keep them out.

Text size is an in-app setting (four discrete sizes, not a slider — a slider is
the wrong control for someone with hand tremor), persisted and applied app-wide.

## Getting started

```bash
flutter pub get
flutter gen-l10n        # regenerates lib/l10n/app_localizations*.dart
flutter run
```

Firebase configuration is not in this repository. You will need your own
`google-services.json` / `GoogleService-Info.plist`, and **anonymous sign-in
must be enabled** in the Firebase console for guest mode to work.

```bash
flutter test            # 107 tests
flutter analyze
```

One test — `hand_metrics_test.dart` → "tremor detects oscillation" — fails. It
predates 2.0 and asserts on the raw-position tremor metric that
`TremorAnalysisService` supersedes; it is left failing rather than silently
adjusted.

## Known limitations

- Scoring thresholds are provisional and have not been calibrated against
  labelled clinical data.
- Pure action tremor is not captured — tremor is read from the rest tasks only,
  because fast tapping falls inside the same 4–6 Hz band.
- Guest gating is UI-only; the Firestore rules do not enforce it.
- FAB results do not persist until `FAB` is added to the Firestore rules
  allow-list.
