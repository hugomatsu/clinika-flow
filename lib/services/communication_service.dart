import 'package:url_launcher/url_launcher.dart';

import '../models/patient.dart';

/// Handles WhatsApp deep-linking and message template interpolation.
class CommunicationService {
  /// Opens WhatsApp with a pre-filled message for the given patient.
  /// Returns true if launched successfully.
  static Future<bool> openWhatsApp({
    required Patient patient,
    required String message,
  }) async {
    final phone = patient.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) return false;

    final fullPhone = phone.startsWith('55') ? phone : '55$phone';
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$fullPhone?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Interpolates variables in a message template.
  static String compileTemplate(
    String template, {
    required String patientFirstName,
    required String clinicName,
    String lastSessionDate = '',
    String daysSinceLastSession = '',
    String discountOffer = '',
  }) {
    return template
        .replaceAll('{patientFirstName}', patientFirstName)
        .replaceAll('{clinicName}', clinicName)
        .replaceAll('{lastSessionDate}', lastSessionDate)
        .replaceAll('{daysSinceLastSession}', daysSinceLastSession)
        .replaceAll('{discountOffer}', discountOffer)
        .trim();
  }

  /// Returns the patient's first name from their full name.
  static String firstName(Patient patient) {
    final parts = patient.fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }
}
