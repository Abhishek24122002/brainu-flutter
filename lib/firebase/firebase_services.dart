import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch User Language
  Future<String> getUserLanguage() async {
    final user = _auth.currentUser;
    if (user == null) return "english"; // Default to English if user not found

    String userId = user.uid;
    try {
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(userId).get();
      if (userDoc.exists) {
        return userDoc.get("language")?.toLowerCase() ?? "english";
      }
    } catch (e) {
      print("Error fetching user language: $e");
    }
    return "english"; // Default to English in case of an error
  }

  
}
