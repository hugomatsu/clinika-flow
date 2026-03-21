# Kelyn Physio - Myofascial Release App

## Executive Summary

A custom-built mobile application designed to streamline myofascial release therapy sessions for physiotherapist Kelyn. The system prioritizes rapid clinical documentation during sessions and operates independently of internet connectivity (offline-first architecture), ensuring she maintains full control over her schedule and patient progress tracking, with cloud backup for security and data synchronization.

**Target Users:** Physiotherapist Kelyn and her clinic staff  
**Primary Goal:** Simplify session documentation while maintaining complete patient records

---

## Technology Stack

| Component | Technology |
|-----------|-----------|
| **Framework** | Flutter (iOS, Android & Web) |
| **Architecture** | Offline-first with automatic cloud sync |
| **Database** | Firebase Firestore with offline persistence (IndexedDB on web, SQLite cache on mobile) |
| **Cloud Backend** | Firebase Firestore (single source of truth — auto-syncs when online) |
| **Calendar Integration** | Google Calendar API (Phase 3: bidirectional sync) |
| **Authentication** | Firebase Auth (Phase 2 — currently single-clinic mode with `clinicId = 'default'`) |

---

## Branding & Color Customization

The app is designed to reflect the client's brand identity through customizable color palettes.

**Color Palette Management:**
- **Storage:** Color preferences are saved in Firestore (`clinics/{clinicId}/settings/branding`) and cached locally for offline access
- **Customization:** Administrator can define primary, secondary, accent, and neutral colors
- **Application:** All UI components automatically follow the stored palette:
  - Buttons, cards, and interactive elements use primary/secondary colors
  - Text contrast and readability maintained across all color combinations
  - Charts, graphs, and data visualizations use extended palette for clarity
- **Persistence:** Colors are applied on every app launch without requiring manual reselection
- **Cloud Sync:** Changes to color palette sync across all user devices

**Implementation Details:**
- Create `BrandingPreferences` entity with color hex codes
- Implement theme switching mechanism in Flutter
- Use `ThemeData` widget to apply colors globally
- Validate color combinations for accessibility (WCAG compliance)

---

## Feature Scope

### 1. Authentication & Security

- **Local Access Control:** PIN, biometric authentication, or username/password
- **Future Cloud Authentication:** Firebase (Email/Password or Google Sign-In)
- **Data Privacy:** Sensitive data and photos isolated from device gallery (LGPD-compliant)
- **Session Security:** Automatic logout after inactivity

### 2. Patient Management (Electronic Medical Records)

**Patient Registration:**
- Full name, contact information, date of birth, profession
- Postural anamnesis notes and injury history
- Emergency contact information

**Patient Status Management:**
- View complete patient history
- Archive inactive patients (preserve clinical records)
- Reactivate archived patients as needed
- Edit patient information

**Search & Filtering:**
- Quick patient search by name
- Filter by status (active/inactive/archived)
- View patient attendance patterns

### 3. Appointment Scheduling

- **Daily/Weekly View:** Visual calendar of scheduled sessions
- **Appointment Status:** Scheduled, Completed, Cancelled, Rescheduled
- **Google Calendar Sync (Phase 3):** Bidirectional synchronization (App ↔ Google Calendar)
- **Notifications:** Reminders for upcoming appointments
- **Quick Rescheduling:** Easy reschedule and cancellation workflows

### 4. Session Recording (The Heart of the App)

Optimized for speed with minimal typing during active sessions:

**Pre & Post-Session Questionnaire:**
- Visual Analog Scale (VAS) 0-10 pain rating using interactive sliders
- Pain recorded at session start and end
- Additional symptom tracking (if applicable)

**Photographic Assessment:**
- In-app photo capture (anterior, posterior, lateral views)
- Text description of asymmetries and findings
- **Future Enhancement:** Drawing/annotation tools over photos

**Quick Notes System:**
- Pre-configured tags/quick notes (Manual Therapy, Cupping, Instrument Release, Trapezius, Lumbar, etc.)
- Single-tap tag selection during session
- Free-text field for specific observations or client complaints
- Technique duration tracking (optional)

### 5. Template System (Session Customization)

Allow users to build fully custom session forms using a drag-and-drop field builder, save them as named templates, and apply them to any session. Templates version themselves automatically so older session records remain readable even after the template is edited.

---

#### 5.1 Field Types

Each field is a self-contained block that the user can add, configure, reorder, and delete inside the template editor.

| Field Type | Description |
|------------|-------------|
| **Slider** | Numeric range (min/max/step/label). Default use: VAS pain scale, range of motion, intensity. |
| **Text Field** | Free-text input. Short (single line) or long (multiline). Optional character limit. |
| **Label** | Static read-only text block. Used for section headers, clinical instructions, or consent reminders. |
| **Tags / Chips** | Multi-select chip list. User defines the tag options. Can allow "add custom tag at fill time". |
| **Combo Box** | Single-select dropdown. User defines the options list. |
| **Image Capture** | Photo slot with label (e.g., "Anterior view", "Post-session"). Opens camera or gallery. |
| **Checkbox** | Single boolean toggle or a checklist (group of labeled checkboxes). Optional "require all" validation. |

---

#### 5.2 Template Builder UI

- **Field palette** — tap a field type to append it to the template, or drag it to a specific position.
- **Reordering** — long-press any field to drag it up/down in the list.
- **Field configuration** — tap a field to expand its settings (label text, placeholder, min/max, options list, required flag, etc.).
- **Delete** — swipe left or tap the trash icon on a field to remove it.
- **Preview mode** — toggle between edit view and a live preview of how the form will look during a session.
- **Save / discard** — save stores a new versioned snapshot; discard rolls back all unsaved changes.

---

#### 5.3 Versioning & GUID Stability

Every field carries a **stable GUID** generated at creation time. GUIDs never change, even when the field label or configuration is edited. This allows session records filled against an older template version to be rendered correctly by mapping stored field GUIDs to their value — even if the template has since been restructured.

**Template save model:**

```
Template
├── id                        (template GUID — stable across all versions)
├── name
├── description
├── currentVersion            (incremented integer, e.g. 3)
├── lastSavedAt               (UTC timestamp)
└── fields[]                  (ordered list of FieldDefinition)

FieldDefinition
├── guid                      (field GUID — NEVER changes after creation)
├── type                      (slider | textField | label | tags | comboBox | image | checkbox)
├── label
├── order                     (sort index for reordering)
├── config                    (type-specific: min/max/step, options[], multiline, required, etc.)
└── addedInVersion            (template version when this field was first introduced)

TemplateVersion  (immutable snapshot stored alongside the template)
├── templateId
├── version                   (integer)
├── savedAt
└── fieldsSnapshot[]          (full copy of fields[] at save time)
```

**Compatibility rules:**
- When rendering a past session record, the system looks up the `TemplateVersion` that was active at fill time.
- Fields present in the snapshot but absent from the current template are shown read-only as "legacy fields".
- Fields added after a session was filled are simply absent from that session's record — they are not backfilled.
- Field GUIDs are used as the key when reading/writing session data, never the label or order index.

---

#### 5.4 Default Templates

The system ships with two built-in templates that can be duplicated but not deleted:

- **Standard Myofascial Session** — Pre-pain slider, techniques tags, post-pain slider, observations text field, photo capture (anterior + posterior).
- **Quick Check-in** — Pre-pain slider, single combo box ("Main complaint today"), observations text field.

---

#### 5.5 Applying a Template to a Session

- When starting a session the user selects a template (or uses the clinic default).
- The session form renders the template's current fields in the defined order.
- The `templateId` and `version` used are stored on the session record so the exact snapshot can be retrieved for future viewing.
- The user can override any field value during the session; no field is mandatory unless marked `required` in the template.

---

#### 5.6 Use Case Example

"Cupping Protocol" template:
1. **Label** — "Pre-session assessment"
2. **Slider** — Pain level (0–10)
3. **Tags** — Techniques (Cupping, Dry Needling, TENS, …)
4. **Tags** — Areas (Trapezius, Lumbar, Cervical, …)
5. **Checkbox** — Contraindication checklist (anticoagulants, skin lesions, pregnancy)
6. **Image** — "Before photo (posterior)"
7. **Label** — "Post-session"
8. **Slider** — Post-session pain (0–10)
9. **Text Field** — Clinical observations (multiline)

### 6. Reports & Dashboard (Metrics & Financial Management)

Comprehensive business intelligence dashboard with weekly, monthly, and annual views:

**Operational Metrics:**
- Total sessions completed
- Cancellation, no-show, and rescheduling rates
- New patient registrations per period

**Financial Tracking:**
- **Gross Revenue:** Auto-calculated from completed sessions (configurable rate per session or packages)
- **Payment Status:** Track payment status per session (Paid, Pending, Package)
- **Accounts Receivable:** Identify overdue payments
- **Revenue Projections:** Forecast based on scheduled appointments

**Clinical Success Metrics:**
- **Most Used Techniques:** Chart of tag frequency (Cupping, Dry Needling, etc.)
- **Pain Evolution:** Average patient pain reduction (auto-calculated from pre/post VAS scores)
- **Session Duration Analysis:** Track average session length
- **Patient Retention Rate:** Monitor repeat client ratio

**Data Export (Phase 3):**
- Export financial and operational summaries as PDF or spreadsheet (CSV/Excel)
- Ready for accounting review or external analysis

---

## Data Model Entities

```
User
├── id
├── name
├── phone
├── email
└── authentication_method

Patient
├── id
├── name
├── phone
├── email
├── date_of_birth
├── occupation
├── emergency_contact
└── status (active/inactive/archived)

Appointment
├── id
├── patient_id
├── scheduled_date
├── duration_minutes
├── status (scheduled/completed/cancelled/rescheduled)
└── notes

SessionRecord
├── id
├── appointment_id
├── templateId                (which template was used)
├── templateVersion           (snapshot version at fill time)
├── fieldValues               (map of fieldGuid → value)
├── session_datetime
│
│   ── Legacy fixed fields (pre-template, kept for backwards compat) ──
├── pre_pain_score (VAS 0-10)
├── post_pain_score (VAS 0-10)
├── techniques_applied (tags)
├── photos (filepaths)
└── observations

FinancialRecord
├── id
├── session_id
├── amount
├── payment_status (paid/pending/package)
├── payment_date
└── notes

Template
├── id                        (stable GUID)
├── name
├── description
├── currentVersion            (int, increments on each save)
├── lastSavedAt               (UTC timestamp)
├── isDefault                 (bool — clinic default template)
└── fields[]                  → FieldDefinition[]

FieldDefinition
├── guid                      (stable GUID — never changes)
├── type                      (slider | textField | label | tags | comboBox | image | checkbox)
├── label
├── order                     (sort index)
├── required                  (bool)
├── addedInVersion            (template version when field was introduced)
└── config                    (type-specific JSON)
    ├── [slider]   min, max, step, unit
    ├── [text]     multiline (bool), maxLength
    ├── [tags]     options[], allowCustom (bool)
    ├── [combo]    options[]
    ├── [checkbox] items[] (label + guid per item), requireAll (bool)
    └── [image]    hint (string)

TemplateVersion               (immutable snapshot)
├── templateId
├── version                   (int)
├── savedAt
└── fieldsSnapshot[]          → FieldDefinition[] (full copy at save time)
```

---

## AI Integration & Development Guidelines

**All AI and developer work on this project MUST adhere to these principles:**

### Localization (Portuguese-BR First)
- **Every user-facing screen and widget MUST use `AppLocalizations`**
- No hardcoded UI strings allowed
- Portuguese-BR (`pt_BR`) is the default locale
- English and other languages are translations only
- Use ARB files for string management (`lib/l10n/app_pt.arb` is source of truth)
- Run `flutter gen-l10n` after adding new strings

### Branding & Color Compliance
- **All UI components must respect the stored color palette from preferences**
- Never hardcode colors; always reference the `BrandingPreferences`
- Ensure WCAG color contrast compliance for accessibility
- Test color combinations across all app screens

### Data Privacy & Security
- Comply with LGPD and local data protection regulations
- Isolate photos from device gallery
- Encrypt sensitive patient data in local storage
- Implement automatic session logout after inactivity

### Code Quality Standards
- Create reusable components and avoid duplication
- Follow Flutter best practices and design patterns
- Use dependency injection for testability
- Write clear, self-documenting code with comments for complex logic
- Test all features for offline functionality

---

## Next Steps

### Phase 1: Foundation ✅
- [x] Set up Flutter project structure and dependencies
- [x] Firebase Firestore with offline persistence (replaces Isar — works on web + mobile)
- [x] All data models (Patient, Appointment, SessionRecord, FinancialRecord, BrandingPreferences)
- [x] Patient management screens (list, detail, form)
- [x] Appointment scheduling interface (week picker, form)
- [x] Session recording workflow (VAS sliders, technique chips)
- [x] Dashboard with operational and financial metrics
- [x] Branding/color customization system
- [x] Localization (pt_BR default, en fallback)

### Phase 2: Auth & Clinic Isolation
- [ ] Firebase Auth (Email/Password or Google Sign-In)
- [ ] Replace `_clinicId = 'default'` with authenticated user's UID
- [ ] Firestore Security Rules to isolate each clinic's data

### Phase 3: Integration & Polish
- [ ] Integrate Google Calendar API (bidirectional sync)
- [ ] Add data export functionality (PDF/CSV)
- [ ] Testing and performance optimization
- [ ] Template system (custom session tags and protocols)

### Phase 4: Enhancement (Future)
- [ ] Photo annotation tools
- [ ] Advanced analytics and reporting
- [ ] Multi-user support (multiple therapists)
- [ ] Client-facing app for appointment booking

---

## Key Success Criteria

✅ Session documentation takes less than 2 minutes per patient  
✅ App functions completely offline  
✅ Cloud backup occurs automatically when online  
✅ All patient data is LGPD-compliant and secure  
✅ Financial tracking is accurate and exportable