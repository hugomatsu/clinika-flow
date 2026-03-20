import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/patient.dart';
import '../../models/appointment.dart';
import '../../models/session_record.dart';
import '../../services/firestore_service.dart';
import 'patient_form_screen.dart';
import '../appointments/appointment_form_screen.dart';
import '../sessions/session_record_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  Patient? _patient;
  List<Appointment> _appointments = [];
  List<SessionRecord> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final patient = await FirestoreService.getPatientById(widget.patientId);
      final appointments =
          await FirestoreService.getAppointmentsByPatient(widget.patientId);
      final sessions = await FirestoreService.getAllSessions();
      final apptIds = appointments.map((a) => a.id).toSet();
      final patientSessions =
          sessions.where((s) => apptIds.contains(s.appointmentId)).toList();

      if (mounted) {
        setState(() {
          _patient = patient;
          _appointments = appointments;
          _sessions = patientSessions;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _archive() async {
    final loc = AppLocalizations.of(context)!;
    final patient = _patient!;
    patient.status = patient.status == PatientStatus.archived
        ? PatientStatus.active
        : PatientStatus.archived;
    await FirestoreService.updatePatient(patient);
    if (mounted) {
      final msg = patient.status == PatientStatus.archived
          ? loc.patientArchived
          : loc.patientReactivated;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _patient = patient);
    }
  }

  Future<void> _openAppointmentOptions(Appointment a, Patient p) async {
    final loc = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(loc.editAppointment),
              onTap: () async {
                Navigator.pop(ctx);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppointmentFormScreen(appointment: a),
                  ),
                );
                _load();
              },
            ),
            if (a.status == AppointmentStatus.scheduled)
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(loc.recordSession),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SessionRecordScreen(appointment: a, patient: p),
                    ),
                  );
                  _load();
                },
              ),
            if (a.status == AppointmentStatus.completed)
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(loc.viewSession),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SessionRecordScreen(appointment: a, patient: p),
                    ),
                  );
                  _load();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.confirmDelete),
        content: Text(loc.deletePatientConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirestoreService.deletePatient(widget.patientId);
      if (mounted) Navigator.pop(context);
    }
  }

  String _appointmentStatusLabel(AppointmentStatus s, AppLocalizations loc) {
    switch (s) {
      case AppointmentStatus.scheduled:
        return loc.statusScheduled;
      case AppointmentStatus.completed:
        return loc.statusCompleted;
      case AppointmentStatus.cancelled:
        return loc.statusCancelled;
      case AppointmentStatus.rescheduled:
        return loc.statusRescheduled;
    }
  }

  Color _appointmentStatusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.rescheduled:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.patientDetails)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final p = _patient;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.patientDetails)),
        body: const Center(child: Icon(Icons.error)),
      );
    }

    final isArchived = p.status == PatientStatus.archived;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.fullName),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: loc.edit,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientFormScreen(patient: p),
                ),
              );
              _load();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'archive') _archive();
              if (value == 'delete') _delete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(isArchived ? loc.reactivate : loc.archive),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(loc.delete),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.phone, loc.phone,
                        p.phone.isNotEmpty ? p.phone : loc.notInformed),
                    const Divider(height: 24),
                    _infoRow(Icons.email, loc.email,
                        p.email.isNotEmpty ? p.email : loc.notInformed),
                    const Divider(height: 24),
                    _infoRow(Icons.work, loc.occupation,
                        p.occupation.isNotEmpty ? p.occupation : loc.notInformed),
                    const Divider(height: 24),
                    _infoRow(Icons.emergency, loc.emergencyContact,
                        p.emergencyContact.isNotEmpty
                            ? p.emergencyContact
                            : loc.notInformed),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(loc.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientFormScreen(patient: p),
                            ),
                          );
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (p.posturalAnamnesis.isNotEmpty || p.injuryHistory.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.posturalAnamnesis.isNotEmpty) ...[
                        Text(loc.posturalAnamnesis,
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(p.posturalAnamnesis),
                      ],
                      if (p.posturalAnamnesis.isNotEmpty && p.injuryHistory.isNotEmpty)
                        const Divider(height: 24),
                      if (p.injuryHistory.isNotEmpty) ...[
                        Text(loc.injuryHistory,
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(p.injuryHistory),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context,
                    label: loc.sessions,
                    value: '${_sessions.length}',
                    icon: Icons.history,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    context,
                    label: loc.appointments,
                    value: '${_appointments.length}',
                    icon: Icons.calendar_today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Appointments header + add button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.appointments,
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(loc.newAppointment),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AppointmentFormScreen(preselectedPatientId: p.id),
                      ),
                    );
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_appointments.isEmpty)
              Text(loc.noAppointments,
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)))
            else
              ..._appointments.map((a) {
                final date = a.scheduledDate;
                return Card(
                  child: ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date.day.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          _monthAbbr(date.month),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    title: Text(
                      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} · ${a.durationMinutes} min',
                    ),
                    subtitle: a.notes.isNotEmpty ? Text(a.notes) : null,
                    trailing: Chip(
                      label: Text(
                        _appointmentStatusLabel(a.status, loc),
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      backgroundColor: _appointmentStatusColor(a.status),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onTap: () => _openAppointmentOptions(a, p),
                  ),
                );
              }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6))),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.onPrimaryContainer),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: colorScheme.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }

  String _monthAbbr(int month) {
    const abbr = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return abbr[month - 1];
  }
}
