import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier { free, essential, professional, clinic }

class TierLimits {
  final int maxPatients;
  final int maxSessionsPerMonth;
  final int maxTemplates;
  final int maxAnamnesisPerMonth;
  final int maxStorageMB;
  final int dashboardDaysHistory; // 0 = unlimited
  final bool customBranding;
  final bool dataExport;

  const TierLimits({
    required this.maxPatients,
    required this.maxSessionsPerMonth,
    required this.maxTemplates,
    required this.maxAnamnesisPerMonth,
    required this.maxStorageMB,
    required this.dashboardDaysHistory,
    required this.customBranding,
    required this.dataExport,
  });

  static const free = TierLimits(
    maxPatients: 15,
    maxSessionsPerMonth: 30,
    maxTemplates: 2,
    maxAnamnesisPerMonth: 5,
    maxStorageMB: 100,
    dashboardDaysHistory: 30,
    customBranding: false,
    dataExport: false,
  );

  static const essential = TierLimits(
    maxPatients: 100,
    maxSessionsPerMonth: 0, // unlimited
    maxTemplates: 10,
    maxAnamnesisPerMonth: 30,
    maxStorageMB: 1024,
    dashboardDaysHistory: 365,
    customBranding: false,
    dataExport: false,
  );

  static const professional = TierLimits(
    maxPatients: 500,
    maxSessionsPerMonth: 0,
    maxTemplates: 0,
    maxAnamnesisPerMonth: 0,
    maxStorageMB: 5120,
    dashboardDaysHistory: 0,
    customBranding: true,
    dataExport: true,
  );

  static const clinic = TierLimits(
    maxPatients: 0,
    maxSessionsPerMonth: 0,
    maxTemplates: 0,
    maxAnamnesisPerMonth: 0,
    maxStorageMB: 20480,
    dashboardDaysHistory: 0,
    customBranding: true,
    dataExport: true,
  );

  static TierLimits forTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return free;
      case SubscriptionTier.essential:
        return essential;
      case SubscriptionTier.professional:
        return professional;
      case SubscriptionTier.clinic:
        return clinic;
    }
  }

  bool isUnlimited(int limit) => limit == 0;
}

class Subscription {
  SubscriptionTier tier;
  String status; // active, trial, past_due, cancelled
  DateTime currentPeriodEnd;
  int patientCount;
  int storageUsedBytes;
  int monthlySessionCount;
  int monthlyAnamnesisCount;
  DateTime monthResetDate;

  Subscription({
    this.tier = SubscriptionTier.free,
    this.status = 'active',
    DateTime? currentPeriodEnd,
    this.patientCount = 0,
    this.storageUsedBytes = 0,
    this.monthlySessionCount = 0,
    this.monthlyAnamnesisCount = 0,
    DateTime? monthResetDate,
  })  : currentPeriodEnd =
            currentPeriodEnd ?? DateTime.now().add(const Duration(days: 365)),
        monthResetDate = monthResetDate ?? DateTime(DateTime.now().year, DateTime.now().month);

  TierLimits get limits => TierLimits.forTier(tier);

  Map<String, dynamic> toMap() => {
        'tier': tier.name,
        'status': status,
        'currentPeriodEnd': Timestamp.fromDate(currentPeriodEnd),
        'patientCount': patientCount,
        'storageUsedBytes': storageUsedBytes,
        'monthlySessionCount': monthlySessionCount,
        'monthlyAnamnesisCount': monthlyAnamnesisCount,
        'monthResetDate': Timestamp.fromDate(monthResetDate),
      };

  factory Subscription.fromMap(Map<String, dynamic> map) => Subscription(
        tier: SubscriptionTier.values.firstWhere(
          (e) => e.name == map['tier'],
          orElse: () => SubscriptionTier.free,
        ),
        status: map['status'] ?? 'active',
        currentPeriodEnd: (map['currentPeriodEnd'] as Timestamp?)?.toDate(),
        patientCount: map['patientCount'] ?? 0,
        storageUsedBytes: map['storageUsedBytes'] ?? 0,
        monthlySessionCount: map['monthlySessionCount'] ?? 0,
        monthlyAnamnesisCount: map['monthlyAnamnesisCount'] ?? 0,
        monthResetDate: (map['monthResetDate'] as Timestamp?)?.toDate(),
      );

  String get tierDisplayName {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Gratis';
      case SubscriptionTier.essential:
        return 'Essencial';
      case SubscriptionTier.professional:
        return 'Profissional';
      case SubscriptionTier.clinic:
        return 'Clinica';
    }
  }

  /// Resets monthly counters if we've rolled into a new month.
  void resetMonthlyIfNeeded() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    if (monthResetDate.isBefore(currentMonth)) {
      monthlySessionCount = 0;
      monthlyAnamnesisCount = 0;
      monthResetDate = currentMonth;
    }
  }
}
