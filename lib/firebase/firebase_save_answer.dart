import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseSave {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save User Answer for Letter
  Future<void> saveAnswer_Letter(String letter, bool isCorrect, String userLanguage) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String userId = user.uid;
    String result = isCorrect ? "Correct" : "Wrong";

    await _firestore
        .collection("users")
        .doc(userId)
        .collection("Letter")
        .doc(userLanguage) // Use the stored language
        .set({letter: result}, SetOptions(merge: true));
  }
}
