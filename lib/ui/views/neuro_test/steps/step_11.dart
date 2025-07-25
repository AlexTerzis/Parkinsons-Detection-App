import 'dart:async';
import 'package:flutter/material.dart';

/// Step 11 - Orientation in time and place.
class NeuroStep11 extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int score) onScored;
  const NeuroStep11({super.key, required this.onNext, required this.onScored});

  @override
  State<NeuroStep11> createState() => _NeuroStep11State();
}

class _NeuroStep11State extends State<NeuroStep11> {
  final _date = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  final _day = TextEditingController();
  final _place = TextEditingController();
  final _city = TextEditingController();
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _timeout = Timer(const Duration(minutes: 2), _submit);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _date.dispose();
    _month.dispose();
    _year.dispose();
    _day.dispose();
    _place.dispose();
    _city.dispose();
    super.dispose();
  }

  void _submit() {
    _timeout?.cancel();
    int score = 0;
    final now = DateTime.now();
    if (_date.text.trim() == '${now.day}') score++;
    if (_month.text.trim().toLowerCase() == _monthName(now.month)) score++;
    if (_year.text.trim() == '${now.year}') score++;
    if (_day.text.trim().toLowerCase() == _weekdayName(now.weekday)) score++;
    if (_place.text.trim().isNotEmpty) score++;
    if (_city.text.trim().isNotEmpty) score++;
    widget.onScored(score);
    widget.onNext();
  }

  String _monthName(int m) {
    const names = [
      'ιανουαριος','φεβρουαριος','μαρτιος','απριλιος','μαϊος','ιουνιος',
      'ιουλιος','αυγουστος','σεπτεμβριος','οκτωβριος','νοεμβριος','δεκεμβριος'
    ];
    return names[m-1];
  }

  String _weekdayName(int d) {
    const names = [
      'δευτερα','τριτη','τεταρτη','πεμπτη','παρασκευη','σαββατο','κυριακη'
    ];
    return names[d-1];
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Προσανατολισμός')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _field('Ημερομηνία', _date),
              _field('Μήνας', _month),
              _field('Χρονιά', _year),
              _field('Ημέρα', _day),
              _field('Μέρος', _place),
              _field('Πόλη', _city),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Ολοκλήρωση'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
