import 'dart:math';
import '../models/session_template.dart';
import 'firestore_service.dart';

/// Seeds built-in default templates if none exist yet for the current clinic.
class TemplateSeeder {
  static bool _seeded = false;

  static Future<void> seedIfNeeded() async {
    if (_seeded) return;
    _seeded = true;

    try {
      final existing = await FirestoreService.getAllTemplates();
      if (existing.isNotEmpty) return;

      // Seed the two built-in templates
      await FirestoreService.createTemplate(_standardMyofascial());
      await FirestoreService.createTemplate(_quickCheckin());
    } catch (_) {
      // Offline or not authenticated yet — will retry next time
      _seeded = false;
    }
  }

  static String _guid() {
    final r = Random();
    return List.generate(20, (_) => r.nextInt(36).toRadixString(36)).join();
  }

  static SessionTemplate _standardMyofascial() {
    return SessionTemplate(
      name: 'Sessão Miofascial Padrão',
      description: 'Modelo completo para sessões de liberação miofascial.',
      isDefault: true,
      isBuiltIn: true,
      fields: [
        FieldDefinition(
          guid: _guid(),
          type: FieldType.label,
          label: 'Avaliação pré-sessão',
          order: 0,
        ),
        FieldDefinition(
          guid: _guid(),
          type: FieldType.slider,
          label: 'Dor antes da sessão',
          order: 1,
          config: {'min': 0.0, 'max': 10.0, 'step': 1.0, 'unit': ''},
        ),
        FieldDefinition(
          guid: _guid(),
          type: FieldType.tags,
          label: 'Técnicas aplicadas',
          order: 2,
          config: {
            'options': [
              'Liberação Miofascial',
              'Ventosaterapia',
              'Dry Needling',
              'Terapia Manual',
              'Alongamento',
              'Exercício Terapêutico',
              'Ultrassom',
              'TENS',
            ],
            'allowCustom': true,
          },
        ),
        FieldDefinition(
          guid: _guid(),
          type: FieldType.tags,
          label: 'Regiões tratadas',
          order: 3,
          config: {
            'options': [
              'Trapézio',
              'Lombar',
              'Cervical',
              'Quadril',
              'Joelho',
              'Ombro',
            ],
            'allowCustom': true,
          },
        ),
        FieldDefinition(
          guid: _guid(),
          type: FieldType.label,
          label: 'Pós-sessão',
          order: 4,
        ),
        FieldDefinition(
          guid: _guid(),
          type: FieldType.slider,
          label: 'Dor após a sessão',
          order: 5,
          config: {'min': 0.0, 'max': 10.0, 'step': 1.0, 'unit': ''},
        ),
        FieldDefinition(
          guid: _guid(),
          type: FieldType.textField,
          label: 'Observações clínicas',
          order: 6,
          config: {'multiline': true, 'maxLength': 0},
        ),
      ],
    );
  }

  static SessionTemplate _quickCheckin() {
    return SessionTemplate(
      name: 'Check-in Rápido',
      description: 'Modelo simplificado para avaliações rápidas.',
      isBuiltIn: true,
      fields: [
        FieldDefinition(
          guid: _guid(),
          type: FieldType.slider,
          label: 'Dor atual',
          order: 0,
          config: {'min': 0.0, 'max': 10.0, 'step': 1.0, 'unit': ''},
        ),
        FieldDefinition(
          guid: _guid(),
          type: FieldType.comboBox,
          label: 'Queixa principal hoje',
          order: 1,
          config: {
            'options': [
              'Dor cervical',
              'Dor lombar',
              'Dor no ombro',
              'Dor no joelho',
              'Tensão muscular',
              'Outro',
            ],
          },
        ),
        FieldDefinition(
          guid: _guid(),
          type: FieldType.textField,
          label: 'Observações',
          order: 2,
          config: {'multiline': true, 'maxLength': 0},
        ),
      ],
    );
  }
}
