# External Anamnesis — Patient Self-Fill via Link

## Overview

The clinician shares a link with the patient so they can fill out the anamnesis form on their own device (phone, tablet, or computer) — **no login required**. The form is rendered as a web page hosted on Firebase Hosting, using the same template engine that powers in-app anamnesis.

This saves chair time: the patient fills demographics, complaint history, and lifestyle questions before the first appointment, and the clinician reviews the completed form when the patient arrives.

---

## User Flow

### Clinician Side

1. Opens the patient detail screen.
2. Taps **"Send anamnesis"** button.
3. Picks which anamnesis template to use (or the clinic default is pre-selected).
4. The app generates a unique, unguessable link and displays share options:
   - **Copy link** — copies to clipboard.
   - **Share** — opens native share sheet (WhatsApp, SMS, email, etc.).
5. The anamnesis status on the patient card updates to **Pending**.
6. When the patient opens the link, status changes to **Opened**.
7. When the patient submits the form, status changes to **Completed** and the data appears on the patient detail screen.

### Patient Side

1. Receives the link via WhatsApp / SMS / email.
2. Opens the link in their phone browser — no app install or login needed.
3. Sees a clean form page with:
   - Clinic branding (name, logo, primary color).
   - Their name displayed at the top (read-only, not editable).
   - All template fields rendered in order (sliders, text fields, tags, dropdowns, checkboxes, toggles).
4. Fills out the fields and taps **"Submit"**.
5. Sees a confirmation screen: "Anamnesis sent successfully!"
6. The link becomes read-only (the patient can revisit it to see what they submitted, but cannot edit).

---

## Link Format & Routing

```
https://<clinic-domain>.web.app/anamnesis/<token>
```

- `<token>` is a unique, unguessable identifier (UUID v4 or Firestore auto-ID) — **not** the patient ID.
- Using a random token prevents enumeration attacks and avoids exposing patient IDs in URLs.

### Routing

| Scenario | Behavior |
|---|---|
| Valid token, status = `pending` | Mark as `opened`, render the form |
| Valid token, status = `opened` | Render the form (patient may have refreshed) |
| Valid token, status = `completed` | Show read-only summary of submitted answers |
| Invalid / expired token | Show "This link is invalid or has expired" message |

---

## Data Model

### `AnamnesisRequest` (Firestore collection: `clinics/{clinicId}/anamnesisRequests`)

| Field | Type | Description |
|---|---|---|
| `id` | `string` | Auto-generated document ID (= the token in the URL) |
| `patientId` | `string` | Reference to the patient |
| `patientName` | `string` | Denormalized for display on the web form (avoids extra query) |
| `templateId` | `string` | Which anamnesis template to render |
| `templateVersion` | `int` | Snapshot version at the time of request creation |
| `fieldsSnapshot` | `List<FieldDefinition>` | Full copy of template fields (so the form is self-contained even if the template changes later) |
| `status` | `string` | `pending` / `opened` / `completed` |
| `responseData` | `Map<String, dynamic>` | Field GUID -> value (populated when patient submits) |
| `createdAt` | `Timestamp` | When the clinician generated the link |
| `openedAt` | `Timestamp?` | When the patient first opened the link |
| `completedAt` | `Timestamp?` | When the patient submitted the form |
| `expiresAt` | `Timestamp` | Auto-expire date (e.g., 30 days after creation) |

### Why a separate collection?

- Keeps the request lifecycle (pending/opened/completed) decoupled from the Patient document.
- Allows multiple anamnesis requests per patient (e.g., re-assessment after 6 months).
- The `fieldsSnapshot` makes the web form fully self-contained — no need to query the templates collection.
- Once completed, the response data is **copied** to `Patient.anamnesisData` for quick access in the app.

---

## Security

| Concern | Mitigation |
|---|---|
| **No authentication** | The token itself acts as a capability token — possession of the link grants access. This is the same model used by Google Docs "anyone with the link" sharing. |
| **Patient ID exposure** | The URL contains only the random token, never the patient ID. |
| **Enumeration** | Firestore auto-IDs are 20 characters of base62 — brute-forcing is infeasible. |
| **Expiration** | Links expire after a configurable period (default: 30 days). Expired links show a generic error. |
| **Write-once** | Once status = `completed`, the form is read-only. The patient cannot overwrite their submission. |
| **Firestore rules** | The `anamnesisRequests` collection allows unauthenticated reads/writes **only** on the specific document matching the token, and only for `status` and `responseData` fields. All other fields are read-only to the client. |

### Firestore Security Rules (sketch)

```javascript
match /clinics/{clinicId}/anamnesisRequests/{requestId} {
  // Anyone with the token (document ID) can read
  allow read: if true;

  // Anyone can update status and responseData, but ONLY if:
  // - current status is not 'completed' (write-once)
  // - only allowed fields are being changed
  allow update: if resource.data.status != 'completed'
    && request.resource.data.diff(resource.data).affectedKeys()
       .hasOnly(['status', 'responseData', 'openedAt', 'completedAt']);

  // Only authenticated clinic users can create or delete
  allow create: if request.auth != null;
  allow delete: if request.auth != null;
}
```

---

## Web Form — UI Specification

The web form is a standalone Flutter Web page (or a lightweight HTML page) served by Firebase Hosting.

### Layout

```
+--------------------------------------------------+
|  [Clinic Logo]   Clinic Name                     |
+--------------------------------------------------+
|                                                  |
|  Anamnesis for: **Patient Name**                 |
|                                                  |
|  ┌─────────────────────────────────────────────┐ |
|  │  Field 1: Queixa principal                  │ |
|  │  [multiline text input]                     │ |
|  ├─────────────────────────────────────────────┤ |
|  │  Field 2: Inicio dos sintomas               │ |
|  │  [dropdown: < 1 semana, 1-4 semanas, ...]   │ |
|  ├─────────────────────────────────────────────┤ |
|  │  Field 3: Nivel de dor                      │ |
|  │  [slider 0-10]                              │ |
|  ├─────────────────────────────────────────────┤ |
|  │  ...                                        │ |
|  └─────────────────────────────────────────────┘ |
|                                                  |
|  [ Submit ]                                      |
|                                                  |
+--------------------------------------------------+
|  Powered by Kelyn Physio                         |
+--------------------------------------------------+
```

### Behavior

- **Responsive**: works on mobile screens (360px+), tablets, and desktop.
- **Auto-save draft**: form state is saved to `localStorage` as the patient types, so they can close the tab and come back without losing progress.
- **Validation**: required fields are enforced before submission. Inline error messages in red below each field.
- **Loading state**: a spinner overlay while submitting to Firestore.
- **Success state**: replaces the form with a confirmation message and a summary of what was submitted.
- **Offline tolerance**: if the patient loses connection mid-fill, the form retains data locally and retries submission when back online.

### Supported Field Types

All field types from the template engine must be supported on the web form:

| Field Type | Web Rendering |
|---|---|
| `slider` | Material slider with min/max labels and current value display |
| `textField` | Single-line or multiline `<textarea>` based on config |
| `label` | Read-only styled text block (section headers, instructions) |
| `tags` | Wrap of tappable chips; multi-select; optional custom tag input |
| `comboBox` | Dropdown / select menu |
| `image` | File upload button + camera capture (on mobile browsers) |
| `checkbox` | Group of labeled checkboxes |
| `toggle` | On/off switch |
| `subTemplate` | Rendered inline (not as a separate page — there's no navigation on the web form) |

---

## Implementation Approach

### Option A: Flutter Web (recommended)

Build the external form as a route within the existing Flutter app and deploy the web build to Firebase Hosting. This reuses 100% of the field rendering widgets already built for the in-app anamnesis form.

**Pros:**
- Zero duplication of field widgets.
- Template rendering logic is already done.
- Firestore SDK works out of the box on Flutter Web.

**Cons:**
- Flutter Web bundle size (~2-3 MB) for a single form page.
- Initial load is slower than a native HTML form.

### Option B: Lightweight HTML + JS

Build a standalone HTML page with vanilla JS or a small framework (e.g., Alpine.js) that reads the `fieldsSnapshot` from Firestore and renders the form dynamically.

**Pros:**
- Very fast load (~50 KB).
- No Flutter Web overhead.

**Cons:**
- Must re-implement every field type renderer.
- Must include Firebase JS SDK.
- Two codebases to maintain for the same field logic.

### Recommendation

**Start with Option A** (Flutter Web). The bundle size is acceptable for a one-time form fill, and it eliminates the risk of field rendering divergence between the app and the web form. If performance becomes a concern, the `fieldsSnapshot` data model supports Option B as a future migration without any backend changes.

---

## Status Display in the App

The patient detail screen should show the anamnesis request status:

| Status | Display | Color |
|---|---|---|
| `pending` | "Anamnesis sent — waiting for patient" | Amber |
| `opened` | "Patient opened the form" | Blue |
| `completed` | "Anamnesis completed" + tap to view | Green |
| _(no request)_ | "Send anamnesis" button | Neutral |

When status changes to `completed`, the app should:
1. Copy `responseData` into `Patient.anamnesisData`.
2. Set `Patient.anamnesisTemplateId` and `Patient.anamnesisTemplateVersion`.
3. Show a notification or badge on the patient card.

This can be done reactively via a Firestore snapshot listener on the request document, or via a Cloud Function trigger.

---

## Localization

The web form language should match the **patient's browser locale**, not the clinician's app locale. The form should support at minimum `pt-BR` (default) and `en`.

### New ARB keys needed

```json
"sendAnamnesis": "Enviar anamnese",
"anamnesisSent": "Anamnese enviada!",
"anamnesisStatusPending": "Aguardando preenchimento",
"anamnesisStatusOpened": "Paciente abriu o formulario",
"anamnesisStatusCompleted": "Anamnese preenchida",
"anamnesisExpired": "Este link expirou",
"anamnesisInvalidLink": "Link invalido ou expirado",
"anamnesisSubmitted": "Anamnese enviada com sucesso!",
"anamnesisSubmittedDesc": "Suas respostas foram salvas. Voce pode fechar esta pagina.",
"anamnesisFormTitle": "Anamnese para: {patientName}",
"submitAnamnesis": "Enviar",
"anamnesisLinkCopied": "Link copiado!",
"shareAnamnesis": "Compartilhar link",
"expiresIn": "Expira em {days} dias",
"resendAnamnesis": "Reenviar link"
```

---

## Edge Cases

| Scenario | Handling |
|---|---|
| Clinician sends a second request before the first is completed | Cancel/expire the previous request and create a new one. Only one active request per patient. |
| Patient fills part of the form and closes the browser | Draft saved in `localStorage`. When they reopen the same link, the form is restored. |
| Template is edited after the request was created | No effect — the request contains a `fieldsSnapshot`. The patient sees the version that was current when the link was generated. |
| Patient tries to submit an already-completed form | Show read-only view with their previous answers. |
| Link expires | Show a friendly message asking them to contact the clinic for a new link. |
| Clinician deletes the patient | The request document remains (orphaned). The web form still works — but the clinician can manually delete the request if needed. |

---

## Phases

### Phase 1 — MVP

- [ ] Create `AnamnesisRequest` model and Firestore collection
- [ ] "Send anamnesis" button on patient detail screen
- [ ] Generate link + share via native share sheet / copy
- [ ] Status badge on patient card (pending / opened / completed)
- [ ] Flutter Web route: `/anamnesis/:token`
- [ ] Web form renders all field types from `fieldsSnapshot`
- [ ] Submit writes `responseData` to Firestore
- [ ] On completion, copy data to `Patient.anamnesisData`
- [ ] Firestore security rules for unauthenticated access
- [ ] Firebase Hosting deployment

### Phase 2 — Polish

- [ ] Auto-save draft to `localStorage`
- [ ] Clinic branding on the web form (logo, colors)
- [ ] Expiration handling (30-day default)
- [ ] Real-time status updates via Firestore listener
- [ ] Push notification when patient completes the form
- [ ] "Resend link" option for expired requests

### Phase 3 — Future

- [ ] PDF export of completed anamnesis
- [ ] Digital signature / consent checkbox
- [ ] Multi-language form (detect patient browser locale)
- [ ] Analytics: average fill time, completion rate, drop-off fields
