# Kelyn Physio - Myofascial Release App

## Executive Summary

A custom-built mobile application designed to streamline myofascial release therapy sessions for physiotherapist Kelyn. The system prioritizes rapid clinical documentation during sessions and operates independently of internet connectivity (offline-first architecture), ensuring she maintains full control over her schedule and patient progress tracking, with cloud backup for security and data synchronization.

**Target Users:** Physiotherapist Kelyn and her clinic staff  
**Primary Goal:** Simplify session documentation while maintaining complete patient records

---

## Technology Stack

| Component | Technology |
|-----------|-----------|
| **Framework** | Flutter (iOS & Android) |
| **Architecture** | Offline-first with cloud sync |
| **Local Storage** | Isar (fast, efficient persistence without internet) |
| **Cloud Backend** | Firebase Firestore (Phase 3: backup & data synchronization) |
| **Calendar Integration** | Google Calendar API (Phase 3: bidirectional sync) |
| **Authentication** | Local PIN/Biometric (Phase 2), Firebase Auth (Phase 3) |

---

## Branding & Color Customization

The app is designed to reflect the client's brand identity through customizable color palettes.

**Color Palette Management:**
- **Storage:** Color preferences are saved in device local storage (Hive/Isar/SQLite) and synced to cloud
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

Allow users to create and manage reusable session templates for consistency and speed:

**Default Tags Management:**
- Create custom tag categories (e.g., "Techniques", "Areas", "Special Notes")
- Define default tags with icons/colors for quick identification
- Set most-used tags as favorites for priority display
- Reorder tags by frequency of use
- Tag validation to prevent duplicates

**Common Protocols:**
- Pre-built session workflows for different treatment types
- Each protocol includes: name, description, default tags, estimated duration, step-by-step instructions
- Quick-apply feature to populate session form with protocol data
- Ability to modify applied protocols during session
- Save custom protocols for future use
- Lock/unlock protocols for template versions

**Protocol Structure:**
- Protocol Name & Description
- Associated Tags (pre-selected)
- Estimated Duration
- Photo requirements checklist
- Common observations template
- Recommended follow-up actions

**Use Case Example:**
"Cupping Treatment Protocol" includes tags (Cupping, Trapezius, Pain Relief), standard photo requirements, and common observations like "check for contraindications", "document cupping marks", etc.

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
├── pre_pain_score (VAS 0-10)
├── post_pain_score (VAS 0-10)
├── techniques_applied (tags)
├── photos (filepaths)
├── observations
└── session_datetime

FinancialRecord
├── id
├── session_id
├── amount
├── payment_status (paid/pending/package)
├── payment_date
└── notes

SessionTag
├── id
├── name
├── category (Techniques, Areas, Special Notes, etc.)
├── icon_name
├── color_hex
├── is_favorite
└── frequency_count

Protocol
├── id
├── name
├── description
├── associated_tags (array of SessionTag IDs)
├── estimated_duration_minutes
├── photo_requirements (array of strings)
├── common_observations (template text)
├── recommended_followup (array of strings)
├── is_locked
└── created_date
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

### Share Feature Protocol
- **Always use `SharePreviewScreen` for sharing Stories** (when implemented)
- No direct `Share.share()` calls for Stories
- Deep link format: `https://magicechoes.app/story/<story_id>`
- Preview card must include: Cover Image, Title, Description, Author, App Badge

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

### Phase 1: Foundation
- [ ] Set up Flutter project structure and dependencies
- [ ] Design and implement local data models with Isar
- [ ] Build authentication UI (PIN/Biometric)

### Phase 2: Core Features
- [ ] Develop patient management screens
- [ ] Implement appointment scheduling interface
- [ ] Create session recording workflow
- [ ] Build dashboard with operational and financial metrics
- [ ] Implement template system (default tags and protocols)
- [ ] Build branding/color customization system

### Phase 3: Integration & Polish
- [ ] Integrate Google Calendar API (bidirectional sync)
- [ ] Implement cloud backup (Firebase Firestore)
- [ ] Add data export functionality (PDF/CSV)
- [ ] Firebase authentication integration
- [ ] Testing and performance optimization

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