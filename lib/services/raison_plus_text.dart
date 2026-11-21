/// Plain-language wording for what rAIson+ returns.
///
/// rAIson+ explains with the agent's input names and values — "Writing coffee
/// is with_difficulty and Rigidity tremor brady rbd is yes [rule r_v19]" — and
/// always in English. The screens show it in the app's language, with each
/// condition said the way the questionnaire asks it, and the rule id kept so a
/// clinician can trace the rule.
///
/// Only lines whose shape is known are rewritten; anything else is shown as
/// rAIson+ sent it, so a change on their side degrades to English, not to a
/// missing line.
class RaisonPlusText {
  RaisonPlusText._();

  /// A decision or verdict title, e.g. `Visit` → `Επίσκεψη σε γιατρό`.
  static String label(String text, {required bool greek}) {
    final t = text.trim();
    return (greek ? _labelsEl : _labelsEn)[t] ?? t;
  }

  /// One explanation line in plain words.
  static String line(String text, {required bool greek}) {
    final t = text.trim();
    final fixed = (greek ? _sentencesEl : _sentencesEn)[t];
    if (fixed != null) return fixed;

    final arg = _argument.firstMatch(t);
    if (arg != null) {
      final what = label(arg.group(1)!, greek: greek);
      final why = conditions(arg.group(2)!, greek: greek);
      final rule = arg.group(3)!;
      return greek
          ? '$what, επειδή: $why (κανόνας $rule)'
          : '$what because of $why (rule $rule)';
    }

    final pref = _preference.firstMatch(t);
    if (pref != null) {
      final id = pref.group(1)!;
      final winner = label(pref.group(2)!, greek: greek);
      final loser = label(pref.group(3)!, greek: greek);
      final cond = conditions(pref.group(4)!, greek: greek);
      return greek
          ? '«$winner» υπερισχύει του «$loser» όταν: $cond (προτίμηση $id)'
          : '"$winner" takes priority over "$loser" when: $cond '
              '(preference $id)';
    }

    final out = _ruledOut.firstMatch(t);
    if (out != null) {
      final id = out.group(1)!;
      final what = label(out.group(2)!, greek: greek);
      return greek
          ? 'Ο κανόνας $id («$what») απορρίπτεται, γιατί υπερισχύει προτίμηση.'
          : 'Rule $id ("$what") is overruled by a preference.';
    }

    final under = _under.firstMatch(t);
    if (under != null) {
      final cond = conditions(under.group(1)!, greek: greek);
      final what = label(under.group(2)!, greek: greek);
      return greek ? 'Όταν $cond → $what.' : 'When $cond → $what.';
    }

    final also = _alsoPossible.firstMatch(t);
    if (also != null) {
      final options = also
          .group(1)!
          .split(', ')
          .map((o) => label(o, greek: greek))
          .join(', ');
      return greek
          ? 'Πιθανά συμπεράσματα: $options'
          : 'Possible conclusions: $options';
    }

    final short = _inShort.firstMatch(t);
    if (short != null) {
      final what = label(short.group(1)!, greek: greek);
      return greek
          ? 'Συνοπτικά: $what. Κανένας κανόνας δεν το αντικρούει με τα '
              'δεδομένα που δόθηκαν.'
          : 'In short: $what. No rule contests it with the facts given.';
    }

    return t;
  }

  /// "A is x and B is y" → "a, b" in plain words, the last joined with "and".
  static String conditions(String text, {required bool greek}) {
    final parts = [
      for (final c in text.split(' and '))
        if (c.trim().isNotEmpty) _condition(c.trim(), greek: greek),
    ];
    if (parts.length < 2) return parts.join();
    final joiner = greek ? ' και ' : ' and ';
    return '${parts.sublist(0, parts.length - 1).join(', ')}$joiner${parts.last}';
  }

  static String _condition(String c, {required bool greek}) {
    final m = RegExp(r'^(.+) is (\S+)$').firstMatch(c);
    if (m == null) return c;
    final key = '${m.group(1)}|${m.group(2)}';
    return (greek ? _conditionsEl : _conditionsEn)[key] ??
        '${m.group(1)} = ${m.group(2)}';
  }

  static final _argument =
      RegExp(r'^(.+?) is supported because (.+) \[rule (\S+)\]$');
  static final _preference = RegExp(
      r'^rule (\S+): (.+?) takes priority over (.+?) \(when (.+)\)( \[.*\])?$');
  static final _ruledOut = RegExp(r'^(\S+) is ruled out \((.+?)\)');
  static final _under = RegExp(r'^Under: (.+) → (.+?)\.?$');
  static final _alsoPossible = RegExp(r'^Also possible: (.+)$');
  static final _inShort = RegExp(r'^In short: (.+?) — nothing else');

  static const _labelsEl = <String, String>{
    'Visit': 'Επίσκεψη σε γιατρό',
    'Do not visit': 'Δεν χρειάζεται επίσκεψη',
    'Conclusion': 'Συμπέρασμα',
    'Multiple equally defensible conclusions':
        'Εξίσου τεκμηριωμένα αντίθετα συμπεράσματα',
    'No matching rule': 'Κανένας κανόνας δεν ταιριάζει',
  };

  static const _labelsEn = <String, String>{
    'Visit': 'Visit a doctor',
    'Do not visit': 'No visit needed',
  };

  static const _sentencesEl = <String, String>{
    'A single conclusion is supported.': 'Υποστηρίζεται ένα μόνο συμπέρασμα.',
    'No preference resolves which one is preferred. '
            'Additional information is needed.':
        'Καμία προτίμηση δεν ορίζει ποιο υπερισχύει. '
            'Χρειάζονται περισσότερες πληροφορίες.',
    "No rule's body fires under the asserted atoms.":
        'Κανένας κανόνας δεν ισχύει με τις απαντήσεις που δόθηκαν.',
  };

  static const _sentencesEn = <String, String>{};

  static const _conditionsEl = <String, String>{
    'Tremor|yes': 'τρόμος',
    'Bradykinesia|yes': 'βραδυκινησία',
    'Rigidity|yes': 'δυσκαμψία',
    'Memory disorder|yes': 'διαταραχή μνήμης',
    'Writing coffee|with_difficulty': 'γράφει και πίνει καφέ με δυσκολία',
    'Writing coffee|not_at_all': 'δεν μπορεί να γράψει ούτε να πιει καφέ',
    'Takes antipsychotics|yes': 'λήψη αντιψυχωσικών',
    'Age|below_50': 'ηλικία κάτω των 50',
    'Age|above_80': 'ηλικία άνω των 80',
    'Brain mri|pathological': 'παθολογική MRI εγκεφάλου',
    'Brain mri|not_pathological': 'φυσιολογική MRI εγκεφάλου',
    'Datscan|pathological': 'παθολογικό DaTSCAN',
    'Datscan|not_pathological': 'φυσιολογικό DaTSCAN',
    'Emg ncs|pathological': 'παθολογικό ΗΜΓ/ΗΝΓ',
    'Genetic test c9orf72|done': 'γενετικός έλεγχος C9orf72',
    'Fh parkinsonism instability|yes': 'οικογενειακό ιστορικό παρκινσονισμού',
    'Fh dementia|yes': 'οικογενειακό ιστορικό άνοιας',
    'Fh psychiatric|yes': 'οικογενειακό ιστορικό ψυχιατρικής νόσου',
    'Rigidity with tremor or bradykinesia|yes':
        'δυσκαμψία μαζί με τρόμο ή βραδυκινησία',
    'Rigidity tremor brady rbd|yes':
        'δυσκαμψία με τρόμο ή βραδυκινησία και διαταραχή ύπνου REM',
    'Rigidity tremor brady memory urinary|yes':
        'δυσκαμψία με τρόμο ή βραδυκινησία, διαταραχή μνήμης και '
            'επιτακτική ούρηση',
    'Memory rigidity tremor brady|yes':
        'διαταραχή μνήμης με δυσκαμψία και τρόμο ή βραδυκινησία',
    'Instability tremor brady rigidity|yes':
        'αστάθεια με τρόμο, βραδυκινησία ή δυσκαμψία',
    'Instability dysarthria|yes': 'αστάθεια με δυσαρθρία',
    'Limb weakness dysarthria|yes': 'αδυναμία άκρων με δυσαρθρία',
    'Limb weakness dysarthria behavioural|yes':
        'αδυναμία άκρων, δυσαρθρία και αλλαγή συμπεριφοράς',
    'Rbd score|above_6': 'βαθμολογία RBD πάνω από 6',
    'Gds score|above_7': 'βαθμολογία GDS πάνω από 7',
    'Moca score|below_24': 'MoCA κάτω από 24',
    'Fab score|below_12': 'FAB κάτω από 12',
  };

  static const _conditionsEn = <String, String>{
    'Tremor|yes': 'tremor',
    'Bradykinesia|yes': 'bradykinesia',
    'Rigidity|yes': 'rigidity',
    'Memory disorder|yes': 'memory problems',
    'Writing coffee|with_difficulty': 'difficulty writing and drinking coffee',
    'Writing coffee|not_at_all': 'cannot write or drink coffee',
    'Takes antipsychotics|yes': 'takes antipsychotics',
    'Age|below_50': 'age under 50',
    'Age|above_80': 'age over 80',
    'Brain mri|pathological': 'abnormal brain MRI',
    'Brain mri|not_pathological': 'normal brain MRI',
    'Datscan|pathological': 'abnormal DaTSCAN',
    'Datscan|not_pathological': 'normal DaTSCAN',
    'Emg ncs|pathological': 'abnormal EMG/NCS',
    'Genetic test c9orf72|done': 'C9orf72 genetic test',
    'Fh parkinsonism instability|yes': 'family history of parkinsonism',
    'Fh dementia|yes': 'family history of dementia',
    'Fh psychiatric|yes': 'family history of psychiatric illness',
    'Rigidity with tremor or bradykinesia|yes':
        'rigidity with tremor or bradykinesia',
    'Rigidity tremor brady rbd|yes':
        'rigidity with tremor or bradykinesia and REM sleep disorder',
    'Rigidity tremor brady memory urinary|yes':
        'rigidity with tremor or bradykinesia, memory problems and urinary '
            'urgency',
    'Memory rigidity tremor brady|yes':
        'memory problems with rigidity and tremor or bradykinesia',
    'Instability tremor brady rigidity|yes':
        'instability with tremor, bradykinesia or rigidity',
    'Instability dysarthria|yes': 'instability with dysarthria',
    'Limb weakness dysarthria|yes': 'limb weakness with dysarthria',
    'Limb weakness dysarthria behavioural|yes':
        'limb weakness, dysarthria and behaviour change',
    'Rbd score|above_6': 'RBD score above 6',
    'Gds score|above_7': 'GDS score above 7',
    'Moca score|below_24': 'MoCA below 24',
    'Fab score|below_12': 'FAB below 12',
  };
}
