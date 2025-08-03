import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:parkinsondetetion/l10n/app_localizations.dart';

import 'questionnaire_schema.dart';

/// Callback invoked when the form is submitted with all responses.
typedef SubmitCallback = Future<void> Function(Map<String, dynamic> responses);

/// A dynamic questionnaire form that renders fields from [questionnaireSchema].
class QuestionnaireForm extends StatefulWidget {
  const QuestionnaireForm({Key? key, required this.onSubmit}) : super(key: key);

  final SubmitCallback onSubmit;

  @override
  State<QuestionnaireForm> createState() => _QuestionnaireFormState();
}

class _QuestionnaireFormState extends State<QuestionnaireForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _responses = {};
  @override
  void initState() {
    super.initState();
    // Initialize all boolean fields to false so “No” is recorded by default.
    for (final q in questionnaireSchema) {
      if (q['type'] == 'boolean') {
        _responses[q['id'] as String] = false;
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    // Group visible questions by section.
    final sections = <String, List<Map<String, dynamic>>>{};
    for (final q in questionnaireSchema) {
      if (_shouldShow(q)) {
        sections.putIfAbsent(q['section'] as String, () => []).add(q);
      }
    }

    return ResponsiveBuilder(
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.questionnaire)),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in sections.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...entry.value.map(_buildField),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isValid() ? _submit : null,
                child: Text(AppLocalizations.of(context)!.submit),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isValid() => _formKey.currentState?.validate() ?? false;

  Future<void> _submit() async {
    if (!_isValid()) return;
    // Only include keys defined in the current schema
    final allowedIds = questionnaireSchema.map((q) => q['id'] as String).toSet();
    final filtered = <String, dynamic>{};
    for (final entry in _responses.entries) {
      if (allowedIds.contains(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }
    // 2. call the injected submit callback
    await widget.onSubmit(filtered);

    // 3. then pop back to the previous screen
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  bool _shouldShow(Map<String, dynamic> q) {
    final cond = q['dependsOn'] as Map<String, dynamic>?;
    if (cond == null) return true;
    return _responses[cond['questionId']] == cond['value'];
  }

  Widget _buildField(Map<String, dynamic> q) {
    final id = q['id'] as String;
    final type = q['type'] as String;
    final label = q['label'] as String;

    switch (type) {
      case 'string':
        return TextFormField(
          decoration: InputDecoration(labelText: label),
          initialValue: _responses[id] as String?,
          validator: (v) => _validate(q, v),
          onChanged: (v) => _responses[id] = v,
        );

      case 'integer':
        return TextFormField(
          decoration: InputDecoration(labelText: label),
          keyboardType: TextInputType.number,
          initialValue: _responses[id]?.toString(),
          validator: (v) => _validate(q, v),
          onChanged: (v) => _responses[id] = int.tryParse(v),
        );

      case 'boolean':
        return SwitchListTile(
          title: Text(label),
          value: _responses[id] as bool? ?? false,
          onChanged: (v) => setState(() => _responses[id] = v),
        );

      case 'select':
        final options = q['options'] as List<dynamic>;
        return DropdownButtonFormField<dynamic>(
          decoration: InputDecoration(labelText: label),
          value: _responses[id],
          items: options
              .map((o) => DropdownMenuItem(
                    value: o['value'],
                    child: Text(o['label']),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _responses[id] = v),
          validator: (v) => _validate(q, v),
        );
      case 'checkbox':
        final options = q['options'] as List<dynamic>;
        // ensure we start with an empty list if nothing's set yet
        final selected = (_responses[id] as List<dynamic>?)?.cast<String>() ?? <String>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            ...options.map<Widget>((opt) {
              final val = opt['value'] as String;
              final lab = opt['label'] as String;
              final isChecked = selected.contains(val);
              return CheckboxListTile(
                title: Text(lab),
                value: isChecked,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      selected.add(val);
                    } else {
                      selected.remove(val);
                    }
                    _responses[id] = selected;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
          ],
        );
  

      case 'radio':
        final options = q['options'] as List<dynamic>;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: options.map<Widget>((o) {
                final val = o['value'];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<dynamic>(
                      value: val,
                      groupValue: _responses[id],
                      onChanged: (v) => setState(() => _responses[id] = v),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _responses[id] = val),
                      child: Text(o['label']),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );

      case 'slider':
        final min = (q['min'] as num).toDouble();
        final max = (q['max'] as num).toDouble();
        final current = (_responses[id] as num?)?.toDouble() ?? min;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: current,
              min: min,
              max: max,
              divisions: (max - min).round(),
              label: current.round().toString(),
              onChanged: (newVal) => setState(() => _responses[id] = newVal.round()),
            ),
            Text('${current.round()}', style: Theme.of(context).textTheme.bodyMedium),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String? _validate(Map<String, dynamic> q, dynamic value) {
    final rules = q['validation'] as Map<String, dynamic>?;
    if (rules != null && rules['required'] == true && (value == null || value.toString().isEmpty)) {
      return 'Required';
    }
    if (value != null && rules != null) {
      final num? min = rules['min'] as num?;
      final num? max = rules['max'] as num?;
      final num? parsed = num.tryParse(value.toString());
      if (parsed != null) {
        if (min != null && parsed < min) return 'Minimum is \$min';
        if (max != null && parsed > max) return 'Maximum is \$max';
      }
    }
    return null;
  }
}
