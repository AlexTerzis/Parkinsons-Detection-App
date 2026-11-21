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
  });
}
