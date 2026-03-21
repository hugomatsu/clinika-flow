import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_template.dart';

enum AnamnesisRequestStatus { pending, opened, completed }

class AnamnesisRequest {
  String id;
  String clinicId;
  String patientId;
  String patientName;
  String clinicName;
  String clinicLogoUrl;
  String templateId;
  int templateVersion;
  List<FieldDefinition> fieldsSnapshot;
  AnamnesisRequestStatus status;
  Map<String, dynamic> responseData;
  DateTime createdAt;
  DateTime? openedAt;
  DateTime? completedAt;
  DateTime expiresAt;

  AnamnesisRequest({
    this.id = '',
    this.clinicId = '',
    this.patientId = '',
    this.patientName = '',
    this.clinicName = '',
    this.clinicLogoUrl = '',
    this.templateId = '',
    this.templateVersion = 1,
    List<FieldDefinition>? fieldsSnapshot,
    this.status = AnamnesisRequestStatus.pending,
    Map<String, dynamic>? responseData,
    DateTime? createdAt,
    this.openedAt,
    this.completedAt,
    DateTime? expiresAt,
  })  : fieldsSnapshot = fieldsSnapshot ?? [],
        responseData = responseData ?? {},
        createdAt = createdAt ?? DateTime.now(),
        expiresAt =
            expiresAt ?? DateTime.now().add(const Duration(days: 30));

  Map<String, dynamic> toMap() => {
        'clinicId': clinicId,
        'patientId': patientId,
        'patientName': patientName,
        'clinicName': clinicName,
        'clinicLogoUrl': clinicLogoUrl,
        'templateId': templateId,
        'templateVersion': templateVersion,
        'fieldsSnapshot':
            fieldsSnapshot.map((f) => f.toMap()).toList(),
        'status': status.name,
        'responseData': responseData,
        'createdAt': Timestamp.fromDate(createdAt),
        'openedAt':
            openedAt != null ? Timestamp.fromDate(openedAt!) : null,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'expiresAt': Timestamp.fromDate(expiresAt),
      };

  factory AnamnesisRequest.fromMap(
          String id, Map<String, dynamic> map) =>
      AnamnesisRequest(
        id: id,
        clinicId: map['clinicId'] ?? '',
        patientId: map['patientId'] ?? '',
        patientName: map['patientName'] ?? '',
        clinicName: map['clinicName'] ?? '',
        clinicLogoUrl: map['clinicLogoUrl'] ?? '',
        templateId: map['templateId'] ?? '',
        templateVersion: map['templateVersion'] ?? 1,
        fieldsSnapshot: (map['fieldsSnapshot'] as List<dynamic>?)
                ?.map((e) =>
                    FieldDefinition.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        status: AnamnesisRequestStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => AnamnesisRequestStatus.pending,
        ),
        responseData:
            Map<String, dynamic>.from(map['responseData'] ?? {}),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        openedAt: (map['openedAt'] as Timestamp?)?.toDate(),
        completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
        expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      );
}
