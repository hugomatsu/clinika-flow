import 'package:cloud_firestore/cloud_firestore.dart';

/// The types of fields a template can contain.
enum FieldType {
  slider,
  textField,
  label,
  tags,
  comboBox,
  image,
  checkbox,
  subTemplate,
  toggle,
}

/// A single field inside a template, identified by a stable GUID.
class FieldDefinition {
  final String guid;
  FieldType type;
  String label;
  int order;
  bool required;
  int addedInVersion;
  Map<String, dynamic> config;

  FieldDefinition({
    required this.guid,
    required this.type,
    this.label = '',
    this.order = 0,
    this.required = false,
    this.addedInVersion = 1,
    Map<String, dynamic>? config,
  }) : config = config ?? _defaultConfig(type);

  static Map<String, dynamic> _defaultConfig(FieldType type) {
    switch (type) {
      case FieldType.slider:
        return {'min': 0.0, 'max': 10.0, 'step': 1.0, 'unit': ''};
      case FieldType.textField:
        return {'multiline': false, 'maxLength': 0};
      case FieldType.label:
        return {};
      case FieldType.tags:
        return {'options': <String>[], 'allowCustom': false};
      case FieldType.comboBox:
        return {'options': <String>[]};
      case FieldType.image:
        return {'hint': ''};
      case FieldType.checkbox:
        return {'items': <Map<String, String>>[], 'requireAll': false};
      case FieldType.subTemplate:
        return {'templateId': '', 'displayMode': 'page'};
      case FieldType.toggle:
        return {'defaultValue': false};
    }
  }

  Map<String, dynamic> toMap() => {
        'guid': guid,
        'type': type.name,
        'label': label,
        'order': order,
        'required': required,
        'addedInVersion': addedInVersion,
        'config': config,
      };

  factory FieldDefinition.fromMap(Map<String, dynamic> map) => FieldDefinition(
        guid: map['guid'] ?? '',
        type: FieldType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => FieldType.textField,
        ),
        label: map['label'] ?? '',
        order: map['order'] ?? 0,
        required: map['required'] ?? false,
        addedInVersion: map['addedInVersion'] ?? 1,
        config: Map<String, dynamic>.from(map['config'] ?? {}),
      );

  FieldDefinition copyWith({
    String? guid,
    FieldType? type,
    String? label,
    int? order,
    bool? required,
    int? addedInVersion,
    Map<String, dynamic>? config,
  }) =>
      FieldDefinition(
        guid: guid ?? this.guid,
        type: type ?? this.type,
        label: label ?? this.label,
        order: order ?? this.order,
        required: required ?? this.required,
        addedInVersion: addedInVersion ?? this.addedInVersion,
        config: config ?? Map<String, dynamic>.from(this.config),
      );
}

/// An immutable snapshot of a template at a specific version.
class TemplateVersion {
  String templateId;
  int version;
  DateTime savedAt;
  List<FieldDefinition> fieldsSnapshot;

  TemplateVersion({
    this.templateId = '',
    this.version = 1,
    DateTime? savedAt,
    List<FieldDefinition>? fieldsSnapshot,
  })  : savedAt = savedAt ?? DateTime.now(),
        fieldsSnapshot = fieldsSnapshot ?? [];

  Map<String, dynamic> toMap() => {
        'templateId': templateId,
        'version': version,
        'savedAt': Timestamp.fromDate(savedAt),
        'fieldsSnapshot': fieldsSnapshot.map((f) => f.toMap()).toList(),
      };

  factory TemplateVersion.fromMap(Map<String, dynamic> map) => TemplateVersion(
        templateId: map['templateId'] ?? '',
        version: map['version'] ?? 1,
        savedAt: (map['savedAt'] as Timestamp?)?.toDate(),
        fieldsSnapshot: (map['fieldsSnapshot'] as List<dynamic>?)
                ?.map((e) =>
                    FieldDefinition.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );
}

/// The top-level template entity.
class SessionTemplate {
  String id;
  String name;
  String description;
  int currentVersion;
  DateTime lastSavedAt;
  bool isDefault;
  bool isBuiltIn;
  List<FieldDefinition> fields;
  DateTime createdAt;

  SessionTemplate({
    this.id = '',
    this.name = '',
    this.description = '',
    this.currentVersion = 1,
    DateTime? lastSavedAt,
    this.isDefault = false,
    this.isBuiltIn = false,
    List<FieldDefinition>? fields,
    DateTime? createdAt,
  })  : lastSavedAt = lastSavedAt ?? DateTime.now(),
        fields = fields ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'currentVersion': currentVersion,
        'lastSavedAt': Timestamp.fromDate(lastSavedAt),
        'isDefault': isDefault,
        'isBuiltIn': isBuiltIn,
        'fields': fields.map((f) => f.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory SessionTemplate.fromMap(String id, Map<String, dynamic> map) =>
      SessionTemplate(
        id: id,
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        currentVersion: map['currentVersion'] ?? 1,
        lastSavedAt: (map['lastSavedAt'] as Timestamp?)?.toDate(),
        isDefault: map['isDefault'] ?? false,
        isBuiltIn: map['isBuiltIn'] ?? false,
        fields: (map['fields'] as List<dynamic>?)
                ?.map((e) =>
                    FieldDefinition.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
