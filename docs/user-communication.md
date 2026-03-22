# Clinika Flow — Patient Communication & Re-engagement

## Philosophy

A clinic's relationship with a patient doesn't start at check-in and end at checkout. The moments **between sessions** are where trust, loyalty, and retention are built. Clinika Flow should make it effortless for clinicians to maintain that relationship without it feeling like a chore — automating the _when_ and _who_, while keeping the clinician in control of the _what_ and _whether_.

**Core principle:** Clinika Flow never sends a message automatically. It **drafts, suggests, and opens the channel** — the clinician always taps "Send". This keeps communication authentic and avoids legal/spam issues with unsolicited automated messaging.

---

## 1. Post-Session Follow-Up

### Problem

After a session, the best clinicians send a WhatsApp message checking on the patient: "How are you feeling? Is the pain better?" This builds trust and shows genuine care. But most clinicians forget, or it takes too much time to do manually for every patient.

### Solution

When a session is marked as **completed**, Clinika Flow schedules a follow-up reminder for a configurable delay (default: 24 hours). The clinician receives an in-app notification with a pre-drafted message and a one-tap action to open WhatsApp with the message ready to send.

### Flow

1. Clinician completes a session for patient "Maria".
2. Next day or 24 hours later, a card appears in the **Dashboard** or a dedicated **Follow-ups** section:
   > **Follow up with Maria**
   > Session: Liberacao Miofascial — yesterday
   > [Send via WhatsApp] [Dismiss] [Snooze 24h]
3. Tapping **"Send via WhatsApp"**:
   - Opens WhatsApp with the patient's number pre-filled (`wa.me/<number>?text=<encoded_message>`).
   - The message is pre-drafted from a configurable template (see Message Templates below).
   - The clinician can edit before sending.
4. After sending (or dismissing), the follow-up is marked as done.

### Follow-Up Feedback Form (Optional)

As an alternative to a simple WhatsApp text, the clinician can send a **feedback form link** — reusing the same external form infrastructure as the external anamnesis feature. The form can include:

- Pain level slider (0–10) for comparison with the session record
- Free-text field: "How are you feeling since the session?"
- Toggle: "Would you like to schedule a follow-up?"

This creates structured data that feeds into the patient's history and the dashboard analytics, unlike a WhatsApp conversation which stays outside the app.

### Data Model

```
clinics/{clinicId}/followUps/{followUpId}
├── patientId: string
├── appointmentId: string
├── type: "post_session" | "reactivation" | "birthday" | "custom"
├── status: "pending" | "sent" | "dismissed" | "snoozed"
├── scheduledAt: Timestamp
├── sentAt: Timestamp?
├── channel: "whatsapp" | "feedback_form" | "manual"
├── messageTemplateId: string?
├── snoozedUntil: Timestamp?
├── createdAt: Timestamp
```

### Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| Follow-up delay | 24 hours | Time after session completion before the reminder appears |
| Auto-create follow-ups | On | Whether completing a session automatically creates a follow-up |
| Default message template | Built-in | Which message template to use for post-session follow-ups |

---

## 2. Patient Re-engagement

### Problem

Patients stop coming. Life gets busy, they forget, or they think they're "cured". The clinic loses revenue, and the patient may relapse without maintenance sessions. Currently, the clinician has to manually remember who hasn't been around — which means it doesn't happen.

### Solution

Clinika Flow automatically identifies patients who haven't had a session in a configurable period and surfaces them for re-engagement. The system never sends messages on its own — it creates a **re-engagement list** and helps the clinician reach out.

### Inactivity Detection

A patient is considered **inactive** when:

| Patient Status | Condition |
|----------------|-----------|
| At risk | No session in 30 days (configurable) |
| Inactive | No session in 60 days (configurable) |
| Dormant | No session in 90+ days |

These thresholds should be configurable per clinic, since session frequency varies by specialty (e.g., weekly physiotherapy vs. monthly maintenance massage).

### Re-engagement Dashboard

A dedicated section (tab or card on Dashboard) showing:

```
+--------------------------------------------------+
|  Patients to re-engage              Filter: All  |
+--------------------------------------------------+
|                                                   |
|  AT RISK (12)                                     |
|  ┌───────────────────────────────────────────┐    |
|  │ Maria Silva          Last session: 32d ago│    |
|  │ [WhatsApp] [Schedule] [Dismiss]           │    |
|  ├───────────────────────────────────────────┤    |
|  │ Joao Santos          Last session: 35d ago│    |
|  │ [WhatsApp] [Schedule] [Dismiss]           │    |
|  └───────────────────────────────────────────┘    |
|                                                   |
|  INACTIVE (7)                                     |
|  ...                                              |
|                                                   |
|  DORMANT (15)                                     |
|  ...                                              |
+--------------------------------------------------+
```

### Re-engagement Actions

| Action | Behavior |
|--------|----------|
| **WhatsApp** | Opens WhatsApp with a pre-drafted re-engagement message (see Message Templates). |
| **Schedule** | Opens the appointment creation screen with the patient pre-selected. |
| **Dismiss** | Removes from the list for this cycle. Patient reappears in the next cycle (30 days) unless marked as archived. |
| **Archive** | Permanently removes the patient from the active list. Can be undone from patient detail. |

### Cooldown System

To prevent spamming patients:

- After a re-engagement message is sent, the patient is removed from the list for **30 days** (configurable).
- A `lastContactedAt` timestamp is stored on the patient document.
- The re-engagement list excludes patients contacted within the cooldown period.
- If a patient schedules a new appointment, they are automatically removed from the re-engagement list.

---

## 3. Message Templates

All messages sent through Clinika Flow use **configurable templates** with variable interpolation. The clinic can customize the default templates or create new ones.

### Built-in Templates

#### Post-Session Follow-Up

**PT-BR (default):**
```
Ola {patientFirstName}, tudo bem? Aqui é da {clinicName}.
Como você está se sentindo após a sessão de ontem?
Alguma mudança na dor ou desconforto?
Estou acompanhando sua evolução. Qualquer coisa, me avise!
```

**EN:**
```
Hi {patientFirstName}! This is {clinicName}.
How are you feeling after yesterday's session?
Any changes in pain or discomfort?
I'm tracking your progress. Let me know if you need anything!
```

#### Re-engagement (At Risk)

**PT-BR:**
```
Ola {patientFirstName}! Aqui e da {clinicName}.
Faz um tempinho que nao nos vemos! Como voce esta?
Lembre que manter a regularidade e importante para os resultados.
Quer agendar uma sessao? Estou com horarios disponiveis!
```

#### Re-engagement (Inactive / Dormant)

**PT-BR:**
```
Ola {patientFirstName}! Aqui e da {clinicName}.
Ja faz um tempo desde a sua ultima sessao e queria saber como voce esta.
Temos novidades e horarios disponiveis.
Que tal agendar uma avaliacao? {discountOffer}
```

#### Birthday

**PT-BR:**
```
Feliz aniversario, {patientFirstName}!
A equipe da {clinicName} deseja um dia incrivel para voce.
Aproveite e reivindique seu desconto exclusivo de 20% no mês do seu aniversário!
Aproveite seu dia! 🎉
```

### Available Variables

| Variable | Source | Example |
|----------|--------|---------|
| `{patientFirstName}` | `patient.fullName.split(' ')[0]` | Maria |
| `{patientFullName}` | `patient.fullName` | Maria Silva |
| `{clinicName}` | `branding.clinicName` | Studio Corpo & Movimento |
| `{lastSessionDate}` | Last completed appointment | 15/02/2026 |
| `{daysSinceLastSession}` | Calculated | 32 |
| `{discountOffer}` | From active campaign (see Section 5) | "Ganhe 10% de desconto na proxima sessao!" |

### Custom Templates

Clinicians can create and save their own message templates from Settings. Each template has:

- Name (e.g., "Pos-sessao com alongamento")
- Body text with variable placeholders
- Use case: post-session / re-engagement / birthday / general
- Language: pt-BR / en

---

## 4. Google Reviews & Feedback Collection

### Problem

Google Maps reviews are critical for local clinic discovery, but patients rarely leave reviews unless asked. The ask needs to happen at the right moment — when satisfaction is highest (right after a good session or after measurable improvement).

### Strategy: Two-Step Approach

**Step 1 — Internal feedback first (NPS-style filter)**

After a configurable number of sessions (e.g., every 5th session), prompt the clinician to send a quick satisfaction check:

> "De 0 a 10, quanto voce recomendaria a {clinicName} para um amigo?"

This can be sent as a simple WhatsApp message or as a one-question feedback form (reusing external form infrastructure).

**Step 2 — Route based on score**

| Score | Action |
|-------|--------|
| 9–10 (Promoter) | Send a follow-up asking for a Google Maps review, with a direct link to the clinic's review page. |
| 7–8 (Passive) | Thank them. Optionally offer an incentive for a review. |
| 0–6 (Detractor) | Thank them and ask what could be improved. Flag internally for the clinician to address. Do NOT ask for a public review. |

This protects the clinic from routing unhappy patients to Google Reviews.

### Google Review Link

The clinic configures their Google Maps review link in **Settings > Clinic Profile**. The format is:

```
https://search.google.com/local/writereview?placeid=<PLACE_ID>
```

### Review Request Message Template

**PT-BR:**
```
{patientFirstName}, muito obrigado pelo feedback positivo!
Ficamos felizes em saber que voce esta satisfeito com o atendimento.
Se puder, deixar uma avaliacao no Google nos ajuda muito a alcancar mais pessoas:
{googleReviewLink}
Agradecemos de coracao!
```

### Incentive Options

To increase review rates, the clinic can optionally attach an incentive:

| Incentive | Example | Implementation |
|-----------|---------|----------------|
| Session discount | 10% off next session | Coupon code or manual discount at checkout |
| Free add-on service | Avaliacao com camera termica gratis | Noted on patient record, applied at next visit |
| Priority scheduling | Escolha o melhor horario da semana | Manual |

Incentives are configured per campaign (see Section 5) and inserted into the message via the `{discountOffer}` variable.

### Data Model

```
clinics/{clinicId}/feedbackRequests/{id}
├── patientId: string
├── type: "nps" | "post_session" | "review_request"
├── score: int? (0-10, filled when patient responds)
├── response: string? (free text)
├── status: "pending" | "responded" | "review_sent" | "dismissed"
├── channel: "whatsapp" | "feedback_form"
├── createdAt: Timestamp
├── respondedAt: Timestamp?
```

### Dashboard Integration

The Dashboard should show:

- **Average NPS score** (last 30/90 days)
- **Review conversion rate** (promoters who actually left a Google review — tracked manually via a "They reviewed" toggle)
- **Feedback trends** over time

---

## 5. Campaigns & Promotions

### Problem

Clinics want to run seasonal promotions, re-engagement discounts, and referral incentives — but they lack the tools to organize and track these campaigns.

### Solution: Campaign Manager

A lightweight campaign system that helps the clinician create time-limited offers and attach them to communication flows.

### Campaign Model

```
clinics/{clinicId}/campaigns/{campaignId}
├── name: string (e.g., "Mes da Mulher 2026")
├── description: string
├── type: "seasonal" | "reengagement" | "referral" | "general"
├── discountType: "percentage" | "fixed" | "addon" | "none"
├── discountValue: number? (e.g., 10 for 10%, or 50 for R$50)
├── discountDescription: string (e.g., "10% de desconto na proxima sessao")
├── startDate: Timestamp
├── endDate: Timestamp
├── targetAudience: "all" | "inactive" | "new" | "returning"
├── status: "draft" | "active" | "ended"
├── usageCount: int (how many patients redeemed)
├── createdAt: Timestamp
```

### Campaign Ideas by Type

| Type | Examples | Target | Timing |
|------|----------|--------|--------|
| **Seasonal** | Mes da Mulher, Dia das Maes, Black Friday, Volta as Aulas | All or specific segments | Calendar-driven |
| **Re-engagement** | "Sentimos sua falta — 15% off" | Inactive 60+ days | Always available, attached to re-engagement messages |
| **Referral** | "Indique um amigo, ganhem desconto" | All active patients | Ongoing |
| **Milestone** | "Sua 10a sessao! Ganhe uma avaliacao gratis" | Returning patients | Triggered by session count |

### How Campaigns Connect to Messages

When a campaign is **active**, the `{discountOffer}` variable in message templates is populated with the campaign's `discountDescription`. If no campaign is active, the variable resolves to an empty string (the message still reads naturally without it).

---

## 6. Referral System

### Problem

Word-of-mouth is the #1 acquisition channel for clinics, but it's entirely untracked. The clinician has no idea which patients are bringing new ones, and there's no incentive structure.

### Solution

A simple referral tracking system:

### Flow

1. Patient "Maria" wants to refer a friend.
2. Clinician taps **"Generate referral link"** on Maria's patient detail screen (or sends a referral message via WhatsApp).
3. When the referred person ("Joao") books their first appointment, the clinician marks Joao's record with `referredBy: Maria's patientId`.
4. Both Maria and Joao receive the referral reward (if a referral campaign is active).

### Data Model

Add to the Patient model:

```dart
referredBy: String?         // patientId of the referrer
referralCount: int          // how many patients this person has referred
```

### Referral Tracking on Dashboard

- **Top referrers** list (patients who brought the most new patients)
- **Referral conversion rate** (referred leads who became patients)
- **Revenue attributed to referrals**

### Why Not a Full Referral Link System?

A referral tracking link (e.g., `clinikaflow.app/ref/<code>`) adds complexity (landing page, code redemption, online booking) that most small clinics don't need yet. The MVP is **manual attribution** — the clinician asks "how did you hear about us?" and tags the referrer in the system. Automated referral links can be a Phase 2 feature tied to online booking.

---

## 7. Appointment Reminders

### Problem

No-shows cost clinics money and waste schedule slots. A simple reminder 24 hours before the appointment dramatically reduces no-shows.

### Solution

When an appointment is scheduled, the system creates a reminder for 24 hours before. Same pattern as follow-ups: a card appears prompting the clinician to send a WhatsApp reminder.

### Reminder Message Template

**PT-BR:**
```
Ola {patientFirstName}! Passando para lembrar da sua sessao amanha,
dia {appointmentDate} as {appointmentTime}, na {clinicName}.
Nos vemos la! Qualquer imprevisto, nos avise com antecedencia.
```

### Future: Automated Reminders

Once Cloud Functions are in place, reminders can be sent automatically via WhatsApp Business API or SMS. This is a Phase 3 feature and requires:

- WhatsApp Business API account (Meta Business verification)
- Approved message templates (WhatsApp requires pre-approval for automated messages)
- Patient opt-in consent

Until then, the manual "tap to send" approach is sufficient and avoids regulatory complexity.

---

## 8. Birthday & Milestone Messages

### Problem

Small personal touches (birthday wishes, session milestones) build loyalty and differentiate the clinic. But remembering every patient's birthday is impractical.

### Solution

Clinika Flow checks `patient.dateOfBirth` daily and surfaces birthday cards on the Dashboard for patients with birthdays today or within the next 3 days. The clinician can send a birthday message via WhatsApp with one tap.

### Session Milestones

Track and celebrate:

| Milestone | Trigger | Suggested Action |
|-----------|---------|------------------|
| 1st session completed | First `completed` appointment | Thank-you message |
| 10th session | `sessionCount == 10` | Congratulations + optional reward from active campaign |
| 6-month anniversary | 6 months since first session | Check-in message + progress review offer |
| 1-year anniversary | 12 months since first session | Celebration message + referral ask |

---

## 9. Communication Hub (Future)

### Vision

A unified **Communication** tab (replacing or supplementing the Dashboard's follow-up cards) that aggregates all pending communication actions:

```
+--------------------------------------------------+
|  Communication                     Today: Mar 22 |
+--------------------------------------------------+
|                                                   |
|  TODAY (5)                                        |
|  [Follow-up] Maria Silva - post-session           |
|  [Reminder] Joao Santos - appointment tomorrow    |
|  [Birthday] Ana Costa - turns 35 today            |
|  [Re-engage] Pedro Lima - inactive 45 days        |
|  [Review]   Lucia Dias - 5th session, ask NPS     |
|                                                   |
|  UPCOMING (12)                                    |
|  Tomorrow: 3 reminders, 1 follow-up               |
|  This week: 2 birthdays, 4 re-engagements         |
|                                                   |
|  SENT RECENTLY (8)                                |
|  ...                                              |
+--------------------------------------------------+
```

This is a Phase 3 feature. In Phase 1, all communication prompts appear as cards on the existing Dashboard.

---

## 10. Monetization Integration

Communication features tie into the subscription tiers:

| Feature | Gratis | Essencial | Profissional | Clinica |
|---------|--------|-----------|--------------|---------|
| Post-session follow-ups | 5/month | 30/month | Unlimited | Unlimited |
| Re-engagement list | View only (no templates) | Full | Full | Full |
| Message templates | Built-in only | 5 custom | Unlimited | Unlimited |
| Campaigns | No | 1 active | Unlimited | Unlimited |
| NPS / Feedback forms | No | 5/month | Unlimited | Unlimited |
| Referral tracking | No | Basic (manual) | Full | Full |
| Appointment reminders | Manual only | Manual only | Manual + auto (Phase 3) | Manual + auto (Phase 3) |
| Birthday alerts | No | Yes | Yes | Yes |
| Communication Hub | No | No | Yes | Yes |

---

## Implementation Phases

### Phase 1 — Follow-ups & Re-engagement (MVP)

- [ ] `FollowUp` data model and Firestore collection
- [ ] Auto-create follow-up when session is completed (24h delay)
- [ ] Follow-up cards on Dashboard with WhatsApp deep-link action
- [ ] Dismiss / Snooze actions
- [ ] Inactivity detection query (30/60/90 day thresholds)
- [ ] Re-engagement list on Dashboard
- [ ] WhatsApp deep-link with pre-filled message (`wa.me` URL scheme)
- [ ] 3 built-in message templates (post-session, re-engagement, birthday)
- [ ] Cooldown tracking (`lastContactedAt` on patient)
- [ ] Quota gating per subscription tier

### Phase 2 — Feedback, Reviews & Campaigns

- [ ] Feedback form via external form infrastructure (reuse anamnesis pattern)
- [ ] NPS score collection and routing (promoter -> review ask)
- [ ] Google Review link configuration in Settings
- [ ] Review request message template
- [ ] Campaign CRUD (create, activate, end campaigns)
- [ ] `{discountOffer}` variable interpolation in templates
- [ ] Custom message template editor in Settings
- [ ] Referral tracking (manual attribution via `referredBy` field)
- [ ] Birthday detection and Dashboard cards
- [ ] Session milestone detection

### Phase 3 — Automation & Communication Hub

- [ ] Dedicated Communication tab
- [ ] Appointment reminder cards (24h before)
- [ ] Cloud Functions for automated reminder scheduling
- [ ] WhatsApp Business API integration (automated sending with patient opt-in)
- [ ] Referral link generation and landing page
- [ ] NPS trends and referral analytics on Dashboard
- [ ] Push notifications for completed feedback forms

---

## Technical Notes

### WhatsApp Deep Links (Phase 1 — No API Required)

The simplest integration is opening WhatsApp via URL scheme. No API key, no Meta Business verification, no cost:

```dart
final phone = patient.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
final message = Uri.encodeComponent(compiledTemplate);
final url = 'https://wa.me/55$phone?text=$message';
// Launch with url_launcher
```

This opens WhatsApp on the clinician's phone with the message pre-filled. The clinician reviews and taps send. Works on both iOS and Android.

### Reusing External Form Infrastructure

Feedback forms and NPS surveys can reuse the exact same infrastructure as external anamnesis:

- Create a `SessionTemplate` with feedback fields (pain slider, satisfaction, free text)
- Generate a token-based link
- Patient fills on their phone browser, no login required
- Responses sync back to Firestore

The only difference is the `type` field on the request (`"feedback"` vs `"anamnesis"`) and where the response data is stored.

### Offline Considerations

Follow-up and re-engagement data should sync with Firestore's offline persistence. If the clinician is offline:

- They can still see pending follow-ups (cached locally)
- Tapping "Send via WhatsApp" works (opens WhatsApp, which handles its own connectivity)
- Status updates sync when back online

### Keeping It Generic

All communication features must be **clinic-type agnostic**:

- No hardcoded references to specific therapies (physiotherapy, massage, etc.)
- Message templates use generic terms ("sessao", "atendimento") that work for any specialty
- Inactivity thresholds are configurable because session frequency varies by specialty
- Campaign types are open-ended, not tied to specific health events
