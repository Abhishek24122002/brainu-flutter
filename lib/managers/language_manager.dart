import 'package:brainu/firebase/firebase_services.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
// import FirebaseServices

class LanguageManager extends ChangeNotifier {
  Locale _currentLocale = Locale('en');
  final String userId;

  LanguageManager({required this.userId});

  Locale get currentLocale => _currentLocale;

  /// Initialize LanguageManager: load from Hive/Firestore
  Future<void> init() async {
    // Open Hive
    try {
      final box = await Hive.openBox('settings');
      String? code = box.get('languageCode');
      _currentLocale = Locale(code ?? 'en');
    } catch (e) {
      print("Hive init error: $e");
      _currentLocale = Locale('en');
    }

    // Sync with Firestore
    try {
      final services = FirebaseServices(userId: userId);
      String userLang = await services.getUserLanguage();
      _currentLocale = Locale(userLang);
    } catch (e) {
      print("Firestore sync error: $e");
    }

    notifyListeners();
  }

  /// Change language and save to Hive + Firestore
  Future<void> setLanguage(String langName) async {
    Map<String, String> languageMap = {
      "English": "en",
      "Hindi": "hi",
      "Urdu": "ur",
      "Persian": "fa",
      "Marathi": "mr",
    };

    String code = languageMap[langName] ?? 'en';
    _currentLocale = Locale(code);

    // Save to Hive + Firestore
    try {
      final services = FirebaseServices(userId: userId);
      await services.saveUserLanguage(code);
    } catch (e) {
      print("Error saving language: $e");
    }

    notifyListeners();
  }
}
