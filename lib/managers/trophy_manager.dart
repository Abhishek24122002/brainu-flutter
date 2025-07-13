import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrophyManager with ChangeNotifier {
  int _trophyCount = 0;
  final String userId;

  TrophyManager({required this.userId});

  int get trophyCount => _trophyCount;

  void increase() {
    _trophyCount++;
    saveToPrefs();
    notifyListeners();
  }

  void reset() {
    _trophyCount = 0;
    saveToPrefs();
    notifyListeners();
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _trophyCount = prefs.getInt('trophyCount') ?? 0;
    notifyListeners();
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trophyCount', _trophyCount);
  }

  Future<void> loadFromFirebase() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data()?['trophy_count'] != null) {
        _trophyCount = doc.data()!['trophy_count'];
        await saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      print("Error loading trophy count from Firebase: $e");
    }
  }

  Future<void> saveToFirebase() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({'trophy_count': _trophyCount}, SetOptions(merge: true));
    } catch (e) {
      print("Error saving trophy count to Firebase: $e");
    }
  }
}
