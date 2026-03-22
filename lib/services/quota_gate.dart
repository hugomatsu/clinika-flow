import 'package:flutter/material.dart';
import 'package:clinika_flow/l10n/app_localizations.dart';
import '../screens/subscription/upgrade_screen.dart';
import 'quota_service.dart';

/// Utility for checking quotas and showing limit dialogs.
class QuotaGate {
  /// Returns true if the action is allowed. Shows a dialog and returns false if blocked.
  static Future<bool> checkAndGate(
    BuildContext context,
    QuotaResource resource,
  ) async {
    final QuotaResult result;
    switch (resource) {
      case QuotaResource.patients:
        result = await QuotaService.checkPatients();
      case QuotaResource.sessions:
        result = await QuotaService.checkSessions();
      case QuotaResource.templates:
        result = await QuotaService.checkTemplates();
      case QuotaResource.anamnesis:
        result = await QuotaService.checkAnamnesis();
    }

    if (result.allowed) return true;

    if (!context.mounted) return false;

    final loc = AppLocalizations.of(context)!;
    final sub = await QuotaService.getSubscription();
    final resourceName = _resourceName(resource, loc);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.lock_outline,
            color: Theme.of(ctx).colorScheme.error, size: 40),
        title: Text(loc.quotaReached),
        content: Text(loc.quotaReachedDesc(resourceName, sub.tierDisplayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              UpgradeScreen.show(context);
            },
            icon: const Icon(Icons.rocket_launch, size: 18),
            label: Text(loc.upgrade),
          ),
        ],
      ),
    );

    return false;
  }

  static String _resourceName(QuotaResource resource, AppLocalizations loc) {
    switch (resource) {
      case QuotaResource.patients:
        return loc.resourcePatients;
      case QuotaResource.sessions:
        return loc.resourceSessions;
      case QuotaResource.templates:
        return loc.resourceTemplates;
      case QuotaResource.anamnesis:
        return loc.resourceAnamnesis;
    }
  }
}
