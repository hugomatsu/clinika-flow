import 'package:cloud_firestore/cloud_firestore.dart';

class SessionRecord {
  String id;
  String appointmentId;

  // Template reference — which template + version was used to fill this session
  String templateId;
  int templateVersion;

  /// Field values keyed by field GUID to dynamic value.
  /// Slider: double, textField: String, tags: list of strings,
  /// comboBox: String, checkbox: list of strings (checked item guids),
  /// image: String (path/url), label: not stored.
  Map<String, dynamic> fieldValues;

  // Legacy fixed fields (pre-template, kept for backwards compat)
  int prePainScore;
  int postPainScore;
  List<String> techniques;
  List<String> photos;
  String observations;

  DateTime sessionDateTime;
  DateTime createdAt;
  DateTime updatedAt;

  SessionRecord({
    this.id = '',
    this.appointmentId = '',
    this.templateId = '',
    this.templateVersion = 0,
    Map<String, dynamic>? fieldValues,
    this.prePainScore = 0,
    this.postPainScore = 0,
    List<String>? techniques,
    List<String>? photos,
    this.observations = '',
    DateTime? sessionDateTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : fieldValues = fieldValues ?? {},
        techniques = techniques ?? [],
        photos = photos ?? [],
        sessionDateTime = sessionDateTime ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'appointmentId': appointmentId,
        'templateId': templateId,
        'templateVersion': templateVersion,
        'fieldValues': fieldValues,
        'prePainScore': prePainScore,
        'postPainScore': postPainScore,
        'techniques': techniques,
        'photos': photos,
        'observations': observations,
        'sessionDateTime': Timestamp.fromDate(sessionDateTime),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory SessionRecord.fromMap(String id, Map<String, dynamic> map) =>
      SessionRecord(
        id: id,
        appointmentId: map['appointmentId'] ?? '',
        templateId: map['templateId'] ?? '',
        templateVersion: map['templateVersion'] ?? 0,
        fieldValues:
            Map<String, dynamic>.from(map['fieldValues'] ?? {}),
        prePainScore: map['prePainScore'] ?? 0,
        postPainScore: map['postPainScore'] ?? 0,
        techniques: List<String>.from(map['techniques'] ?? []),
        photos: List<String>.from(map['photos'] ?? []),
        observations: map['observations'] ?? '',
        sessionDateTime: (map['sessionDateTime'] as Timestamp?)?.toDate(),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}
