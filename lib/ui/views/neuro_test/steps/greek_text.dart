/// Folds a Greek string down to the form the assessments compare against.
///
/// Strips accents, normalises final sigma, drops everything that is not a
/// letter, and upper-cases the result — so "Μαργαρίτα!", "μαργαριτα" and
/// "ΜΑΡΓΑΡΙΤΑ" all match. Speech recognition returns accents inconsistently and
/// patients type without them, so a raw `==` would fail answers that are right.
///
/// Was copy-pasted into `immediate_recall.dart` and `delayed_recall.dart`
/// verbatim, with a third, differently-behaved variant in `similarities.dart`.
String normalizeGreek(String s) {
  const accents = {
    'ά': 'α', 'έ': 'ε', 'ή': 'η', 'ί': 'ι', 'ό': 'ο', 'ύ': 'υ', 'ώ': 'ω',
    'ϊ': 'ι', 'ΐ': 'ι', 'ϋ': 'υ', 'ΰ': 'υ', 'ς': 'σ',
    'Ά': 'Α', 'Έ': 'Ε', 'Ή': 'Η', 'Ί': 'Ι', 'Ό': 'Ο', 'Ύ': 'Υ', 'Ώ': 'Ω',
    'Ϊ': 'Ι', 'Ϋ': 'Υ',
  };

  final buffer = StringBuffer();
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(accents[ch] ?? ch);
  }

  return buffer
      .toString()
      .replaceAll(RegExp(r'[^\p{L}]', unicode: true), '')
      .toUpperCase()
      .trim();
}
