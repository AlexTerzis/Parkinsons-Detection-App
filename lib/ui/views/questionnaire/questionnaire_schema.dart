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
      // A1: Τρόμος (Άνω ή Κάτω Άκρα)
  {
    'id': 'A1',
    'section': 'Symptom Assessment',
    'type': 'boolean',
    'label': 'Έχετε τρόμο (Άνω ή Κάτω Άκρα);',
    'validation': {'required': true},
  },

  // A1: πλευρά τρόμου
  {
    'id': 'A1_side',
    'section': 'Symptom Assessment',
    'type': 'radio',
    'label': 'Σε ποια πλευρά εμφανίζεται ο τρόμος;',
    'options': [
      {'value': 'Aa', 'label': 'Δεξιά'},
      {'value': 'Ab',  'label': 'Αριστερά'},
      {'value': 'Ac',  'label': 'Αμφώ'},
    ],
    'validation': {'required': true},
    'dependsOn': {'questionId': 'A1', 'value': true},
  },

  // A1_side → A1_write_coffee
  {
    'id': 'AA',
    'section': 'Symptom Assessment',
    'type': 'radio',
    'label': 'Μπορείτε να γράψετε και να πιείτε καφέ;',
    'options': [
      {'value': 'AA1', 'label': 'Χωρίς δυσκολία'},
      {'value': 'AA2', 'label': 'Με δυσκολία'},
      {'value': 'AA3', 'label': 'Καθόλου'},
    ],
    'validation': {'required': true},
    'dependsOn': {'questionId': 'A1', 'value': true},
  },

  // A2: Βραδυκινησία
  {
    'id': 'A2',
    'section': 'Symptom Assessment',
    'type': 'boolean',
    'label': 'Έχετε βραδυκινησία;',
    'validation': {'required': true},
  },

   // A3: Δυσκαμψία
{
  'id': 'A3',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε δυσκαμψία;',
  'validation': {'required': true},
},

// RBD Study check: pathological sleep study for RBD performed?
{
  'id': 'RBD_study',
  'section': 'Symptom Assessment',
  'type': 'radio',
  'label': 'Έχετε κάνει παθολογική μελέτη ύπνου για RBD διαταραχή;',
  'options': [
    {'value': true, 'label': 'Ναι'},
    {'value': false, 'label': 'Όχι'},
  ],
  'validation': {'required': true},
},

// If study performed, was it positive for RBD?
{
  'id': 'RBD_study_positive',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Η μελέτη ύπνου έδειξε RBD (διαταραχή);',
  'validation': {'required': true},
  'dependsOn': {'questionId': 'RBD_study', 'value': true},
},

// If study not performed, ask questionnaire flag
{
  'id': 'RBD_q',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε συμπτώματα διαταραχής ύπνου REM (π.χ. έντονα όνειρα, κινήσεις);',
  'validation': {'required': true},
  'dependsOn': {'questionId': 'RBD_study', 'value': false},
},
// Memory disorder
{
  'id': 'Memory_Disorder',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε διαταραχή μνήμης;',
  'validation': { 'required': true },
},

// Urgent urination
{
  'id': 'Urgent_Urination',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε επιτακτικές ανάγκες ούρησης;',
  'validation': { 'required': true },
},
// Executive  dysfunction
{
  'id': 'Execute_Disorder',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε δυσεπιτελική δυσλειτουργία (έχω ρούχα μπροστά μου και δεν ξέρω να τα φορέσω);',
  'validation': { 'required': true },
},
// Language dysfunction
{
  'id': 'Language_Disorder',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε διαταραχή λόγου;',
  'validation': { 'required': true },
},

// Behavior change
{
  'id': 'Behavior_Change',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε αλλαγές στη συμπεριφορά σας;',
  'validation': { 'required': true },
},

// Dysarthria
{
  'id': 'Dysarthria',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε δυσαρθρία;',
  'validation': { 'required': true },
},

// Dysphagia
{
  'id': 'Dysphagia',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε δυσκαταποσία;',
  'validation': { 'required': true },
},

// Limb weakness
{
  'id': 'Limb_Weakness',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε αδυναμία στα άνω ή κάτω άκρα;',
  'validation': { 'required': true },
},

// Atrophy
{
  'id': 'Atrophy',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Παρατηρείτε ατροφία στα άνω ή κάτω άκρα;',
  'validation': { 'required': true },
},
// A11_instability: Αστάθεια
{
  'id': 'Instability',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε αστάθεια;',
  'validation': { 'required': true },
},
// A11_falls: Πτώσεις
{
  'id': 'Falls',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε πτώσεις πρόσφατα;',
  'validation': { 'required': true },
},


// Rest movements (involuntary at rest)
{
  'id': 'A16',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Κάνετε ξαφνικές κινήσεις ή τινάγματα όταν ξαπλώνετε;',
  'validation': { 'required': true },
},

// Involuntary posture
{
  'id': 'A17',
  'section': 'Symptom Assessment',
  'type': 'boolean',
  'label': 'Έχετε θέση θέση στα άνω ή κάτω άκρα;',
  'validation': { 'required': true },
},

//----------------Family History-------------------
{
  'id': 'B',
  'section': 'Family History',
  'type': 'radio',
  'label': 'Υπάρχει οικογενειακό ιστορικό;',
  'options': [
    {'value': 'yes', 'label': 'Ναι'},
    {'value': 'no',  'label': 'Όχι'},
    {'B7': 'dont_remember', 'label': 'Δεν θυμάμαι'},
  ],
  'validation': {'required': true},
},
{
  'id': 'B1',
  'section': 'Family History',
  'type': 'boolean',
  'label': 'Οικογενειακό ιστορικό παρκινσονισμού;',
  'dependsOn': {'questionId': 'B', 'value': 'yes'},
  'validation': {'required': true},
},
{
  'id': 'B2',
  'section': 'Family History',
  'type': 'boolean',
  'label': 'Οικογενειακό ιστορικό άνοιας;',
  'dependsOn': {'questionId': 'B', 'value': 'yes'},
  'validation': {'required': true},
},
{
  'id': 'B3',
  'section': 'Family History',
  'type': 'boolean',
  'label': 'Οικογενειακό ιστορικό ψυχιατρικής νόσου;',
  'dependsOn': {'questionId': 'B', 'value': 'yes'},
  'validation': {'required': true},
},

];
