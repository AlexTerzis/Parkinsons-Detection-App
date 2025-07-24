import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class NeuroStep2 extends StatefulWidget {
  final VoidCallback onNext;
  final Function(int) onScored;

  const NeuroStep2({
    super.key,
    required this.onNext,
    required this.onScored,
  });

  @override
  _NeuroStep2State createState() => _NeuroStep2State();
}

class _NeuroStep2State extends State<NeuroStep2> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  void _handleNext({required int score}) async {
    if (_controller.isNotEmpty) score = 1;
    widget.onScored(score);
    widget.onNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Οπτικο-Κατασκευαστικές Ικανότητες')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Αντιγράψτε τον κύβο που βλέπετε παρακάτω ☞',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          // Reference cube
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/cube_reference.png',
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          // Drawing canvas
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () => _controller.clear(),
                  child: const Text('Καθάρισμα'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _handleNext(score: 0),
                  child: const Text('Επόμενο'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
