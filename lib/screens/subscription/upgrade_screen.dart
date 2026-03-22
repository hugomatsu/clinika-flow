import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../../models/subscription.dart';
import '../../services/quota_service.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpgradeScreen()),
    );
  }

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  SubscriptionTier _currentTier = SubscriptionTier.free;
  bool _loading = true;
  bool _upgrading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sub = await QuotaService.getSubscription();
    if (mounted) {
      setState(() {
        _currentTier = sub.tier;
        _loading = false;
      });
    }
  }

  Future<void> _selectTier(SubscriptionTier tier) async {
    if (tier == _currentTier || _upgrading) return;
    setState(() => _upgrading = true);
    await QuotaService.upgradeTo(tier);
    if (mounted) {
      setState(() {
        _currentTier = tier;
        _upgrading = false;
      });
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.planUpgraded)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.upgradePlan),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _tierCard(
                  context,
                  tier: SubscriptionTier.free,
                  name: loc.freeTier,
                  price: 'R\$ 0',
                  color: Colors.grey.shade600,
                  limits: TierLimits.free,
                  loc: loc,
                ),
                const SizedBox(height: 12),
                _tierCard(
                  context,
                  tier: SubscriptionTier.essential,
                  name: loc.essentialTier,
                  price: 'R\$ 29,90',
                  color: Colors.blue.shade700,
                  limits: TierLimits.essential,
                  loc: loc,
                ),
                const SizedBox(height: 12),
                _tierCard(
                  context,
                  tier: SubscriptionTier.professional,
                  name: loc.professionalTier,
                  price: 'R\$ 69,90',
                  color: Colors.purple.shade700,
                  limits: TierLimits.professional,
                  loc: loc,
                  highlighted: true,
                ),
                const SizedBox(height: 12),
                _tierCard(
                  context,
                  tier: SubscriptionTier.clinic,
                  name: loc.clinicTier,
                  price: 'R\$ 149,90',
                  color: Colors.teal.shade700,
                  limits: TierLimits.clinic,
                  loc: loc,
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _tierCard(
    BuildContext context, {
    required SubscriptionTier tier,
    required String name,
    required String price,
    required Color color,
    required TierLimits limits,
    required AppLocalizations loc,
    bool highlighted = false,
  }) {
    final isCurrent = tier == _currentTier;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: highlighted ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent
            ? BorderSide(color: color, width: 2)
            : highlighted
                ? BorderSide(color: color.withValues(alpha: 0.4), width: 1.5)
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      loc.currentPlanBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '$price${loc.perMonth}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Limits
            _limitRow(Icons.people, loc.patientsLimit,
                _limitValue(limits.maxPatients, loc)),
            _limitRow(Icons.event_note, loc.sessionsMonthLimit,
                _limitValue(limits.maxSessionsPerMonth, loc)),
            _limitRow(Icons.description, loc.templatesLimit,
                _limitValue(limits.maxTemplates, loc)),
            _limitRow(Icons.send, loc.anamnesisMonthLimit,
                _limitValue(limits.maxAnamnesisPerMonth, loc)),
            _limitRow(Icons.cloud, loc.storageLimit,
                limits.maxStorageMB >= 1024 ? '${limits.maxStorageMB ~/ 1024} GB' : '${limits.maxStorageMB} MB'),
            _limitRow(
              Icons.bar_chart,
              loc.dashboardHistory,
              limits.dashboardDaysHistory == 0
                  ? loc.unlimitedLabel
                  : limits.dashboardDaysHistory == 365
                      ? loc.months12
                      : loc.days30,
            ),
            _limitRow(Icons.palette, loc.customBrandingFeature,
                limits.customBranding ? '✓' : '—'),
            _limitRow(Icons.download, loc.dataExportFeature,
                limits.dataExport ? '✓' : '—'),
            const SizedBox(height: 16),
            // Action button
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      child: Text(loc.currentPlanBadge),
                    )
                  : FilledButton(
                      onPressed: _upgrading ? null : () => _selectTier(tier),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _upgrading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(loc.selectPlan),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _limitValue(int value, AppLocalizations loc) {
    return value == 0 ? loc.unlimitedLabel : '$value';
  }

  Widget _limitRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
