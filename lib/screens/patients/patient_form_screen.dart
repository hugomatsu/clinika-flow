import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/patient.dart';
import '../../services/firestore_service.dart';

class PatientFormScreen extends StatefulWidget {
  final Patient? patient;

  const PatientFormScreen({super.key, this.patient});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _whatsappCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _occupationCtrl;
  late final TextEditingController _emergencyCtrl;
  late final TextEditingController _anamnesisCtrl;
  late final TextEditingController _injuryCtrl;
  DateTime? _dateOfBirth;
  PatientStatus _status = PatientStatus.active;
  bool _saving = false;

  bool get _isEditing => widget.patient != null;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _nameCtrl = TextEditingController(text: p?.fullName ?? '');
    _whatsappCtrl = TextEditingController(text: p?.whatsapp ?? '');
    _instagramCtrl = TextEditingController(text: p?.instagram ?? '');
    _emailCtrl = TextEditingController(text: p?.email ?? '');
    _occupationCtrl = TextEditingController(text: p?.occupation ?? '');
    _emergencyCtrl = TextEditingController(text: p?.emergencyContact ?? '');
    _anamnesisCtrl = TextEditingController(text: p?.posturalAnamnesis ?? '');
    _injuryCtrl = TextEditingController(text: p?.injuryHistory ?? '');
    _dateOfBirth = p?.dateOfBirth;
    _status = p?.status ?? PatientStatus.active;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _whatsappCtrl.dispose();
    _instagramCtrl.dispose();
    _emailCtrl.dispose();
    _occupationCtrl.dispose();
    _emergencyCtrl.dispose();
    _anamnesisCtrl.dispose();
    _injuryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final patient = widget.patient ?? Patient();
    patient.fullName = _nameCtrl.text.trim();
    patient.whatsapp = _whatsappCtrl.text.trim();
    patient.instagram = _instagramCtrl.text.trim();
    patient.email = _emailCtrl.text.trim();
    patient.occupation = _occupationCtrl.text.trim();
    patient.emergencyContact = _emergencyCtrl.text.trim();
    patient.posturalAnamnesis = _anamnesisCtrl.text.trim();
    patient.injuryHistory = _injuryCtrl.text.trim();
    patient.status = _status;
    if (_dateOfBirth != null) patient.dateOfBirth = _dateOfBirth!;

    if (_isEditing) {
      await FirestoreService.updatePatient(patient);
    } else {
      await FirestoreService.createPatient(patient);
    }

    if (mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.patientSaved)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? loc.editPatient : loc.newPatient),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check),
              tooltip: loc.save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              context,
              icon: Icons.person,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: loc.name,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? loc.fieldRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _whatsappCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: loc.whatsapp,
                    prefixIcon: const Icon(Icons.chat_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instagramCtrl,
                  decoration: InputDecoration(
                    labelText: loc.instagram,
                    prefixIcon: const Icon(Icons.camera_alt_outlined),
                    hintText: '@usuario',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: loc.email,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && !v.contains('@')) {
                      return loc.invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _occupationCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: loc.occupation,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: loc.dateOfBirth,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                          : loc.notInformed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.emergency,
              children: [
                TextFormField(
                  controller: _emergencyCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: loc.emergencyContact,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              icon: Icons.medical_information,
              children: [
                TextFormField(
                  controller: _anamnesisCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: loc.posturalAnamnesis,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _injuryCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: loc.injuryHistory,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              _buildSection(
                context,
                icon: Icons.flag,
                children: [
                  DropdownButtonFormField<PatientStatus>(
                    // ignore: deprecated_member_use
                    value: _status,
                    decoration: InputDecoration(
                      labelText: loc.patientStatus,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: PatientStatus.active,
                        child: Text(loc.statusActive),
                      ),
                      DropdownMenuItem(
                        value: PatientStatus.inactive,
                        child: Text(loc.statusInactive),
                      ),
                      DropdownMenuItem(
                        value: PatientStatus.archived,
                        child: Text(loc.statusArchived),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(loc.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
