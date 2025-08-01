import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class DelayedRecallStep extends StatefulWidget {
  final void Function(int score, VerbalMemoryResult result) onFinished;
  final List<String> immediateTrials;

  const DelayedRecallStep({
    Key? key,
    required this.onFinished,
    required this.immediateTrials,
  }) : super(key: key);

  @override
  State<DelayedRecallStep> createState() => _DelayedRecallStepState();
}

class _RowAnswer {
  String text = '';
  bool locked = false;
  int? wordIndex; // Which word (index in _words) this row is matched to (if locked)
  int hintStep = 0;
  String? choiceAnswer;
}

class _DelayedRecallStepState extends State<DelayedRecallStep> {
  static const _words = [
    'ΠΡΟΣΩΠΟ',
    'ΒΕΛΟΥΔΟ',
    'ΕΚΚΛΗΣΙΑ',
    'ΜΑΡΓΑΡΙΤΑ',
    'ΚΟΚΚΙΝΟ',
  ];
  static const _cues = [
    'ένα μέρος του σώματος',
    'ένα είδος υφάσματος',
    'ένας τόπος λατρείας',
    'ένα είδος λουλουδιού',
    'ένα χρώμα',
  ];
  static const _choices = [
    ['ΠΡΟΣΩΠΟ', 'ΓΕΦΥΡΑ', 'ΛΑΜΠΑ'],
    ['ΒΕΛΟΥΔΟ', 'ΜΕΤΑΞΙ', 'ΜΑΧΑΙΡΙ'],
    ['ΕΚΚΛΗΣΙΑ', 'ΕΡΓΟΣΤΑΣΙΟ', 'ΚΑΦΕΝΕΙΟ'],
    ['ΜΑΡΓΑΡΙΤΑ', 'ΤΟΥΛΙΠΑ', 'ΔΡΥΣ'],
    ['ΚΟΚΚΙΝΟ', 'ΠΡΑΣΙΝΟ', 'ΓΑΛΑΖΙΟ'],
  ];

  final SpeechToText _speech = SpeechToText();
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  final List<_RowAnswer> _rows = List.generate(5, (_) => _RowAnswer());

  bool _speechReady = false;
  bool _finished = false;

  final ScrollController _scrollController = ScrollController();
  bool _showScrollArrow = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _scrollController.addListener(_checkScrollArrow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollArrow());
    _refreshUnclaimedMapping();
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

  void _toggleListening(int i) async {
    if (!_speechReady) return;
    if (_rows[i].locked) return;
    if (_controllers[i].text.isNotEmpty) _controllers[i].clear();
    setState(() {
      _rows[i].text = '';
    });
    await _speech.listen(
      localeId: 'el_GR',
      onResult: (r) {
        setState(() {
          _rows[i].text = r.recognizedWords;
          _controllers[i].text = r.recognizedWords;
        });
      },
    );
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

  // Set of all claimed word indices (via text or choice)
  Set<int> _claimedWordIndices() {
    final used = <int>{};
    for (final row in _rows) {
      if (row.locked && row.wordIndex != null) used.add(row.wordIndex!);
      if (row.choiceAnswer != null) {
        final idx = _words.indexWhere((w) => normalizeGreek(w) == normalizeGreek(row.choiceAnswer!));
        if (idx != -1) used.add(idx);
      }
    }
    return used;
  }

  // Assign the next available (unclaimed) word to each unlocked row, for hints/choices
  void _refreshUnclaimedMapping() {
    final claimed = _claimedWordIndices();
    int nextUnclaimed = 0;
    for (int i = 0; i < 5; i++) {
      if (!_rows[i].locked) {
        // Look for the next unclaimed word
        while (nextUnclaimed < _words.length && claimed.contains(nextUnclaimed)) {
          nextUnclaimed++;
        }
        _rows[i].wordIndex = (nextUnclaimed < _words.length) ? nextUnclaimed : null;
        nextUnclaimed++;
      }
    }
  }

  void _onSubmit(int i) {
    if (_rows[i].locked) return;
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
        _rows[i].locked = true;
        _rows[i].wordIndex = matchIdx;
        _rows[i].text = _controllers[i].text;
        _refreshUnclaimedMapping();
      });
    } else {
      setState(() {}); // stay open, can still submit/hint
    }
  }

  void _onHint(int i) {
    if (_rows[i].locked || _rows[i].wordIndex == null) return;
    setState(() {
      if (_rows[i].hintStep == 0) {
        _rows[i].hintStep = 1;
      } else if (_rows[i].hintStep == 1) {
        _rows[i].hintStep = 2;
      }
    });
  }

  void _onChoice(int i, String choice) {
    int? idx = _words.indexWhere((w) => normalizeGreek(w) == normalizeGreek(choice));
    if (idx == -1) return;
    setState(() {
      _rows[i].choiceAnswer = choice;
      _rows[i].locked = true;
      _rows[i].wordIndex = idx;
      _refreshUnclaimedMapping();
    });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    int score = 0;
    final used = <int>{};
    for (final row in _rows) {
      if (row.locked && row.wordIndex != null && !used.contains(row.wordIndex!)) {
        score++;
        used.add(row.wordIndex!);
      }
    }
    widget.onFinished(
      score,
      VerbalMemoryResult(
        immediateTrials: widget.immediateTrials,
        delayedFreeRecall: _rows.map((r) => r.text).toList().join(' '),
        categoryCueAnswers: Map.fromIterables(
            _words, List.generate(5, (i) => _rows[i].hintStep >= 1 ? _rows[i].text : null)),
        choiceAnswers: Map.fromIterables(_words, _rows.map((r) => r.choiceAnswer)),
        score: score,
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    for (final c in _controllers) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allDone = _rows.every((r) => r.locked);
    _refreshUnclaimedMapping();
    return Scaffold(
      appBar: AppBar(title: const Text('Καθυστερημένη Ανάκληση')),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Πείτε όσες λέξεις θυμάστε (μόνο με φωνή, η σειρά δεν μετράει).',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < 5; i++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: _rows[i].locked ? Colors.green.withOpacity(0.08) : null,
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
                              hintText: (_rows[i].locked || _rows[i].wordIndex != null)
                                  ? 'Πείτε τη λέξη με το μικρόφωνο'
                                  : 'Όλες οι λέξεις έχουν βρεθεί!',
                              suffixIcon: IconButton(
                                icon: Icon(_rows[i].locked ? Icons.check : Icons.mic),
                                onPressed: (!_rows[i].locked && _rows[i].wordIndex != null)
                                    ? () => _toggleListening(i)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: (!_rows[i].locked &&
                                        _controllers[i].text.trim().isNotEmpty &&
                                        _rows[i].wordIndex != null)
                                    ? () => _onSubmit(i)
                                    : null,
                                child: const Text('Υποβολή'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: (!_rows[i].locked && _rows[i].wordIndex != null)
                                    ? () => _onHint(i)
                                    : null,
                                child: const Text('Υπόδειξη'),
                              ),
                            ],
                          ),
                          if (_rows[i].locked)
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
                          if (_rows[i].hintStep == 1 &&
                              !_rows[i].locked &&
                              _rows[i].wordIndex != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0, left: 2.0),
                              child: Text('Υπόδειξη: ${_cues[_rows[i].wordIndex!]}',
                                  style: const TextStyle(color: Colors.blue)),
                            ),
                          if (_rows[i].hintStep == 2 &&
                              !_rows[i].locked &&
                              _rows[i].wordIndex != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0, left: 2.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ποια από τις παρακάτω λέξεις ήταν στη λίστα;'),
                                  ...(() {
                                    final opts =
                                        List<String>.from(_choices[_rows[i].wordIndex!]);
                                    opts.shuffle(Random());
                                    return opts.map((opt) => RadioListTile<String>(
                                          value: opt,
                                          groupValue: _rows[i].choiceAnswer,
                                          title: Text(opt),
                                          onChanged: (v) => _onChoice(i, v!),
                                        ));
                                  })(),
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

class VerbalMemoryResult {
  const VerbalMemoryResult({
    required this.immediateTrials,
    required this.delayedFreeRecall,
    required this.categoryCueAnswers,
    required this.choiceAnswers,
    required this.score,
  });

  final List<String> immediateTrials;
  final String delayedFreeRecall;
  final Map<String, String?> categoryCueAnswers;
  final Map<String, String?> choiceAnswers;
  final int score;

  Map<String, dynamic> toJson() => {
        'immediateTrials': immediateTrials,
        'delayedFreeRecall': delayedFreeRecall,
        'categoryCueAnswers': categoryCueAnswers,
        'choiceAnswers': choiceAnswers,
        'score': score,
      };
}
