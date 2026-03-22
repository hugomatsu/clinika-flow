import 'package:cloud_firestore/cloud_firestore.dart';

enum FollowUpType { postSession, reactivation, birthday, custom }

enum FollowUpStatus { pending, sent, dismissed, snoozed }

class FollowUp {
  String id;
  String patientId;
  String patientName;
  String patientWhatsapp;
  String appointmentId;
  FollowUpType type;
  FollowUpStatus status;
  DateTime scheduledAt;
  DateTime? sentAt;
  DateTime? snoozedUntil;
  String channel; // whatsapp, manual
  DateTime createdAt;

  FollowUp({
    this.id = '',
    this.patientId = '',
    this.patientName = '',
    this.patientWhatsapp = '',
    this.appointmentId = '',
    this.type = FollowUpType.postSession,
    this.status = FollowUpStatus.pending,
    DateTime? scheduledAt,
    this.sentAt,
    this.snoozedUntil,
    this.channel = 'whatsapp',
    DateTime? createdAt,
  })  : scheduledAt = scheduledAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'patientName': patientName,
        'patientWhatsapp': patientWhatsapp,
        'appointmentId': appointmentId,
        'type': type.name,
        'status': status.name,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
        'snoozedUntil':
            snoozedUntil != null ? Timestamp.fromDate(snoozedUntil!) : null,
        'channel': channel,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory FollowUp.fromMap(String id, Map<String, dynamic> map) => FollowUp(
        id: id,
        patientId: map['patientId'] ?? '',
        patientName: map['patientName'] ?? '',
        patientWhatsapp: map['patientWhatsapp'] ?? '',
        appointmentId: map['appointmentId'] ?? '',
        type: FollowUpType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => FollowUpType.postSession,
        ),
        status: FollowUpStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => FollowUpStatus.pending,
        ),
        scheduledAt: (map['scheduledAt'] as Timestamp?)?.toDate(),
        sentAt: (map['sentAt'] as Timestamp?)?.toDate(),
        snoozedUntil: (map['snoozedUntil'] as Timestamp?)?.toDate(),
        channel: map['channel'] ?? 'whatsapp',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
