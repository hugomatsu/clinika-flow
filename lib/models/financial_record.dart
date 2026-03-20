import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { paid, pending, package, overdue }

class FinancialRecord {
  String id;
  String sessionId;
  double amount;
  PaymentStatus paymentStatus;
  String notes;
  DateTime createdAt;
  DateTime updatedAt;

  FinancialRecord({
    this.id = '',
    this.sessionId = '',
    this.amount = 0.0,
    this.paymentStatus = PaymentStatus.pending,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'amount': amount,
        'paymentStatus': paymentStatus.name,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory FinancialRecord.fromMap(String id, Map<String, dynamic> map) =>
      FinancialRecord(
        id: id,
        sessionId: map['sessionId'] ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: PaymentStatus.values.firstWhere(
          (s) => s.name == map['paymentStatus'],
          orElse: () => PaymentStatus.pending,
        ),
        notes: map['notes'] ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}
