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
  /// `result`. `verdict` is an object such as
  /// `{"kind": "multiple", "title": "Multiple equally defensible conclusions",
  /// "message": ...}`; `explanation` is text, one argument per line.
  ///
  ///  * A decision: each `decision` becomes a solution with the explanation,
  ///    and each other `possible` option a non-solution.
  ///  * No decision but several possible options (`kind: multiple`, a
  ///    dilemma): one solution titled with the verdict, whose lines are the
  ///    options and the arguments for each, followed by the options as
  ///    non-solutions. The screens list only solutions, so without this a
  ///    dilemma — which does carry reasoning — would look like no result.
  ///  * Nothing (`kind: empty`, no rule applies): one non-solution, never an
  ///    empty list, because the screens read an empty list as "no
  ///    questionnaire yet".
  ///
  /// Read leniently — a field may be a string, a list or an object — so that a
  /// change of shape degrades to fewer results rather than an exception.
  static List<RaisonResult> listFromReason(Map<String, dynamic> json) {
    final decided = _labels(json['decision']);
    final possible = _labels(json['possible']);
    final rawExplanation = json['explanation'];
    final title = _verdictTitle(json['verdict']);

    if (decided.isEmpty && possible.isNotEmpty) {
      return [
        RaisonResult(
          label: title ?? possible.map(readable).join(' / '),
          explanation: _clean(_lines(rawExplanation), title),
          isSolution: true,
        ),
        for (final p in possible)
          RaisonResult(label: readable(p), explanation: const [], isSolution: false),
      ];
    }

    final results = <RaisonResult>[
      for (final d in decided)
        RaisonResult(
          label: readable(d),
          explanation: _clean(_explanationFor(rawExplanation, d), title),
          isSolution: true,
        ),
      for (final p in possible)
        if (!decided.contains(p))
          RaisonResult(label: readable(p), explanation: const [], isSolution: false),
    ];
    if (results.isEmpty) {
      return [
        RaisonResult(
          label: title == null ? '' : readable(title),
          explanation: const [],
          isSolution: false,
        ),
      ];
    }
    return results;
  }

  /// The verdict's title, from `{"title": ...}` or a plain string.
  static String? _verdictTitle(dynamic verdict) {
    final t = verdict is Map ? verdict['title'] : verdict;
    return t is String && t.trim().isNotEmpty ? t.trim() : null;
  }

  /// Explanation lines that say something the card does not already show.
  ///
  /// rAIson+ explains in steps: the arguments that fire, every pair of them
  /// that conflicts, the preferences, and a resolution that lists each rule
  /// again. On a phone the conflicts alone ran to 74 lines. Kept: the verdict
  /// message, the arguments, the preferences, what was ruled out and the
  /// summary. Dropped: the repeated title, `Decision: ...` (the card's
  /// heading), the `Step N` headings, the conflict pairs and the per-rule
  /// resolution lines; list dashes are removed.
  static List<String> _clean(List<String> lines, String? title) {
    final dropped = [
      RegExp(r'^Step \d+\b'),
      RegExp(r'^Decision:'),
      RegExp(r'are mutually exclusive$'),
      RegExp(r'^\S+ supports (the winning|a possible) conclusion\b'),
    ];
    final kept = <String>[];
    for (final raw in lines) {
      final l = raw.startsWith('- ') ? raw.substring(2) : raw;
      if (l == title || dropped.any((p) => p.hasMatch(l))) continue;
      kept.add(l);
    }
    return kept;
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

/// One rAIson+ `/reason` response kept as lists, for an agent whose
/// conclusions can hold together, such as the diagnosis agent: several
/// diagnoses are indications to consider, not rival answers.
class RaisonReasoning {
  const RaisonReasoning({
    required this.decided,
    required this.possible,
    required this.explanation,
    this.verdictTitle,
  });

  /// Conclusions the agent decided on.
  final List<String> decided;

  /// Conclusions the agent found supported without deciding between them.
  final List<String> possible;

  /// Explanation lines, cleaned as for [RaisonResult].
  final List<String> explanation;

  final String? verdictTitle;

  /// What to show as indications: the decided conclusions, or, when the
  /// agent left them undecided, every supported one.
  List<String> get indications => decided.isNotEmpty ? decided : possible;

  factory RaisonReasoning.fromJson(Map<String, dynamic> json) {
    final title = RaisonResult._verdictTitle(json['verdict']);
    return RaisonReasoning(
      decided: RaisonResult._labels(json['decision']),
      possible: RaisonResult._labels(json['possible']),
      explanation:
          RaisonResult._clean(RaisonResult._lines(json['explanation']), title),
      verdictTitle: title,
    );
  }
}
