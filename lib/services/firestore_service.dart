import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment.dart';
import '../models/branding_preferences.dart';
import '../models/financial_record.dart';
import '../models/patient.dart';
import '../models/session_record.dart';

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

  static DocumentReference<Map<String, dynamic>> get _branding =>
      _db.doc('clinics/$_clinicId/settings/branding');

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
        .orderBy('scheduledDate', descending: true)
        .get();
    return snap.docs
        .map((d) => Appointment.fromMap(d.id, d.data()))
        .toList();
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
}
