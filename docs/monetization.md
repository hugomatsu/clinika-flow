# Clinika Flow — Monetization Strategy

## Philosophy

The free tier must be **genuinely useful** — enough to run a small practice for a few months — but create natural friction that makes upgrading feel like a relief, not a punishment. The goal is data lock-in through value: once a clinician has 3+ months of patient history, session records, and templates built, switching to another tool costs more than upgrading.

---

## Free Tier Analysis

### Current proposal (problems)

| Limit | Value | Issue |
|-------|-------|-------|
| Patients | 50 | Too generous. A solo practitioner takes ~5 months to hit this. By then they're locked in, but you've given 5 months of free usage. |
| Storage | 10 MB | Too restrictive. A single phone photo is 2–5 MB. With image compression (~200 KB each), that's still only ~50 photos. A clinician taking before/after photos per session hits this in 2–3 weeks. Users will feel the app is broken, not that they need to upgrade. |
| Sessions | 100 | Reasonable as a total cap, but ambiguous — is it 100 total or per month? At 5 sessions/day, 100 total lasts ~1 month. |
| Templates | 4 | Fine. Most solo practitioners use 2–3 templates. |

### Recommended free tier

| Limit | Value | Reasoning |
|-------|-------|-----------|
| Patients | 15 | Enough to genuinely try the app with real patients for 2–3 weeks. Small enough that a working clinician hits the wall within the first month. |
| Storage | 100 MB | With compression (~200 KB/photo), that's ~500 photos — enough to not feel broken. Storage is cheap; the real cost driver is Firestore reads. |
| Sessions | 30 / month | Monthly cap feels fairer than a total cap and keeps the free tier usable indefinitely (for a very small practice). But 30/month means ~1.5 sessions/day — any real practice needs more. |
| Templates | 2 | Enough to start (one session template + one anamnesis). Forces upgrade when they want to specialize protocols. |
| External anamnesis | 5 / month | Let them try the feature, but gate it quickly. |
| Reports / Dashboard | Last 30 days only | They can see it works, but can't do quarterly reviews without upgrading. |
| Branding | Disabled | Default Clinika Flow branding. Paid plans unlock custom colors/logo. |
| Data export | Disabled | No CSV/PDF export on free tier. |

---

## Subscription Tiers

### Pricing (monthly)

| | Gratis | Essencial | Profissional | Clinica |
|---|--------|-----------|-------------|---------|
| **Price** | R$ 0 | R$ 29,90/mo | R$ 69,90/mo | R$ 149,90/mo |
| **Annual** | — | R$ 24,90/mo (R$ 299/yr) | R$ 59,90/mo (R$ 719/yr) | R$ 129,90/mo (R$ 1.559/yr) |
| **Target** | Evaluation | Solo practitioner | Established solo / small clinic | Multi-professional clinic |

### Limits per tier

| Resource | Gratis | Essencial | Profissional | Clinica |
|----------|--------|-----------|-------------|---------|
| Patients | 15 | 100 | 500 | Unlimited |
| Storage | 100 MB | 1 GB | 5 GB | 20 GB |
| Sessions | 30/month | Unlimited | Unlimited | Unlimited |
| Templates | 2 | 10 | Unlimited | Unlimited |
| External anamnesis | 5/month | 30/month | Unlimited | Unlimited |
| Professionals (users) | 1 | 1 | 1 | 5 |

### Features per tier

| Feature | Gratis | Essencial | Profissional | Clinica |
|---------|--------|-----------|-------------|---------|
| Patient management | Yes | Yes | Yes | Yes |
| Appointment scheduling | Yes | Yes | Yes | Yes |
| Session recording | Yes | Yes | Yes | Yes |
| Template builder | Yes | Yes | Yes | Yes |
| Financial tracking | Basic | Full | Full | Full |
| Dashboard / Reports | 30 days | 12 months | Unlimited history | Unlimited history |
| Data export (PDF/CSV) | No | No | Yes | Yes |
| Custom branding | No | No | Yes | Yes |
| External anamnesis | Limited | Limited | Unlimited | Unlimited |
| Google Calendar sync | No | Yes | Yes | Yes |
| Priority support | No | No | Yes | Yes |
| Multi-professional | No | No | No | Yes (up to 5) |

---

## Pricing Rationale

**Why not R$ 15?** At R$ 15/mo, the revenue per user is too low to sustain Firebase costs + development. A clinician charging R$ 150–300 per session won't blink at R$ 30/mo for a tool they use daily. Underpricing signals low quality in the Brazilian health market.

**Why R$ 29,90 for Essencial?** This is the "no-brainer" price point. Less than a single session fee. Removes all friction for solo practitioners who just need more patients and sessions. No premium features — just higher limits.

**Why R$ 69,90 for Profissional?** This is where the real value lives: unlimited templates, data export, branding, unlimited history. A practitioner seeing 15+ patients/week easily justifies this. Comparable tools (Clinicorp, ZenFisio) charge R$ 100–200+.

**Why R$ 149,90 for Clinica?** Multi-professional support is the key differentiator. A clinic with 2–5 therapists paying R$ 150/mo total is far cheaper than per-seat alternatives. The 20 GB storage accommodates heavier photo usage across multiple professionals.

**Annual discount (~17% off):** Standard SaaS incentive. Reduces churn and improves cash flow predictability.

---

## Implementation Notes

### Enforcement strategy

- **Soft limits:** When approaching a limit (80%), show a banner: "You've used 12 of 15 patient slots." No data loss, no blocked features — just awareness.
- **Hard limits:** When hitting a limit, block new creation (can't add patient #16) but never restrict access to existing data. Users must always be able to view and edit what they already have.
- **Grace period:** If a paid user downgrades or payment fails, give 15 days before enforcing free-tier limits. During grace, show "Renew to keep access" banners. After grace, mark excess data as read-only (not deleted).

### What to track in Firestore

```
clinics/{clinicId}/subscription
├── tier: "free" | "essential" | "professional" | "clinic"
├── status: "active" | "trial" | "past_due" | "cancelled"
├── currentPeriodEnd: Timestamp
├── patientCount: int (denormalized for quick checks)
├── storageUsedBytes: int
├── monthlySessionCount: int
├── monthlyAnamnesisCount: int
└── paymentProvider: "stripe" | "google_play" | "apple"
```

### Payment integration

- **Web:** Stripe Checkout (supports PIX, boleto, credit card)
- **Android:** Google Play Billing (required by Play Store policy for in-app subscriptions)
- **iOS:** StoreKit / Apple IAP (required by App Store policy)
- Consider Stripe as the canonical subscription system, with Play/Apple as wrappers that sync status via Cloud Functions.

---

## Revenue projections

| Scenario | Users | Mix | MRR |
|----------|-------|-----|-----|
| Conservative (6 months) | 200 total, 30 paid | 20 Essencial + 8 Profissional + 2 Clinica | R$ 1.457 |
| Moderate (12 months) | 800 total, 150 paid | 90 Essencial + 45 Profissional + 15 Clinica | R$ 7.935 |
| Optimistic (18 months) | 2.000 total, 500 paid | 300 Essencial + 150 Profissional + 50 Clinica | R$ 26.965 |

Assumes ~15–25% free-to-paid conversion rate, which is typical for vertical SaaS tools where the free tier is intentionally friction-creating.

---

## Key Decisions Still Open

1. **Trial period?** Consider 14-day free trial of Profissional tier for all new signups, then drop to Gratis. This lets users experience the full product before deciding.
2. **Per-seat vs per-clinic pricing for Clinica tier?** Current model is per-clinic (up to 5 users). Simpler, but large clinics (10+ therapists) need a custom/enterprise tier.
3. **Lifetime deal?** Early adopter offer (e.g., R$ 999 one-time = Profissional forever) can generate upfront cash but caps long-term revenue. Use sparingly.
4. **Referral program?** "Invite a colleague, both get 1 month free of Essencial" — low-cost acquisition channel for niche health market.
