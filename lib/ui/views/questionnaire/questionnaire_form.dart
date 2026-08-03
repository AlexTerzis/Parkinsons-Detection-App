import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';
import 'package:parkinsondetetion/ui/common/app_tokens.dart';
import 'package:parkinsondetetion/ui/common/widgets/app_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'questionnaire_schema.dart';
import 'questionnaire_english.dart';

/// Callback invoked when the form is submitted with all responses.
typedef SubmitCallback = Future<void> Function(Map<String, dynamic> responses);

/// A guided, auto-saving questionnaire built from [questionnaireSchema].
class QuestionnaireForm extends StatefulWidget {
  const QuestionnaireForm({super.key, required this.onSubmit});

  final SubmitCallback onSubmit;

  @override
  State<QuestionnaireForm> createState() => _QuestionnaireFormState();
}

enum _QuestionnaireStage { loading, introduction, questions, review }

class _QuestionPage {
  const _QuestionPage(this.section, this.questions, this.part, this.partCount);

  final String section;
  final List<Map<String, dynamic>> questions;
  final int part;
  final int partCount;
}

class _QuestionnaireFormState extends State<QuestionnaireForm> {
  static const _draftKey = 'questionnaire_draft_v2';
  static const _pageSize = 6;

  final Map<String, dynamic> _responses = {};
  final ScrollController _scrollController = ScrollController();
  Timer? _saveDebounce;
  _QuestionnaireStage _stage = _QuestionnaireStage.loading;
  int _pageIndex = 0;
  bool _saved = false;
  bool _submitting = false;
  String? _pageError;

  bool get _isGreek => Localizations.localeOf(context).languageCode == 'el';
  String _t(String english, String greek) => _isGreek ? greek : english;

  String _questionLabel(Map<String, dynamic> question) {
    if (_isGreek) return question['label'] as String;
    return questionnaireEnglishLabels[question['id'] as String] ??
        question['label'] as String;
  }

  String _optionLabel(Map<dynamic, dynamic> option) {
    final label = option['label'] as String;
    return _isGreek ? label : questionnaireEnglishOptions[label] ?? label;
  }

  String _sectionName(String section) {
    if (!_isGreek) return section;
    return const {
          'Demographics': 'Δημογραφικά στοιχεία',
          'Symptom Assessment': 'Αξιολόγηση συμπτωμάτων',
          'Family History': 'Οικογενειακό ιστορικό',
          'Medication': 'Φαρμακευτική αγωγή',
          'Clinical': 'Κλινικό ιστορικό',
          'GDS': 'Διάθεση και ευεξία (GDS)',
          'QUIP': 'Συνήθειες και παρορμήσεις (QUIP)',
          'RBD': 'Ύπνος και όνειρα (RBD)',
          'SCOPA‑AUT': 'Αυτόνομες λειτουργίες (SCOPA-AUT)',
          'SCOPAâ€‘AUT': 'Αυτόνομες λειτουργίες (SCOPA-AUT)',
        }[section] ??
        section;
  }

  String? _sectionDescription(String section) => switch (section) {
        'GDS' => _t(
            'These questions concern your mood and wellbeing during the recent period.',
            'Οι ερωτήσεις αφορούν τη διάθεση και την ευεξία σας κατά το πρόσφατο διάστημα.'),
        'QUIP' => _t(
            'These questions concern urges or habits that may be difficult to control. Answering honestly helps the assessment.',
            'Οι ερωτήσεις αφορούν παρορμήσεις ή συνήθειες που μπορεί να είναι δύσκολο να ελεγχθούν. Η ειλικρινής απάντηση βοηθά την αξιολόγηση.'),
        'RBD' => _t(
            'These questions concern movements, speech, or vivid dreams while sleeping.',
            'Οι ερωτήσεις αφορούν κινήσεις, ομιλία ή έντονα όνειρα κατά τη διάρκεια του ύπνου.'),
        'SCOPA‑AUT' || 'SCOPAâ€‘AUT' => _t(
            'These questions concern automatic body functions such as digestion, urination, sweating, and blood pressure.',
            'Οι ερωτήσεις αφορούν αυτόματες λειτουργίες του σώματος, όπως η πέψη, η ούρηση, η εφίδρωση και η αρτηριακή πίεση.'),
        _ => null,
      };

  String? _questionHelp(String id) => switch (id) {
        'A2' => _t(
            'Bradykinesia means that everyday movements have become unusually slow or take longer to begin.',
            'Βραδυκινησία σημαίνει ότι οι καθημερινές κινήσεις έχουν γίνει ασυνήθιστα αργές ή αργούν να ξεκινήσουν.'),
        'A3' => _t(
            'Rigidity means persistent stiffness or resistance when moving an arm, leg, or the neck.',
            'Δυσκαμψία σημαίνει επίμονη ακαμψία ή αντίσταση όταν κινείτε ένα χέρι, ένα πόδι ή τον αυχένα.'),
        'RBD_study' => _t(
            'RBD is REM sleep behaviour disorder. A sleep study is an overnight examination performed in a sleep laboratory.',
            'Η RBD είναι διαταραχή συμπεριφοράς στον ύπνο REM. Η μελέτη ύπνου είναι νυχτερινή εξέταση σε εργαστήριο ύπνου.'),
        'RBD_study_positive' || 'RBD_q' => _t(
            'RBD may cause a person to speak, shout, or move as if acting out a dream while asleep.',
            'Η RBD μπορεί να προκαλεί ομιλία, φωνές ή κινήσεις σαν το άτομο να πραγματοποιεί το όνειρό του ενώ κοιμάται.'),
        'Execute_Disorder' => _t(
            'Executive difficulties affect planning, organising steps, making decisions, or completing a familiar task.',
            'Οι εκτελεστικές δυσκολίες επηρεάζουν τον σχεδιασμό, την οργάνωση βημάτων, τη λήψη αποφάσεων ή την ολοκλήρωση μιας γνώριμης εργασίας.'),
        'Dysarthria' => _t(
            'Dysarthria is speech that becomes slurred, quiet, slow, or difficult for others to understand because of reduced muscle control.',
            'Δυσαρθρία είναι η ομιλία που γίνεται ασαφής, χαμηλή, αργή ή δυσνόητη λόγω μειωμένου ελέγχου των μυών.'),
        'Dysphagia' => _t(
            'Dysphagia means difficulty swallowing food, liquids, or saliva, including coughing or choking while eating.',
            'Δυσκαταποσία σημαίνει δυσκολία στην κατάποση τροφής, υγρών ή σάλιου, όπως βήχας ή πνιγμός κατά το φαγητό.'),
        'Atrophy' => _t(
            'Atrophy means a visible reduction in muscle size compared with the past or with the opposite limb.',
            'Ατροφία σημαίνει ορατή μείωση του μεγέθους ενός μυός σε σύγκριση με παλαιότερα ή με το αντίθετο άκρο.'),
        'Instability' => _t(
            'Instability means difficulty keeping your balance when standing, turning, or walking.',
            'Αστάθεια σημαίνει δυσκολία στη διατήρηση της ισορροπίας όταν στέκεστε, στρίβετε ή περπατάτε.'),
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final answers = decoded['responses'] as Map<String, dynamic>?;
        if (answers != null) _responses.addAll(answers);
        _pageIndex = (decoded['page'] as num?)?.toInt() ?? 0;
      } catch (_) {
        await prefs.remove(_draftKey);
      }
    }
    if (!mounted) return;
    setState(() => _stage = _QuestionnaireStage.introduction);
  }

  List<_QuestionPage> get _allPages {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final question in questionnaireSchema) {
      grouped.putIfAbsent(question['section'] as String, () => []).add(question);
    }

    final pages = <_QuestionPage>[];
    for (final entry in grouped.entries) {
      final partCount = (entry.value.length / _pageSize).ceil();
      for (var start = 0; start < entry.value.length; start += _pageSize) {
        final end = (start + _pageSize).clamp(0, entry.value.length).toInt();
        pages.add(_QuestionPage(
          entry.key,
          entry.value.sublist(start, end),
          (start ~/ _pageSize) + 1,
          partCount,
        ));
      }
    }
    return pages;
  }

  List<Map<String, dynamic>> _visibleQuestions(_QuestionPage page) =>
      page.questions.where(_shouldShow).toList();

  List<int> get _visiblePageIndexes {
    final pages = _allPages;
    return [
      for (var i = 0; i < pages.length; i++)
        if (_visibleQuestions(pages[i]).isNotEmpty) i,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.questionnaire),
        actions: [
          if (_stage == _QuestionnaireStage.questions ||
              _stage == _QuestionnaireStage.review)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    _saved ? _t('Saved', 'Αποθηκεύτηκε') : '',
                    key: ValueKey(_saved),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: switch (_stage) {
        _QuestionnaireStage.loading => const Center(
            child: CircularProgressIndicator(),
          ),
        _QuestionnaireStage.introduction => _buildIntroduction(),
        _QuestionnaireStage.questions => _buildQuestions(),
        _QuestionnaireStage.review => _buildReview(),
      },
    );
  }

  Widget _buildIntroduction() {
    final hasDraft = _responses.isNotEmpty;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.fact_check_outlined,
                      size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _t('A few small steps', 'Μερικά μικρά βήματα'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_t(
                    'The questionnaire is divided into short sections. Your progress is saved automatically, so you can leave and continue later.',
                    'Το ερωτηματολόγιο χωρίζεται σε μικρές ενότητες. Η πρόοδός σας αποθηκεύεται αυτόματα, ώστε να μπορείτε να συνεχίσετε αργότερα.',
                  )),
                  const SizedBox(height: AppSpacing.lg),
                  _IntroFact(
                    icon: Icons.schedule_outlined,
                    text: _t('Usually takes 15–20 minutes',
                        'Συνήθως διαρκεί 15–20 λεπτά'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _IntroFact(
                    icon: Icons.touch_app_outlined,
                    text: _t('Large, simple answer controls',
                        'Μεγάλα και απλά πεδία απάντησης'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _IntroFact(
                    icon: Icons.lock_outline,
                    text: _t('Review everything before submitting',
                        'Έλεγχος όλων πριν από την υποβολή'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _IntroFact(
                    icon: Icons.save_outlined,
                    text: _t(
                        'Before submission, your draft stays on this device. After submission, it is stored in your signed-in account in Firebase Firestore and replaces your previous questionnaire.',
                        'Πριν από την υποβολή, το πρόχειρο παραμένει σε αυτή τη συσκευή. Μετά την υποβολή, αποθηκεύεται στον συνδεδεμένο λογαριασμό σας στο Firebase Firestore και αντικαθιστά το προηγούμενο ερωτηματολόγιο.'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _startQuestions,
                      icon: Icon(hasDraft ? Icons.play_arrow : Icons.arrow_forward),
                      label: Text(hasDraft
                          ? _t('Continue questionnaire', 'Συνέχεια ερωτηματολογίου')
                          : _t('Start questionnaire', 'Έναρξη ερωτηματολογίου')),
                    ),
                  ),
                  if (hasDraft) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: TextButton(
                        onPressed: _confirmStartOver,
                        child: Text(_t('Start over', 'Έναρξη από την αρχή')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startQuestions() {
    final pages = _allPages;
    if (_pageIndex >= pages.length) _pageIndex = 0;
    setState(() => _stage = _QuestionnaireStage.questions);
  }

  Future<void> _confirmStartOver() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Start over?', 'Έναρξη από την αρχή;')),
        content: Text(_t('Your saved questionnaire answers will be cleared.',
            'Οι αποθηκευμένες απαντήσεις θα διαγραφούν.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t('Cancel', 'Ακύρωση')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t('Clear answers', 'Διαγραφή απαντήσεων')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    if (!mounted) return;
    setState(() {
      _responses.clear();
      _pageIndex = 0;
      _saved = false;
      _stage = _QuestionnaireStage.questions;
    });
  }

  Widget _buildQuestions() {
    final pages = _allPages;
    final visibleIndexes = _visiblePageIndexes;
    if (visibleIndexes.isEmpty) return const SizedBox.shrink();
    if (!visibleIndexes.contains(_pageIndex)) _pageIndex = visibleIndexes.first;
    final visiblePosition = visibleIndexes.indexOf(_pageIndex);
    final page = pages[_pageIndex];
    final questions = _visibleQuestions(page);
    final progress = (visiblePosition + 1) / visibleIndexes.length;
    final answered = questionnaireSchema.where(_isAnswered).length;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_t('Step ${visiblePosition + 1} of ${visibleIndexes.length}',
                        'Βήμα ${visiblePosition + 1} από ${visibleIndexes.length}')),
                    Text('${(progress * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _t('$answered answers completed', '$answered απαντήσεις ολοκληρώθηκαν'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
              children: [
                Text(_sectionName(page.section),
                    style: Theme.of(context).textTheme.headlineSmall),
                if (_sectionDescription(page.section) case final description?)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(description),
                  ),
                if (page.partCount > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(_t('Part ${page.part} of ${page.partCount}',
                        'Μέρος ${page.part} από ${page.partCount}')),
                  ),
                const SizedBox(height: AppSpacing.md),
                ...questions.map((q) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(child: _buildField(q)),
                    )),
                if (_pageError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      _pageError!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
          _buildNavigation(visibleIndexes, visiblePosition),
        ],
      ),
    );
  }

  Widget _buildNavigation(List<int> visibleIndexes, int position) {
    final isLast = position == visibleIndexes.length - 1;
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: position == 0 ? null : () => _goTo(visibleIndexes[position - 1]),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(_t('Back', 'Πίσω')),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _continue(visibleIndexes, position),
                  icon: Icon(isLast ? Icons.fact_check_outlined : Icons.arrow_forward),
                  label: Text(isLast
                      ? _t('Review', 'Έλεγχος')
                      : _t('Continue', 'Συνέχεια')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continue(List<int> visibleIndexes, int position) {
    final missing = _visibleQuestions(_allPages[_pageIndex])
        .where((q) => !_isAnswered(q))
        .toList();
    if (missing.isNotEmpty) {
      setState(() => _pageError = _t(
          'Please answer every question on this page.',
          'Παρακαλώ απαντήστε σε κάθε ερώτηση αυτής της σελίδας.'));
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      return;
    }
    if (position == visibleIndexes.length - 1) {
      setState(() {
        _pageError = null;
        _stage = _QuestionnaireStage.review;
      });
    } else {
      _goTo(visibleIndexes[position + 1]);
    }
  }

  void _goTo(int index) {
    setState(() {
      _pageIndex = index;
      _pageError = null;
      _stage = _QuestionnaireStage.questions;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
    _scheduleSave();
  }

  Widget _buildReview() {
    final sections = <String, List<Map<String, dynamic>>>{};
    for (final q in questionnaireSchema.where(_shouldShow)) {
      sections.putIfAbsent(q['section'] as String, () => []).add(q);
    }
    final missingTotal = sections.values
        .expand((questions) => questions)
        .where((question) => !_isAnswered(question))
        .length;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(_t('Review your answers', 'Ελέγξτε τις απαντήσεις σας'),
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(missingTotal == 0
                    ? _t('Everything is complete. You can still edit any section.',
                        'Όλα είναι συμπληρωμένα. Μπορείτε ακόμη να επεξεργαστείτε οποιαδήποτε ενότητα.')
                    : _t('$missingTotal answers still need attention.',
                        '$missingTotal απαντήσεις χρειάζονται συμπλήρωση.')),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(_t(
                            'When you submit, these answers will be stored in your signed-in account in Firebase Firestore. A later submission replaces this questionnaire.',
                            'Με την υποβολή, οι απαντήσεις θα αποθηκευτούν στον συνδεδεμένο λογαριασμό σας στο Firebase Firestore. Μια νέα υποβολή θα αντικαταστήσει αυτό το ερωτηματολόγιο.')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final entry in sections.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ReviewSection(
                      title: _sectionName(entry.key),
                      answered: entry.value.where(_isAnswered).length,
                      total: entry.value.length,
                      editLabel: _t('Edit', 'Επεξεργασία'),
                      onEdit: () => _editSection(entry.key),
                    ),
                  ),
              ],
            ),
          ),
          Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _stage = _QuestionnaireStage.questions),
                        child: Text(_t('Back', 'Πίσω')),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: missingTotal == 0 && !_submitting ? _submit : null,
                        icon: _submitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(AppLocalizations.of(context)!.submit),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editSection(String section) {
    final index = _allPages.indexWhere((page) => page.section == section &&
        _visibleQuestions(page).any((question) => !_isAnswered(question)));
    final fallback = _allPages.indexWhere((page) => page.section == section);
    _goTo(index >= 0 ? index : fallback);
  }

  bool _shouldShow(Map<String, dynamic> q) {
    final condition = q['dependsOn'] as Map<String, dynamic>?;
    if (condition == null) return true;
    return _responses[condition['questionId']] == condition['value'];
  }

  bool _isAnswered(Map<String, dynamic> q) {
    if (!_shouldShow(q)) return true;
    final value = _responses[q['id'] as String];
    final rules = q['validation'] as Map<String, dynamic>?;
    final required = rules?['required'] == true;
    if (value == null) return !required;
    if (value is String && value.trim().isEmpty) return !required;
    if (value is List && value.isEmpty) return !required;
    if (value is num && rules != null) {
      final min = rules['min'] as num?;
      final max = rules['max'] as num?;
      if (min != null && value < min) return false;
      if (max != null && value > max) return false;
    }
    return true;
  }

  void _setAnswer(String id, dynamic value) {
    setState(() {
      _responses[id] = value;
      _saved = false;
      _pageError = null;
      _clearHiddenAnswers();
    });
    _scheduleSave();
  }

  void _clearHiddenAnswers() {
    for (final question in questionnaireSchema) {
      if (!_shouldShow(question)) _responses.remove(question['id']);
    }
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 350), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _draftKey,
      jsonEncode({'responses': _responses, 'page': _pageIndex}),
    );
    if (mounted) setState(() => _saved = true);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final allowedIds = questionnaireSchema.map((q) => q['id'] as String).toSet();
      final filtered = <String, dynamic>{
        for (final entry in _responses.entries)
          if (allowedIds.contains(entry.key)) entry.key: entry.value,
      };
      await widget.onSubmit(filtered);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('Could not submit. Your answers are still saved.',
            'Η υποβολή απέτυχε. Οι απαντήσεις σας παραμένουν αποθηκευμένες.')),
      ));
      setState(() => _submitting = false);
    }
  }

  Widget _buildField(Map<String, dynamic> q) {
    final id = q['id'] as String;
    final type = q['type'] as String;
    final label = _questionLabel(q);
    final value = _responses[id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuestionPrompt(
          label: label,
          help: _questionHelp(id),
          isGreek: _isGreek,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (type == 'boolean')
          _ChoiceButtons(
            options: [
              _Choice(true, _t('Yes', 'Ναι')),
              _Choice(false, _t('No', 'Όχι')),
            ],
            value: value,
            onChanged: (answer) => _setAnswer(id, answer),
          )
        else if (type == 'radio' || type == 'select')
          _ChoiceButtons(
            options: (q['options'] as List<dynamic>)
                .map((o) => _Choice(
                    o['value'], _optionLabel(o as Map<dynamic, dynamic>)))
                .toList(),
            value: value,
            onChanged: (answer) => _setAnswer(id, answer),
          )
        else if (type == 'checkbox')
          ...(q['options'] as List<dynamic>).map((option) {
            final selected = (value as List<dynamic>?)?.toList() ?? [];
            final optionValue = option['value'];
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(_optionLabel(option as Map<dynamic, dynamic>)),
              value: selected.contains(optionValue),
              onChanged: (checked) {
                checked == true ? selected.add(optionValue) : selected.remove(optionValue);
                _setAnswer(id, selected);
              },
            );
          })
        else if (type == 'slider')
          _NullableSlider(
            min: (q['min'] as num).toDouble(),
            max: (q['max'] as num).toDouble(),
            value: (value as num?)?.toDouble(),
            chooseLabel: _t('Tap or drag to choose', 'Πατήστε ή σύρετε για επιλογή'),
            onChanged: (answer) => _setAnswer(id, answer.round()),
          )
        else if (type == 'integer' || type == 'string')
          TextFormField(
            initialValue: value?.toString(),
            keyboardType: type == 'integer' ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: _t('Type your answer', 'Γράψτε την απάντησή σας'),
            ),
            onChanged: (answer) => _setAnswer(
                id, type == 'integer' ? int.tryParse(answer) : answer),
          ),
      ],
    );
  }
}

class _IntroFact extends StatelessWidget {
  const _IntroFact({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text)),
      ]);
}

class _QuestionPrompt extends StatefulWidget {
  const _QuestionPrompt({
    required this.label,
    required this.help,
    required this.isGreek,
  });
  final String label;
  final String? help;
  final bool isGreek;

  @override
  State<_QuestionPrompt> createState() => _QuestionPromptState();
}

class _QuestionPromptState extends State<_QuestionPrompt> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
          if (widget.help != null) ...[
            TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.help_outline),
              label: Text(widget.isGreek
                  ? 'Τι σημαίνει αυτό;'
                  : 'What does this mean?'),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(widget.help!),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      );
}

class _Choice {
  const _Choice(this.value, this.label);
  final dynamic value;
  final String label;
}

class _ChoiceButtons extends StatelessWidget {
  const _ChoiceButtons({required this.options, required this.value, required this.onChanged});
  final List<_Choice> options;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: options.map((option) {
          final selected = value == option.value;
          return Semantics(
            selected: selected,
            button: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.minTap, minWidth: 104),
              child: selected
                  ? FilledButton(
                      onPressed: () => onChanged(option.value),
                      child: Text(option.label),
                    )
                  : OutlinedButton(
                      onPressed: () => onChanged(option.value),
                      child: Text(option.label),
                    ),
            ),
          );
        }).toList(),
      );
}

class _NullableSlider extends StatelessWidget {
  const _NullableSlider({
    required this.min,
    required this.max,
    required this.value,
    required this.chooseLabel,
    required this.onChanged,
  });
  final double min;
  final double max;
  final double? value;
  final String chooseLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final displayValue = value ?? min;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value == null ? chooseLabel : displayValue.round().toString()),
        Slider(
          value: displayValue,
          min: min,
          max: max,
          divisions: (max - min).round(),
          label: value?.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.answered,
    required this.total,
    required this.editLabel,
    required this.onEdit,
  });
  final String title;
  final int answered;
  final int total;
  final String editLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final complete = answered == total;
    return AppCard(
      onTap: onEdit,
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle : Icons.error_outline,
            color: complete
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text('$answered / $total'),
              ],
            ),
          ),
          Text(editLabel),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
