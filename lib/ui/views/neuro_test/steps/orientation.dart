import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
        _weekdayNames[now.weekday - 1].toLowerCase()) score++;

    final enteredCity = _city.text.trim().toLowerCase();
    final enteredCountry = _country.text.trim().toLowerCase();
    if (_deviceLocation != null) {
      if (enteredCity.isNotEmpty && enteredCity == _deviceLocation!["city"]) score++;
      if (enteredCountry.isNotEmpty && enteredCountry == _deviceLocation!["country"]) score++;
    } else {
      if (enteredCity.isNotEmpty) score++;
      if (enteredCountry.isNotEmpty) score++;
    }

    widget.onScored(score);
    widget.onNext();
  }

  Widget _rollPicker<T>({
    required T value,
    required List<T> items,
    required void Function(T) onChanged,
    required double width,
  }) {
    return SizedBox(
      width: width,
      height: 42,
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Center(child: Text('$e', style: const TextStyle(fontSize: 15))),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Προσανατολισμός')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.93),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Συμπληρώστε τα παρακάτω:\n\n'
                      '• Ημερομηνία (π.χ. 01 / 01 / 2020)\n'
                      '• Ημέρα (π.χ. Δευτέρα)\n'
                      '• Χώρα\n'
                      '• Πόλη\n\n'
                      'Μπορείτε να γράψετε ή να χρησιμοποιήσετε το μικρόφωνο.',
                      style: TextStyle(fontSize: 15.5),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  // DATE
                  const Text("Ημερομηνία", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _rollPicker<int>(
                        value: _selectedDate,
                        items: List.generate(31, (i) => i + 1),
                        onChanged: (v) => setState(() => _selectedDate = v),
                        width: 55,
                      ),
                      const SizedBox(width: 4),
                      // Month dropdown with Greek names
                      SizedBox(
                        width: 110,
                        height: 42,
                        child: DropdownButton<int>(
                          value: _selectedMonth,
                          isExpanded: true,
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedMonth = v);
                          },
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Center(child: Text(_monthNames[i], style: const TextStyle(fontSize: 15))),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _rollPicker<int>(
                        value: _selectedYear,
                        items: List.generate(11, (i) => 2020 + i),
                        onChanged: (v) => setState(() => _selectedYear = v),
                        width: 75,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // DAY
                  const Text("Ημέρα", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 42,
                        child: DropdownButton<int>(
                          value: _selectedWeekday,
                          isExpanded: true,
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedWeekday = v);
                          },
                          items: List.generate(
                            7,
                            (i) => DropdownMenuItem(
                              value: i,
                              child: Center(child: Text(_weekdayNames[i], style: const TextStyle(fontSize: 15))),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // COUNTRY
                  const Text("Χώρα", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _country,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'π.χ. Ελλάδα',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_listening[1] ? Icons.mic : Icons.mic_none),
                        color: _listening[1] ? Colors.green : null,
                        onPressed: _listening[1] ? null : () => _startListening(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // CITY
                  const Text("Πόλη", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _city,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'π.χ. Αθήνα',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_listening[0] ? Icons.mic : Icons.mic_none),
                        color: _listening[0] ? Colors.green : null,
                        onPressed: _listening[0] ? null : () => _startListening(0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  // Show spinner while fetching location if not yet tried
                  if (!_locationTried)
                    Center(child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(),
                    )),
                  if (_locationTried && _deviceLocation == null)
                    Center(child: Text(
                      'Δεν επιτράπηκε η πρόσβαση στην τοποθεσία.\nΟι απαντήσεις στην Πόλη/Χώρα θα γίνουν δεκτές όπως είναι.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent, fontSize: 14),
                    )),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16),
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Επόμενο'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
