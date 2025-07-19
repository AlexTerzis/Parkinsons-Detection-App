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
    'label': 'Είστε δεξιόχειρας ή Αριστερόχειρας;',
    'options': [
      {'value': 'Z1', 'label': 'Δεξιοχείρας'},
      {'value': 'Z2', 'label': 'Αριστερόχειρας'},
      {'value': 'Z3', 'label': 'Αμφίχειρας'},
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
  //----------------C-----------------------------
    // Medication Section
    // Γ: Παίρνετε φάρμακα αυτή τη στιγμή;
    {
      'id': 'G',
      'section': 'Medication',
      'type': 'radio',
      'label': 'Παίρνετε φάρμακα αυτή τη στιγμή;',
      'options': [
        {'value': 'G1', 'label': 'Ναι'},
        {'value': 'G2', 'label': 'Όχι'},
      ],
      'validation': {'required': true},
    },
    // Γ1α: Ντοπαμινεργικοί αγωνιστές
    {
      'id': 'G1a',
      'section': 'Medication',
      'type': 'boolean',
      'label': 'Ντοπαμινεργικοί αγωνιστές;',
      'dependsOn': {'questionId': 'G', 'value': 'G1'},
      'validation': {'required': true},
    },
    
    // Γ1aΙ: Ανταπόκριση στη λεβοντόπα
    {
      'id': 'G1aI',
      'section': 'Medication',
      'type': 'radio',
      'label': 'Ανταπόκριση στους ντοπαμινεργικούς αγωνιστές;',
      'options': [
        {'value': 'G1aI1', 'label': 'Όχι'},
        {'value': 'G1aI3', 'label': 'Ναι, μετρίως'},
        {'value': 'G1aI2', 'label': 'Ναι, πολύ'},
      ],
      'dependsOn': {'questionId': 'G1a', 'value': true},
      'validation': {'required': true},
    },
    // Γ1β: Λεβοντόπα
    {
      'id': 'G1b',
      'section': 'Medication',
      'type': 'boolean',
      'label': 'Λεβοντόπα;',
      'dependsOn': {'questionId': 'G', 'value': 'G1'},
      'validation': {'required': true},
    },
    // Γ1γ: Αναστολείς ΜΑΟ
    {
      'id': 'G1g',
      'section': 'Medication',
      'type': 'boolean',
      'label': 'Αναστολείς ΜΑΟ;',
      'dependsOn': {'questionId': 'G', 'value': 'G1'},
      'validation': {'required': true},
    },
    // Γ1δ: Αναστολείς COMT
    {
      'id': 'G1d',
      'section': 'Medication',
      'type': 'boolean',
      'label': 'Αναστολείς COMT;',
      'dependsOn': {'questionId': 'G', 'value': 'G1'},
      'validation': {'required': true},
    },
    // Γ1ε: Αναστολείς χολινεστεράσης
    {
      'id': 'G1e',
      'section': 'Medication',
      'type': 'boolean',
      'label': 'Αναστολείς χολινεστεράσης;',
      'dependsOn': {'questionId': 'G', 'value': 'G1'},
      'validation': {'required': true},
    },
    // Γ1στ: NMDA ανταγωνιστές
    {
      'id': 'G1st',
      'section': 'Medication',
      'type': 'boolean',
      'label': 'NMDA ανταγωνιστές;',
      'dependsOn': {'questionId': 'G', 'value': 'G1'},
      'validation': {'required': true},
    },
    // Γ1η: Αντικαταθλιπτικά
    {
      'id': 'G1h',
      'section': 'Medication',
      'type': 'boolean',
      'label': 'Αντικαταθλιπτικά;',
      'dependsOn': {'questionId': 'G', 'value': 'G1'},
      'validation': {'required': true},
    },
    // Γ1θ: Αντιψυχωσικά/νευροληπτικά
    {
      'id': 'G1u',
      'section': 'Medication',
      'type': 'boolean',
      'label': 'Αντιψυχωσικά/νευροληπτικά;',
      'dependsOn': {'questionId': 'G', 'value': 'G1'},
      'validation': {'required': true},
    },
  //------------Diagnostics----------------
    // D: Έχετε κάνει παρακλινικό έλεγχο;
    {
      'id': 'D',
      'section': 'Clinical',
      'type': 'radio',
      'label': 'Έχετε κάνει παρακλινικό έλεγχο;',
      'options': [
        {'value': 'D1', 'label': 'Ναι'},
        {'value': 'D2', 'label': 'Όχι'},
      ],
      'validation': {'required': true},
    },
    // --- D1α: MRI εγκεφάλου ---
  {
    "id": "D1a_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει MRI εγκεφάλου;",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1a",
    "section": "Clinical",
    "type": "radio",
    "label": "MRI εγκεφάλου αποτελέσματα;",
    "options": [
      { "value": "D1a1", "label": "Παθολογικά ευρήματα" },
      { "value": "D1a2", "label": "Μη παθολογικά ευρήματα" }
    ],
    "dependsOn": { "questionId": "D1a_done", "value": true },
    "validation": { "required": true }
  },

  // --- D1β: MRI ΑΜΣΣ (αυχενική μοίρα) ---
  {
    "id": "D1b_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει MRI ΑΜΣΣ(αυχενική μοίρα της σπονδυλικής στήλης);",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1b",
    "section": "Clinical",
    "type": "radio",
    "label": "MRI ΑΜΣΣ αποτελέσματα;",
    "options": [
      { "value": "D1b1", "label": "Παθολογικά ευρήματα" },
      { "value": "D1b2", "label": "Μη παθολογικά ευρήματα" }
    ],
    "dependsOn": { "questionId": "D1b_done", "value": true },
    "validation": { "required": true }
  },

  // --- D1γ: MRI ΘΜΣΣ (θωρακική μοίρα) ---
  {
    "id": "D1g_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει MRI ΘΜΣΣ (θωρακικής);",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1g",
    "section": "Clinical",
    "type": "radio",
    "label": "MRI ΘΜΣΣ αποτελέσματα;",
    "options": [
      { "value": "D1g1", "label": "Παθολογικά ευρήματα" },
      { "value": "D1g2", "label": "Μη παθολογικά ευρήματα" }
    ],
    "dependsOn": { "questionId": "D1g_done", "value": true },
    "validation": { "required": true }
  },

  // --- D1δ: MRI ΟΜΣΣ (οσφυϊκή μοίρα) ---
  {
    "id": "D1d_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει MRI ΟΜΣΣ (Οσφυικής);",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1d",
    "section": "Clinical",
    "type": "radio",
    "label": "MRI ΟΜΣΣ αποτελέσματα;",
    "options": [
      { "value": "D1d1", "label": "Παθολογικά ευρήματα" },
      { "value": "D1d2", "label": "Μη παθολογικά ευρήματα" }
    ],
    "dependsOn": { "questionId": "D1d_done", "value": true },
    "validation": { "required": true }
  },



  // --- D1ζ: DaTSCAN ---
  {
    "id": "D1z_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει DaTSCAN;",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1z",
    "section": "Clinical",
    "type": "radio",
    "label": "DaTSCAN αποτελέσματα;",
    "options": [
      { "value": "D1z1", "label": "Παθολογικά ευρήματα" },
      { "value": "D1z2", "label": "Μη παθολογικά ευρήματα" }
    ],
    "dependsOn": { "questionId": "D1z_done", "value": true },
    "validation": { "required": true }
  },

  // --- D1η: HMPAO ---
  {
    "id": "D1h_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει HMPAO;",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1h",
    "section": "Clinical",
    "type": "radio",
    "label": "HMPAO αποτελέσματα;",
    "options": [
      { "value": "D1h1", "label": "Παθολογικά ευρήματα" },
      { "value": "D1h2", "label": "Μη παθολογικά ευρήματα" }
    ],
    "dependsOn": { "questionId": "D1h_done", "value": true },
    "validation": { "required": true }
  },

  // --- D1θ: MIBG ---
  {
    "id": "D1u_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει MIBG;",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1u",
    "section": "Clinical",
    "type": "radio",
    "label": "MIBG αποτελέσματα;",
    "options": [
      { "value": "D1u1", "label": "Παθολογικά ευρήματα" },
      { "value": "D1u2", "label": "Μη παθολογικά ευρήματα" }
    ],
    "dependsOn": { "questionId": "D1u_done", "value": true },
    "validation": { "required": true }
  },

  // --- D1κ: Μελέτη ΑΝΣ (αυτόνομο νευρικό σύστημα) ---
  {
    "id": "D1k_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει μελέτη ΑΝΣ (αυτόνομο νευρικό σύστημα);",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1k",
    "section": "Clinical",
    "type": "radio",
    "label": "Μελέτη ΑΝΣ αποτελέσματα;",
    "options": [
      { "value": "D1k1", "label": "Παθολογικά ευρήματα" },
      { "value": "D1k2", "label": "Μη παθολογικά ευρήματα" }
    ],
    "dependsOn": { "questionId": "D1k_done", "value": true },
    "validation": { "required": true }
  },

  // --- D1λ: Μελέτη ύπνου ---
  {
    "id": "D1l_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει μελέτη ύπνου;",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1l",
    "section": "Clinical",
    "type": "radio",
    "label": "Μελέτη ύπνου αποτελέσματα;",
    "options": [
      { "value": "D1l1", "label": "Παθολογικά ευρήματα για RBD" },
      { "value": "D1l2", "label": "Παθολογικά ευρήματα για Άπνοια‑Υπόπνοια" },
      { "value": "D1l3", "label": "Μη παθολογικά ευρήματα" },
      { "value": "D1l5", "label": "Παθολογικά ευρήματα για RBD χωρίς ατονία" },
      { "value": "D1l6", "label": "Παθολογικά ευρήματα για RLS" }
    ],
    "dependsOn": { "questionId": "D1l_done", "value": true },
    "validation": { "required": true }
  },
  {
    "id": "D1l4",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε ανήσυχο ύπνο (κλωτσάτε, πέφτετε από το κρεβάτι);",
    "dependsOn": { "questionId": "D1l_done", "value": "false" },
    "validation": { "required": true }
  },

  // --- D1μ: Αιματολογικός έλεγχος ---
  {
    "id": "D1m_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει αιματολογικό έλεγχο;",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1m",
    "section": "Clinical",
    "type": "radio",
    "label": "Αιματολογικός έλεγχος αποτελέσματα;",
    "options": [
      { "value": "D1m1", "label": "Γενική αίματος" },
      { "value": "D1m2", "label": "Βιοχημικός" },
      { "value": "D1m3", "label": "Δ1μ1+Δ1μ2" },
      { "value": "D1m4", "label": "Ανοσολογικός" },
      { "value": "D1m5", "label": "Παρανεοπλασματικά αντισώματα" },
      { "value": "D1m6", "label": "Συνδυασμός Δ1μ1–Δ1μ5" }
    ],
    "dependsOn": { "questionId": "D1m_done", "value": true },
    "validation": { "required": true }
  },

  // --- D1ν: Γενετικός/μοριακός έλεγχος ---
  {
    "id": "D1n_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει γενετικό/μοριακό έλεγχο;",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1n",
    "section": "Clinical",
    "type": "radio",
    "label": "Γενετικός/μοριακός έλεγχος αποτελέσματα;",
    "options": [
      { "value": "D1na", "label": "Παθολογικά ευρήματα" },
      { "value": "D1nb", "label": "Μη παθολογικά ευρήματα" }
    ],
    "dependsOn": { "questionId": "D1n_done", "value": true },
    "validation": { "required": true }
  },

  // --- D1ξ: Οσφυονωτιαία παρακέντηση ---
  {
    "id": "D1j_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει οσφυονωτιαία παρακέντηση;",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1j",
    "section": "Clinical",
    "type": "radio",
    "label": "Οσφυονωτιαία παρακέντηση αποτελέσματα;",
    "options": [
      { "value": "D1ja", "label": "Παθολογικά ευρήματα" },
      { "value": "D1jb", "label": "Μη παθολογικά ευρήματα" }
    ],
    "dependsOn": { "questionId": "D1j_done", "value": true },
    "validation": { "required": true }
  },

  // --- D1ο: ΗΜΓ/ΗΝΓ ---
  {
    "id": "D1o_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει ΗΜΓ/ΗΝΓ (Ηλεκτρομυογράφημα – Ηλεκτρονευρογράφημα );",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1o",
    "section": "Clinical",
    "type": "radio",
    "label": "ΗΜΓ/ΗΝΓ αποτελέσματα;",
    "options": [
      { "value": "D1oa", "label": "Παθολογικα ευρήματα" },
      { "value": "D1ob", "label": "Μη παθολογικά ευρήματα" }
    ],
    "dependsOn": { "questionId": "D1o_done", "value": true },
    "validation": { "required": true }
  },

  // --- D1π: Νευροψυχολογικός έλεγχος ---
  {
    "id": "D1p_done",
    "section": "Clinical",
    "type": "boolean",
    "label": "Έχετε κάνει νευροψυχολογικό έλεγχο;",
    "dependsOn": { "questionId": "D", "value": "D1" },
    "validation": { "required": true }
  },
  {
    "id": "D1p",
    "section": "Clinical",
    "type": "radio",
    "label": "Νευροψυχολογικός έλεγχος αποτελέσματα;",
    "options": [
      { "value": "D1p1", "label": "Παθολογικά ευρήματα" },
      { "value": "D1p2", "label": "Μη παθολογικά ευρήματα" }
    ],
    "dependsOn": { "questionId": "D1p_done", "value": true },
    "validation": { "required": true }
  },
  //-----Δ1π3=GDS score Tot_---------
  // --- Υποερωτήσεις GDS (boolean) ---
  {
    "id": "D1p3i",
    "section": "GDS",
    "type": "boolean",
    "label": "Είστε ικανοποιημένος από τη ζωή σας;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3ii",
    "section": "GDS",
    "type": "boolean",
    "label": "Έχουν ατονίσει αρκετές από τις δραστηριότητες‑ενδιαφέροντά σας;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3iii",
    "section": "GDS",
    "type": "boolean",
    "label": "Αισθάνεστε ότι η ζωή σας είναι άδεια;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3iv",
    "section": "GDS",
    "type": "boolean",
    "label": "Συχνά νιώθετε ότι βαριέστε;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3v",
    "section": "GDS",
    "type": "boolean",
    "label": "Έχετε καλή διάθεση τον περισσότερο καιρό;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3vi",
    "section": "GDS",
    "type": "boolean",
    "label": "Φοβάστε ότι κάτι κακό πρόκειται να σας συμβεί;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3vii",
    "section": "GDS",
    "type": "boolean",
    "label": "Αισθάνεστε ευτυχής τον περισσότερο καιρό;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3viii",
    "section": "GDS",
    "type": "boolean",
    "label": "Αισθάνεστε συχνά αβοήθητος;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3ix",
    "section": "GDS",
    "type": "boolean",
    "label": "Προτιμάτε να μένετε στο σπίτι παρά να βγαίνετε και να κάνετε καινούργια πράγματα;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3x",
    "section": "GDS",
    "type": "boolean",
    "label": "Αισθάνεστε ότι έχετε περισσότερα προβλήματα μνήμης από άλλους;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3xi",
    "section": "GDS",
    "type": "boolean",
    "label": "Πιστεύετε ότι είναι υπέροχο να ζει κανείς;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3xii",
    "section": "GDS",
    "type": "boolean",
    "label": "Αισθάνεστε ότι δεν αξίζει να είστε στην κατάσταση που βρίσκεστε;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3xiii",
    "section": "GDS",
    "type": "boolean",
    "label": "Αισθάνεστε γεμάτος ενέργεια;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3xiv",
    "section": "GDS",
    "type": "boolean",
    "label": "Αισθάνεστε ότι η κατάστασή σας είναι χωρίς ελπίδα;",
    "validation": { "required": true }
  },
  {
    "id": "D1p3xv",
    "section": "GDS",
    "type": "boolean",
    "label": "Αισθάνεστε ότι οι περισσότεροι άνθρωποι είναι καλύτερα από εσάς;",
    "validation": { "required": true }
  },
  // --- Δ1π4: QUIP boolean questions ---
  {
    "id": "D1p4i",
    "section": "QUIP",
    "type": "boolean",
    "label": "Ψυχαναγκαστική συμπεριφορά me τζόγο",
    "validation": { "required": true }
  },
  {
    "id": "D1p4ii",
    "section": "QUIP",
    "type": "boolean",
    "label": "Ψυχαναγκαστική σεξουαλική συμπεριφορά",
    "validation": { "required": true }
  },
  {
    "id": "D1p4iii",
    "section": "QUIP",
    "type": "boolean",
    "label": "Ψυχαναγκαστική καταναλωτική συμπεριφορά",
    "validation": { "required": true }
  },
  {
    "id": "D1p4iv",
    "section": "QUIP",
    "type": "boolean",
    "label": "Ψυχαναγκαστική διατροφική συμπεριφορά",
    "validation": { "required": true }
  },
  {
    "id": "D1p4v",
    "section": "QUIP",
    "type": "boolean",
    "label": "Ψυχαναγκαστική ενασχόληση με χόμπι",
    "validation": { "required": true }
  },
  {
    "id": "D1p4vi",
    "section": "QUIP",
    "type": "boolean",
    "label": "Ψυχαναγκαστική ενασχόληση με απλές κινητικές δραστηριότητες",
    "validation": { "required": true }
  },
  {
    "id": "D1p4vii",
    "section": "QUIP",
    "type": "boolean",
    "label": "Ψυχαναγκαστικό περπάτημα ή οδήγηση",
    "validation": { "required": true }
  },
  {
    "id": "D1p4viii",
    "section": "QUIP",
    "type": "boolean",
    "label": "Ψυχαναγκαστική χρήση φαρμάκων",
    "validation": { "required": true }
  },
  // --- Δ1π5: RBD screening questionnaire boolean questions ---
  {
    "id": "D1p5i",
    "section": "RBD",
    "type": "boolean",
    "label": "Βλέπω μερικές φορές πολύ έντονα όνειρα;",
    "validation": { "required": true }
  },
  {
    "id": "D1p5ii",
    "section": "RBD",
    "type": "boolean",
    "label": "Τα όνειρά μου έχουν επιθετικό χαρακτήρα με βίαιες κινήσεις;",
    "validation": { "required": true }
  },
  {
    "id": "D1p5iii",
    "section": "RBD",
    "type": "boolean",
    "label": "Το περιεχόμενο των ονείρων ταιριάζει κυρίως με τη νυχτερινή μου συμπεριφορά;",
    "validation": { "required": true }
  },
  {
    "id": "D1p5iv",
    "section": "RBD",
    "type": "boolean",
    "label": "Γνωρίζω ότι τα χέρια μου ή πόδια μου κινούνται όταν κοιμάμαι;",
    "validation": { "required": true }
  },
  {
    "id": "D1p5v",
    "section": "RBD",
    "type": "boolean",
    "label": "Συμβαίνει να χτυπώ ασυναίσθητα τον σύντροφό μου όταν κοιμάμαι;",
    "validation": { "required": true }
  },
  {
    "id": "D1p5via",
    "section": "RBD",
    "type": "boolean",
    "label": "Κατά τη διάρκεια του ύπνου φωνάζω, μιλάω ή γελώ δυνατά;",
    "validation": { "required": true }
  },
  {
    "id": "D1p5vib",
    "section": "RBD",
    "type": "boolean",
    "label": "Κατά τη διάρκεια του ύπνου κάνω ξαφνικές κινήσεις;",
    "validation": { "required": true }
  },
  {
    "id": "D1p5vic",
    "section": "RBD",
    "type": "boolean",
    "label": "Κατά τη διάρκεια του ύπνου κάνω χειρονομίες ή πολύπλοκες κινήσεις (π.χ. χαιρετισμό, πέφτω από το κρεβάτι);",
    "validation": { "required": true }
  },
  {
    "id": "D1p5vid",
    "section": "RBD",
    "type": "boolean",
    "label": "Κατά τη διάρκεια του ύπνου ρίχνω από το κρεβάτι αντικείμενα (π.χ. πορτατίφ, γυαλιά);",
    "validation": { "required": true }
  },
  {
    "id": "D1p5vii",
    "section": "RBD",
    "type": "boolean",
    "label": "Οι κινήσεις μου ξυπνούν εμένα ή άλλους;",
    "validation": { "required": true }
  },
  {
    "id": "D1p5viii",
    "section": "RBD",
    "type": "boolean",
    "label": "Όταν ξυπνάω, συνήθως θυμάμαι καλά το περιεχόμενο των ονείρων μου;",
    "validation": { "required": true }
  },
  {
    "id": "D1p5ix",
    "section": "RBD",
    "type": "boolean",
    "label": "Ο ύπνος μου συχνά διαταράσσεται;",
    "validation": { "required": true }
  },
  {
    "id": "D1p5x",
    "section": "RBD",
    "type": "checkbox",
    "label": "Έχω ή είχα κάποιο νόσημα του νευρικού συστήματος από τα παρακάτω (επιλέξτε ένα ή περισσότερα):",
    "options": [
      { "value": "D1p5x_xa",   "label": "Εγκεφαλικό" },
      { "value": "D1p5x_xb",   "label": "Τραύμα κεφαλής" },
      { "value": "D1p5x_xc",   "label": "Παρκινσονισμός (τρόμος/βραδυκινησία/δυσκαμψία)" },
      { "value": "D1p5x_xd",   "label": "Σύνδρομο ανήσυχων ποδιών" },
      { "value": "D1p5x_xe",   "label": "Ναρκοληψία" },
      { "value": "D1p5x_xf",   "label": "Κατάθλιψη" },
      { "value": "D1p5x_xg",   "label": "Επιληψία" },
      { "value": "D1p5x_xh",   "label": "Φλεγμονώδης νόσος εγκεφάλου" },
      { "value": "D1p5x_xi",   "label": "Άλλο" },
      { "value": "D1p5x_none", "label": "Κανένα" },
    ],
    "validation": { "required": true }
  },
  //------SCOPA‑AUT-------------------
  // --- SCOPA‑AUT: Δυσκολία στην κατάποση ---
  {
    "id": "D1p6i",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε δυσκολία στην κατάποση ή είχατε πνιγεί;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Σάλια ---
  {
    "id": "D1p6ii",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα σας τρέχουν σάλια;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Φαγητό στο λαιμό ---
  {
    "id": "D1p6iii",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα σας έχει ποτέ σταθεί φαγητό στο λαιμό;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Γρήγορο κορεσμός ---
  {
    "id": "D1p6iv",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα νιώσατε ότι χορτάσατε πολύ γρήγορα;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Δυσκοιλιότητα ---
  {
    "id": "D1p6v",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε προβλήματα δυσκοιλιότητας;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Δυσκολία κένωσης ---
  {
    "id": "D1p6vi",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα χρειάσθηκε να καταβάλλετε μεγάλη προσπάθεια κατά την κένωση του εντέρου;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Ακούσια κένωση ---
  {
    "id": "D1p6vii",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα σας έφυγαν κόπρανα χωρίς τη θέλησή σας;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Δυσουρία ---
  {
    "id": "D1p6viii",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε δυσκολία να συγκρατήσετε τα ούρα σας;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Ακράτεια ούρων ---
  {
    "id": "D1p6ix",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε ακράτεια ούρων;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Ατελής κένωση ---
  {
    "id": "D1p6x",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε μετά την ούρηση το αίσθημα ότι δεν άδειασε τελείως η κύστη σας;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Μειωμένη ροή ούρων ---
  {
    "id": "D1p6xi",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα η ροή των ούρων ήταν μειωμένη;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Ουρήσεις σε 2 ώρες ---
  {
    "id": "D1p6xii",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα χρειάστηκε να ουρήσετε ξανά μέσα σε 2 ώρες από προηγούμενη ούρηση;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Νυκτουρία ---
  {
    "id": "D1p6xiii",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε ούρηση κατά τη διάρκεια της νύχτας;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Ορθοστατική συμπτωματολογία ---
  {
    "id": "D1p6xiv",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα όταν στέκεστε όρθιος είχατε αίσθηση ελαφράς κεφαλαλγίας ή δυσκολία όρασης/σκέψης;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Ζάλη μετά από όρθια θέση ---
  {
    "id": "D1p6xv",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα ζαλιστήκατε αφού μείνατε όρθιος για κάποια ώρα;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Λιποθυμία ---
  {
    "id": "D1p6xvi",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Έχετε λιποθυμήσει τους τελευταίους 6 μήνες;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Υπερβολικός ιδρώτας ημέρας ---
  {
    "id": "D1p6xvii",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα ιδρώσατε υπερβολικά κατά τη διάρκεια της ημέρας;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Υπερβολικός ιδρώτας νύχτας ---
  {
    "id": "D1p6xviii",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα ιδρώσατε υπερβολικά κατά τη διάρκεια της νύχτας;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Ευαισθησία σε έντονο φωτισμό ---
  {
    "id": "D1p6xix",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε ευαισθησία σε έντονο φωτισμό;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Δυσανεξία κρύου ---
  {
    "id": "D1p6xx",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε πρόβλημα να ανεχτείτε το κρύο;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Δυσανεξία ζέστης ---
  {
    "id": "D1p6xxi",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε πρόβλημα να ανεχτείτε τη ζέστη;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Στυτική δυσλειτουργία (άνδρες μόνο) ---
  {
    "id": "D1p6xxii",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε πρόβλημα στύσης;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "dependsOn": { "questionId": "W", "value": "W1" },
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Δυσκολία εκσπερμάτισης (άνδρες μόνο) ---
  {
    "id": "D1p6xxiii",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε πρόβλημα εκσπερμάτισης;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "dependsOn": { "questionId": "W", "value": "W1" },
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Ουρολογική φαρμακευτική αγωγή στύσης (άνδρες μόνο) ---
  {
    "id": "D1p6xxiv",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα λάβατε φαρμακευτική αγωγή για διαταραχές στύσης;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "dependsOn": { "questionId": "W", "value": "W1" },
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Ξηρότητα κόλπου (γυναίκες μόνο) ---
  {
    "id": "D1p6xxv",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε ξηρότητα κόλπου κατά τη συνουσία;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "dependsOn": { "questionId": "W", "value": "W2" },
    "validation": { "required": true }
  },

  // --- SCOPA‑AUT: Δυσκολία οργασμού (γυναίκες μόνο) ---
  {
    "id": "D1p6xxvi",
    "section": "SCOPA‑AUT",
    "type": "radio",
    "label": "Τον τελευταίο μήνα είχατε δυσκολία να φτάσετε σε οργασμό;",
    "options": [
      { "value": "0", "label": "Ποτέ" },
      { "value": "1", "label": "Μερικές φορές" },
      { "value": "2", "label": "Τακτικά" },
      { "value": "3", "label": "Συχνά" }
    ],
    "dependsOn": { "questionId": "W", "value": "W2" },
    "validation": { "required": true }
  }
];
