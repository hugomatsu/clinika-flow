import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/appointment.dart';
import '../../models/patient.dart';
import '../../services/firestore_service.dart';
import 'appointment_form_screen.dart';
import '../sessions/session_record_screen.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  List<Appointment> _appointments = [];
  Map<String, Patient> _patientMap = {};
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();
  bool _weekView = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await FirestoreService.getAllAppointments();
      final patients = await FirestoreService.getAllPatients();
      final patientMap = {for (final p in patients) p.id: p};
      if (mounted) {
        setState(() {
          _appointments = all;
          _patientMap = patientMap;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  DateTime get _weekStart {
    final d = _selectedDate;
    return DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: d.weekday - 1));
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  List<Appointment> _appointmentsForDay(DateTime day) {
    return _appointments.where((a) {
      final s = a.scheduledDate;
      return s.year == day.year && s.month == day.month && s.day == day.day;
    }).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  List<Appointment> get _weekAppointments {
    final start = _weekStart;
    final end = start.add(const Duration(days: 7));
    return _appointments
        .where((a) =>
            !a.scheduledDate.isBefore(start) && a.scheduledDate.isBefore(end))
        .toList();
  }

  List<Appointment> get _forSelectedDate =>
      _appointmentsForDay(_selectedDate);

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  // ── Status helpers ─────────────────────────────────────────────────────────

  String _statusLabel(AppointmentStatus s, AppLocalizations loc) {
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

  Color _statusColor(AppointmentStatus s) {
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

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _openOptions(Appointment a) async {
    final loc = AppLocalizations.of(context)!;
    final patient = _patientMap[a.patientId];

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
            if (a.status == AppointmentStatus.scheduled && patient != null)
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(loc.recordSession),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SessionRecordScreen(appointment: a, patient: patient),
                    ),
                  );
                  _load();
                },
              ),
            if (a.status == AppointmentStatus.completed && patient != null)
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(loc.viewSession),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SessionRecordScreen(appointment: a, patient: patient),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appointments),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(_weekView ? Icons.view_day_outlined : Icons.view_week_outlined),
            tooltip: _weekView ? loc.dayView : loc.weekView,
            onPressed: () => setState(() => _weekView = !_weekView),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _weekView
              ? _buildWeekView(loc, colorScheme)
              : _buildDayView(loc, colorScheme),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_appointments',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AppointmentFormScreen(),
            ),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: Text(loc.newAppointment),
      ),
    );
  }

  // ── Week View ──────────────────────────────────────────────────────────────

  Widget _buildWeekView(AppLocalizations loc, ColorScheme colorScheme) {
    final weekAppts = _weekAppointments;
    final done = weekAppts
        .where((a) => a.status == AppointmentStatus.completed)
        .length;
    final total = weekAppts.length;
    final progress = total == 0 ? 0.0 : done / total;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          // Progress header
          Container(
            color: colorScheme.primaryContainer,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() =>
                          _selectedDate =
                              _selectedDate.subtract(const Duration(days: 7))),
                    ),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Text(
                        _weekRangeLabel(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() =>
                          _selectedDate =
                              _selectedDate.add(const Duration(days: 7))),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.weekConsultsDone(done, total),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '$done/$total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor:
                        colorScheme.onPrimaryContainer.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      done == total && total > 0
                          ? Colors.green
                          : colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          // Day sections
          ..._weekDays.map((day) => _buildDaySection(day, loc, colorScheme)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDaySection(
      DateTime day, AppLocalizations loc, ColorScheme colorScheme) {
    final appts = _appointmentsForDay(day);
    final isNow = _isToday(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isNow
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _dayLabel(day, loc),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        isNow ? colorScheme.onPrimary : colorScheme.onSurface,
                  ),
                ),
              ),
              if (appts.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '${appts.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (appts.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              loc.noAppointments,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          )
        else
          ...appts.map((a) => Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: _appointmentCard(a, loc, colorScheme),
              )),
      ],
    );
  }

  // ── Day View ───────────────────────────────────────────────────────────────

  Widget _buildDayView(AppLocalizations loc, ColorScheme colorScheme) {
    final dayAppts = _forSelectedDate;

    return Column(
      children: [
        Container(
          color: colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _selectedDate =
                        _selectedDate.subtract(const Duration(days: 7))),
                  ),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Text(
                      '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() =>
                        _selectedDate =
                            _selectedDate.add(const Duration(days: 7))),
                  ),
                ],
              ),
              SizedBox(
                height: 64,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: 7,
                  itemBuilder: (context, i) {
                    final day = _selectedDate
                        .subtract(
                            Duration(days: _selectedDate.weekday - 1 - i))
                        .copyWith(
                            hour: 0, minute: 0, second: 0, millisecond: 0);
                    final isSelected = day.day == _selectedDate.day &&
                        day.month == _selectedDate.month &&
                        day.year == _selectedDate.year;
                    final isNow = _isToday(day);
                    final hasAppts = _appointments.any((a) {
                      final s = a.scheduledDate;
                      return s.year == day.year &&
                          s.month == day.month &&
                          s.day == day.day;
                    });

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = day),
                      child: Container(
                        width: 44,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _weekdayAbbr(day.weekday),
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontWeight: isNow
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onPrimaryContainer,
                              ),
                            ),
                            if (hasAppts)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: dayAppts.isEmpty
              ? Center(
                  child: Text(
                    loc.noAppointments,
                    style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: dayAppts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) =>
                        _appointmentCard(dayAppts[index], loc, colorScheme),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Shared appointment card ────────────────────────────────────────────────

  Widget _appointmentCard(
      Appointment a, AppLocalizations loc, ColorScheme colorScheme) {
    final patient = _patientMap[a.patientId];
    final time = a.scheduledDate;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(a.status).withValues(alpha: 0.15),
          child: Icon(Icons.access_time, color: _statusColor(a.status)),
        ),
        title: Text(
          patient?.fullName ?? '—',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} · ${a.durationMinutes} min',
        ),
        trailing: Chip(
          label: Text(
            _statusLabel(a.status, loc),
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: _statusColor(a.status),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onTap: () => _openOptions(a),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _weekRangeLabel() {
    final days = _weekDays;
    final start = days.first;
    final end = days.last;
    if (start.month == end.month) {
      return '${start.day}–${end.day} ${_monthAbbr(start.month)} ${start.year}';
    }
    return '${start.day} ${_monthAbbr(start.month)} – ${end.day} ${_monthAbbr(end.month)} ${end.year}';
  }

  String _dayLabel(DateTime day, AppLocalizations loc) {
    if (_isToday(day)) {
      return '${loc.today}, ${day.day} ${_monthAbbr(day.month)}';
    }
    return '${_weekdayFull(day.weekday)}, ${day.day} ${_monthAbbr(day.month)}';
  }

  String _weekdayAbbr(int weekday) {
    const abbr = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return abbr[weekday - 1];
  }

  String _weekdayFull(int weekday) {
    const full = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo'
    ];
    return full[weekday - 1];
  }

  String _monthAbbr(int month) {
    const abbr = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return abbr[month - 1];
  }
}
