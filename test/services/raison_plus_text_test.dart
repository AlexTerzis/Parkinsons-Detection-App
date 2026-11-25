import 'package:flutter_test/flutter_test.dart';
import 'package:parkinsondetetion/services/raison_plus_text.dart';

void main() {
  group('RaisonPlusText', () {
    test('an argument in plain Greek, with the rule kept', () {
      expect(
        RaisonPlusText.line(
          'Visit is supported because Tremor is yes and Writing coffee is '
          'with_difficulty [rule r_v02]',
          greek: true,
        ),
        'Επίσκεψη σε γιατρό, επειδή: τρόμος και γράφει και πίνει καφέ με '
        'δυσκολία (κανόνας r_v02)',
      );
    });

    test('an argument in plain English', () {
      expect(
        RaisonPlusText.line(
          'Visit is supported because Age is below_50 and Rigidity tremor '
          'brady rbd is yes and Rbd score is above_6 [rule r_v20]',
          greek: false,
        ),
        'Visit a doctor because of age under 50, rigidity with tremor or '
        'bradykinesia and REM sleep disorder and RBD score above 6 '
        '(rule r_v20)',
      );
    });

    test('decisions and verdict titles', () {
      expect(RaisonPlusText.label('Do not visit', greek: true),
          'Δεν χρειάζεται επίσκεψη');
      expect(
        RaisonPlusText.label('Multiple equally defensible conclusions',
            greek: true),
        'Εξίσου τεκμηριωμένα αντίθετα συμπεράσματα',
      );
    });

    test('a preference', () {
      expect(
        RaisonPlusText.line(
          'rule p_v06: Visit takes priority over Do not visit (when Tremor is '
          'yes and Brain mri is pathological) [conditional first-level '
          'preference]',
          greek: true,
        ),
        '«Επίσκεψη σε γιατρό» υπερισχύει του «Δεν χρειάζεται επίσκεψη» '
        'όταν: τρόμος και παθολογική MRI εγκεφάλου (προτίμηση p_v06)',
      );
    });

    test('the summary and the possible options', () {
      expect(
        RaisonPlusText.line(
          'In short: Visit — nothing else contests it under the facts '
          'given.',
          greek: true,
        ),
        'Συνοπτικά: Επίσκεψη σε γιατρό. Κανένας κανόνας δεν το αντικρούει '
        'με τα δεδομένα που δόθηκαν.',
      );
      expect(
        RaisonPlusText.line('Also possible: Do not visit, Visit', greek: true),
        'Πιθανά συμπεράσματα: Δεν χρειάζεται επίσκεψη, Επίσκεψη σε γιατρό',
      );
    });

    test('an unknown condition or line is kept, not lost', () {
      expect(
        RaisonPlusText.line(
          'Visit is supported because Something new is maybe [rule r_v99]',
          greek: true,
        ),
        'Επίσκεψη σε γιατρό, επειδή: Something new = maybe (κανόνας r_v99)',
      );
      expect(RaisonPlusText.line('Unexpected text', greek: true),
          'Unexpected text');
    });
  });

  group('RaisonPlusText, for the patient', () {
    test('main reasons: most frequent first, only for that conclusion', () {
      final lines = [
        'A single conclusion is supported.',
        'Visit is supported because Tremor is yes and Writing coffee is '
            'with_difficulty [rule r_v02]',
        'Visit is supported because Age is below_50 and Tremor is yes and '
            'Rigidity is yes [rule r_v16]',
        'Visit is supported because Age is below_50 and Rigidity with tremor '
            'or bradykinesia is yes [rule r_v18]',
        'Do not visit is supported because Takes antipsychotics is yes '
            '[rule r_v01]',
        'Visit is supported because Something new is maybe [rule r_v99]',
      ];
      expect(
        RaisonPlusText.mainReasons('Visit', lines, greek: true, max: 3),
        ['τρόμος', 'ηλικία κάτω των 50', 'γράφει και πίνει καφέ με δυσκολία'],
      );
      expect(
        RaisonPlusText.mainReasons('Do not visit', lines, greek: false),
        ['takes antipsychotics'],
      );
    });

    test('one sentence of advice per decision', () {
      expect(RaisonPlusText.advice('Visit', greek: true),
          'Με βάση τις απαντήσεις σας, καλό είναι να επισκεφθείτε γιατρό.');
      expect(RaisonPlusText.advice('Do not visit', greek: false),
          startsWith('Based on your answers, no visit is needed'));
      expect(
          RaisonPlusText.advice('Multiple equally defensible conclusions',
              greek: true),
          startsWith('Οι απαντήσεις σας δεν οδηγούν σε σαφή σύσταση'));
    });

    test('the "all arguments hold" sentence', () {
      expect(
        RaisonPlusText.line('All fired arguments can hold simultaneously.',
            greek: true),
        'Όλα τα επιχειρήματα που ισχύουν συμφωνούν μεταξύ τους.',
      );
    });
  });

  group('RaisonPlusText, diagnosis agent', () {
    test('diagnoses by name or by id', () {
      expect(RaisonPlusText.label("Parkinson's disease", greek: true),
          'Νόσος Πάρκινσον');
      expect(RaisonPlusText.label('restless_legs_syndrome', greek: true),
          'Σύνδρομο ανήσυχων άκρων');
      expect(RaisonPlusText.label('restless_legs_syndrome', greek: false),
          'Restless legs syndrome');
    });

    test('an argument with the new inputs', () {
      expect(
        RaisonPlusText.line(
          'Restless legs syndrome is supported because Leg jerks lying down '
          'is yes and Sleep study is rls [rule r_d29]',
          greek: true,
        ),
        'Σύνδρομο ανήσυχων άκρων, επειδή: ακούσιες κινήσεις ή τινάγματα των '
        'ποδιών στην κατάκλιση και μελέτη ύπνου με ευρήματα συνδρόμου '
        'ανήσυχων άκρων (κανόνας r_d29)',
      );
    });

    test('conclusions named "Indicate …", as the deployed agent names them',
        () {
      expect(RaisonPlusText.label('Indicate nph', greek: true),
          'Υδροκέφαλος φυσιολογικής πίεσης');
      expect(RaisonPlusText.label('Indicate parkinsons disease', greek: true),
          'Νόσος Πάρκινσον');
      expect(RaisonPlusText.label('Indicate ftd mnd', greek: false),
          'Frontotemporal dementia ± motor neuron disease');
      expect(RaisonPlusText.label('indicate_corticobasal_syndrome',
              greek: true),
          'Φλοιοβασικό σύνδρομο');
      expect(RaisonPlusText.label('Indicate msa', greek: false),
          'Multiple system atrophy');
      expect(RaisonPlusText.label('Indicate psp', greek: true),
          'Υπερπυρηνική προϊούσα παράλυση');
      // An unknown diagnosis is kept, in words.
      expect(RaisonPlusText.label('Indicate something_new', greek: true),
          'Something new');
    });

    test('an argument for an "Indicate …" conclusion with a MoCA band', () {
      expect(
        RaisonPlusText.line(
          'Indicate essential tremor is supported because Tremor is yes and '
          'Moca score is v28_to_30 [rule r_d01]',
          greek: true,
        ),
        'Ιδιοπαθής τρόμος, επειδή: τρόμος και MoCA 28–30 (κανόνας r_d01)',
      );
      expect(
        RaisonPlusText.line('Also possible: Indicate msa, Indicate psp',
            greek: false),
        'Possible conclusions: Multiple system atrophy, '
        'Progressive supranuclear palsy',
      );
    });
  });
}
