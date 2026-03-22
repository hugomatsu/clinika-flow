import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/anamnesis_request.dart';
import '../models/appointment.dart';
import '../models/branding_preferences.dart';
import '../models/financial_record.dart';
import '../models/follow_up.dart';
import '../models/patient.dart';
import '../models/session_record.dart';
import '../models/session_template.dart';
import '../models/subscription.dart';

class FirestoreService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Uses the authenticated user's UID so each clinic's data is isolated.
  static String get _clinicId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'default';

  static CollectionReference<Map<String, dynamic>> get _patients =>
      _db.collection('clinics/$_clinicId/patients');

  static CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('clinics/$_clinicId/appointments');

  static CollectionReference<Map<String, dynamic>> get _sessions =>
      _db.collection('clinics/$_clinicId/sessions');

  static CollectionReference<Map<String, dynamic>> get _financials =>
      _db.collection('clinics/$_clinicId/financials');

  static CollectionReference<Map<String, dynamic>> get _templates =>
      _db.collection('clinics/$_clinicId/templates');

  static CollectionReference<Map<String, dynamic>> get _followUps =>
      _db.collection('clinics/$_clinicId/followUps');

  static DocumentReference<Map<String, dynamic>> get _branding =>
      _db.doc('clinics/$_clinicId/settings/branding');

  static DocumentReference<Map<String, dynamic>> get _subscription =>
      _db.doc('clinics/$_clinicId/settings/subscription');

  // ── Subscription ────────────────────────────────────────────────────────────

  static Future<Subscription> getSubscription() async {
    final doc = await _subscription.get();
    if (!doc.exists || doc.data() == null) return Subscription();
    return Subscription.fromMap(doc.data()!);
  }

  static Future<void> updateSubscription(Subscription sub) async {
    await _subscription.set(sub.toMap(), SetOptions(merge: true));
  }

  // ── Patient ───────────────────────────────────────────────────────────────

  static Future<Patient> createPatient(Patient patient) async {
    final ref = _patients.doc();
    patient.id = ref.id;
    patient.createdAt = DateTime.now();
    patient.updatedAt = DateTime.now();
    await ref.set(patient.toMap());
    return patient;
  }

  static Future<Patient> updatePatient(Patient patient) async {
    patient.updatedAt = DateTime.now();
    await _patients.doc(patient.id).update(patient.toMap());
    return patient;
  }

  static Future<List<Patient>> getAllPatients() async {
    final snap = await _patients.orderBy('fullName').get();
    return snap.docs.map((d) => Patient.fromMap(d.id, d.data())).toList();
  }

  static Future<Patient?> getPatientById(String id) async {
    final doc = await _patients.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Patient.fromMap(doc.id, doc.data()!);
  }

  static Future<void> deletePatient(String id) async {
    await _patients.doc(id).delete();
  }

  // ── Appointment ───────────────────────────────────────────────────────────

  static Future<Appointment> createAppointment(Appointment appointment) async {
    final ref = _appointments.doc();
    appointment.id = ref.id;
    appointment.createdAt = DateTime.now();
    appointment.updatedAt = DateTime.now();
    await ref.set(appointment.toMap());
    return appointment;
  }

  static Future<Appointment> updateAppointment(Appointment appointment) async {
    appointment.updatedAt = DateTime.now();
    await _appointments.doc(appointment.id).update(appointment.toMap());
    return appointment;
  }

  static Future<List<Appointment>> getAllAppointments() async {
    final snap =
        await _appointments.orderBy('scheduledDate', descending: true).get();
    return snap.docs
        .map((d) => Appointment.fromMap(d.id, d.data()))
        .toList();
  }

  static Future<List<Appointment>> getAppointmentsByPatient(
      String patientId) async {
    final snap = await _appointments
        .where('patientId', isEqualTo: patientId)
        .get();
    final list = snap.docs
        .map((d) => Appointment.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    return list;
  }

  static Future<void> deleteAppointment(String id) async {
    await _appointments.doc(id).delete();
  }

  // ── SessionRecord ─────────────────────────────────────────────────────────

  static Future<SessionRecord> createSessionRecord(
      SessionRecord record) async {
    final ref = _sessions.doc();
    record.id = ref.id;
    record.createdAt = DateTime.now();
    record.updatedAt = DateTime.now();
    await ref.set(record.toMap());
    return record;
  }

  static Future<SessionRecord> updateSessionRecord(
      SessionRecord record) async {
    record.updatedAt = DateTime.now();
    await _sessions.doc(record.id).update(record.toMap());
    return record;
  }

  static Future<List<SessionRecord>> getSessionsByAppointment(
      String appointmentId) async {
    final snap = await _sessions
        .where('appointmentId', isEqualTo: appointmentId)
        .get();
    return snap.docs
        .map((d) => SessionRecord.fromMap(d.id, d.data()))
        .toList();
  }

  static Future<List<SessionRecord>> getAllSessions() async {
    final snap =
        await _sessions.orderBy('sessionDateTime', descending: true).get();
    return snap.docs
        .map((d) => SessionRecord.fromMap(d.id, d.data()))
        .toList();
  }

  // ── FinancialRecord ───────────────────────────────────────────────────────

  static Future<FinancialRecord> createFinancialRecord(
      FinancialRecord record) async {
    final ref = _financials.doc();
    record.id = ref.id;
    record.createdAt = DateTime.now();
    record.updatedAt = DateTime.now();
    await ref.set(record.toMap());
    return record;
  }

  static Future<List<FinancialRecord>> getAllFinancialRecords() async {
    final snap = await _financials.get();
    return snap.docs
        .map((d) => FinancialRecord.fromMap(d.id, d.data()))
        .toList();
  }

  // ── SessionTemplate ──────────────────────────────────────────────────────

  static Future<SessionTemplate> createTemplate(
      SessionTemplate template) async {
    final ref = _templates.doc();
    template.id = ref.id;
    template.createdAt = DateTime.now();
    template.lastSavedAt = DateTime.now();
    template.currentVersion = 1;
    await ref.set(template.toMap());
    // Store the initial version snapshot
    await _saveVersionSnapshot(template);
    return template;
  }

  static Future<SessionTemplate> updateTemplate(
      SessionTemplate template) async {
    template.currentVersion += 1;
    template.lastSavedAt = DateTime.now();
    await _templates.doc(template.id).update(template.toMap());
    await _saveVersionSnapshot(template);
    return template;
  }

  static Future<void> _saveVersionSnapshot(SessionTemplate template) async {
    final version = TemplateVersion(
      templateId: template.id,
      version: template.currentVersion,
      savedAt: template.lastSavedAt,
      fieldsSnapshot: template.fields
          .map((f) => f.copyWith())
          .toList(),
    );
    await _templates
        .doc(template.id)
        .collection('versions')
        .doc('v${template.currentVersion}')
        .set(version.toMap());
  }

  static Future<List<SessionTemplate>> getAllTemplates() async {
    final snap = await _templates.orderBy('name').get();
    return snap.docs
        .map((d) => SessionTemplate.fromMap(d.id, d.data()))
        .toList();
  }

  static Future<SessionTemplate?> getTemplateById(String id) async {
    final doc = await _templates.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return SessionTemplate.fromMap(doc.id, doc.data()!);
  }

  static Future<TemplateVersion?> getTemplateVersion(
      String templateId, int version) async {
    final doc = await _templates
        .doc(templateId)
        .collection('versions')
        .doc('v$version')
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return TemplateVersion.fromMap(doc.data()!);
  }

  static Future<void> deleteTemplate(String id) async {
    // Delete version snapshots first
    final versions =
        await _templates.doc(id).collection('versions').get();
    for (final v in versions.docs) {
      await v.reference.delete();
    }
    await _templates.doc(id).delete();
  }

  // ── AnamnesisRequest ─────────────────────────────────────────────────────
  // Top-level collection so unauthenticated patients can access by token.

  static CollectionReference<Map<String, dynamic>> get _anamnesisRequests =>
      _db.collection('anamnesisRequests');

  static Future<AnamnesisRequest> createAnamnesisRequest(
      AnamnesisRequest request) async {
    final ref = _anamnesisRequests.doc();
    request.id = ref.id;
    request.clinicId = _clinicId;
    request.createdAt = DateTime.now();
    await ref.set(request.toMap());
    return request;
  }

  /// Fetch by token (document ID) — no auth required.
  static Future<AnamnesisRequest?> getAnamnesisRequestByToken(
      String token) async {
    final doc = await _anamnesisRequests.doc(token).get();
    if (!doc.exists || doc.data() == null) return null;
    return AnamnesisRequest.fromMap(doc.id, doc.data()!);
  }

  /// Get the active request for a patient (most recent non-completed).
  static Future<AnamnesisRequest?> getActiveAnamnesisRequest(
      String patientId) async {
    final snap = await _anamnesisRequests
        .where('clinicId', isEqualTo: _clinicId)
        .where('patientId', isEqualTo: patientId)
        .get();
    final list = snap.docs
        .map((d) => AnamnesisRequest.fromMap(d.id, d.data()))
        .toList();
    // Return most recent that isn't expired
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.isNotEmpty ? list.first : null;
  }

  /// Update status (e.g. pending → opened → completed).
  static Future<void> updateAnamnesisRequestStatus(
    String token, {
    required AnamnesisRequestStatus status,
    Map<String, dynamic>? responseData,
  }) async {
    final data = <String, dynamic>{'status': status.name};
    if (status == AnamnesisRequestStatus.opened) {
      data['openedAt'] = Timestamp.fromDate(DateTime.now());
    }
    if (status == AnamnesisRequestStatus.completed) {
      data['completedAt'] = Timestamp.fromDate(DateTime.now());
      if (responseData != null) data['responseData'] = responseData;
    }
    await _anamnesisRequests.doc(token).update(data);
  }

  // ── BrandingPreferences ───────────────────────────────────────────────────

  static Future<void> saveBranding(BrandingPreferences prefs) async {
    prefs.updatedAt = DateTime.now();
    await _branding.set(prefs.toMap(), SetOptions(merge: true));
  }

  static Future<BrandingPreferences?> getBranding() async {
    final doc = await _branding.get();
    if (!doc.exists || doc.data() == null) return null;
    return BrandingPreferences.fromMap(doc.data()!);
  }

  // ── FollowUp ───────────────────────────────────────────────────────────────

  static Future<FollowUp> createFollowUp(FollowUp followUp) async {
    final ref = _followUps.doc();
    followUp.id = ref.id;
    followUp.createdAt = DateTime.now();
    await ref.set(followUp.toMap());
    return followUp;
  }

  static Future<void> updateFollowUp(FollowUp followUp) async {
    await _followUps.doc(followUp.id).update(followUp.toMap());
  }

  /// Returns pending follow-ups that are due (scheduledAt <= now),
  /// including snoozed ones whose snooze has expired.
  static Future<List<FollowUp>> getPendingFollowUps() async {
    final now = DateTime.now();
    final snap = await _followUps
        .where('status', isEqualTo: FollowUpStatus.pending.name)
        .get();
    final list = snap.docs
        .map((d) => FollowUp.fromMap(d.id, d.data()))
        .where((f) {
      if (f.snoozedUntil != null && f.snoozedUntil!.isAfter(now)) {
        return false;
      }
      return !f.scheduledAt.isAfter(now);
    }).toList();
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  /// Check if a follow-up already exists for a given appointment.
  static Future<bool> followUpExistsForAppointment(
      String appointmentId) async {
    final snap = await _followUps
        .where('appointmentId', isEqualTo: appointmentId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── Inactivity queries ─────────────────────────────────────────────────────

  /// Returns active patients whose most recent completed appointment
  /// is older than [daysThreshold] days and who haven't been contacted
  /// within [cooldownDays].
  static Future<List<InactivePatient>> getInactivePatients({
    required int daysThreshold,
    int cooldownDays = 30,
  }) async {
    final patients = await getAllPatients();
    final appointments = await getAllAppointments();
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: daysThreshold));
    final cooldownCutoff = now.subtract(Duration(days: cooldownDays));

    // Build map: patientId -> most recent completed appointment date
    final lastSession = <String, DateTime>{};
    for (final a in appointments) {
      if (a.status != AppointmentStatus.completed) continue;
      final existing = lastSession[a.patientId];
      if (existing == null || a.scheduledDate.isAfter(existing)) {
        lastSession[a.patientId] = a.scheduledDate;
      }
    }

    final result = <InactivePatient>[];
    for (final p in patients) {
      if (p.status != PatientStatus.active) continue;
      final last = lastSession[p.id];
      if (last == null) continue; // never had a session
      if (last.isAfter(cutoff)) continue; // still active

      // Skip if contacted recently
      if (p.lastContactedAt != null &&
          p.lastContactedAt!.isAfter(cooldownCutoff)) {
        continue;
      }

      result.add(InactivePatient(
        patient: p,
        lastSessionDate: last,
        daysSinceLastSession: now.difference(last).inDays,
      ));
    }

    result.sort((a, b) =>
        a.lastSessionDate.compareTo(b.lastSessionDate));
    return result;
  }

  /// Update only the lastContactedAt field on a patient.
  static Future<void> markPatientContacted(String patientId) async {
    await _patients.doc(patientId).update({
      'lastContactedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}

class InactivePatient {
  final Patient patient;
  final DateTime lastSessionDate;
  final int daysSinceLastSession;

  const InactivePatient({
    required this.patient,
    required this.lastSessionDate,
    required this.daysSinceLastSession,
  });
}
