import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/appointment.dart';
import '../../models/patient.dart';
import '../../services/firestore_service.dart';

class AppointmentFormScreen extends StatefulWidget {
  final Appointment? appointment;
  final String? preselectedPatientId;

  const AppointmentFormScreen({
    super.key,
    this.appointment,
    this.preselectedPatientId,
  });

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<Patient> _patients = [];
  String? _selectedPatientId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  AppointmentStatus _status = AppointmentStatus.scheduled;
  bool _reminderEnabled = true;
  bool _saving = false;

  bool get _isEditing => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    _durationCtrl.text = (a?.durationMinutes ?? 45).toString();
    _notesCtrl.text = a?.notes ?? '';
    _selectedPatientId = a?.patientId ?? widget.preselectedPatientId;
    if (a != null) {
      _selectedDate = a.scheduledDate;
      _selectedTime = TimeOfDay.fromDateTime(a.scheduledDate);
      _status = a.status;
      _reminderEnabled = a.reminderEnabled;
    }
    _loadPatients();
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await FirestoreService.getAllPatients();
      if (mounted) {
        setState(() {
          _patients =
              patients.where((p) => p.status == PatientStatus.active).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) return;

    setState(() => _saving = true);

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final appointment = widget.appointment ?? Appointment();
    appointment.patientId = _selectedPatientId!;
    appointment.scheduledDate = scheduledDateTime;
    appointment.durationMinutes = int.tryParse(_durationCtrl.text) ?? 45;
    appointment.notes = _notesCtrl.text.trim();
    appointment.status = _status;
    appointment.reminderEnabled = _reminderEnabled;

    if (_isEditing) {
      await FirestoreService.updateAppointment(appointment);
    } else {
      await FirestoreService.createAppointment(appointment);
    }

    if (mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.appointmentSaved)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? loc.editAppointment : loc.newAppointment),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient selector
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: loc.patient,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      // ignore: deprecated_member_use
                      value: _selectedPatientId,
                      items: _patients
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.fullName),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedPatientId = v),
                      validator: (v) =>
                          v == null ? loc.fieldRequired : null,
                    ),
                    const SizedBox(height: 12),
                    // Date
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: loc.appointmentDate,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Time
                    InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: loc.appointmentTime,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Duration
                    TextFormField(
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: loc.duration,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.timer),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? loc.fieldRequired : null,
                    ),
                    const SizedBox(height: 12),
                    // Status
                    DropdownButtonFormField<AppointmentStatus>(
                      decoration: InputDecoration(
                        labelText: loc.appointmentStatus,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.flag),
                      ),
                      // ignore: deprecated_member_use
                      value: _status,
                      items: [
                        DropdownMenuItem(
                          value: AppointmentStatus.scheduled,
                          child: Text(loc.statusScheduled),
                        ),
                        DropdownMenuItem(
                          value: AppointmentStatus.completed,
                          child: Text(loc.statusCompleted),
                        ),
                        DropdownMenuItem(
                          value: AppointmentStatus.cancelled,
                          child: Text(loc.statusCancelled),
                        ),
                        DropdownMenuItem(
                          value: AppointmentStatus.rescheduled,
                          child: Text(loc.statusRescheduled),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    // Reminder switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(loc.reminder),
                      value: _reminderEnabled,
                      onChanged: (v) => setState(() => _reminderEnabled = v),
                    ),
                    const SizedBox(height: 4),
                    // Notes
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: loc.notes,
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
}
