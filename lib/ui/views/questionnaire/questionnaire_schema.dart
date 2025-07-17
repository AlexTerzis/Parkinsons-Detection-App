const List<Map<String, dynamic>> questionnaireSchema = [
  // W: Ποιο είναι το φύλο σας;
   // W: Ποιο είναι το φύλο σας;
  {
    'id': 'W',
    'section': 'Demographics',
    'type': 'radio',
    'label': 'Ποιο είναι το φύλο σας;',
    'options': [
      {'value': 'W1', 'label': 'Άνδρας'},  // W1
      {'value': 'W2', 'label': 'Γυναίκα'}, // W2
    ],
    'validation': {'required': true},
  },

  // X: Ποια είναι η ηλικία σας;  ← now as slider
  {
    'id': 'X',
    'section': 'Demographics',
    'type': 'slider',
    'label': 'Ποια είναι η ηλικία σας;',
    'min': 18,
    'max': 100,
    'validation': {'required': true},
  },

  // Y: Πόσα έτη εκπαίδευσης έχετε;
  {
    'id': 'Y',
    'section': 'Demographics',
    'type': 'slider',
    'label': 'Πόσα έτη εκπαίδευσης έχετε;', 
    'min': 0,
    'max': 20,
    'validation': {'required': true},
  },

  // Z: Ποια είναι η ευχειρία σας;
  {
    'id': 'Z',
    'section': 'Demographics',
    'type': 'radio',
    'label': 'Ποια είναι η ευχειρία σας;',
    'options': [
      {'value': 'Z1', 'label': 'Δεξιοχείρ'},
      {'value': 'Z2',  'label': 'Αριστεροχείρ'},
      {'value': 'Z3',  'label': 'Αμφίχειρ'},
    ],
    'validation': {'required': true},
  },

  // … the rest of your schema …
];
