import '../models/session_template.dart';

/// A preset field with its category for the field library.
class PresetField {
  final String category;
  final FieldType type;
  final String label;
  final Map<String, dynamic> config;
  final bool popular;

  const PresetField({
    required this.category,
    required this.type,
    required this.label,
    required this.config,
    this.popular = false,
  });
}

const _pain = 'Dor & Sensação';
const _session = 'Avaliação Pré/Pós';
const _myo = 'Liberação Miofascial';
const _anamnesis = 'Anamnese';
const _posture = 'Postura & Movimento';
const _general = 'Geral';

/// All preset categories in display order.
const presetCategories = [
  _pain,
  _session,
  _myo,
  _anamnesis,
  _posture,
  _general,
];

/// All pre-made fields available in the library.
const presetFields = <PresetField>[
  // ── Pain & Sensation ──────────────────────────────────────────────────────
  PresetField(
    category: _pain,
    type: FieldType.slider,
    label: 'Dor (VAS)',
    config: {'min': 0.0, 'max': 10.0, 'step': 1.0, 'unit': ''},
    popular: true,
  ),
  PresetField(
    category: _pain,
    type: FieldType.tags,
    label: 'Localização da dor',
    config: {
      'options': [
        'Cervical', 'Lombar', 'Torácico', 'Ombro',
        'Quadril', 'Joelho', 'Tornozelo', 'Punho',
      ],
      'allowCustom': true,
    },
    popular: true,
  ),
  PresetField(
    category: _pain,
    type: FieldType.tags,
    label: 'Caráter da dor',
    config: {
      'options': [
        'Aguda', 'Queimação', 'Formigamento',
        'Pulsátil', 'Pressão', 'Irradiada',
      ],
      'allowCustom': false,
    },
  ),
  PresetField(
    category: _pain,
    type: FieldType.comboBox,
    label: 'Frequência da dor',
    config: {
      'options': ['Constante', 'Intermitente', 'Ao movimento', 'Noturna'],
    },
  ),

  // ── Session Pre/Post ──────────────────────────────────────────────────────
  PresetField(
    category: _session,
    type: FieldType.slider,
    label: 'Dor pré-sessão (VAS)',
    config: {'min': 0.0, 'max': 10.0, 'step': 1.0, 'unit': ''},
    popular: true,
  ),
  PresetField(
    category: _session,
    type: FieldType.slider,
    label: 'Dor pós-sessão (VAS)',
    config: {'min': 0.0, 'max': 10.0, 'step': 1.0, 'unit': ''},
    popular: true,
  ),
  PresetField(
    category: _session,
    type: FieldType.tags,
    label: 'Sensação após sessão',
    config: {
      'options': [
        'Aliviado', 'Relaxado', 'Pesado', 'Sem diferença', 'Fatigado',
      ],
      'allowCustom': false,
    },
  ),
  PresetField(
    category: _session,
    type: FieldType.comboBox,
    label: 'Evolução percebida',
    config: {
      'options': ['Muito melhor', 'Melhor', 'Igual', 'Pior'],
    },
  ),
  PresetField(
    category: _session,
    type: FieldType.textField,
    label: 'Observações da sessão',
    config: {'multiline': true, 'maxLength': 500},
  ),

  // ── Myofascial Release ────────────────────────────────────────────────────
  PresetField(
    category: _myo,
    type: FieldType.tags,
    label: 'Técnicas aplicadas',
    config: {
      'options': [
        'Rolamento', 'Compressão isquêmica',
        'Deslizamento longitudinal', 'Liberação por barreira', 'Stretching',
      ],
      'allowCustom': true,
    },
    popular: true,
  ),
  PresetField(
    category: _myo,
    type: FieldType.tags,
    label: 'Regiões tratadas',
    config: {
      'options': [
        'Trapézio', 'Peitoral', 'Paravertebral', 'Glúteo',
        'IT Band', 'Psoas', 'Gastrocnêmio', 'Plantar',
      ],
      'allowCustom': true,
    },
  ),
  PresetField(
    category: _myo,
    type: FieldType.slider,
    label: 'Intensidade da pressão',
    config: {'min': 1.0, 'max': 5.0, 'step': 1.0, 'unit': '/ 5'},
  ),
  PresetField(
    category: _myo,
    type: FieldType.slider,
    label: 'Tempo por região',
    config: {'min': 1.0, 'max': 10.0, 'step': 1.0, 'unit': 'min'},
  ),
  PresetField(
    category: _myo,
    type: FieldType.checkbox,
    label: 'Pontos gatilho encontrados',
    config: {
      'items': [
        {'guid': 'pg_trap', 'label': 'Trapézio sup.'},
        {'guid': 'pg_infra', 'label': 'Infraespinhoso'},
        {'guid': 'pg_ql', 'label': 'Quadrado lombar'},
        {'guid': 'pg_piri', 'label': 'Piriformis'},
      ],
      'requireAll': false,
    },
  ),
  PresetField(
    category: _myo,
    type: FieldType.comboBox,
    label: 'Resposta ao tratamento',
    config: {
      'options': [
        'Liberação completa', 'Liberação parcial',
        'Sem liberação', 'Dor referida presente',
      ],
    },
  ),

  // ── Anamnesis ─────────────────────────────────────────────────────────────
  PresetField(
    category: _anamnesis,
    type: FieldType.textField,
    label: 'Queixa principal',
    config: {'multiline': true, 'maxLength': 300},
    popular: true,
  ),
  PresetField(
    category: _anamnesis,
    type: FieldType.comboBox,
    label: 'Início dos sintomas',
    config: {
      'options': [
        'Menos de 1 semana', '1–4 semanas',
        '1–6 meses', 'Mais de 6 meses', 'Crônico (+1 ano)',
      ],
    },
  ),
  PresetField(
    category: _anamnesis,
    type: FieldType.tags,
    label: 'Mecanismo de lesão',
    config: {
      'options': [
        'Trauma', 'Esforço repetitivo', 'Postura',
        'Sem causa definida', 'Pós-cirúrgico',
      ],
      'allowCustom': false,
    },
  ),
  PresetField(
    category: _anamnesis,
    type: FieldType.checkbox,
    label: 'Histórico de tratamento',
    config: {
      'items': [
        {'guid': 'ht_fisio', 'label': 'Fisioterapia anterior'},
        {'guid': 'ht_med', 'label': 'Medicação'},
        {'guid': 'ht_cir', 'label': 'Cirurgia'},
        {'guid': 'ht_none', 'label': 'Nenhum'},
      ],
      'requireAll': false,
    },
  ),
  PresetField(
    category: _anamnesis,
    type: FieldType.comboBox,
    label: 'Atividade física',
    config: {
      'options': [
        'Sedentário', 'Caminhada', 'Musculação',
        'Esporte amador', 'Esporte profissional',
      ],
    },
  ),
  PresetField(
    category: _anamnesis,
    type: FieldType.comboBox,
    label: 'Sono',
    config: {
      'options': ['Bom', 'Regular', 'Ruim', 'Insônia frequente'],
    },
  ),
  PresetField(
    category: _anamnesis,
    type: FieldType.slider,
    label: 'Nível de estresse',
    config: {'min': 0.0, 'max': 10.0, 'step': 1.0, 'unit': ''},
  ),

  // ── Posture & Movement ────────────────────────────────────────────────────
  PresetField(
    category: _posture,
    type: FieldType.textField,
    label: 'Avaliação postural',
    config: {'multiline': true, 'maxLength': 0},
  ),
  PresetField(
    category: _posture,
    type: FieldType.textField,
    label: 'ADM (amplitude de movimento)',
    config: {'multiline': true, 'maxLength': 0},
  ),
  PresetField(
    category: _posture,
    type: FieldType.tags,
    label: 'Testes especiais',
    config: {
      'options': [
        'Lasègue', 'Patrick', 'Impingement',
        'Phalen', 'Tinel', 'Thomas',
      ],
      'allowCustom': true,
    },
  ),
  PresetField(
    category: _posture,
    type: FieldType.comboBox,
    label: 'Resultado dos testes',
    config: {
      'options': [
        'Negativo', 'Positivo direito',
        'Positivo esquerdo', 'Bilateral positivo',
      ],
    },
  ),
  PresetField(
    category: _posture,
    type: FieldType.slider,
    label: 'Força muscular (MRC)',
    config: {'min': 0.0, 'max': 5.0, 'step': 1.0, 'unit': '/ 5'},
  ),

  // ── General ───────────────────────────────────────────────────────────────
  PresetField(
    category: _general,
    type: FieldType.textField,
    label: 'Evolução clínica',
    config: {'multiline': true, 'maxLength': 400},
  ),
  PresetField(
    category: _general,
    type: FieldType.textField,
    label: 'Plano para próxima sessão',
    config: {'multiline': true, 'maxLength': 300},
  ),
  PresetField(
    category: _general,
    type: FieldType.toggle,
    label: 'Sessão remota?',
    config: {'defaultValue': false},
  ),
  PresetField(
    category: _general,
    type: FieldType.comboBox,
    label: 'Frequência semanal',
    config: {
      'options': ['1x', '2x', '3x', 'Intensivo'],
    },
  ),
  PresetField(
    category: _general,
    type: FieldType.image,
    label: 'Fotos de evolução',
    config: {'hint': 'Fotografar região tratada'},
  ),
];
