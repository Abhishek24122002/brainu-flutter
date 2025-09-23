import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class FirebaseServices {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseServices({required this.userId});

  /// Fetch User Language from Hive first, then Firestore
  /// Fallback to default "en"
  Future<String> getUserLanguage() async {
    String languageCode = "en"; // default

    // Open Hive once
    late Box box;
    try {
      box = await Hive.openBox('settings');
      final cachedLang = box.get('languageCode');
      if (cachedLang != null && cachedLang is String) {
        languageCode = cachedLang;
      }
    } catch (e) {
      print("Hive read error: $e");
    }

    // Fetch from Firestore and update Hive if different
    try {
      final doc = await _firestore.collection("users").doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final firestoreLang = doc.get("language")?.toString().toLowerCase();
        if (firestoreLang != null && firestoreLang.isNotEmpty) {
          languageCode = firestoreLang;

          // Update Hive
          try {
            await box.put('languageCode', languageCode);
          } catch (e) {
            print("Hive write error: $e");
          }
        }
      }
    } catch (e) {
      print("Firestore fetch error: $e");
    }

    return languageCode;
  }

  /// Save language to Firestore + Hive
  Future<void> saveUserLanguage(String languageCode) async {
    // Update Hive
    try {
      final box = await Hive.openBox('settings');
      await box.put('languageCode', languageCode);
    } catch (e) {
      print("Hive save error: $e");
    }

    // Update Firestore
    try {
      await _firestore.collection("users").doc(userId).set({
        "language": languageCode,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Firestore save error: $e");
    }
  }
}
