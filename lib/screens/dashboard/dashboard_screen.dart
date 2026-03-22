import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/follow_up.dart';
import '../../models/patient.dart';
import '../../models/session_record.dart';
import '../../models/session_template.dart';
import '../../services/communication_service.dart';
import '../../services/firestore_service.dart';
import '../../services/quota_gate.dart';
import '../../services/quota_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  bool _isAnnual = false;
  DateTime _currentDate = DateTime.now();
  int _dashboardDaysLimit = 0; // 0 = unlimited

  // Raw data
  List<Patient> _allPatients = [];
  List<SessionRecord> _allSessions = [];
  List<SessionTemplate> _allTemplates = [];

  // Communication data
  List<FollowUp> _pendingFollowUps = [];
  List<InactivePatient> _inactivePatients = [];
  String _clinicName = '';

  // Computed stats
  int _newPatients = 0;
  int _recurringPatients = 0;
  int _totalSessions = 0;
  String _bestWeekSessions = '—';
  double _totalReceived = 0;
  String _bestWeekReceived = '—';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        FirestoreService.getAllPatients(),
        FirestoreService.getAllSessions(),
        FirestoreService.getAllTemplates(),
        QuotaService.getSubscription(),
        FirestoreService.getPendingFollowUps(),
        FirestoreService.getInactivePatients(daysThreshold: 30),
        FirestoreService.getBranding(),
      ]);

      if (mounted) {
        final branding = results[6] as dynamic;
        setState(() {
          _allPatients = results[0] as List<Patient>;
          _allSessions = results[1] as List<SessionRecord>;
          _allTemplates = results[2] as List<SessionTemplate>;
          _dashboardDaysLimit =
              (results[3] as dynamic).limits.dashboardDaysHistory as int;
          _pendingFollowUps = results[4] as List<FollowUp>;
          _inactivePatients = results[5] as List<InactivePatient>;
          _clinicName = branding?.clinicName ?? 'Clinika Flow';
          _loading = false;
        });
        _computeStats();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _computeStats() {
    final DateTime start;
    final DateTime end;

    if (_isAnnual) {
      start = DateTime(_currentDate.year);
      end = DateTime(_currentDate.year + 1);
    } else {
      start = DateTime(_currentDate.year, _currentDate.month);
      end = DateTime(_currentDate.year, _currentDate.month + 1);
    }

    // Filter sessions in period
    final periodSessions = _allSessions
        .where((s) =>
            s.sessionDateTime.isAfter(start) &&
            s.sessionDateTime.isBefore(end))
        .toList();

    // Patients stats
    final newPatients = _allPatients
        .where((p) => p.createdAt.isAfter(start) && p.createdAt.isBefore(end))
        .length;

    // Recurring patients: patients with more than 1 session in this period
    final patientSessionCounts = <String, int>{};
    for (final s in periodSessions) {
      patientSessionCounts[s.appointmentId] =
          (patientSessionCounts[s.appointmentId] ?? 0) + 1;
    }
    // We need appointment → patient mapping. For now, count unique appointments
    // with sessions in this period. A recurring patient has sessions in a
    // previous period AND this period.
    final periodPatientIds = <String>{};
    for (final s in periodSessions) {
      periodPatientIds.add(s.appointmentId);
    }
    // Patients who had sessions before `start` AND in this period
    final previousPatientIds = <String>{};
    for (final s in _allSessions) {
      if (s.sessionDateTime.isBefore(start)) {
        previousPatientIds.add(s.appointmentId);
      }
    }
    final recurring =
        periodPatientIds.intersection(previousPatientIds).length;

    // Revenue from currency fields in session fieldValues
    double totalReceived = 0;
    // Find currency field GUIDs across templates
    final currencyGuids = <String>{};
    for (final t in _allTemplates) {
      for (final f in t.fields) {
        if (f.type == FieldType.currency) {
          currencyGuids.add(f.guid);
        }
      }
    }
    for (final s in periodSessions) {
      for (final guid in currencyGuids) {
        final val = s.fieldValues[guid];
        if (val != null) {
          totalReceived += (val is num) ? val.toDouble() : 0;
        }
      }
    }

    // Best week: group sessions by ISO week
    final weekSessions = <int, List<SessionRecord>>{};
    final weekRevenue = <int, double>{};
    for (final s in periodSessions) {
      final weekKey = _weekNumber(s.sessionDateTime);
      weekSessions.putIfAbsent(weekKey, () => []).add(s);
      double rev = 0;
      for (final guid in currencyGuids) {
        final val = s.fieldValues[guid];
        if (val != null && val is num) rev += val.toDouble();
      }
      weekRevenue[weekKey] = (weekRevenue[weekKey] ?? 0) + rev;
    }

    int bestWeekSessionCount = 0;
    double bestWeekRevenue = 0;
    for (final entry in weekSessions.entries) {
      if (entry.value.length > bestWeekSessionCount) {
        bestWeekSessionCount = entry.value.length;
      }
    }
    for (final entry in weekRevenue.entries) {
      if (entry.value > bestWeekRevenue) {
        bestWeekRevenue = entry.value;
      }
    }

    setState(() {
      _newPatients = newPatients;
      _recurringPatients = recurring;
      _totalSessions = periodSessions.length;
      _bestWeekSessions =
          bestWeekSessionCount > 0 ? '$bestWeekSessionCount' : '—';
      _totalReceived = totalReceived;
      _bestWeekReceived = bestWeekRevenue > 0
          ? 'R\$ ${bestWeekRevenue.toStringAsFixed(2)}'
          : '—';
    });
  }

  int _weekNumber(DateTime date) {
    // Year-week composite key
    final dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays;
    final week = (dayOfYear / 7).floor() + 1;
    return date.year * 100 + week;
  }

  bool _canNavigateBack() {
    if (_dashboardDaysLimit == 0) return true; // unlimited
    final earliest =
        DateTime.now().subtract(Duration(days: _dashboardDaysLimit));
    if (_isAnnual) {
      return DateTime(_currentDate.year - 1) .isAfter(earliest);
    } else {
      return DateTime(_currentDate.year, _currentDate.month - 1)
          .isAfter(earliest);
    }
  }

  void _navigate(int delta) {
    if (delta < 0 && !_canNavigateBack()) return;
    setState(() {
      if (_isAnnual) {
        _currentDate =
            DateTime(_currentDate.year + delta, _currentDate.month);
      } else {
        _currentDate =
            DateTime(_currentDate.year, _currentDate.month + delta);
      }
    });
    _computeStats();
  }

  void _toggleMode(bool annual) {
    setState(() {
      _isAnnual = annual;
      _currentDate = DateTime.now();
    });
    _computeStats();
  }

  String _periodLabel() {
    final locale = Localizations.localeOf(context).toString();
    if (_isAnnual) {
      return '${_currentDate.year}';
    }
    return DateFormat.yMMMM(locale).format(_currentDate);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.dashboard),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Period toggle + navigation
                  _buildPeriodSelector(loc, colorScheme),
                  const SizedBox(height: 16),

                  // Patients section
                  _sectionTitle(context, Icons.people, loc.patients),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          context,
                          label: loc.newPatients,
                          value: '$_newPatients',
                          icon: Icons.person_add,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricCard(
                          context,
                          label: loc.recurringPatients,
                          value: '$_recurringPatients',
                          icon: Icons.replay,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sessions section
                  _sectionTitle(context, Icons.history, loc.sessions),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          context,
                          label: loc.totalSessions,
                          value: '$_totalSessions',
                          icon: Icons.event_note,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricCard(
                          context,
                          label: loc.bestWeekSessions,
                          value: _bestWeekSessions,
                          icon: Icons.star,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Financial section
                  _sectionTitle(context, Icons.attach_money, loc.finance),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          context,
                          label: loc.totalReceived,
                          value: _totalReceived > 0
                              ? 'R\$ ${_totalReceived.toStringAsFixed(2)}'
                              : '—',
                          icon: Icons.monetization_on,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricCard(
                          context,
                          label: loc.bestWeek,
                          value: _bestWeekReceived,
                          icon: Icons.trending_up,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Follow-ups section
                  _sectionTitle(
                      context, Icons.chat_outlined, loc.followUps),
                  const SizedBox(height: 8),
                  if (_pendingFollowUps.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.green.shade600),
                            const SizedBox(width: 12),
                            Text(loc.noFollowUps),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._pendingFollowUps.map(
                        (f) => _followUpCard(f, loc, colorScheme)),

                  const SizedBox(height: 24),

                  // Re-engagement section
                  _sectionTitle(
                      context, Icons.person_search, loc.reengagement),
                  const SizedBox(height: 8),
                  if (_inactivePatients.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.green.shade600),
                            const SizedBox(width: 12),
                            Text(loc.noInactivePatients),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._inactivePatients
                        .map((ip) => _reengagementCard(ip, loc, colorScheme)),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations loc, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Month/Year toggle
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(loc.monthly)),
                ButtonSegment(value: true, label: Text(loc.annual)),
              ],
              selected: {_isAnnual},
              onSelectionChanged: (v) => _toggleMode(v.first),
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const Spacer(),
            // Navigation
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _canNavigateBack() ? () => _navigate(-1) : null,
            ),
            Text(
              _periodLabel(),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _navigate(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  // ── Follow-up card ──────────────────────────────────────────────────────

  Widget _followUpCard(
      FollowUp followUp, AppLocalizations loc, ColorScheme colorScheme) {
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMd(locale).format(followUp.scheduledAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.followUpWith(followUp.patientName),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              loc.followUpSessionInfo(dateStr),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _sendFollowUp(followUp, loc),
                  icon: const Icon(Icons.send, size: 16),
                  label: Text(loc.sendWhatsApp),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _snoozeFollowUp(followUp, loc),
                  child: Text(loc.snooze),
                ),
                TextButton(
                  onPressed: () => _dismissFollowUp(followUp, loc),
                  child: Text(loc.dismiss),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFollowUp(FollowUp followUp, AppLocalizations loc) async {
    if (followUp.patientWhatsapp.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.noWhatsApp)));
      }
      return;
    }

    final allowed =
        await QuotaGate.checkAndGate(context, QuotaResource.followUps);
    if (!allowed) return;

    final patient = Patient(
      fullName: followUp.patientName,
      whatsapp: followUp.patientWhatsapp,
    );
    final firstName = CommunicationService.firstName(patient);
    final message = loc.msgPostSessionPt(firstName, _clinicName);

    final sent =
        await CommunicationService.openWhatsApp(patient: patient, message: message);
    if (sent) {
      followUp.status = FollowUpStatus.sent;
      followUp.sentAt = DateTime.now();
      followUp.channel = 'whatsapp';
      await FirestoreService.updateFollowUp(followUp);
      await FirestoreService.markPatientContacted(followUp.patientId);
      await QuotaService.incrementFollowUpCount();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.followUpSent)));
        _loadData();
      }
    }
  }

  Future<void> _snoozeFollowUp(FollowUp followUp, AppLocalizations loc) async {
    followUp.snoozedUntil = DateTime.now().add(const Duration(hours: 24));
    await FirestoreService.updateFollowUp(followUp);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.followUpSnoozed)));
      _loadData();
    }
  }

  Future<void> _dismissFollowUp(
      FollowUp followUp, AppLocalizations loc) async {
    followUp.status = FollowUpStatus.dismissed;
    await FirestoreService.updateFollowUp(followUp);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.followUpDismissed)));
      _loadData();
    }
  }

  // ── Re-engagement card ─────────────────────────────────────────────────

  Widget _reengagementCard(
      InactivePatient ip, AppLocalizations loc, ColorScheme colorScheme) {
    final Color badgeColor;
    final String badge;
    if (ip.daysSinceLastSession >= 90) {
      badgeColor = Colors.red.shade600;
      badge = loc.dormant;
    } else if (ip.daysSinceLastSession >= 60) {
      badgeColor = Colors.orange.shade700;
      badge = loc.inactive;
    } else {
      badgeColor = Colors.amber.shade700;
      badge = loc.atRisk;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          ip.patient.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.lastSessionDaysAgo(ip.daysSinceLastSession),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: loc.sendWhatsApp,
              onPressed: () => _sendReengagement(ip, loc),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReengagement(
      InactivePatient ip, AppLocalizations loc) async {
    if (ip.patient.whatsapp.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.noWhatsApp)));
      }
      return;
    }

    final allowed =
        await QuotaGate.checkAndGate(context, QuotaResource.followUps);
    if (!allowed) return;

    final firstName = CommunicationService.firstName(ip.patient);
    final message = loc.msgReengagePt(firstName, _clinicName);

    final sent = await CommunicationService.openWhatsApp(
        patient: ip.patient, message: message);
    if (sent) {
      await FirestoreService.markPatientContacted(ip.patient.id);
      await QuotaService.incrementFollowUpCount();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.followUpSent)));
        _loadData();
      }
    }
  }

  // ── Metric card ────────────────────────────────────────────────────────

  Widget _metricCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
