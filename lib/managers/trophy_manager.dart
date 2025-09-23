import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class TrophyManager with ChangeNotifier {
  int _trophyCount = 0;
  final String userId;

  TrophyManager({required this.userId});

  int get trophyCount => _trophyCount;

  void increase() {
    _trophyCount++;
    saveToHive();
    notifyListeners();
  }

  void reset() {
    _trophyCount = 0;
    saveToHive();
    notifyListeners();
  }

  Future<void> loadFromHive() async {
    final box = await Hive.openBox('trophies');
    _trophyCount = box.get('${userId}_trophyCount', defaultValue: 0);
    notifyListeners();
  }

  Future<void> saveToHive() async {
    final box = await Hive.openBox('trophies');
    await box.put('${userId}_trophyCount', _trophyCount);
  }

  Future<void> loadFromFirebase() async {
    if (userId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data()?['trophy_count'] != null) {
        _trophyCount = doc.data()!['trophy_count'];
        await saveToHive();
        notifyListeners();
      }
    } catch (e) {
      print("Error loading trophy count from Firebase: $e");
    }
  }

  Future<void> saveToFirebase() async {
    if (userId.isEmpty) return;
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
