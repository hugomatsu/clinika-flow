import 'package:cloud_firestore/cloud_firestore.dart';

enum PatientStatus { active, inactive, archived }

class Patient {
  String id;
  String fullName;
  String whatsapp;
  String instagram;
  String email;
  DateTime dateOfBirth;
  String occupation;
  String emergencyContact;
  String posturalAnamnesis;
  String injuryHistory;
  PatientStatus status;

  // Template-based anamnesis: templateId + version + field values
  String anamnesisTemplateId;
  int anamnesisTemplateVersion;
  Map<String, dynamic> anamnesisData;

  // Communication tracking
  DateTime? lastContactedAt;

  DateTime createdAt;
  DateTime updatedAt;

  Patient({
    this.id = '',
    this.fullName = '',
    this.whatsapp = '',
    this.instagram = '',
    this.email = '',
    DateTime? dateOfBirth,
    this.occupation = '',
    this.emergencyContact = '',
    this.posturalAnamnesis = '',
    this.injuryHistory = '',
    this.status = PatientStatus.active,
    this.anamnesisTemplateId = '',
    this.anamnesisTemplateVersion = 0,
    Map<String, dynamic>? anamnesisData,
    this.lastContactedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : dateOfBirth = dateOfBirth ?? DateTime(1970),
        anamnesisData = anamnesisData ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'whatsapp': whatsapp,
        'instagram': instagram,
        'email': email,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'occupation': occupation,
        'emergencyContact': emergencyContact,
        'posturalAnamnesis': posturalAnamnesis,
        'injuryHistory': injuryHistory,
        'status': status.name,
        'anamnesisTemplateId': anamnesisTemplateId,
        'anamnesisTemplateVersion': anamnesisTemplateVersion,
        'anamnesisData': anamnesisData,
        'lastContactedAt': lastContactedAt != null
            ? Timestamp.fromDate(lastContactedAt!)
            : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory Patient.fromMap(String id, Map<String, dynamic> map) => Patient(
        id: id,
        fullName: map['fullName'] ?? '',
        whatsapp: map['whatsapp'] ?? map['phone'] ?? '',
        instagram: map['instagram'] ?? '',
        email: map['email'] ?? '',
        dateOfBirth: (map['dateOfBirth'] as Timestamp?)?.toDate(),
        occupation: map['occupation'] ?? '',
        emergencyContact: map['emergencyContact'] ?? '',
        posturalAnamnesis: map['posturalAnamnesis'] ?? '',
        injuryHistory: map['injuryHistory'] ?? '',
        anamnesisTemplateId: map['anamnesisTemplateId'] ?? '',
        anamnesisTemplateVersion: map['anamnesisTemplateVersion'] ?? 0,
        anamnesisData:
            Map<String, dynamic>.from(map['anamnesisData'] ?? {}),
        lastContactedAt: (map['lastContactedAt'] as Timestamp?)?.toDate(),
        status: PatientStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => PatientStatus.active,
        ),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}
