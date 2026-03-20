import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Enable offline persistence on all platforms.
    // On mobile this is on by default; on web it uses IndexedDB.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    // Firebase not configured yet — run flutterfire configure.
    debugPrint('Firebase init failed: $e');
  }

  runApp(const ClinikaApp());

  // Load theme after app is visible — ValueNotifier updates UI when ready.
  ThemeService.loadFromStorage();
}
