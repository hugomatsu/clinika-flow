import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/patient.dart';
import '../../models/financial_record.dart';
import '../../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  int _totalPatients = 0;
  int _activePatients = 0;
  int _totalSessions = 0;
  double _totalRevenue = 0;
  double _pendingRevenue = 0;
  double _avgPainReduction = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final patients = await FirestoreService.getAllPatients();
      final sessions = await FirestoreService.getAllSessions();
      final financials = await FirestoreService.getAllFinancialRecords();

      double totalRevenue = 0;
      double pendingRevenue = 0;
      for (final f in financials) {
        if (f.paymentStatus == PaymentStatus.paid) {
          totalRevenue += f.amount;
        } else if (f.paymentStatus == PaymentStatus.pending ||
            f.paymentStatus == PaymentStatus.overdue) {
          pendingRevenue += f.amount;
        }
      }

      double avgPainReduction = 0;
      if (sessions.isNotEmpty) {
        final reductions =
            sessions.map((s) => s.prePainScore - s.postPainScore);
        avgPainReduction = reductions.reduce((a, b) => a + b) / sessions.length;
      }

      if (mounted) {
        setState(() {
          _totalPatients = patients.length;
          _activePatients =
              patients.where((p) => p.status == PatientStatus.active).length;
          _totalSessions = sessions.length;
          _totalRevenue = totalRevenue;
          _pendingRevenue = pendingRevenue;
          _avgPainReduction = avgPainReduction;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Patients section
                  _sectionTitle(context, Icons.people, loc.patients),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          context,
                          label: loc.totalPatients,
                          value: '$_totalPatients',
                          icon: Icons.people,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricCard(
                          context,
                          label: loc.activePatients,
                          value: '$_activePatients',
                          icon: Icons.person_pin,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Sessions section
                  _sectionTitle(context, Icons.history, loc.sessionHistory),
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
                          label: loc.averagePainReduction,
                          value: _totalSessions > 0
                              ? '${_avgPainReduction.toStringAsFixed(1)} pts'
                              : '—',
                          icon: Icons.trending_down,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Financial section
                  _sectionTitle(
                      context, Icons.attach_money, loc.totalRevenue),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          context,
                          label: loc.totalRevenue,
                          value: _totalSessions > 0
                              ? 'R\$ ${_totalRevenue.toStringAsFixed(2)}'
                              : '—',
                          icon: Icons.monetization_on,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _metricCard(
                          context,
                          label: loc.pendingPayments,
                          value: _pendingRevenue > 0
                              ? 'R\$ ${_pendingRevenue.toStringAsFixed(2)}'
                              : '—',
                          icon: Icons.pending_actions,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
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
