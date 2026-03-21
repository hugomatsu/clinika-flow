import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/anamnesis_request.dart';
import '../../models/patient.dart';
import '../../models/appointment.dart';
import '../../models/session_record.dart';
import '../../models/session_template.dart';
import '../../services/firestore_service.dart';
import '../../services/image_service.dart';
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
  List<SessionTemplate> _templates = [];
  AnamnesisRequest? _anamnesisRequest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final patient = await FirestoreService.getPatientById(widget.patientId);

      List<Appointment> appointments = [];
      List<SessionRecord> patientSessions = [];
      List<SessionTemplate> templates = [];
      try {
        appointments =
            await FirestoreService.getAppointmentsByPatient(widget.patientId);
        final sessions = await FirestoreService.getAllSessions();
        final apptIds = appointments.map((a) => a.id).toSet();
        patientSessions =
            sessions.where((s) => apptIds.contains(s.appointmentId)).toList();
        templates = await FirestoreService.getAllTemplates();
      } catch (e) {
        debugPrint('Failed to load appointments/sessions: $e');
      }

      AnamnesisRequest? anamnesisReq;
      try {
        anamnesisReq = await FirestoreService.getActiveAnamnesisRequest(
            widget.patientId);

        // Copy completed external anamnesis response to the patient document.
        if (anamnesisReq != null &&
            anamnesisReq.status == AnamnesisRequestStatus.completed &&
            anamnesisReq.responseData.isNotEmpty &&
            patient != null &&
            patient.anamnesisData.isEmpty) {
          patient.anamnesisTemplateId = anamnesisReq.templateId;
          patient.anamnesisTemplateVersion = anamnesisReq.templateVersion;
          patient.anamnesisData =
              Map<String, dynamic>.from(anamnesisReq.responseData);
          await FirestoreService.updatePatient(patient);
        }
      } catch (e) {
        debugPrint('Failed to load anamnesis request: $e');
      }

      if (mounted) {
        setState(() {
          _patient = patient;
          _appointments = appointments;
          _sessions = patientSessions;
          _templates = templates;
          _anamnesisRequest = anamnesisReq;
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

  Future<void> _openAnamnesis(Patient p) async {
    final loc = AppLocalizations.of(context)!;

    // Pick template if none set yet
    String tmplId = p.anamnesisTemplateId;
    if (tmplId.isEmpty && _templates.isNotEmpty) {
      final picked = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(loc.selectTemplate,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              ..._templates.map((t) => ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(t.name),
                    subtitle: t.description.isNotEmpty
                        ? Text(t.description, maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                    onTap: () => Navigator.pop(ctx, t.id),
                  )),
            ],
          ),
        ),
      );
      if (picked == null) return;
      tmplId = picked;
    }

    if (tmplId.isEmpty) return;

    final tmpl = await FirestoreService.getTemplateById(tmplId);
    if (tmpl == null || !mounted) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _AnamnesisFormScreen(
          template: tmpl,
          initialValues: Map<String, dynamic>.from(p.anamnesisData),
          patientName: p.fullName,
        ),
      ),
    );

    if (result != null && mounted) {
      p.anamnesisTemplateId = tmplId;
      p.anamnesisTemplateVersion = tmpl.currentVersion;
      p.anamnesisData = result;
      await FirestoreService.updatePatient(p);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.anamnesisSaved)));
      _load();
    }
  }

  Future<void> _sendAnamnesis(Patient p) async {
    final loc = AppLocalizations.of(context)!;

    // Pick template
    String? tmplId;
    if (_templates.isEmpty) return;

    if (_templates.length == 1) {
      tmplId = _templates.first.id;
    } else {
      tmplId = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(loc.selectTemplate,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              ..._templates.map((t) => ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(t.name),
                    subtitle: t.description.isNotEmpty
                        ? Text(t.description,
                            maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                    onTap: () => Navigator.pop(ctx, t.id),
                  )),
            ],
          ),
        ),
      );
    }

    if (tmplId == null || !mounted) return;

    final tmpl = await FirestoreService.getTemplateById(tmplId);
    if (tmpl == null || !mounted) return;

    // Fetch branding for clinic name + logo
    final branding = await FirestoreService.getBranding();

    final request = AnamnesisRequest(
      patientId: p.id,
      patientName: p.fullName,
      clinicName: branding?.clinicName ?? '',
      clinicLogoUrl: branding?.logoUrl ?? '',
      templateId: tmpl.id,
      templateVersion: tmpl.currentVersion,
      fieldsSnapshot: tmpl.fields.map((f) => f.copyWith()).toList(),
    );

    final created = await FirestoreService.createAnamnesisRequest(request);

    if (!mounted) return;

    final link = 'https://clinika-flow.web.app/anamnesis/${created.id}';

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link, size: 48, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(height: 16),
              Text(loc.anamnesisSent,
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              SelectableText(link,
                  style: TextStyle(
                      color: Theme.of(ctx).colorScheme.primary,
                      fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(loc.anamnesisLinkCopied)));
                      },
                      icon: const Icon(Icons.copy),
                      label: Text(loc.copyLink),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    _load();
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

            // ── Anamnesis section ──
            const SizedBox(height: 16),
            _buildAnamnesisSection(p, loc, colorScheme),

            // ── Stats & Activity section ──
            const SizedBox(height: 24),
            Text(loc.sessionHistoryTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
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

            // Sessions history
            const SizedBox(height: 12),
            _buildSessionsHistory(loc, colorScheme),

            // Appointments
            const SizedBox(height: 16),
            _buildAppointmentsSection(p, loc, colorScheme),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Anamnesis section ─────────────────────────────────────────────────────

  Widget _buildAnamnesisSection(
      Patient p, AppLocalizations loc, ColorScheme colorScheme) {
    final hasLegacy =
        p.posturalAnamnesis.isNotEmpty || p.injuryHistory.isNotEmpty;
    final hasTemplate = p.anamnesisData.isNotEmpty;
    final req = _anamnesisRequest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.anamnesis,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        // Action buttons row — send externally + fill in-app
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _sendAnamnesis(p),
                icon: const Icon(Icons.send, size: 18),
                label: Text(loc.sendAnamnesis, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _openAnamnesis(p),
                icon: Icon(hasTemplate ? Icons.edit : Icons.add, size: 18),
                label: Text(
                    hasTemplate ? loc.editAnamnesis : loc.fillAnamnesis,
                    overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // External anamnesis request status card
        if (req != null) _buildExternalAnamnesisCard(req, loc, colorScheme),

        // Legacy text fields
        if (hasLegacy)
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
                  if (p.posturalAnamnesis.isNotEmpty &&
                      p.injuryHistory.isNotEmpty)
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
        // Template-based anamnesis summary
        if (hasTemplate)
          Card(
            child: ListTile(
              leading: Icon(Icons.assignment_turned_in,
                  color: Colors.green.shade700),
              title: Text(loc.anamnesis),
              subtitle: Text(loc.subTemplateCompleted),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openAnamnesis(p),
            ),
          ),
      ],
    );
  }

  Widget _buildExternalAnamnesisCard(
      AnamnesisRequest req, AppLocalizations loc, ColorScheme colorScheme) {
    final IconData icon;
    final String label;
    final Color color;

    switch (req.status) {
      case AnamnesisRequestStatus.pending:
        icon = Icons.hourglass_empty;
        label = loc.anamnesisStatusPending;
        color = Colors.amber.shade700;
      case AnamnesisRequestStatus.opened:
        icon = Icons.visibility;
        label = loc.anamnesisStatusOpened;
        color = Colors.blue.shade700;
      case AnamnesisRequestStatus.completed:
        icon = Icons.check_circle;
        label = loc.anamnesisStatusCompleted;
        color = Colors.green.shade700;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        subtitle: req.status == AnamnesisRequestStatus.completed
            ? null
            : Text(
                'https://clinika-flow.web.app/anamnesis/${req.id}',
                style: TextStyle(fontSize: 11, color: colorScheme.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: req.status != AnamnesisRequestStatus.completed
            ? IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: loc.copyLink,
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text:
                          'https://clinika-flow.web.app/anamnesis/${req.id}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.anamnesisLinkCopied)));
                },
              )
            : Icon(Icons.chevron_right,
                color: colorScheme.onSurface.withValues(alpha: 0.3)),
        onTap: req.status == AnamnesisRequestStatus.completed
            ? () => _openAnamnesis(_patient!)
            : null,
      ),
    );
  }

  // ── Sessions history ──────────────────────────────────────────────────────

  Widget _buildSessionsHistory(AppLocalizations loc, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_sessions.isEmpty)
          Text(loc.noSessions,
              style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5)))
        else
          ..._sessions.map((s) {
            final date = s.sessionDateTime;
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
                    Text(_monthAbbr(date.month),
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
                title: Text(DateFormat('dd/MM/yyyy – HH:mm',
                        Localizations.localeOf(context).toString())
                    .format(date)),
                subtitle: s.observations.isNotEmpty
                    ? Text(s.observations,
                        maxLines: 2, overflow: TextOverflow.ellipsis)
                    : null,
                trailing: Icon(Icons.chevron_right,
                    color: colorScheme.onSurface.withValues(alpha: 0.3)),
                onTap: () {
                  // Find the appointment for this session
                  final appt = _appointments
                      .where((a) => a.id == s.appointmentId)
                      .toList();
                  if (appt.isNotEmpty && _patient != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionRecordScreen(
                          appointment: appt.first,
                          patient: _patient!,
                        ),
                      ),
                    ).then((_) => _load());
                  }
                },
              ),
            );
          }),
      ],
    );
  }

  // ── Appointments section ──────────────────────────────────────────────────

  Widget _buildAppointmentsSection(
      Patient p, AppLocalizations loc, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5)))
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
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

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

// ── Anamnesis form screen (template-based) ──────────────────────────────────

class _AnamnesisFormScreen extends StatefulWidget {
  final SessionTemplate template;
  final Map<String, dynamic> initialValues;
  final String patientName;

  const _AnamnesisFormScreen({
    required this.template,
    required this.initialValues,
    required this.patientName,
  });

  @override
  State<_AnamnesisFormScreen> createState() => _AnamnesisFormScreenState();
}

class _AnamnesisFormScreenState extends State<_AnamnesisFormScreen> {
  late List<FieldDefinition> _fields;
  final Map<String, dynamic> _values = {};

  @override
  void initState() {
    super.initState();
    _fields = widget.template.fields.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    _values.addAll(widget.initialValues);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.anamnesis),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: loc.save,
            onPressed: () => Navigator.pop(context, _values),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Patient header
          Card(
            color: colorScheme.primaryContainer,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary,
                child: Text(
                  widget.patientName.isNotEmpty
                      ? widget.patientName[0].toUpperCase()
                      : '?',
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
              ),
              title: Text(widget.patientName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer)),
              subtitle: Text(widget.template.name,
                  style: TextStyle(color: colorScheme.onPrimaryContainer)),
            ),
          ),
          const SizedBox(height: 16),
          ..._fields.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildField(f, colorScheme),
              )),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, _values),
            icon: const Icon(Icons.check),
            label: Text(loc.save),
          ),
        ],
      ),
    );
  }

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
                Text(field.label,
                    style: Theme.of(context).textTheme.titleSmall),
                Slider(
                  value: val,
                  min: mn,
                  max: mx,
                  divisions: divisions > 0 ? divisions : null,
                  label: val.round().toString(),
                  onChanged: (v) =>
                      setState(() => _values[field.guid] = v),
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
              // ignore: deprecated_member_use
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
                Text(field.label,
                    style: Theme.of(context).textTheme.titleSmall),
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
        final val = (_values[field.guid] ?? field.config['defaultValue'] ?? false) as bool;
        return Card(
          child: SwitchListTile(
            title: Text(field.label,
                style: Theme.of(context).textTheme.titleSmall),
            value: val,
            onChanged: (v) => setState(() => _values[field.guid] = v),
          ),
        );

      case FieldType.image:
        return _buildImage(field, colorScheme);

      case FieldType.subTemplate:
        return Card(
          child: ListTile(
            leading: Icon(Icons.article_outlined, color: colorScheme.primary),
            title: Text(field.label),
          ),
        );
    }
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showImageSourceSheet(field, loc),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(loc.addPhoto),
              ),
            ),
            if (urls.isEmpty && hint.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(hint,
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5))),
              ),
          ],
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
              child: Image.network(url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image, color: Colors.white54, size: 64)),
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
}
