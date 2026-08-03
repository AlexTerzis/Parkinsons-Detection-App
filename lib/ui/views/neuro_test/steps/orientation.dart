import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../common/widgets/widgets.dart';

/// MoCA orientation: date, weekday, city and country.
///
/// The weekday and month names stay Greek: they are compared against the
/// patient's dropdown choice, and the comparison is what carries the score.
class OrientationStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;
  const OrientationStep({super.key, required this.onNext, required this.onScored});

  @override
  State<OrientationStep> createState() => _OrientationStepState();
}

class _OrientationStepState extends State<OrientationStep> {
  int _selectedDate = 1;
  int _selectedMonth = 1; // still 1-based (January = 1)
  int _selectedYear = 2020;
  int _selectedWeekday = 0; // Index for weekdays
  final _city = TextEditingController();
  final _country = TextEditingController();
  late SpeechToText _speech;
  final _listening = [false, false]; // [city, country]
  Timer? _timeout;

  static const _weekdayNames = [
    'Δευτέρα', 'Τρίτη', 'Τετάρτη', 'Πέμπτη', 'Παρασκευή', 'Σάββατο', 'Κυριακή'
  ];
  static const _monthNames = [
    'Ιανουάριος', 'Φεβρουάριος', 'Μάρτιος', 'Απρίλιος',
    'Μάιος', 'Ιούνιος', 'Ιούλιος', 'Αύγουστος',
    'Σεπτέμβριος', 'Οκτώβριος', 'Νοέμβριος', 'Δεκέμβριος'
  ];

  // Store device location result (city and country)
  Map<String, String>? _deviceLocation;
  bool _locationTried = false; // To avoid showing spinner forever

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
    _timeout = Timer(const Duration(minutes: 2), _submit);
    _fetchLocation();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _city.dispose();
    _country.dispose();
    _speech.stop();
    super.dispose();
  }

  // Request permission and get device city/country
  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _deviceLocation = null;
          _locationTried = true;
        });
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude, pos.longitude
      );
      Placemark place = placemarks.first;
      setState(() {
        _deviceLocation = {
          "city": (place.locality ?? '').toLowerCase().trim(),
          "country": (place.country ?? '').toLowerCase().trim(),
        };
        _locationTried = true;
      });
    } catch (e) {
      setState(() {
        _deviceLocation = null;
        _locationTried = true;
      });
    }
  }

  Future<void> _startListening(int idx) async {
    if (_listening[idx]) return;
    final available = await _speech.initialize();
    if (!available) return;
    setState(() => _listening[idx] = true);

    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          if (idx == 0) {
            _city.text = r.recognizedWords.trim();
          } else {
            _country.text = r.recognizedWords.trim();
          }
        });
        if (r.finalResult) {
          _speech.stop();
          setState(() => _listening[idx] = false);
        }
      },
    );
  }

  void _submit() {
    _timeout?.cancel();
    int score = 0;
    final now = DateTime.now();

    if (_selectedDate == now.day) score++;
    if (_selectedMonth == now.month) score++;
    if (_selectedYear == now.year) score++;
    if (_weekdayNames[_selectedWeekday].toLowerCase() ==
        _weekdayNames[now.weekday - 1].toLowerCase()) {
      score++;
    }

    final enteredCity = _city.text.trim().toLowerCase();
    final enteredCountry = _country.text.trim().toLowerCase();
    if (_deviceLocation != null) {
      if (enteredCity.isNotEmpty && enteredCity == _deviceLocation!["city"]) {
        score++;
      }
      if (enteredCountry.isNotEmpty &&
          enteredCountry == _deviceLocation!["country"]) {
        score++;
      }
    } else {
      // Without a location fix there is nothing to check against, so any
      // non-empty answer is credited rather than penalising the patient for a
      // permission they were never asked about.
      if (enteredCity.isNotEmpty) score++;
      if (enteredCountry.isNotEmpty) score++;
    }

    widget.onScored(score);
    widget.onNext();
  }

  /// A labelled dropdown. [flex] shares the date row's width between the day,
  /// month and year pickers rather than pinning each to a fixed pixel count
  /// that clips once the text scaler grows.
  Widget _picker<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required void Function(T) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(labelOf(e))))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final semantic = AppSemanticColors.of(context);

    return TestStepScaffold(
      title: l10n.stepTitleOrientation,
      instruction: '${l10n.stepInstructionOrientation}\n'
          '• ${l10n.stepInstructionOrientationDate}\n'
          '• ${l10n.stepInstructionOrientationDay}\n'
          '• ${l10n.stepInstructionOrientationCountry}\n'
          '• ${l10n.stepInstructionOrientationCity}\n\n'
          '${l10n.stepTypeOrUseMic}',
      onNext: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.stepInstructionOrientationDate,
            style: theme.textTheme.titleSmall,
          ),
          const AppGap.xs(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _picker<int>(
                  value: _selectedDate,
                  items: List.generate(31, (i) => i + 1),
                  labelOf: (v) => '$v',
                  onChanged: (v) => setState(() => _selectedDate = v),
                ),
              ),
              const AppGap.wide(AppSpacing.xs),
              Expanded(
                flex: 4,
                child: _picker<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (i) => i + 1),
                  labelOf: (v) => _monthNames[v - 1],
                  onChanged: (v) => setState(() => _selectedMonth = v),
                ),
              ),
              const AppGap.wide(AppSpacing.xs),
              Expanded(
                flex: 3,
                child: _picker<int>(
                  value: _selectedYear,
                  items: List.generate(11, (i) => 2020 + i),
                  labelOf: (v) => '$v',
                  onChanged: (v) => setState(() => _selectedYear = v),
                ),
              ),
            ],
          ),
          const AppGap.md(),
          Text(
            l10n.stepInstructionOrientationDay,
            style: theme.textTheme.titleSmall,
          ),
          const AppGap.xs(),
          _picker<int>(
            value: _selectedWeekday,
            items: List.generate(7, (i) => i),
            labelOf: (v) => _weekdayNames[v],
            onChanged: (v) => setState(() => _selectedWeekday = v),
          ),
          const AppGap.md(),
          Text(
            l10n.stepInstructionOrientationCountry,
            style: theme.textTheme.titleSmall,
          ),
          const AppGap.xs(),
          SpeechTextField(
            controller: _country,
            listening: _listening[1],
            onListen: () => _startListening(1),
            hintText: l10n.stepHintCountryExample,
            micTooltip: l10n.stepSayWithMic,
          ),
          const AppGap.md(),
          Text(
            l10n.stepInstructionOrientationCity,
            style: theme.textTheme.titleSmall,
          ),
          const AppGap.xs(),
          SpeechTextField(
            controller: _city,
            listening: _listening[0],
            onListen: () => _startListening(0),
            hintText: l10n.stepHintCityExample,
            micTooltip: l10n.stepSayWithMic,
          ),
          const AppGap.lg(),
          if (!_locationTried)
            const AppLoading()
          else if (_deviceLocation == null)
            Text(
              l10n.stepLocationDenied,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: semantic.warning),
            ),
        ],
      ),
    );
  }
}
