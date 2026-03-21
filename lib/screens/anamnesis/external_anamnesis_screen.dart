import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/anamnesis_request.dart';
import '../../models/session_template.dart';
import '../../services/firestore_service.dart';

/// Standalone screen for patients to fill anamnesis via external link.
/// No authentication required — accessed by token.
class ExternalAnamnesisScreen extends StatefulWidget {
  final String token;
  const ExternalAnamnesisScreen({super.key, required this.token});

  @override
  State<ExternalAnamnesisScreen> createState() =>
      _ExternalAnamnesisScreenState();
}

class _ExternalAnamnesisScreenState extends State<ExternalAnamnesisScreen> {
  AnamnesisRequest? _request;
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;
  final Map<String, dynamic> _values = {};

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    try {
      final req =
          await FirestoreService.getAnamnesisRequestByToken(widget.token);

      if (req == null) {
        setState(() {
          _error = 'invalid';
          _loading = false;
        });
        return;
      }

      // Check expiration
      if (DateTime.now().isAfter(req.expiresAt)) {
        setState(() {
          _error = 'expired';
          _loading = false;
        });
        return;
      }

      // If already completed, show read-only
      if (req.status == AnamnesisRequestStatus.completed) {
        _values.addAll(req.responseData);
        setState(() {
          _request = req;
          _submitted = true;
          _loading = false;
        });
        return;
      }

      // Mark as opened if pending
      if (req.status == AnamnesisRequestStatus.pending) {
        await FirestoreService.updateAnamnesisRequestStatus(
          widget.token,
          status: AnamnesisRequestStatus.opened,
        );
        req.status = AnamnesisRequestStatus.opened;
      }

      // Pre-fill any existing response data (partial fill)
      _values.addAll(req.responseData);

      setState(() {
        _request = req;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading anamnesis request: $e');
      setState(() {
        _error = 'invalid';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      // Only update the anamnesisRequests doc — no auth needed.
      // The clinician-side patient detail screen copies response data
      // to the Patient document when it loads.
      await FirestoreService.updateAnamnesisRequestStatus(
        widget.token,
        status: AnamnesisRequestStatus.completed,
        responseData: _values,
      );

      if (mounted) {
        setState(() {
          _submitted = true;
          _submitting = false;
        });
      }
    } catch (e) {
      debugPrint('Error submitting anamnesis: $e');
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error submitting. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(loc.anamnesisFormTitle),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link_off,
                    size: 64,
                    color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  _error == 'expired'
                      ? loc.anamnesisExpired
                      : loc.anamnesisInvalidLink,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_submitted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle,
                    size: 80, color: Colors.green.shade600),
                const SizedBox(height: 24),
                Text(loc.anamnesisSubmitted,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(loc.anamnesisSubmittedDesc,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    final req = _request!;
    final fields = req.fieldsSnapshot.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header — clinic logo + name
                const SizedBox(height: 8),
                if (req.clinicLogoUrl.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        req.clinicLogoUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.assignment,
                            size: 48,
                            color: colorScheme.primary),
                      ),
                    ),
                  )
                else
                  Icon(Icons.assignment,
                      size: 48, color: colorScheme.primary),
                const SizedBox(height: 12),
                if (req.clinicName.isNotEmpty)
                  Text(req.clinicName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                Text(loc.anamnesisFormTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),

                // Patient name card
                Card(
                  color: colorScheme.primaryContainer,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        req.patientName.isNotEmpty
                            ? req.patientName[0].toUpperCase()
                            : '?',
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                    ),
                    title: Text(req.patientName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer)),
                  ),
                ),
                const SizedBox(height: 16),

                // Form fields
                ...fields.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildField(f, colorScheme),
                    )),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: Text(loc.submitAnamnesis),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Field builders (same logic as _AnamnesisFormScreen) ──────────────────

  Widget _buildField(FieldDefinition field, ColorScheme colorScheme) {
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
                _fieldLabel(field),
                Slider(
                  value: val,
                  min: mn,
                  max: mx,
                  divisions: divisions > 0 ? divisions : null,
                  label: val.round().toString(),
                  onChanged: (v) =>
                      setState(() => _values[field.guid] = v),
                ),
                Center(
                  child: Text(
                    '${val.round()}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
              controller: TextEditingController(
                  text: (_values[field.guid] ?? '') as String),
              maxLines: multiline ? 5 : 1,
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
                _fieldLabel(field),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: options.map((o) {
                    return FilterChip(
                      label: Text(o),
                      selected: selected.contains(o),
                      onSelected: (v) {
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
              value: (val != null && options.contains(val)) ? val : null,
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _values[field.guid] = v),
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
                _fieldLabel(field),
                ...items.map((item) {
                  final guid = item['guid'] ?? '';
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['label'] ?? ''),
                    value: checked.contains(guid),
                    onChanged: (v) {
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
        final val = (_values[field.guid] ??
            field.config['defaultValue'] ??
            false) as bool;
        return Card(
          child: SwitchListTile(
            title: _fieldLabel(field),
            value: val,
            onChanged: (v) => setState(() => _values[field.guid] = v),
          ),
        );

      case FieldType.currency:
        final prefix = field.config['prefix'] ?? 'R\$';
        final val = (_values[field.guid]?.toString()) ?? '';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: TextEditingController(text: val),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: field.label,
                prefixText: '$prefix ',
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                _values[field.guid] = parsed ?? 0.0;
              },
            ),
          ),
        );

      case FieldType.image:
        // Image capture not supported on external web form
        return const SizedBox.shrink();

      case FieldType.subTemplate:
        // Sub-templates rendered inline
        return const SizedBox.shrink();
    }
  }

  Widget _fieldLabel(FieldDefinition field) {
    return Text(field.label,
        style: Theme.of(context).textTheme.titleSmall);
  }
}
