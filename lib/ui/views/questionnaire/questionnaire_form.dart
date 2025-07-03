import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

import 'questionnaire_schema.dart';

/// Callback invoked when the form is submitted with all responses.
typedef SubmitCallback = Future<void> Function(Map<String, dynamic> responses);

/// A dynamic questionnaire form that renders fields from [questionnaireSchema].
class QuestionnaireForm extends StatefulWidget {
  const QuestionnaireForm({super.key, required this.onSubmit});

  final SubmitCallback onSubmit;

  @override
  State<QuestionnaireForm> createState() => _QuestionnaireFormState();
}

class _QuestionnaireFormState extends State<QuestionnaireForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _responses = {};

  @override
  Widget build(BuildContext context) {
    // Group visible questions by section.
    final sections = <String, List<Map<String, dynamic>>>{};
    for (final q in questionnaireSchema) {
      if (_shouldShow(q)) {
        sections.putIfAbsent(q['section'] as String, () => []).add(q);
      }
    }

    return ResponsiveBuilder(builder: (context, _) {
      return Scaffold(
        appBar: AppBar(title: const Text('Questionnaire')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in sections.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(entry.key,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                ...entry.value.map(_buildField),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isValid() ? _submit : null,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      );
    });
  }

  bool _isValid() => _formKey.currentState?.validate() ?? false;

  void _submit() {
    if (_isValid()) {
      widget.onSubmit(Map<String, dynamic>.from(_responses));
    }
  }

  bool _shouldShow(Map<String, dynamic> q) {
    final cond = q['dependsOn'];
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
          initialValue: _responses[id],
          validator: (v) => _validate(q, v),
          onChanged: (v) => _responses[id] = v,
        );
      case 'number':
      case 'integer':
        return TextFormField(
          decoration: InputDecoration(labelText: label),
          keyboardType: TextInputType.number,
          initialValue: _responses[id]?.toString(),
          validator: (v) => _validate(q, v),
          onChanged: (v) => _responses[id] = num.tryParse(v ?? ''),
        );
      case 'boolean':
        return SwitchListTile(
          title: Text(label),
          value: _responses[id] ?? false,
          onChanged: (v) => setState(() => _responses[id] = v),
        );
      case 'select':
        final options = q['options'] as List;
        return DropdownButtonFormField(
          decoration: InputDecoration(labelText: label),
          value: _responses[id],
          items: options
              .map<DropdownMenuItem<dynamic>>(
                (o) => DropdownMenuItem(
                  value: o['value'],
                  child: Text(o['label']),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _responses[id] = v),
          validator: (v) => _validate(q, v),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String? _validate(Map<String, dynamic> q, dynamic value) {
    final rules = q['validation'] as Map<String, dynamic>? ?? {};
    if (rules['required'] == true && (value == null || value.toString().isEmpty)) {
      return 'Required';
    }
    if (value != null && value.toString().isNotEmpty) {
      final num? min = rules['min'];
      final num? max = rules['max'];
      final num? parsed = num.tryParse(value.toString());
      if (parsed != null) {
        if (min != null && parsed < min) return 'Minimum is $min';
        if (max != null && parsed > max) return 'Maximum is $max';
      }
    }
    return null;
  }
}