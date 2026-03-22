import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/patient.dart';
import '../../services/firestore_service.dart';
import '../../services/quota_gate.dart';
import '../../services/quota_service.dart';
import '../subscription/upgrade_screen.dart';
import 'patient_form_screen.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Patient> _allPatients = [];
  List<Patient> _filtered = [];
  PatientStatus? _statusFilter;
  final _searchController = TextEditingController();
  QuotaResult? _patientQuota;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final patients = await FirestoreService.getAllPatients();
      final quota = await QuotaService.checkPatients();
      if (mounted) {
        setState(() {
          _allPatients = patients;
          _patientQuota = quota;
          _applyFilter();
        });
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _allPatients.where((p) {
        final matchesQuery = query.isEmpty || p.fullName.toLowerCase().contains(query);
        final matchesStatus = _statusFilter == null || p.status == _statusFilter;
        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  Future<void> _openForm({Patient? patient}) async {
    // Gate new patient creation
    if (patient == null) {
      final allowed =
          await QuotaGate.checkAndGate(context, QuotaResource.patients);
      if (!allowed) return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientFormScreen(patient: patient),
      ),
    );
    _load();
  }

  Future<void> _openDetail(Patient patient) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailScreen(patientId: patient.id),
      ),
    );
    _load();
  }

  Color _statusColor(PatientStatus status) {
    switch (status) {
      case PatientStatus.active:
        return Colors.green;
      case PatientStatus.inactive:
        return Colors.orange;
      case PatientStatus.archived:
        return Colors.grey;
    }
  }

  String _statusLabel(PatientStatus status, AppLocalizations loc) {
    switch (status) {
      case PatientStatus.active:
        return loc.statusActive;
      case PatientStatus.inactive:
        return loc.statusInactive;
      case PatientStatus.archived:
        return loc.statusArchived;
    }
  }

  Widget _quotaBanner(AppLocalizations loc, ColorScheme colorScheme) {
    final q = _patientQuota!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loc.quotaNearLimit(q.current, q.limit, loc.resourcePatients),
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ),
          TextButton(
            onPressed: () => _openUpgrade(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(loc.upgrade, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _openUpgrade() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UpgradeScreen(),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.patients),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: loc.searchPatients,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: loc.filter,
                  icon: Badge(
                    isLabelVisible: _statusFilter != null,
                    child: const Icon(Icons.filter_list),
                  ),
                  onPressed: () => _showFilterSheet(context, loc),
                ),
              ],
            ),
          ),
          if (_patientQuota != null && _patientQuota!.isNearLimit)
            _quotaBanner(loc, colorScheme),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      loc.noPatients,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final p = _filtered[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                p.fullName.isNotEmpty
                                    ? p.fullName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              p.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              p.whatsapp.isNotEmpty ? p.whatsapp : p.email,
                            ),
                            trailing: Chip(
                              label: Text(
                                _statusLabel(p.status, loc),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: _statusColor(p.status),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            onTap: () => _openDetail(p),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_patients',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: Text(loc.newPatient),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _filterTile(ctx, loc.all, null, loc),
            _filterTile(ctx, loc.statusActive, PatientStatus.active, loc),
            _filterTile(ctx, loc.statusInactive, PatientStatus.inactive, loc),
            _filterTile(ctx, loc.statusArchived, PatientStatus.archived, loc),
          ],
        ),
      ),
    );
  }

  Widget _filterTile(BuildContext ctx, String label, PatientStatus? status,
      AppLocalizations loc) {
    final selected = _statusFilter == status;
    return ListTile(
      title: Text(label),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () {
        setState(() => _statusFilter = status);
        _applyFilter();
        Navigator.pop(ctx);
      },
    );
  }
}
