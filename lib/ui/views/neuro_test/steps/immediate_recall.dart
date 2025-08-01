import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ImmediateRecallStep extends StatefulWidget {
  final void Function(List<String> responses, String allTogether) onFinished;

  const ImmediateRecallStep({Key? key, required this.onFinished}) : super(key: key);

  @override
  State<ImmediateRecallStep> createState() => _ImmediateRecallStepState();
}

class _ImmediateRecallStepState extends State<ImmediateRecallStep> {
  static const _words = [
    'ΠΡΟΣΩΠΟ',
    'ΒΕΛΟΥΔΟ',
    'ΕΚΚΛΗΣΙΑ',
    'ΜΑΡΓΑΡΙΤΑ',
    'ΚΟΚΚΙΝΟ',
  ];

  final SpeechToText _speech = SpeechToText();
  final TextEditingController _allController = TextEditingController();
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  final List<bool> _listening = List.filled(5, false);
  final List<bool> _locked = List.filled(5, false);
  final List<int?> _assigned = List.filled(5, null); // Which _words index each row claimed

  bool _speechReady = false;
  int _phase = 0; // 0: instructions, 1: all-together, 2: per-word
  final ScrollController _scrollController = ScrollController();
  bool _showScrollArrow = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _scrollController.addListener(_checkScrollArrow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollArrow());
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
    setState(() => _speechReady = true);
  }

  void _checkScrollArrow() {
    if (!_scrollController.hasClients) return;
    final show = !_scrollController.position.atEdge || _scrollController.position.pixels == 0.0;
    setState(() {
      _showScrollArrow = show && _scrollController.position.maxScrollExtent > 0;
    });
  }

  String normalizeGreek(String s) {
    return s
        .replaceAll('ά', 'α')
        .replaceAll('έ', 'ε')
        .replaceAll('ή', 'η')
        .replaceAll('ί', 'ι')
        .replaceAll('ό', 'ο')
        .replaceAll('ύ', 'υ')
        .replaceAll('ώ', 'ω')
        .replaceAll('Ά', 'Α')
        .replaceAll('Έ', 'Ε')
        .replaceAll('Ή', 'Η')
        .replaceAll('Ί', 'Ι')
        .replaceAll('Ό', 'Ο')
        .replaceAll('Ύ', 'Υ')
        .replaceAll('Ώ', 'Ω')
        .replaceAll('ϊ', 'ι')
        .replaceAll('ΐ', 'ι')
        .replaceAll('Ϊ', 'Ι')
        .replaceAll('ϋ', 'υ')
        .replaceAll('ΰ', 'υ')
        .replaceAll('Ϋ', 'Υ')
        .replaceAll(RegExp(r'[^\p{L}]', unicode: true), '')
        .toUpperCase()
        .trim();
  }

  Set<int> _claimedWordIndices() {
    final used = <int>{};
    for (final idx in _assigned) {
      if (idx != null) used.add(idx);
    }
    return used;
  }

  void _toggleListeningAll() async {
    if (!_speechReady) return;
    setState(() {
      _allController.clear();
    });
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _allController.text = r.recognizedWords;
        });
      },
    );
  }

  void _toggleListening(int i) async {
    if (!_speechReady || _locked[i]) return;
    setState(() {
      _listening[i] = true;
      _controllers[i].clear();
    });
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _controllers[i].text = r.recognizedWords;
        });
      },
    );
  }

  void _onSubmit(int i) {
    if (_locked[i]) return;
    final input = normalizeGreek(_controllers[i].text);
    final claimed = _claimedWordIndices();
    int matchIdx = -1;
    for (int j = 0; j < _words.length; j++) {
      if (!claimed.contains(j) && normalizeGreek(_words[j]) == input) {
        matchIdx = j;
        break;
      }
    }
    if (matchIdx != -1) {
      setState(() {
        _locked[i] = true;
        _assigned[i] = matchIdx;
      });
    } else {
      setState(() {});
    }
  }

  void _nextPhase() {
    setState(() {
      _phase++;
    });
  }

  void _finish() {
    final answers = _controllers.map((c) => c.text.trim()).toList();
    widget.onFinished(answers, _allController.text.trim());
  }

  @override
  void dispose() {
    _speech.stop();
    _allController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 0) {
      // Instructions + show all words
      return Scaffold(
        appBar: AppBar(title: const Text('Άμεση Ανάκληση')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Θα σας πω 5 λέξεις. Προσπαθήστε να τις απομνημονεύσετε γιατί λίγο αργότερα θα σας ζητηθούν ξανά.\n\n'
                  'Για εξάσκηση πρώτα θα τις επαναλάβετε όλες μαζί. Μετά, θα προσπαθήσετε να επαναλάβετε κάθε λέξη ξεχωριστά.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: _words.map((w) => Chip(label: Text(w))).toList(),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _nextPhase,
                  child: const Text('Άμεση επανάληψη'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_phase == 1) {
      // All together recall (one field)
      return Scaffold(
        appBar: AppBar(title: const Text('Άμεση Ανάκληση')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Πείτε τις λέξεις από τη λίστα (όλες μαζί, με όποια σειρά θέλετε): ΠΡΟΣΩΠΟ, ΒΕΛΟΥΔΟ, ΕΚΚΛΗΣΙΑ, ΜΑΡΓΑΡΙΤΑ, ΚΟΚΚΙΝΟ',
                style: TextStyle(fontSize: 17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _allController,
                readOnly: true,
                enableInteractiveSelection: false,
                showCursor: false,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Πείτε τις λέξεις',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: _toggleListeningAll,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _allController.text.trim().isEmpty ? null : _nextPhase,
                child: const Text('Επόμενο'),
              ),
            ],
          ),
        ),
      );
    }
    // Phase 2: Per-word recall
    final allDone = _locked.every((x) => x);
    return Scaffold(
      appBar: AppBar(title: const Text('Άμεση Ανάκληση')),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Πείτε τις λέξεις, μία σε κάθε πεδίο. ΠΡΟΣΩΠΟ, ΒΕΛΟΥΔΟ, ΕΚΚΛΗΣΙΑ, ΜΑΡΓΑΡΙΤΑ, ΚΟΚΚΙΝΟ',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < 5; i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: _locked[i] ? Colors.green.withOpacity(0.08) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Λέξη ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextField(
                            controller: _controllers[i],
                            readOnly: true,
                            enableInteractiveSelection: false,
                            showCursor: false,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: 'Πείτε τη λέξη με το μικρόφωνο',
                              suffixIcon: IconButton(
                                icon: Icon(_locked[i] ? Icons.check : Icons.mic),
                                onPressed: !_locked[i] ? () => _toggleListening(i) : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            onPressed: !_locked[i] && _controllers[i].text.trim().isNotEmpty
                                ? () => _onSubmit(i)
                                : null,
                            child: const Text('Υποβολή'),
                          ),
                          if (_locked[i])
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, left: 2.0),
                              child: Row(
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.green, size: 22),
                                  SizedBox(width: 6),
                                  Text("Σωστό!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 60),
              ],
            ),
          ),
          if (_showScrollArrow)
            Positioned(
              right: 12,
              bottom: 80,
              child: Icon(Icons.keyboard_arrow_down, size: 38, color: Colors.black45),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onPressed: _finish,
                child: Text(allDone ? 'Ολοκλήρωση' : 'Επόμενο'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
