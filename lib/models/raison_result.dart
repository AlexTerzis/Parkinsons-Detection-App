/// One outcome of the reasoning service: a decision with its explanation, or
/// an option that was possible but not chosen.
class RaisonResult {
  const RaisonResult({
    required this.label,
    required this.explanation,
    required this.isSolution,
  });

  final String label;
  final List<String> explanation;
  final bool isSolution;

  /// The results of one rAIson+ `/reason` response.
  ///
  /// The response carries `decision`, `explanation`, `possible`, `verdict` and
  /// `result`. Each `decision` becomes a solution with the explanation; each
  /// `possible` option that was not decided becomes a non-solution.
  ///
  /// Read leniently — a field may be a string, a list or an object — so that a
  /// change of shape degrades to fewer results rather than an exception. When
  /// nothing can be read, one non-solution is returned instead of an empty
  /// list, because the screens read an empty list as "no questionnaire yet".
  static List<RaisonResult> listFromReason(Map<String, dynamic> json) {
    final decided = _labels(json['decision']);
    final possible = _labels(json['possible']);
    final rawExplanation = json['explanation'];

    final results = <RaisonResult>[
      for (final d in decided)
        RaisonResult(
          label: readable(d),
          explanation: _explanationFor(rawExplanation, d),
          isSolution: true,
        ),
      for (final p in possible)
        if (!decided.contains(p))
          RaisonResult(label: readable(p), explanation: const [], isSolution: false),
    ];
    if (results.isEmpty) {
      final verdict = json['verdict'];
      return [
        RaisonResult(
          label: verdict is String ? readable(verdict) : '',
          explanation: const [],
          isSolution: false,
        ),
      ];
    }
    return results;
  }

  /// `visit_neurologist` → `Visit neurologist`; other text is left as it is.
  static String readable(String name) {
    if (!RegExp(r'^[a-z0-9]+(_[a-z0-9]+)+$').hasMatch(name)) return name;
    final words = name.replaceAll('_', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }

  /// Labels from a string, a list of strings or objects, or one object.
  static List<String> _labels(dynamic raw) {
    String? one(dynamic v) {
      if (v is String) return v.trim().isEmpty ? null : v.trim();
      if (v is Map) {
        for (final k in const ['label', 'name', 'option', 'id', 'decision']) {
          final s = one(v[k]);
          if (s != null) return s;
        }
      }
      return null;
    }

    if (raw is List) return raw.map(one).whereType<String>().toList();
    final single = one(raw);
    return single == null ? const [] : [single];
  }

  /// Explanation lines for [label]: from a map keyed by decision when there is
  /// one, otherwise the whole explanation.
  static List<String> _explanationFor(dynamic raw, String label) {
    if (raw is Map && raw.containsKey(label)) return _lines(raw[label]);
    return _lines(raw);
  }

  static List<String> _lines(dynamic raw) {
    if (raw == null) return const [];
    if (raw is String) {
      return [
        for (final l in raw.split('\n'))
          if (l.trim().isNotEmpty) l.trim(),
      ];
    }
    if (raw is List) return [for (final v in raw) ..._lines(v)];
    if (raw is Map) {
      for (final k in const ['text', 'explanation', 'reason']) {
        if (raw[k] != null) return _lines(raw[k]);
      }
      return [for (final v in raw.values) ..._lines(v)];
    }
    return ['$raw'];
  }
}
