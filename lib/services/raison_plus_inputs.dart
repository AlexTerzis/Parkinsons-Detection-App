/// Turns the app's questionnaire answers into the inputs of the rAIson+
/// agent `AI_diagnosis_of_PD_visit_rules_rAIson_no_dilemma` (1cf91fc368ae).
///
/// The agent names its inputs in plain words (`tremor`, `datscan`, ...), while
/// the questionnaire stores answers under the spreadsheet's field IDs (`A1`,
/// `D1z`, ...). Everything is derived here from the raw answers, not from the
/// composite flags the questionnaire also stores (`A5`, `D1p51V`, ...), so a
/// questionnaire saved by an older version of the app gives the same inputs.
///
/// An input is sent only when the answer supports it. A missing answer, or a
/// value the agent has no word for, leaves the input out, so the rules that
/// need it do not apply. Sending `no` would claim something nobody answered.
///
/// Pure functions of their arguments, so they can be tested without Firebase.
class RaisonPlusInputs {
  RaisonPlusInputs._();

  /// GDS-15 items, one boolean each.
  static const List<String> gdsKeys = [
    'D1p3i', 'D1p3ii', 'D1p3iii', 'D1p3iv', 'D1p3v',
    'D1p3vi', 'D1p3vii', 'D1p3viii', 'D1p3ix', 'D1p3x',
    'D1p3xi', 'D1p3xii', 'D1p3xiii', 'D1p3xiv', 'D1p3xv',
  ];

  /// RBD screening items, one boolean each. `D1p5x` is a multi-select and is
  /// counted separately, see [rbdCount].
  static const List<String> rbdKeys = [
    'D1p5i', 'D1p5ii', 'D1p5iii', 'D1p5iv', 'D1p5v',
    'D1p5via', 'D1p5vib', 'D1p5vic', 'D1p5vid', 'D1p5vii',
    'D1p5viii', 'D1p5ix',
  ];

  /// Key of the fact "MoCA below 24", written by `CognitiveFacts`.
  static const String mocaKey = 'D1p11I';

  /// Key of the fact "FAB below 12", written by `CognitiveFacts`.
  static const String fabKey = 'D1p21II';

  /// The `data` object of a `/reason` request for [answers].
  static Map<String, String> dataFrom(Map<String, dynamic> answers) {
    bool yes(String key) => answers[key] == true;

    final tremor = yes('A1');
    final brady = yes('A2');
    final rigidity = yes('A3');
    final memory = yes('Memory_Disorder');
    final instability = yes('Instability');
    final dysarthria = yes('Dysarthria');
    final weakness = yes('Limb_Weakness');

    // Rigidity together with tremor or bradykinesia: the questionnaire's A5.
    final rigidityPlus = rigidity && (tremor || brady);
    final rbdSymptoms = yes('RBD_study_positive') || yes('RBD_q');

    final data = <String, String>{};
    void put(String name, bool when, [String value = 'yes']) {
      if (when) data[name] = value;
    }

    // Symptoms.
    put('tremor', tremor);
    put('bradykinesia', brady);
    put('rigidity', rigidity);
    put('memory_disorder', memory);
    switch (answers['AA']) {
      case 'AA2':
        data['writing_coffee'] = 'with_difficulty';
      case 'AA3':
        data['writing_coffee'] = 'not_at_all';
    }

    // Combinations, named as the agent names them.
    put('rigidity_with_tremor_or_bradykinesia', rigidityPlus);
    put('rigidity_tremor_brady_rbd', rigidityPlus && rbdSymptoms);
    put(
      'rigidity_tremor_brady_memory_urinary',
      rigidityPlus && memory && yes('Urgent_Urination'),
    );
    put('memory_rigidity_tremor_brady', memory && rigidityPlus);
    put('instability_tremor_brady_rigidity',
        instability && (tremor || brady || rigidity));
    put('instability_dysarthria', instability && dysarthria);
    put('limb_weakness_dysarthria', weakness && dysarthria);
    put(
      'limb_weakness_dysarthria_behavioural',
      weakness && dysarthria && yes('Behavior_Change'),
    );

    // Medication and family history.
    put('takes_antipsychotics', yes('G1u'));
    put('fh_parkinsonism_instability', yes('B1'));
    put('fh_dementia', yes('B2'));
    put('fh_psychiatric', yes('B3'));

    // Age, only at the two bands the agent knows.
    final age = answers['X'];
    if (age is num) {
      if (age < 50) data['age'] = 'below_50';
      if (age > 80) data['age'] = 'above_80';
    }

    // Investigations.
    final mri = _finding(answers['D1a'], 'D1a1', 'D1a2');
    if (mri != null) data['brain_mri'] = mri;
    final datscan = _finding(answers['D1z'], 'D1z1', 'D1z2');
    if (datscan != null) data['datscan'] = datscan;
    // The agent only knows a pathological EMG/NCS.
    put('emg_ncs', answers['D1o'] == 'D1oa', 'pathological');
    // `genetic_test_c9orf72` is not sent: the questionnaire asks whether a
    // genetic or molecular test was done, not whether it was for C9orf72.

    // Scales.
    put('gds_score', gdsCount(answers) > 7, 'above_7');
    put('rbd_score', rbdCount(answers) > 6, 'above_6');

    // Cognitive tests taken in the app (see CognitiveFacts).
    put('moca_score', yes(mocaKey), 'below_24');
    put('fab_score', yes(fabKey), 'below_12');

    return data;
  }

  /// GDS-15 items phrased positively ("Are you basically satisfied with your
  /// life?"), where the answer that counts towards depression is *no*.
  static const Set<String> gdsReversedKeys = {
    'D1p3i', 'D1p3v', 'D1p3vii', 'D1p3xi', 'D1p3xiii',
  };

  /// GDS-15 score: one point per answer pointing to depression — yes for the
  /// ten negatively phrased items, no for the five in [gdsReversedKeys].
  /// An unanswered item scores nothing.
  ///
  /// The questionnaire's own `D1p3a` flag counts yes answers only, so a
  /// cheerful patient scores high on the five positive items; that is the
  /// reversal noted in the cleaned visit-rules workbook (open question 12).
  static int gdsCount(Map<String, dynamic> answers) => gdsKeys
      .where((k) => answers[k] == !gdsReversedKeys.contains(k))
      .length;

  /// RBD items answered yes, plus one if any condition other than "none" was
  /// picked in `D1p5x`. The same count the questionnaire uses for `D1p51V`.
  static int rbdCount(Map<String, dynamic> answers) {
    final picked = answers['D1p5x'];
    final conditions =
        picked is List ? picked.map((e) => '$e').toList() : const <String>[];
    final anyCondition =
        conditions.isNotEmpty && !conditions.contains('D1p5x_none');
    return rbdKeys.where((k) => answers[k] == true).length +
        (anyCondition ? 1 : 0);
  }

  static String? _finding(dynamic value, String pathological, String normal) {
    if (value == pathological) return 'pathological';
    if (value == normal) return 'not_pathological';
    return null;
  }
}
