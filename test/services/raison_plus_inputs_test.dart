import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/services/raison_plus_inputs.dart';

void main() {
  group('RaisonPlusInputs.dataFrom', () {
    test('sends nothing for an empty questionnaire', () {
      expect(RaisonPlusInputs.dataFrom({}), isEmpty);
    });

    test('maps the core motor symptoms', () {
      final data = RaisonPlusInputs.dataFrom({
        'A1': true,
        'A2': true,
        'A3': false,
        'AA': 'AA2',
      });
      expect(data['tremor'], 'yes');
      expect(data['bradykinesia'], 'yes');
      expect(data.containsKey('rigidity'), isFalse);
      expect(data['writing_coffee'], 'with_difficulty');
    });

    test('writing and coffee without difficulty sends nothing', () {
      expect(
        RaisonPlusInputs.dataFrom({'AA': 'AA1'}).containsKey('writing_coffee'),
        isFalse,
      );
      expect(
        RaisonPlusInputs.dataFrom({'AA': 'AA3'})['writing_coffee'],
        'not_at_all',
      );
    });

    test('a "no" answer is left out rather than sent', () {
      final data = RaisonPlusInputs.dataFrom({'A1': false, 'G1u': false});
      expect(data, isEmpty);
    });

    test('rigidity combinations need rigidity and tremor or bradykinesia', () {
      expect(
        RaisonPlusInputs.dataFrom({'A1': true, 'A2': true})
            .containsKey('rigidity_with_tremor_or_bradykinesia'),
        isFalse,
      );
      final data = RaisonPlusInputs.dataFrom({
        'A3': true,
        'A1': true,
        'RBD_q': true,
        'Memory_Disorder': true,
        'Urgent_Urination': true,
      });
      expect(data['rigidity_with_tremor_or_bradykinesia'], 'yes');
      expect(data['rigidity_tremor_brady_rbd'], 'yes');
      expect(data['rigidity_tremor_brady_memory_urinary'], 'yes');
      expect(data['memory_rigidity_tremor_brady'], 'yes');
    });

    test('instability and weakness combinations', () {
      final data = RaisonPlusInputs.dataFrom({
        'Instability': true,
        'A2': true,
        'Dysarthria': true,
        'Limb_Weakness': true,
        'Behavior_Change': true,
      });
      expect(data['instability_tremor_brady_rigidity'], 'yes');
      expect(data['instability_dysarthria'], 'yes');
      expect(data['limb_weakness_dysarthria'], 'yes');
      expect(data['limb_weakness_dysarthria_behavioural'], 'yes');
    });

    test('age is sent only below 50 or above 80', () {
      expect(RaisonPlusInputs.dataFrom({'X': 49})['age'], 'below_50');
      expect(RaisonPlusInputs.dataFrom({'X': 50}).containsKey('age'), isFalse);
      expect(RaisonPlusInputs.dataFrom({'X': 80}).containsKey('age'), isFalse);
      expect(RaisonPlusInputs.dataFrom({'X': 81})['age'], 'above_80');
    });

    test('investigation results map to pathological or not', () {
      final data = RaisonPlusInputs.dataFrom({
        'D1a': 'D1a2',
        'D1z': 'D1z1',
        'D1o': 'D1oa',
      });
      expect(data['brain_mri'], 'not_pathological');
      expect(data['datscan'], 'pathological');
      expect(data['emg_ncs'], 'pathological');
      expect(
        RaisonPlusInputs.dataFrom({'D1o': 'D1ob'}).containsKey('emg_ncs'),
        isFalse,
      );
    });

    test('medication and family history', () {
      final data = RaisonPlusInputs.dataFrom({
        'G1u': true,
        'B1': true,
        'B2': true,
        'B3': true,
      });
      expect(data['takes_antipsychotics'], 'yes');
      expect(data['fh_parkinsonism_instability'], 'yes');
      expect(data['fh_dementia'], 'yes');
      expect(data['fh_psychiatric'], 'yes');
    });

    test('GDS is sent above 7 points', () {
      // n answers pointing to depression: no to a positive item, yes to the
      // others.
      Map<String, dynamic> gds(int n) => {
            for (final k in RaisonPlusInputs.gdsKeys.take(n))
              k: !RaisonPlusInputs.gdsReversedKeys.contains(k),
          };
      expect(RaisonPlusInputs.dataFrom(gds(7)).containsKey('gds_score'),
          isFalse);
      expect(RaisonPlusInputs.dataFrom(gds(8))['gds_score'], 'above_7');
    });

    test('GDS scores the five positive items when answered no', () {
      // Satisfied, in good spirits, happy, glad to be alive, full of energy:
      // all yes is not depression.
      final cheerful = {
        for (final k in RaisonPlusInputs.gdsKeys)
          k: RaisonPlusInputs.gdsReversedKeys.contains(k),
      };
      expect(RaisonPlusInputs.gdsCount(cheerful), 0);
      expect(
        RaisonPlusInputs.gdsCount({
          for (final k in RaisonPlusInputs.gdsReversedKeys) k: false,
        }),
        5,
      );
    });

    test('RBD is sent above 6, counting the condition list once', () {
      Map<String, dynamic> rbd(int n) => {
            for (final k in RaisonPlusInputs.rbdKeys.take(n)) k: true,
          };
      expect(RaisonPlusInputs.dataFrom(rbd(6)).containsKey('rbd_score'),
          isFalse);
      expect(RaisonPlusInputs.dataFrom(rbd(7))['rbd_score'], 'above_6');
      expect(
        RaisonPlusInputs.dataFrom({
          ...rbd(6),
          'D1p5x': ['D1p5x_a', 'D1p5x_b'],
        })['rbd_score'],
        'above_6',
      );
      expect(
        RaisonPlusInputs.dataFrom({
          ...rbd(6),
          'D1p5x': ['D1p5x_none'],
        }).containsKey('rbd_score'),
        isFalse,
      );
    });

    test('MoCA and FAB come from the cognitive facts', () {
      final data = RaisonPlusInputs.dataFrom({
        RaisonPlusInputs.mocaKey: true,
        RaisonPlusInputs.fabKey: false,
      });
      expect(data['moca_score'], 'below_24');
      expect(data.containsKey('fab_score'), isFalse);
    });

    test('never sends the C9orf72 genetic test', () {
      expect(
        RaisonPlusInputs.dataFrom({'D1n_done': true, 'D1n': 'D1na'})
            .containsKey('genetic_test_c9orf72'),
        isFalse,
      );
    });
  });
}
