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
      await FirestoreService.createTemplate(_standardSession());
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

  static SessionTemplate _standardSession() {
    return SessionTemplate(
      name: 'Sessão Padrão',
      description: 'Modelo leve: anotações, valor pago e tempo gasto.',
      fields: [
        FieldDefinition(
          guid: _guid(),
          type: FieldType.textField,
          label: 'Anotações',
          order: 0,
          config: {'multiline': true, 'maxLength': 0},
        ),
        FieldDefinition(
          guid: _guid(),
          type: FieldType.currency,
          label: 'Valor pago',
          order: 1,
          config: {'prefix': 'R\$'},
        ),
        FieldDefinition(
          guid: _guid(),
          type: FieldType.slider,
          label: 'Tempo gasto (min)',
          order: 2,
          config: {'min': 0.0, 'max': 120.0, 'step': 5.0, 'unit': 'min'},
        ),
      ],
    );
  }

  static SessionTemplate _quickCheckin() {
    return SessionTemplate(
      name: 'Check-in Rápido',
      description: 'Modelo simplificado para avaliações rápidas.',
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
