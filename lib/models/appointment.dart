import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { scheduled, completed, cancelled, rescheduled }

class Appointment {
  String id;
  String patientId;
  DateTime scheduledDate;
  int durationMinutes;
  AppointmentStatus status;
  String notes;
  bool reminderEnabled;
  DateTime createdAt;
  DateTime updatedAt;

  Appointment({
    this.id = '',
    this.patientId = '',
    DateTime? scheduledDate,
    this.durationMinutes = 45,
    this.status = AppointmentStatus.scheduled,
    this.notes = '',
    this.reminderEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : scheduledDate = scheduledDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'durationMinutes': durationMinutes,
        'status': status.name,
        'notes': notes,
        'reminderEnabled': reminderEnabled,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory Appointment.fromMap(String id, Map<String, dynamic> map) =>
      Appointment(
        id: id,
        patientId: map['patientId'] ?? '',
        scheduledDate: (map['scheduledDate'] as Timestamp?)?.toDate(),
        durationMinutes: map['durationMinutes'] ?? 45,
        status: AppointmentStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => AppointmentStatus.scheduled,
        ),
        notes: map['notes'] ?? '',
        reminderEnabled: map['reminderEnabled'] ?? true,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}
