import 'package:flutter/material.dart';

class CreateFormDialog extends StatefulWidget {
  final String title;
  final List<FormFieldConfig> fields;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;
  final Widget? extraWidget;
  final void Function(String key, dynamic value)? onAddFieldChanged;

  const CreateFormDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
    this.extraWidget,
    this.onAddFieldChanged,
  });

  @override
  State<CreateFormDialog> createState() => _CreateFormDialogState();
}

class FormFieldConfig {
  final String key;
  final String label;
  final String? hint;
  final FormFieldType type;
  final List<String>? options;
  final bool required;
  final dynamic value;

  const FormFieldConfig({
    required this.key,
    required this.label,
    this.hint,
    this.type = FormFieldType.text,
    this.options,
    this.required = false,
    this.value,
  });
}

enum FormFieldType { text, dropdown }

class _CreateFormDialogState extends State<CreateFormDialog> {
  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      if (field.type == FormFieldType.dropdown) {
        _formData[field.key] = field.value ??
            ((field.options != null && field.options!.isNotEmpty)
                ? field.options!.first
                : null);
      } else {
        final initial = field.value?.toString() ?? '';
        _formData[field.key] = initial;
        _controllers[field.key] = TextEditingController(text: initial);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
                ),
              ...widget.fields.map((field) {
                if (field.type == FormFieldType.dropdown) {
                  final options = field.options ?? [];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      initialValue: _formData[field.key],
                      decoration: InputDecoration(
                        labelText: field.label,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: options
                          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _formData[field.key] = v);
                        widget.onAddFieldChanged?.call(field.key, v);
                      },
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _controllers[field.key],
                    decoration: InputDecoration(
                      labelText: field.label,
                      hintText: field.hint,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (v) => _formData[field.key] = v,
                    validator: field.required
                        ? (v) => (v == null || v.isEmpty)
                            ? '${field.label} is required'
                            : null
                        : null,
                  ),
                );
              }),
              if (widget.extraWidget != null) widget.extraWidget!,
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  if (widget.fields.any((f) => f.required) &&
                      !_formKey.currentState!.validate()) {
                    return;
                  }
                  setState(() {
                    _isSubmitting = true;
                    _error = null;
                  });

                  final cleanData = <String, dynamic>{};
                  for (final entry in _formData.entries) {
                    if (entry.value != null && entry.value.toString().isNotEmpty) {
                      cleanData[entry.key] = entry.value;
                    }
                  }

                  try {
                    final success = await widget.onSubmit(cleanData);
                    if (mounted) {
                      setState(() => _isSubmitting = false);
                    }
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pop(context, true);
                    } else {
                      setState(() => _error = 'Failed to create. Please try again.');
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isSubmitting = false;
                        _error = 'Error: $e';
                      });
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }
}
