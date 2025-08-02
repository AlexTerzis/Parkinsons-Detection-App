import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

String normalizeGreek(String text) => text
  .replaceAll(RegExp(r'[άα]'), 'α')
  .replaceAll(RegExp(r'[έε]'), 'ε')
  .replaceAll(RegExp(r'[ήη]'), 'η')
  .replaceAll(RegExp(r'[ίιϊΐ]'), 'ι')
  .replaceAll(RegExp(r'[όο]'), 'ο')
  .replaceAll(RegExp(r'[ύυϋΰ]'), 'υ')
  .replaceAll(RegExp(r'[ώω]'), 'ω')
  .replaceAll(RegExp(r'[ς]'), 'σ')
  .toLowerCase();

class OrientationStep extends StatefulWidget {
  final VoidCallback onNext;
  final Function(double score) onScored;
  const OrientationStep({super.key, required this.onNext, required this.onScored});

  @override
  State<OrientationStep> createState() => _OrientationStepState();
}

class _OrientationStepState extends State<OrientationStep> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  late SpeechToText _speech;
  final _listening = List.generate(6, (_) => false);
  Timer? _timeout;

  static const _monthNames = [
    'ιανουαριος','φεβρουαριος','μαρτιος','απριλιος','μαιος','ιουνιος',
    'ιουλιος','αυγουστος','σεπτεμβριος','οκτωβριος','νοεμβριος','δεκεμβριος'
  ];
  static const _dayNames = [
    'δευτερα','τριτη','τεταρτη','πεμπτη','παρασκευη','σαββατο','κυριακη'
  ];

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
    _timeout = Timer(const Duration(minutes: 2), _submit);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    for (final c in _controllers) c.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _listen(int idx) async {
    if (_listening[idx]) return;
    final available = await _speech.initialize();
    if (!available) return;
    setState(() => _listening[idx] = true);

    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _controllers[idx].text = r.recognizedWords.trim();
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
    double score = 0;
    final now = DateTime.now();

    // Date
    final date = int.tryParse(_controllers[0].text.trim()) ?? -1;
    if ((date == now.day) || (date == now.day - 1) || (date == now.day + 1)) score++;

    // Month
    final userMonth = normalizeGreek(_controllers[1].text.trim());
    final correctMonth = _monthNames[now.month - 1];
    if (userMonth == correctMonth || userMonth == '${now.month}') score++;

    // Year
    if (_controllers[2].text.trim() == '${now.year}') score++;

    // Day of week
    final userDay = normalizeGreek(_controllers[3].text.trim());
    final correctDay = _dayNames[now.weekday - 1];
    if (userDay == correctDay) score++;

    // Place (any non-empty)
    if (_controllers[4].text.trim().isNotEmpty) score++;

    // City (any non-empty)
    if (_controllers[5].text.trim().isNotEmpty) score++;

    widget.onScored(score);
    widget.onNext();
  }

  Widget _field(String label, TextEditingController c, int idx, {TextInputType? type, String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: c,
              keyboardType: type,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(_listening[idx] ? Icons.mic : Icons.mic_none),
            color: _listening[idx] ? Colors.green : null,
            onPressed: _listening[idx] ? null : () => _listen(idx),
            tooltip: 'Λέγεται στο μικρόφωνο',
          ),
        ],
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
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Πείτε ή πληκτρολογήστε τις σωστές απαντήσεις για:\n'
                      'Ημερομηνία, μήνα, χρονιά, μέρα της εβδομάδας, μέρος και πόλη.\n'
                      'Παράδειγμα: 4 Ιουλίου 2025, Παρασκευή, Νοσοκομείο, Αθήνα',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                  _field('Ημερομηνία', _controllers[0], 0, type: TextInputType.number, hint: 'π.χ. 4'),
                  _field('Μήνας', _controllers[1], 1, hint: 'π.χ. Ιούλιος ή 7'),
                  _field('Χρονιά', _controllers[2], 2, type: TextInputType.number, hint: 'π.χ. 2025'),
                  _field('Ημέρα (της εβδομάδας)', _controllers[3], 3, hint: 'π.χ. Παρασκευή'),
                  _field('Μέρος (π.χ. νοσοκομείο)', _controllers[4], 4, hint: 'π.χ. νοσοκομείο'),
                  _field('Πόλη', _controllers[5], 5, hint: 'π.χ. Αθήνα'),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16),
              child: Material(
                color: Colors.transparent,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    side: BorderSide(color: Colors.black.withOpacity(0.09)),
                    elevation: 4,
                    shadowColor: Colors.black12,
                  ),
                  onPressed: _submit,
                  child: const Text('Επόμενο'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
