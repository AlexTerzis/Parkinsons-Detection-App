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
/// The same answers feed a second agent, the diagnosis agent built from the
/// sheet «Διαγνώσεις», which shares most input names. [dataFrom] builds every
/// input either agent knows; [forAgent] keeps the ones one agent accepts.
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

  /// Key under which `CognitiveFacts` keeps the scores the facts came from.
  static const String cognitiveMetaKey = 'cognitiveInputs';

  /// Inputs and values of the visit agent (its `/schema`, 21 Nov 2026).
  static const Map<String, Set<String>> visitInputs = {
    'tremor': {'yes'},
    'takes_antipsychotics': {'yes'},
    'writing_coffee': {'with_difficulty', 'not_at_all'},
    'brain_mri': {'pathological', 'not_pathological'},
    'datscan': {'pathological', 'not_pathological'},
    'age': {'below_50', 'above_80'},
    'bradykinesia': {'yes'},
    'fh_parkinsonism_instability': {'yes'},
    'fh_dementia': {'yes'},
    'rigidity': {'yes'},
    'rigidity_with_tremor_or_bradykinesia': {'yes'},
    'rigidity_tremor_brady_rbd': {'yes'},
    'rbd_score': {'above_6'},
    'moca_score': {'below_24'},
    'fab_score': {'below_12'},
    'rigidity_tremor_brady_memory_urinary': {'yes'},
    'memory_rigidity_tremor_brady': {'yes'},
    'gds_score': {'above_7'},
    'memory_disorder': {'yes'},
    'instability_tremor_brady_rigidity': {'yes'},
    'instability_dysarthria': {'yes'},
    'limb_weakness_dysarthria': {'yes'},
    'emg_ncs': {'pathological'},
    'genetic_test_c9orf72': {'done'},
    'limb_weakness_dysarthria_behavioural': {'yes'},
    'fh_psychiatric': {'yes'},
  };

  /// Inputs and values of the diagnosis agent (agent 43141074d002, built
  /// from diagnosis_scenario_30_rules.txt). The builder prefixes values that
  /// start with a digit with `v`, so the MoCA bands are `v24_to_27` and
  /// `v28_to_30`.
  static const Map<String, Set<String>> diagnosisInputs = {
    'tremor': {'yes'},
    'writing_coffee': {'with_difficulty', 'not_at_all'},
    'rigidity': {'yes'},
    'bradykinesia': {'yes'},
    'fh_other_not_parkinsonism': {'yes'},
    'moca_score': {'below_24', 'v24_to_27', 'v28_to_30'},
    'brain_mri': {'pathological', 'not_pathological'},
    'takes_antipsychotics': {'yes'},
    'scopa_score': {'above_3'},
    'rbd_score': {'above_6'},
    'sleep_study': {'rbd', 'rls'},
    'rigidity_with_tremor_or_bradykinesia': {'yes'},
    'fh_parkinsonism_instability': {'yes'},
    'datscan': {'pathological'},
    'genetic_test': {'pathological'},
    'rigidity_tremor_brady_rbd': {'yes'},
    'rigidity_tremor_brady_memory_urinary': {'yes'},
    'fab_score': {'below_12'},
    'memory_rigidity_tremor_brady': {'yes'},
    'instability_tremor_brady_rigidity': {'yes'},
    'instability_dysarthria': {'yes'},
    'applause_sign': {'pathological'},
    'limb_weakness_dysarthria': {'yes'},
    'limb_weakness_dysarthria_behavioural': {'yes'},
    'fh_psychiatric': {'yes'},
    'fh_dementia': {'yes'},
    'emg_ncs': {'pathological'},
    'genetic_test_c9orf72': {'done'},
    'leg_jerks_lying_down': {'yes'},
    'agonist_response': {'good'},
    'low_iron_ferritin': {'yes'},
    'dystonic_posture': {'yes'},
  };

  /// The part of [data] that an agent with [inputs] accepts: known names with
  /// a value the agent knows. An unknown value is left out, not sent.
  static Map<String, String> forAgent(
    Map<String, String> data,
    Map<String, Set<String>> inputs,
  ) =>
      {
        for (final e in data.entries)
          if (inputs[e.key]?.contains(e.value) ?? false) e.key: e.value,
      };

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

    // Cognitive tests taken in the app (see CognitiveFacts). The MoCA band
    // comes from the total when it is stored, otherwise from the fact.
    final band = mocaBand(answers);
    if (band != null) {
      data['moca_score'] = band;
    } else {
      put('moca_score', yes(mocaKey), 'below_24');
    }
    put('fab_score', yes(fabKey), 'below_12');

    // Inputs only the diagnosis agent uses.
    put('dystonic_posture', yes('A17'));
    put('leg_jerks_lying_down', yes('A16'));
    switch (answers['D1l']) {
      case 'D1l1':
        data['sleep_study'] = 'rbd';
      case 'D1l6':
        data['sleep_study'] = 'rls';
    }
    put('agonist_response', answers['G1aI'] == 'G1aI2', 'good');
    put('genetic_test', answers['D1n'] == 'D1na', 'pathological');
    // Β4: no parkinsonism in the family, but dementia and psychiatric
    // disease; the questionnaire's own B4 flag reads it the same way.
    put('fh_other_not_parkinsonism',
        answers['B1'] == false && yes('B2') && yes('B3'));
    final scopa = answers['SCOPA_total'];
    put('scopa_score', scopa is num && scopa > 3, 'above_3');
    // Not collected by the app, so never sent: applause_sign,
    // low_iron_ferritin (blood test results), genetic_test_c9orf72.

    return data;
  }

  /// The MoCA band of the stored total, named as the diagnosis agent names
  /// it: `below_24`, `v24_to_27` or `v28_to_30`. Null when no total is
  /// stored.
  static String? mocaBand(Map<String, dynamic> answers) {
    final meta = answers[cognitiveMetaKey];
    final total = meta is Map ? meta['mocaScore'] : null;
    if (total is! num) return null;
    if (total < 24) return 'below_24';
    if (total < 28) return 'v24_to_27';
    return 'v28_to_30';
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
