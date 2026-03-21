# Pre-made Template Fields

## Overview

When building a session template, the user can pick from a library of **pre-made fields** (ready to use, just drag in) or create fully custom ones. Pre-made fields are regular field definitions with sensible defaults pre-filled — the user can still edit label, range, options, etc. after adding them.

### How the library works

- A **search bar** filters fields by name and category in real-time.
- Fields are grouped by category (e.g. "Pain", "Posture", "Movement").
- Tapping a pre-made field **inserts it at the bottom** of the current template and opens its config for quick review before saving.
- A badge marks fields that are commonly used across clinics (⭐ Popular).

---

## Field Library

### Pain & Sensation

| Field | Type | Default config |
|---|---|---|
| **VAS Pain** | Slider | 0–10, step 1, label "Dor (VAS)" |
| **Numeric Pain Scale** | Slider | 0–10, step 1 |
| **Pain location (body area)** | Tags | Options: Cervical, Lombar, Torácico, Ombro, Quadril, Joelho, Tornozelo, Punho |
| **Pain character** | Tags | Options: Aguda, Queimação, Formigamento, Pulsátil, Pressão, Irradiada |
| **Pain frequency** | ComboBox | Options: Constante, Intermitente, Ao movimento, Noturna |

---

### Session — Pre/Post Evaluation

| Field | Type | Default config |
|---|---|---|
| **Dor pré-sessão (VAS)** | Slider | 0–10, step 1 |
| **Dor pós-sessão (VAS)** | Slider | 0–10, step 1 |
| **Sensação após sessão** | Tags | Options: Aliviado, Relaxado, Pesado, Sem diferença, Fatigado |
| **Evolução percebida** | ComboBox | Options: Muito melhor, Melhor, Igual, Pior |
| **Observações da sessão** | TextField | Multiline, limit 500 |

---

### Myofascial Release (Liberação Miofascial)

| Field | Type | Default config |
|---|---|---|
| **Técnicas aplicadas** | Tags | Options: Rolamento, Compressão isquêmica, Deslizamento longitudinal, Liberação por barreira, Stretching |
| **Regiões tratadas** | Tags | Options: Trapézio, Peitoral, Paravertebral, Glúteo, IT Band, Psoas, Gastrocnêmio, Plantar |
| **Intensidade da pressão** | Slider | 1–5, step 1, unit "/ 5" |
| **Tempo por região (min)** | Slider | 1–10, step 1, unit "min" |
| **Pontos gatilho encontrados** | Checkbox | Items: Trapézio sup., Infraespinhoso, Quadrado lombar, Piriformis |
| **Resposta ao tratamento** | ComboBox | Options: Liberação completa, Liberação parcial, Sem liberação, Dor referida presente |

---

### Anamnesis (Anamnese Inicial)

| Field | Type | Default config |
|---|---|---|
| **Queixa principal** | TextField | Multiline, limit 300 |
| **Início dos sintomas** | ComboBox | Options: Menos de 1 semana, 1–4 semanas, 1–6 meses, Mais de 6 meses, Crônico (+1 ano) |
| **Mecanismo de lesão** | Tags | Options: Trauma, Esforço repetitivo, Postura, Sem causa definida, Pós-cirúrgico |
| **Histórico de tratamento** | Checkbox | Items: Fisioterapia anterior, Medicação, Cirurgia, Nenhum |
| **Atividade física** | ComboBox | Options: Sedentário, Caminhada, Musculação, Esporte amador, Esporte profissional |
| **Sono** | ComboBox | Options: Bom, Regular, Ruim, Insônia frequente |
| **Nível de estresse** | Slider | 0–10, step 1 |

---

### Posture & Movement

| Field | Type | Default config |
|---|---|---|
| **Avaliação postural** | TextField | Multiline, label "Descrição postural" |
| **ADM (amplitude de movimento)** | TextField | Multiline, label "Ângulos e restrições observados" |
| **Testes especiais** | Tags | Options: Lasègue, Patrick, Impingement, Phalen, Tinel, Thomas |
| **Resultado dos testes** | ComboBox | Options: Negativo, Positivo direito, Positivo esquerdo, Bilateral positivo |
| **Força muscular (escala MRC)** | Slider | 0–5, step 1, unit "/ 5" |

---

### General & Administrative

| Field | Type | Default config |
|---|---|---|
| **Evolução clínica** | TextField | Multiline, limit 400 |
| **Plano para próxima sessão** | TextField | Multiline, limit 300 |
| **Sessão remota?** | Toggle | Default: off |
| **Frequência semanal** | ComboBox | Options: 1x, 2x, 3x, Intensivo |
| **Fotos de evolução** | Image | Hint "Fotografar região tratada" |

---

## Notes for implementation

- Pre-made fields are **not stored in Firestore** — they are defined as a static Dart list in the app (e.g. `lib/data/preset_fields.dart`).
- Inserting a pre-made field creates a **copy** with a new GUID — modifying it does not affect the library.
- The search bar should match against field label, category name, and option values.
- Consider a **"Recently used"** section at the top of the library (tracked locally per device).
