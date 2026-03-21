import 'package:cloud_firestore/cloud_firestore.dart';

class BrandingPreferences {
  String clinicName;
  String logoUrl;
  // hex codes including #
  String primaryColor;
  String secondaryColor;
  String accentColor;
  bool darkMode;
  DateTime updatedAt;

  BrandingPreferences({
    this.clinicName = 'Kelyn Physio',
    this.logoUrl = '',
    this.primaryColor = '#2962FF',
    this.secondaryColor = '#26A69A',
    this.accentColor = '#FFCA28',
    this.darkMode = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'clinicName': clinicName,
        'logoUrl': logoUrl,
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'accentColor': accentColor,
        'darkMode': darkMode,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory BrandingPreferences.fromMap(Map<String, dynamic> map) =>
      BrandingPreferences(
        clinicName: map['clinicName'] ?? 'Kelyn Physio',
        logoUrl: map['logoUrl'] ?? '',
        primaryColor: map['primaryColor'] ?? '#2962FF',
        secondaryColor: map['secondaryColor'] ?? '#26A69A',
        accentColor: map['accentColor'] ?? '#FFCA28',
        darkMode: map['darkMode'] ?? false,
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );
}
