import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final _picker = ImagePicker();
  static FirebaseStorage get _storage => FirebaseStorage.instance;

  static String get _clinicId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'default';

  /// Pick image from gallery or camera, compress, and upload to Firebase Storage.
  /// Returns the download URL or null if cancelled.
  static Future<String?> pickAndUpload({
    required ImageSource source,
    int maxDimension = 2048,
    int quality = 85,
  }) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final compressed = await _compressImage(bytes, maxDimension, quality);

    final filename =
        '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
    final ref = _storage.ref('clinics/$_clinicId/images/$filename');

    await ref.putData(compressed, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Pick, compress, and upload clinic logo. Returns download URL or null.
  static Future<String?> pickAndUploadLogo({
    required ImageSource source,
  }) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final compressed = await _compressImage(bytes, 512, 80);

    final ref = _storage.ref('clinics/$_clinicId/logo.jpg');
    await ref.putData(compressed, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Decode, resize (if needed), and re-encode as JPEG.
  static Future<Uint8List> _compressImage(
      Uint8List bytes, int maxDimension, int quality) async {
    var decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    // Resize proportionally if either dimension exceeds maxDimension
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      if (decoded.width >= decoded.height) {
        decoded = img.copyResize(decoded, width: maxDimension);
      } else {
        decoded = img.copyResize(decoded, height: maxDimension);
      }
    }

    return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
  }
}
