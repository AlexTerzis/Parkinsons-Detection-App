import '../views/questionnaire/questionnaire_english.dart';
import '../views/questionnaire/questionnaire_schema.dart';

/// One answered question, ready to show.
class QuestionnaireAnswer {
  const QuestionnaireAnswer({
    required this.id,
    required this.label,
    required this.value,
    this.affirmative = false,
  });

  /// A symptom the patient reported having.
  ///
  /// What a clinician scans for first, so it is worth marking rather than
  /// leaving them to read every "no" looking for the yesses.
  const QuestionnaireAnswer.affirmed({
    required this.id,
    required this.label,
    required this.value,
  }) : affirmative = true;

  /// The stable schema id, e.g. `A1`. Shown only when nothing better exists.
  final String id;

  /// The question as asked, in the reader's language.
  final String label;

  /// The answer, already turned into something readable.
  final String value;

  final bool affirmative;
}

/// A group of answers as the questionnaire itself groups them.
class QuestionnaireSection {
  const QuestionnaireSection({required this.name, required this.answers});

  final String name;
  final List<QuestionnaireAnswer> answers;

  int get affirmativeCount => answers.where((a) => a.affirmative).length;
}

/// Reads a stored questionnaire result into sections a doctor can work through.
///
/// The stored `data` is a flat map of schema id to raw answer — `{'A1': true,
/// 'W': 'W1'}` — which is what the reasoning engine wants and is unreadable to
/// anyone else. The doctor's screen showed those keys verbatim. This resolves
/// each one against [questionnaireSchema] for its question text, its section
/// and, for a multiple choice, the label of the option actually chosen.
///
/// Keys with no schema entry are kept rather than dropped: `SCOPA>3` and the
/// other derived flags are written by the view model after scoring and are
/// genuinely part of the answer set.
List<QuestionnaireSection> questionnaireSections(
  Map<String, dynamic> data, {
  required bool inGreek,
}) {
  if (data.isEmpty) return const [];

  final fields = <String, Map<String, dynamic>>{
    for (final field in questionnaireSchema)
      if (field['id'] is String) field['id'] as String: field,
  };

  final bySection = <String, List<QuestionnaireAnswer>>{};

  for (final entry in data.entries) {
    final field = fields[entry.key];
    final section = field?['section'] as String? ?? _derivedSection;
    final label = _labelFor(entry.key, field, inGreek: inGreek);
    final value = _valueFor(entry.value, field, inGreek: inGreek);

    final answer = entry.value == true
        ? QuestionnaireAnswer.affirmed(
            id: entry.key, label: label, value: value)
        : QuestionnaireAnswer(id: entry.key, label: label, value: value);

    bySection.putIfAbsent(section, () => <QuestionnaireAnswer>[]).add(answer);
  }

  // Fixed order, so the same section is in the same place on every patient.
  final ordered = <QuestionnaireSection>[];
  for (final name in [...sectionOrder, _derivedSection]) {
    final answers = bySection.remove(name);
    if (answers == null || answers.isEmpty) continue;
    ordered.add(QuestionnaireSection(name: name, answers: answers));
  }
  // Anything the schema gained since this list was written still shows up.
  for (final entry in bySection.entries) {
    ordered.add(QuestionnaireSection(name: entry.key, answers: entry.value));
  }
  return ordered;
}

/// The sections in the order the questionnaire asks them.
const List<String> sectionOrder = <String>[
  'Demographics',
  'Symptom Assessment',
  'Clinical',
  'Family History',
  'Medication',
];

/// Where the flags the view model computes after scoring are collected.
const String _derivedSection = 'Scored';

/// The question text, in the reader's language.
///
/// The schema holds the Greek clinical source text and
/// [questionnaireEnglishLabels] the English rendering of the same ids, so which
/// one to use depends on the locale rather than on which is present.
String _labelFor(
  String id,
  Map<String, dynamic>? field, {
  required bool inGreek,
}) {
  final greek = field?['label'] as String?;
  final english = questionnaireEnglishLabels[id];

  if (inGreek) return greek ?? english ?? id;
  return english ?? greek ?? id;
}

/// The answer, resolved through the field's options where it is a choice.
String _valueFor(
  Object? raw,
  Map<String, dynamic>? field, {
  required bool inGreek,
}) {
  if (raw == null) return '—';
  if (raw is bool) return raw ? _yes(inGreek) : _no(inGreek);

  final options = field?['options'];
  if (options is List) {
    for (final option in options) {
      if (option is Map && option['value'] == raw) {
        return option['label'] as String? ?? '$raw';
      }
    }
  }

  if (raw is num) {
    // Sliders store whole numbers; do not print 45.0 for an age.
    return raw == raw.roundToDouble() ? raw.toInt().toString() : '$raw';
  }
  return '$raw';
}

String _yes(bool inGreek) => inGreek ? 'Ναι' : 'Yes';
String _no(bool inGreek) => inGreek ? 'Όχι' : 'No';
