import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/appointment.dart';
import '../../models/patient.dart';
import '../../models/session_record.dart';
import '../../models/session_template.dart';
import '../../services/firestore_service.dart';
import '../../services/image_service.dart';

class SessionRecordScreen extends StatefulWidget {
  final Appointment appointment;
  final Patient patient;

  const SessionRecordScreen({
    super.key,
    required this.appointment,
    required this.patient,
  });

  @override
  State<SessionRecordScreen> createState() => _SessionRecordScreenState();
}

class _SessionRecordScreenState extends State<SessionRecordScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _viewMode = false;

  SessionTemplate? _template;
  List<SessionTemplate> _allTemplates = [];
  List<FieldDefinition> _fields = [];
  final Map<String, dynamic> _values = {};
  SessionRecord? _existingRecord;

  // Legacy fallback controllers (used when no template)
  double _prePain = 0;
  double _postPain = 0;
  final _observationsCtrl = TextEditingController();
  final Set<String> _selectedTechniques = {};

  static const _defaultTechniques = [
    'Liberação Miofascial',
    'Ventosaterapia',
    'Dry Needling',
    'Terapia Manual',
    'Alongamento',
    'Exercício Terapêutico',
    'Ultrassom',
    'TENS',
    'Trapézio',
    'Lombar',
    'Cervical',
    'Quadril',
    'Joelho',
    'Ombro',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _observationsCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      // Check for existing session record (view/edit completed)
      final sessions = await FirestoreService.getSessionsByAppointment(
          widget.appointment.id);
      if (sessions.isNotEmpty) {
        _existingRecord = sessions.first;
        _viewMode = widget.appointment.status == AppointmentStatus.completed;
      }

      // Load all templates for the selector
      _allTemplates = await FirestoreService.getAllTemplates();

      // Load template
      SessionTemplate? tmpl;
      if (_existingRecord != null && _existingRecord!.templateId.isNotEmpty) {
        // Load the exact version that was used
        tmpl = await FirestoreService.getTemplateById(
            _existingRecord!.templateId);
        if (tmpl != null && _existingRecord!.templateVersion > 0) {
          final snap = await FirestoreService.getTemplateVersion(
              tmpl.id, _existingRecord!.templateVersion);
          if (snap != null) {
            _fields = snap.fieldsSnapshot;
          } else {
            _fields = tmpl.fields;
          }
        } else if (tmpl != null) {
          _fields = tmpl.fields;
        }
      } else if (_allTemplates.isNotEmpty) {
        // Try loading the default template first, fall back to first available
        tmpl = _allTemplates.firstWhere((t) => t.isDefault,
            orElse: () => _allTemplates.first);
        _fields = tmpl.fields;
      }
      _template = tmpl;

      // Populate values from existing record
      if (_existingRecord != null) {
        if (_existingRecord!.fieldValues.isNotEmpty) {
          _values.addAll(_existingRecord!.fieldValues);
        }
        // Legacy fields
        _prePain = _existingRecord!.prePainScore.toDouble();
        _postPain = _existingRecord!.postPainScore.toDouble();
        _selectedTechniques.addAll(_existingRecord!.techniques);
        _observationsCtrl.text = _existingRecord!.observations;
      }

      _fields.sort((a, b) => a.order.compareTo(b.order));
    } catch (_) {
      // Proceed with no template (legacy mode)
    }

    if (mounted) setState(() => _loading = false);
  }

  // Deep-convert maps so Firestore gets plain maps at every nesting level.
  dynamic _sanitize(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
    }
    if (value is List) {
      return value.map(_sanitize).toList();
    }
    return value;
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final record = _existingRecord ?? SessionRecord();
      record.appointmentId = widget.appointment.id;
      record.sessionDateTime = DateTime.now();

      if (_template != null && _fields.isNotEmpty) {
        record.templateId = _template!.id;
        record.templateVersion = _template!.currentVersion;
        record.fieldValues =
            Map<String, dynamic>.from(_sanitize(_values) as Map);
      }

      // Always store legacy fields too for dashboard compat
      record.prePainScore = _prePain.round();
      record.postPainScore = _postPain.round();
      record.techniques = _selectedTechniques.toList();
      record.observations = _observationsCtrl.text.trim();

      if (_existingRecord != null) {
        await FirestoreService.updateSessionRecord(record);
      } else {
        await FirestoreService.createSessionRecord(record);
      }

      // Mark appointment as completed
      widget.appointment.status = AppointmentStatus.completed;
      await FirestoreService.updateAppointment(widget.appointment);

      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.sessionSaved)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_viewMode ? loc.sessionDetails : loc.recordSession),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          if (_viewMode)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: loc.edit,
              onPressed: () => setState(() => _viewMode = false),
            )
          else if (_saving)
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Patient header
                _patientHeader(colorScheme),
                const SizedBox(height: 16),
                // Template selector (only for new sessions)
                if (_existingRecord == null && _allTemplates.isNotEmpty)
                  _templateSelector(loc, colorScheme),
                // Template fields or legacy fallback
                if (_template != null && _fields.isNotEmpty)
                  ..._fields.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildField(f, colorScheme),
                      ))
                else
                  ..._legacyFields(loc, colorScheme),
                const SizedBox(height: 24),
                if (!_viewMode)
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(loc.save),
                  ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _patientHeader(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.primaryContainer,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary,
          child: Text(
            widget.patient.fullName.isNotEmpty
                ? widget.patient.fullName[0].toUpperCase()
                : '?',
            style: TextStyle(color: colorScheme.onPrimary),
          ),
        ),
        title: Text(
          widget.patient.fullName,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer),
        ),
        subtitle: Text(
          '${widget.appointment.scheduledDate.day.toString().padLeft(2, '0')}/${widget.appointment.scheduledDate.month.toString().padLeft(2, '0')}/${widget.appointment.scheduledDate.year} · ${widget.appointment.durationMinutes} min',
          style: TextStyle(color: colorScheme.onPrimaryContainer),
        ),
      ),
    );
  }

  // ── Template selector ────────────────────────────────────────────────────

  Widget _templateSelector(AppLocalizations loc, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: loc.selectTemplate,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.description_outlined),
        ),
        // ignore: deprecated_member_use
        value: _template?.id,
        items: _allTemplates
            .map((t) => DropdownMenuItem(
                  value: t.id,
                  child: Text(t.name),
                ))
            .toList(),
        onChanged: _viewMode ? null : (id) => _switchTemplate(id),
      ),
    );
  }

  void _switchTemplate(String? templateId) {
    if (templateId == null) return;
    final tmpl = _allTemplates.firstWhere((t) => t.id == templateId);
    setState(() {
      _template = tmpl;
      _fields = tmpl.fields.toList()..sort((a, b) => a.order.compareTo(b.order));
      _values.clear();
    });
  }

  // ── Dynamic field rendering ────────────────────────────────────────────────

  Widget _buildField(FieldDefinition field, ColorScheme colorScheme) {
    switch (field.type) {
      case FieldType.slider:
        return _buildSlider(field, colorScheme);
      case FieldType.textField:
        return _buildTextField(field);
      case FieldType.label:
        return _buildLabel(field, colorScheme);
      case FieldType.tags:
        return _buildTags(field, colorScheme);
      case FieldType.comboBox:
        return _buildComboBox(field);
      case FieldType.image:
        return _buildImage(field, colorScheme);
      case FieldType.checkbox:
        return _buildCheckbox(field);
      case FieldType.subTemplate:
        return _buildSubTemplate(field, colorScheme);
      case FieldType.toggle:
        return _buildToggle(field);
    }
  }

  Widget _buildSlider(FieldDefinition field, ColorScheme colorScheme) {
    final mn = ((field.config['min'] ?? 0.0) as num).toDouble();
    final mx = ((field.config['max'] ?? 10.0) as num).toDouble();
    final step = ((field.config['step'] ?? 1.0) as num).toDouble();
    final unit = field.config['unit'] ?? '';
    final divisions = step > 0 ? ((mx - mn) / step).round() : 10;
    final val = ((_values[field.guid] ?? mn) as num).toDouble().clamp(mn, mx);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(mn.toStringAsFixed(mn == mn.roundToDouble() ? 0 : 1),
                    style: const TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: val,
                    min: mn,
                    max: mx,
                    divisions: divisions > 0 ? divisions : null,
                    label: '${val.round()}${unit.isNotEmpty ? ' $unit' : ''}',
                    onChanged: _viewMode
                        ? null
                        : (v) => setState(() => _values[field.guid] = v),
                  ),
                ),
                Text(mx.toStringAsFixed(mx == mx.roundToDouble() ? 0 : 1),
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                _vasChip(val.round(), colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(FieldDefinition field) {
    final multiline = field.config['multiline'] ?? false;
    final maxLen = (field.config['maxLength'] ?? 0) as int;
    // Use a controller that stays in sync with _values
    final currentVal = (_values[field.guid] ?? '') as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: TextEditingController(text: currentVal),
          maxLines: multiline ? 5 : 1,
          maxLength: maxLen > 0 ? maxLen : null,
          readOnly: _viewMode,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
            alignLabelWithHint: multiline,
          ),
          onChanged: (v) => _values[field.guid] = v,
        ),
      ),
    );
  }

  Widget _buildLabel(FieldDefinition field, ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(field.label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTags(FieldDefinition field, ColorScheme colorScheme) {
    final options = List<String>.from(field.config['options'] ?? []);
    final selected =
        Set<String>.from((_values[field.guid] ?? <String>[]) as List);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sell_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(field.label,
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: options.map((o) {
                final isSelected = selected.contains(o);
                return FilterChip(
                  label: Text(o, style: const TextStyle(fontSize: 13)),
                  selected: isSelected,
                  onSelected: _viewMode
                      ? null
                      : (v) {
                          setState(() {
                            if (v) {
                              selected.add(o);
                            } else {
                              selected.remove(o);
                            }
                            _values[field.guid] = selected.toList();
                          });
                        },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComboBox(FieldDefinition field) {
    final options = List<String>.from(field.config['options'] ?? []);
    final val = _values[field.guid] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          value: (val != null && options.contains(val)) ? val : null,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: _viewMode
              ? null
              : (v) => setState(() => _values[field.guid] = v),
        ),
      ),
    );
  }

  void _showFullImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.white54, size: 64),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(FieldDefinition field, ImageSource source) async {
    final url = await ImageService.pickAndUpload(source: source);
    if (url != null && mounted) {
      setState(() {
        final urls = List<String>.from(
            (_values[field.guid] ?? <String>[]) as List);
        urls.add(url);
        _values[field.guid] = urls;
      });
    }
  }

  void _showImageSourceSheet(FieldDefinition field, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(loc.camera),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(field, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(loc.gallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(field, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(FieldDefinition field, ColorScheme colorScheme) {
    final hint = field.config['hint'] ?? '';
    final loc = AppLocalizations.of(context)!;
    final urls = List<String>.from(
        (_values[field.guid] ?? <String>[]) as List);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            // Show existing images
            if (urls.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: urls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showFullImage(urls[i]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            urls[i],
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              width: 120,
                              color: colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                      if (!_viewMode)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                urls.removeAt(i);
                                _values[field.guid] = urls;
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Add image button
            if (!_viewMode)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showImageSourceSheet(field, loc),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(loc.addPhoto),
                ),
              )
            else if (urls.isEmpty)
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        color: colorScheme.onSurface.withValues(alpha: 0.4)),
                    if (hint.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(hint,
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5))),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(FieldDefinition field) {
    final items = List<Map<String, dynamic>>.from(
        (field.config['items'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e)) ??
            []);
    final checked =
        Set<String>.from((_values[field.guid] ?? <String>[]) as List);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label,
                style: Theme.of(context).textTheme.titleSmall),
            ...items.map((item) {
              final guid = item['guid'] ?? '';
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item['label'] ?? ''),
                value: checked.contains(guid),
                onChanged: _viewMode
                    ? null
                    : (v) {
                        setState(() {
                          if (v == true) {
                            checked.add(guid);
                          } else {
                            checked.remove(guid);
                          }
                          _values[field.guid] = checked.toList();
                        });
                      },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(FieldDefinition field) {
    final val = (_values[field.guid] ?? field.config['defaultValue'] ?? false) as bool;
    return Card(
      child: SwitchListTile(
        title: Text(field.label,
            style: Theme.of(context).textTheme.titleSmall),
        value: val,
        onChanged: _viewMode
            ? null
            : (v) => setState(() => _values[field.guid] = v),
      ),
    );
  }

  Widget _buildSubTemplate(FieldDefinition field, ColorScheme colorScheme) {
    final loc = AppLocalizations.of(context)!;
    final tmplId = field.config['templateId'] ?? '';
    final mode = field.config['displayMode'] ?? 'page';
    final subValues = Map<String, dynamic>.from(
        (_values[field.guid] ?? <String, dynamic>{}) as Map);
    final hasData = subValues.isNotEmpty;

    if (tmplId.isEmpty) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.article_outlined,
              color: colorScheme.onSurface.withValues(alpha: 0.4)),
          title: Text(field.label,
              style: Theme.of(context).textTheme.titleSmall),
          subtitle: Text(loc.noTemplateSelected),
        ),
      );
    }

    if (mode == 'inline') {
      return _buildInlineSubTemplate(field, tmplId, colorScheme);
    }

    // Page mode — show a card that navigates to a sub-form
    return Card(
      child: ListTile(
        leading: Icon(Icons.article_outlined, color: colorScheme.primary),
        title: Text(field.label,
            style: Theme.of(context).textTheme.titleSmall),
        subtitle: hasData
            ? Text(loc.subTemplateCompleted,
                style: TextStyle(color: Colors.green.shade700))
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (_) => _SubTemplateFormScreen(
                templateId: tmplId,
                fieldLabel: field.label,
                initialValues: subValues,
                viewMode: _viewMode,
              ),
            ),
          );
          if (result != null && mounted) {
            setState(() => _values[field.guid] = result);
          }
        },
      ),
    );
  }

  Widget _buildInlineSubTemplate(
      FieldDefinition field, String tmplId, ColorScheme colorScheme) {
    // Find the template in the cached list
    final tmpl = _allTemplates.where((t) => t.id == tmplId).toList();
    if (tmpl.isEmpty) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.article_outlined,
              color: colorScheme.onSurface.withValues(alpha: 0.4)),
          title: Text(field.label),
          subtitle: Text(AppLocalizations.of(context)!.noTemplateSelected),
        ),
      );
    }

    final subFields = tmpl.first.fields.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final subValues = Map<String, dynamic>.from(
        (_values[field.guid] ?? <String, dynamic>{}) as Map);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            ...subFields.map((sf) {
              // Wrap each sub-field so its values are stored inside our sub-map
              final wrappedField = sf.copyWith();
              // Temporarily swap _values to subValues for rendering
              return _SubFieldWidget(
                field: wrappedField,
                values: subValues,
                viewMode: _viewMode,
                onChanged: () {
                  setState(() => _values[field.guid] = subValues);
                },
                parentState: this,
                colorScheme: colorScheme,
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Legacy fields (no template) ────────────────────────────────────────────

  List<Widget> _legacyFields(AppLocalizations loc, ColorScheme colorScheme) {
    return [
      // Pre-session VAS
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.sentiment_very_dissatisfied,
                    color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(loc.prePainScore,
                    style: Theme.of(context).textTheme.titleSmall),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Text('0', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _prePain,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _prePain.round().toString(),
                    onChanged: _viewMode
                        ? null
                        : (v) => setState(() => _prePain = v),
                  ),
                ),
                const Text('10', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                _vasChip(_prePain.round(), colorScheme),
              ]),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      // Post-session VAS
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.sentiment_satisfied,
                    color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(loc.postPainScore,
                    style: Theme.of(context).textTheme.titleSmall),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Text('0', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _postPain,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _postPain.round().toString(),
                    activeColor: Colors.green.shade600,
                    onChanged: _viewMode
                        ? null
                        : (v) => setState(() => _postPain = v),
                  ),
                ),
                const Text('10', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                _vasChip(_postPain.round(), colorScheme,
                    color: Colors.green.shade600),
              ]),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      // Techniques
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.medical_services, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(loc.techniquesApplied,
                    style: Theme.of(context).textTheme.titleSmall),
              ]),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _defaultTechniques.map((t) {
                  final selected = _selectedTechniques.contains(t);
                  return FilterChip(
                    label: Text(t, style: const TextStyle(fontSize: 13)),
                    selected: selected,
                    onSelected: _viewMode
                        ? null
                        : (v) {
                            setState(() {
                              if (v) {
                                _selectedTechniques.add(t);
                              } else {
                                _selectedTechniques.remove(t);
                              }
                            });
                          },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      // Observations
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.notes, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(loc.sessionObservations,
                    style: Theme.of(context).textTheme.titleSmall),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _observationsCtrl,
                maxLines: 5,
                readOnly: _viewMode,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '...',
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _vasChip(int value, ColorScheme colorScheme, {Color? color}) {
    Color bg;
    if (value <= 3) {
      bg = Colors.green.shade600;
    } else if (value <= 6) {
      bg = Colors.orange.shade600;
    } else {
      bg = Colors.red.shade600;
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color ?? bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Sub-template page form ────────────────────────────────────────────────

class _SubTemplateFormScreen extends StatefulWidget {
  final String templateId;
  final String fieldLabel;
  final Map<String, dynamic> initialValues;
  final bool viewMode;

  const _SubTemplateFormScreen({
    required this.templateId,
    required this.fieldLabel,
    required this.initialValues,
    required this.viewMode,
  });

  @override
  State<_SubTemplateFormScreen> createState() => _SubTemplateFormScreenState();
}

class _SubTemplateFormScreenState extends State<_SubTemplateFormScreen> {
  bool _loading = true;
  List<FieldDefinition> _fields = [];
  final Map<String, dynamic> _values = {};
  String _templateName = '';

  @override
  void initState() {
    super.initState();
    _values.addAll(widget.initialValues);
    _load();
  }

  Future<void> _load() async {
    try {
      final tmpl =
          await FirestoreService.getTemplateById(widget.templateId);
      if (tmpl != null) {
        _templateName = tmpl.name;
        _fields = tmpl.fields.toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fieldLabel),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          if (!widget.viewMode)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: loc.save,
              onPressed: () => Navigator.pop(context, _values),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _fields.isEmpty
              ? Center(child: Text(loc.noTemplateSelected))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_templateName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_templateName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ..._fields.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildSubField(f, colorScheme),
                        )),
                  ],
                ),
    );
  }

  Widget _buildSubField(FieldDefinition field, ColorScheme colorScheme) {
    switch (field.type) {
      case FieldType.slider:
        final mn = ((field.config['min'] ?? 0.0) as num).toDouble();
        final mx = ((field.config['max'] ?? 10.0) as num).toDouble();
        final step = ((field.config['step'] ?? 1.0) as num).toDouble();
        final divisions = step > 0 ? ((mx - mn) / step).round() : 10;
        final val =
            ((_values[field.guid] ?? mn) as num).toDouble().clamp(mn, mx);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.label,
                    style: Theme.of(context).textTheme.titleSmall),
                Slider(
                  value: val,
                  min: mn,
                  max: mx,
                  divisions: divisions > 0 ? divisions : null,
                  label: val.round().toString(),
                  onChanged: widget.viewMode
                      ? null
                      : (v) => setState(() => _values[field.guid] = v),
                ),
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
              controller:
                  TextEditingController(text: (_values[field.guid] ?? '') as String),
              maxLines: multiline ? 5 : 1,
              readOnly: widget.viewMode,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: field.label,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => _values[field.guid] = v,
            ),
          ),
        );

      case FieldType.label:
        return Card(
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(field.label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
        );

      case FieldType.tags:
        final options = List<String>.from(field.config['options'] ?? []);
        final selected =
            Set<String>.from((_values[field.guid] ?? <String>[]) as List);
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
                  children: options.map((o) {
                    return FilterChip(
                      label: Text(o),
                      selected: selected.contains(o),
                      onSelected: widget.viewMode
                          ? null
                          : (v) {
                              setState(() {
                                if (v) {
                                  selected.add(o);
                                } else {
                                  selected.remove(o);
                                }
                                _values[field.guid] = selected.toList();
                              });
                            },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );

      case FieldType.comboBox:
        final options = List<String>.from(field.config['options'] ?? []);
        final val = _values[field.guid] as String?;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: field.label,
                border: const OutlineInputBorder(),
              ),
              // ignore: deprecated_member_use
              value: (val != null && options.contains(val)) ? val : null,
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: widget.viewMode
                  ? null
                  : (v) => setState(() => _values[field.guid] = v),
            ),
          ),
        );

      case FieldType.checkbox:
        final items = List<Map<String, dynamic>>.from(
            (field.config['items'] as List<dynamic>?)
                    ?.map((e) => Map<String, dynamic>.from(e)) ??
                []);
        final checked =
            Set<String>.from((_values[field.guid] ?? <String>[]) as List);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.label,
                    style: Theme.of(context).textTheme.titleSmall),
                ...items.map((item) {
                  final guid = item['guid'] ?? '';
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['label'] ?? ''),
                    value: checked.contains(guid),
                    onChanged: widget.viewMode
                        ? null
                        : (v) {
                            setState(() {
                              if (v == true) {
                                checked.add(guid);
                              } else {
                                checked.remove(guid);
                              }
                              _values[field.guid] = checked.toList();
                            });
                          },
                  );
                }),
              ],
            ),
          ),
        );

      case FieldType.toggle:
        final val = (_values[field.guid] ?? field.config['defaultValue'] ?? false) as bool;
        return Card(
          child: SwitchListTile(
            title: Text(field.label,
                style: Theme.of(context).textTheme.titleSmall),
            value: val,
            onChanged: widget.viewMode
                ? null
                : (v) => setState(() => _values[field.guid] = v),
          ),
        );

      case FieldType.image:
      case FieldType.subTemplate:
        // Simplified rendering for nested levels
        return Card(
          child: ListTile(
            leading: Icon(
              field.type == FieldType.image
                  ? Icons.image_outlined
                  : Icons.article_outlined,
              color: colorScheme.primary,
            ),
            title: Text(field.label),
          ),
        );
    }
  }
}

// ── Inline sub-field widget ───────────────────────────────────────────────

class _SubFieldWidget extends StatelessWidget {
  final FieldDefinition field;
  final Map<String, dynamic> values;
  final bool viewMode;
  final VoidCallback onChanged;
  final _SessionRecordScreenState parentState;
  final ColorScheme colorScheme;

  const _SubFieldWidget({
    required this.field,
    required this.values,
    required this.viewMode,
    required this.onChanged,
    required this.parentState,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case FieldType.slider:
        final mn = ((field.config['min'] ?? 0.0) as num).toDouble();
        final mx = ((field.config['max'] ?? 10.0) as num).toDouble();
        final step = ((field.config['step'] ?? 1.0) as num).toDouble();
        final divisions = step > 0 ? ((mx - mn) / step).round() : 10;
        final val =
            ((values[field.guid] ?? mn) as num).toDouble().clamp(mn, mx);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label,
                style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: val,
              min: mn,
              max: mx,
              divisions: divisions > 0 ? divisions : null,
              label: val.round().toString(),
              onChanged: viewMode
                  ? null
                  : (v) {
                      values[field.guid] = v;
                      onChanged();
                    },
            ),
          ],
        );

      case FieldType.textField:
        final multiline = field.config['multiline'] ?? false;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: TextEditingController(
                text: (values[field.guid] ?? '') as String),
            maxLines: multiline ? 3 : 1,
            readOnly: viewMode,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) {
              values[field.guid] = v;
              onChanged();
            },
          ),
        );

      case FieldType.label:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(field.label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        );

      case FieldType.tags:
        final options = List<String>.from(field.config['options'] ?? []);
        final selected =
            Set<String>.from((values[field.guid] ?? <String>[]) as List);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: options.map((o) {
                return FilterChip(
                  label: Text(o, style: const TextStyle(fontSize: 13)),
                  selected: selected.contains(o),
                  onSelected: viewMode
                      ? null
                      : (v) {
                          if (v) {
                            selected.add(o);
                          } else {
                            selected.remove(o);
                          }
                          values[field.guid] = selected.toList();
                          onChanged();
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        );

      case FieldType.toggle:
        final val = (values[field.guid] ?? field.config['defaultValue'] ?? false) as bool;
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(field.label,
              style: Theme.of(context).textTheme.titleSmall),
          value: val,
          onChanged: viewMode
              ? null
              : (v) {
                  values[field.guid] = v;
                  onChanged();
                },
        );

      case FieldType.comboBox:
      case FieldType.checkbox:
      case FieldType.image:
      case FieldType.subTemplate:
        // Simplified for inline nesting
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.subdirectory_arrow_right,
              color: colorScheme.primary),
          title: Text(field.label),
        );
    }
  }
}
