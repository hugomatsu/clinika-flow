import 'dart:math';
import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/session_template.dart';
import '../../services/firestore_service.dart';

// Cached list of templates for the sub-template picker
List<SessionTemplate> _cachedTemplates = [];

class TemplateBuilderScreen extends StatefulWidget {
  final SessionTemplate? template;

  const TemplateBuilderScreen({super.key, this.template});

  @override
  State<TemplateBuilderScreen> createState() => _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState extends State<TemplateBuilderScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late List<FieldDefinition> _fields;
  bool _saving = false;
  bool _preview = false;

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _fields = t?.fields.map((f) => f.copyWith()).toList() ?? [];
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      _cachedTemplates = await FirestoreService.getAllTemplates();
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _newGuid() {
    final r = Random();
    return List.generate(20, (_) => r.nextInt(36).toRadixString(36)).join();
  }

  void _addField(FieldType type) {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _fields.add(FieldDefinition(
        guid: _newGuid(),
        type: type,
        label: _fieldTypeName(type, loc),
        order: _fields.length,
        addedInVersion: (widget.template?.currentVersion ?? 0) + 1,
      ));
    });
  }

  void _removeField(int index) {
    setState(() => _fields.removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _fields.removeAt(oldIndex);
      _fields.insert(newIndex, item);
      for (var i = 0; i < _fields.length; i++) {
        _fields[i].order = i;
      }
    });
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.fieldRequired)),
      );
      return;
    }

    setState(() => _saving = true);

    // Normalise order indices
    for (var i = 0; i < _fields.length; i++) {
      _fields[i].order = i;
    }

    if (_isEditing) {
      final t = widget.template!;
      t.name = _nameCtrl.text.trim();
      t.description = _descCtrl.text.trim();
      t.fields = _fields;
      await FirestoreService.updateTemplate(t);
    } else {
      final t = SessionTemplate(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        fields: _fields,
      );
      await FirestoreService.createTemplate(t);
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.templateSaved)));
      Navigator.pop(context);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? loc.editTemplate : loc.newTemplate),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(_preview ? Icons.edit : Icons.preview),
            tooltip: loc.preview,
            onPressed: () => setState(() => _preview = !_preview),
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check),
              tooltip: loc.save,
            ),
        ],
      ),
      body: _preview ? _buildPreview(loc, colorScheme) : _buildEditor(loc, colorScheme),
      floatingActionButton: _preview
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab_template_builder',
              onPressed: () => _showAddFieldSheet(context, loc),
              icon: const Icon(Icons.add),
              label: Text(loc.addField),
            ),
    );
  }

  // ── Editor view ────────────────────────────────────────────────────────────

  Widget _buildEditor(AppLocalizations loc, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Name + description
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: loc.templateName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: loc.templateDescription,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Reorderable field list
        if (_fields.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                loc.addField,
                style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _fields.length,
            onReorder: _reorder,
            itemBuilder: (context, i) =>
                _fieldEditorCard(i, _fields[i], loc, colorScheme),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _fieldEditorCard(
      int index, FieldDefinition field, AppLocalizations loc, ColorScheme colorScheme) {
    return Card(
      key: ValueKey(field.guid),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: Icon(_fieldIcon(field.type), color: colorScheme.primary),
        title: Text(field.label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          _fieldTypeName(field.type, loc),
          style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _removeField(index),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _fieldConfigEditor(field, loc),
          ),
        ],
      ),
    );
  }

  Widget _fieldConfigEditor(FieldDefinition field, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (all types)
        TextField(
          controller: TextEditingController(text: field.label),
          decoration: InputDecoration(
            labelText: loc.fieldLabel,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) => field.label = v,
        ),
        const SizedBox(height: 8),
        // Required toggle (not for label type)
        if (field.type != FieldType.label)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.requiredField),
            value: field.required,
            onChanged: (v) => setState(() => field.required = v),
          ),
        // Type-specific config
        ..._typeSpecificConfig(field, loc),
      ],
    );
  }

  List<Widget> _typeSpecificConfig(FieldDefinition field, AppLocalizations loc) {
    switch (field.type) {
      case FieldType.slider:
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(
                      text: (field.config['min'] ?? 0.0).toString()),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: loc.minimum,
                      border: const OutlineInputBorder(),
                      isDense: true),
                  onChanged: (v) =>
                      field.config['min'] = double.tryParse(v) ?? 0.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: TextEditingController(
                      text: (field.config['max'] ?? 10.0).toString()),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: loc.maximum,
                      border: const OutlineInputBorder(),
                      isDense: true),
                  onChanged: (v) =>
                      field.config['max'] = double.tryParse(v) ?? 10.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(
                      text: (field.config['step'] ?? 1.0).toString()),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: loc.step,
                      border: const OutlineInputBorder(),
                      isDense: true),
                  onChanged: (v) =>
                      field.config['step'] = double.tryParse(v) ?? 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: TextEditingController(
                      text: field.config['unit'] ?? ''),
                  decoration: InputDecoration(
                      labelText: loc.unit,
                      border: const OutlineInputBorder(),
                      isDense: true),
                  onChanged: (v) => field.config['unit'] = v,
                ),
              ),
            ],
          ),
        ];

      case FieldType.textField:
        return [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.multiline),
            value: field.config['multiline'] ?? false,
            onChanged: (v) =>
                setState(() => field.config['multiline'] = v),
          ),
          TextField(
            controller: TextEditingController(
                text: (field.config['maxLength'] ?? 0).toString()),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: loc.maxLength,
                border: const OutlineInputBorder(),
                isDense: true),
            onChanged: (v) =>
                field.config['maxLength'] = int.tryParse(v) ?? 0,
          ),
        ];

      case FieldType.tags:
        return [
          _optionsEditor(field, loc),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.allowCustomTags),
            value: field.config['allowCustom'] ?? false,
            onChanged: (v) =>
                setState(() => field.config['allowCustom'] = v),
          ),
        ];

      case FieldType.comboBox:
        return [_optionsEditor(field, loc)];

      case FieldType.image:
        return [
          TextField(
            controller: TextEditingController(
                text: field.config['hint'] ?? ''),
            decoration: InputDecoration(
                labelText: loc.imageHint,
                border: const OutlineInputBorder(),
                isDense: true),
            onChanged: (v) => field.config['hint'] = v,
          ),
        ];

      case FieldType.checkbox:
        return [
          _checkboxItemsEditor(field, loc),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.requireAll),
            value: field.config['requireAll'] ?? false,
            onChanged: (v) =>
                setState(() => field.config['requireAll'] = v),
          ),
        ];

      case FieldType.label:
        return [];

      case FieldType.subTemplate:
        final currentId = field.config['templateId'] ?? '';
        final mode = field.config['displayMode'] ?? 'page';
        // Exclude self to avoid circular reference
        final available = _cachedTemplates
            .where((t) => t.id != widget.template?.id)
            .toList();
        return [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: loc.subTemplateSelect,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            value: currentId.isNotEmpty &&
                    available.any((t) => t.id == currentId)
                ? currentId
                : null,
            items: available
                .map((t) =>
                    DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: (v) =>
                setState(() => field.config['templateId'] = v ?? ''),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: loc.displayMode,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            value: mode,
            items: [
              DropdownMenuItem(
                  value: 'page', child: Text(loc.displayModePage)),
              DropdownMenuItem(
                  value: 'inline', child: Text(loc.displayModeInline)),
            ],
            onChanged: (v) =>
                setState(() => field.config['displayMode'] = v ?? 'page'),
          ),
        ];

      case FieldType.toggle:
        return [];
    }
  }

  Widget _optionsEditor(FieldDefinition field, AppLocalizations loc) {
    final options = List<String>.from(field.config['options'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.options,
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        ...options.asMap().entries.map((e) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: e.value),
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                  onChanged: (v) {
                    options[e.key] = v;
                    field.config['options'] = options;
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    options.removeAt(e.key);
                    field.config['options'] = options;
                  });
                },
              ),
            ],
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: Text(loc.addOption),
          onPressed: () {
            setState(() {
              options.add('');
              field.config['options'] = options;
            });
          },
        ),
      ],
    );
  }

  Widget _checkboxItemsEditor(FieldDefinition field, AppLocalizations loc) {
    final items = List<Map<String, dynamic>>.from(
        (field.config['items'] as List<dynamic>?)?.map(
                (e) => Map<String, dynamic>.from(e)) ??
            []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.options,
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        ...items.asMap().entries.map((e) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller:
                      TextEditingController(text: e.value['label'] ?? ''),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (v) {
                    items[e.key]['label'] = v;
                    field.config['items'] = items;
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    items.removeAt(e.key);
                    field.config['items'] = items;
                  });
                },
              ),
            ],
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: Text(loc.addOption),
          onPressed: () {
            setState(() {
              items.add({'guid': _newGuid(), 'label': ''});
              field.config['items'] = items;
            });
          },
        ),
      ],
    );
  }

  // ── Preview view ───────────────────────────────────────────────────────────

  Widget _buildPreview(AppLocalizations loc, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Simulated patient header
        Card(
          color: colorScheme.primaryContainer,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: const Text('P',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(loc.preview,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer)),
          ),
        ),
        const SizedBox(height: 12),
        // Render each field as it will appear during a session
        ..._fields.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _previewField(f, colorScheme),
            )),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check),
          label: Text(loc.save),
        ),
      ],
    );
  }

  Widget _previewField(FieldDefinition field, ColorScheme colorScheme) {
    switch (field.type) {
      case FieldType.slider:
        final mn = (field.config['min'] ?? 0.0) as num;
        final mx = (field.config['max'] ?? 10.0) as num;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.label,
                    style: Theme.of(context).textTheme.titleSmall),
                Slider(
                    value: mn.toDouble(), min: mn.toDouble(), max: mx.toDouble(), onChanged: null),
              ],
            ),
          ),
        );

      case FieldType.textField:
        final multiline = field.config['multiline'] ?? false;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              enabled: false,
              maxLines: multiline ? 3 : 1,
              decoration: InputDecoration(
                  labelText: field.label,
                  border: const OutlineInputBorder()),
            ),
          ),
        );

      case FieldType.label:
        return Card(
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(field.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
          ),
        );

      case FieldType.tags:
        final options = List<String>.from(field.config['options'] ?? []);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.label,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: options
                      .map((o) => FilterChip(
                          label: Text(o), selected: false, onSelected: null))
                      .toList(),
                ),
              ],
            ),
          ),
        );

      case FieldType.comboBox:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                  labelText: field.label,
                  border: const OutlineInputBorder()),
              items: (List<String>.from(field.config['options'] ?? []))
                  .map((o) =>
                      DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: null,
            ),
          ),
        );

      case FieldType.image:
        final hint = field.config['hint'] ?? '';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.label,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 32, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                      if (hint.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(hint,
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.5))),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case FieldType.checkbox:
        final items = List<Map<String, dynamic>>.from(
            (field.config['items'] as List<dynamic>?)
                    ?.map((e) => Map<String, dynamic>.from(e)) ??
                []);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.label,
                    style: Theme.of(context).textTheme.titleSmall),
                ...items.map((item) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['label'] ?? ''),
                      value: false,
                      onChanged: null,
                    )),
              ],
            ),
          ),
        );

      case FieldType.toggle:
        return Card(
          child: SwitchListTile(
            title: Text(field.label,
                style: Theme.of(context).textTheme.titleSmall),
            value: field.config['defaultValue'] ?? false,
            onChanged: null,
          ),
        );

      case FieldType.subTemplate:
        final tmplId = field.config['templateId'] ?? '';
        final linked = _cachedTemplates
            .where((t) => t.id == tmplId)
            .toList();
        final tmplName = linked.isNotEmpty ? linked.first.name : '—';
        return Card(
          child: ListTile(
            leading: Icon(Icons.article_outlined, color: colorScheme.primary),
            title: Text(field.label,
                style: Theme.of(context).textTheme.titleSmall),
            subtitle: Text(tmplName),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
    }
  }

  // ── Add-field bottom sheet ─────────────────────────────────────────────────

  void _showAddFieldSheet(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: FieldType.values.map((type) {
            return ListTile(
              leading: Icon(_fieldIcon(type)),
              title: Text(_fieldTypeName(type, loc)),
              onTap: () {
                Navigator.pop(ctx);
                _addField(type);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fieldTypeName(FieldType type, AppLocalizations loc) {
    switch (type) {
      case FieldType.slider:
        return loc.fieldSlider;
      case FieldType.textField:
        return loc.fieldTextField;
      case FieldType.label:
        return loc.fieldLabelType;
      case FieldType.tags:
        return loc.fieldTags;
      case FieldType.comboBox:
        return loc.fieldComboBox;
      case FieldType.image:
        return loc.fieldImage;
      case FieldType.checkbox:
        return loc.fieldCheckbox;
      case FieldType.subTemplate:
        return loc.fieldSubTemplate;
      case FieldType.toggle:
        return loc.fieldToggle;
    }
  }

  IconData _fieldIcon(FieldType type) {
    switch (type) {
      case FieldType.slider:
        return Icons.linear_scale;
      case FieldType.textField:
        return Icons.text_fields;
      case FieldType.label:
        return Icons.label_outline;
      case FieldType.tags:
        return Icons.sell_outlined;
      case FieldType.comboBox:
        return Icons.arrow_drop_down_circle_outlined;
      case FieldType.image:
        return Icons.camera_alt_outlined;
      case FieldType.checkbox:
        return Icons.check_box_outlined;
      case FieldType.subTemplate:
        return Icons.article_outlined;
      case FieldType.toggle:
        return Icons.toggle_on_outlined;
    }
  }
}
