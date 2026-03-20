import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/appointment.dart';
import '../../models/patient.dart';
import '../../models/session_record.dart';
import '../../services/firestore_service.dart';

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
  double _prePain = 0;
  double _postPain = 0;
  final _observationsCtrl = TextEditingController();
  final Set<String> _selectedTechniques = {};
  bool _saving = false;

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
  void dispose() {
    _observationsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final record = SessionRecord();
    record.appointmentId = widget.appointment.id;
    record.prePainScore = _prePain.round();
    record.postPainScore = _postPain.round();
    record.techniques = _selectedTechniques.toList();
    record.observations = _observationsCtrl.text.trim();
    record.sessionDateTime = DateTime.now();

    await FirestoreService.createSessionRecord(record);

    // Mark appointment as completed
    final appointment = widget.appointment;
    appointment.status = AppointmentStatus.completed;
    await FirestoreService.updateAppointment(appointment);

    if (mounted) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.sessionSaved)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.recordSession),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Patient + appointment info
          Card(
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
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              subtitle: Text(
                '${widget.appointment.scheduledDate.day.toString().padLeft(2, '0')}/${widget.appointment.scheduledDate.month.toString().padLeft(2, '0')}/${widget.appointment.scheduledDate.year} · ${widget.appointment.durationMinutes} min',
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Pre-session pain VAS
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sentiment_very_dissatisfied,
                          color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        loc.prePainScore,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('0', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _prePain,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: _prePain.round().toString(),
                          onChanged: (v) => setState(() => _prePain = v),
                        ),
                      ),
                      const Text('10', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      _vasChip(_prePain.round(), colorScheme),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Post-session pain VAS
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sentiment_satisfied,
                          color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        loc.postPainScore,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('0', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _postPain,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: _postPain.round().toString(),
                          activeColor: Colors.green.shade600,
                          onChanged: (v) => setState(() => _postPain = v),
                        ),
                      ),
                      const Text('10', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      _vasChip(_postPain.round(), colorScheme,
                          color: Colors.green.shade600),
                    ],
                  ),
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
                  Row(
                    children: [
                      Icon(Icons.medical_services, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        loc.techniquesApplied,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _defaultTechniques.map((t) {
                      final selected = _selectedTechniques.contains(t);
                      return FilterChip(
                        label: Text(t, style: const TextStyle(fontSize: 13)),
                        selected: selected,
                        onSelected: (v) {
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
                  Row(
                    children: [
                      Icon(Icons.notes, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        loc.sessionObservations,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _observationsCtrl,
                    maxLines: 5,
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
          const SizedBox(height: 24),
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
