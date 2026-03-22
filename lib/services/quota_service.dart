import '../models/subscription.dart';
import 'firestore_service.dart';

enum QuotaResource { patients, sessions, templates, anamnesis }

class QuotaResult {
  final bool allowed;
  final int current;
  final int limit; // 0 = unlimited
  final QuotaResource resource;

  const QuotaResult({
    required this.allowed,
    required this.current,
    required this.limit,
    required this.resource,
  });

  bool get isUnlimited => limit == 0;

  /// Returns usage percentage (0.0 - 1.0). Returns 0 if unlimited.
  double get usageRatio => isUnlimited ? 0.0 : current / limit;

  /// True when usage >= 80% of limit.
  bool get isNearLimit => !isUnlimited && usageRatio >= 0.8;
}

class QuotaService {
  static Subscription? _cached;

  static void clearCache() => _cached = null;

  static Future<Subscription> getSubscription() async {
    if (_cached != null) {
      _cached!.resetMonthlyIfNeeded();
      return _cached!;
    }
    final sub = await FirestoreService.getSubscription();
    sub.resetMonthlyIfNeeded();
    _cached = sub;
    return sub;
  }

  static Future<QuotaResult> checkPatients() async {
    final sub = await getSubscription();
    final limits = sub.limits;
    final count = sub.patientCount;
    return QuotaResult(
      allowed: limits.isUnlimited(limits.maxPatients) ||
          count < limits.maxPatients,
      current: count,
      limit: limits.maxPatients,
      resource: QuotaResource.patients,
    );
  }

  static Future<QuotaResult> checkSessions() async {
    final sub = await getSubscription();
    final limits = sub.limits;
    final count = sub.monthlySessionCount;
    return QuotaResult(
      allowed: limits.isUnlimited(limits.maxSessionsPerMonth) ||
          count < limits.maxSessionsPerMonth,
      current: count,
      limit: limits.maxSessionsPerMonth,
      resource: QuotaResource.sessions,
    );
  }

  static Future<QuotaResult> checkTemplates() async {
    final sub = await getSubscription();
    final limits = sub.limits;
    final templates = await FirestoreService.getAllTemplates();
    final count = templates.length;
    return QuotaResult(
      allowed: limits.isUnlimited(limits.maxTemplates) ||
          count < limits.maxTemplates,
      current: count,
      limit: limits.maxTemplates,
      resource: QuotaResource.templates,
    );
  }

  static Future<QuotaResult> checkAnamnesis() async {
    final sub = await getSubscription();
    final limits = sub.limits;
    final count = sub.monthlyAnamnesisCount;
    return QuotaResult(
      allowed: limits.isUnlimited(limits.maxAnamnesisPerMonth) ||
          count < limits.maxAnamnesisPerMonth,
      current: count,
      limit: limits.maxAnamnesisPerMonth,
      resource: QuotaResource.anamnesis,
    );
  }

  static Future<void> incrementPatientCount() async {
    final sub = await getSubscription();
    sub.patientCount++;
    await FirestoreService.updateSubscription(sub);
  }

  static Future<void> decrementPatientCount() async {
    final sub = await getSubscription();
    if (sub.patientCount > 0) sub.patientCount--;
    await FirestoreService.updateSubscription(sub);
  }

  static Future<void> incrementSessionCount() async {
    final sub = await getSubscription();
    sub.monthlySessionCount++;
    await FirestoreService.updateSubscription(sub);
  }

  static Future<void> incrementAnamnesisCount() async {
    final sub = await getSubscription();
    sub.monthlyAnamnesisCount++;
    await FirestoreService.updateSubscription(sub);
  }

  static Future<void> upgradeTo(SubscriptionTier tier) async {
    final sub = await getSubscription();
    sub.tier = tier;
    sub.status = 'active';
    sub.currentPeriodEnd = DateTime.now().add(const Duration(days: 30));
    await FirestoreService.updateSubscription(sub);
    _cached = sub;
  }
}
