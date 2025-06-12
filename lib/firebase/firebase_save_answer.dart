import 'package:brainu/screens/Letter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseSave {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save User Answer for Letter
  Future<void> saveAnswer_Letter(String letter, bool isCorrect,
      String selectedOption, String userLanguage) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String userId = user.uid;
    String result = isCorrect ? "Correct" : "Wrong";
    String letter_option = letter + "_selected_option";

    await _firestore
        .collection("users")
        .doc(userId)
        .collection("1 Letter")
        .doc(userLanguage) // Use the stored language
        .set({letter: result, letter_option: selectedOption},
            SetOptions(merge: true));
  }

  // Future<void> saveAnswer_Identify(
  //     String uploadedUrl, String userLanguage, String imageNamesKey) async {
  //   final user = _auth.currentUser;
  //   if (user == null) return;

  //   String userId = user.uid;

  //   await _firestore
  //       .collection("users")
  //       .doc(userId)
  //       .collection("2 Identify")
  //       .doc(userLanguage) // Grouped by user’s language
  //       .set({
  //     imageNamesKey: uploadedUrl, // 🔑 Key = 15 image names, 🔗 value = AWS URL
  //   }, SetOptions(merge: true)); // 🛡 Merge to avoid overwriting
  // }

  Future<void> saveAnswer_Identify(
    String language,
    String iterationKey,
    List<String> items,
    String audioUrl,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('2 Identify')
        .doc(language); // One doc per language

    await docRef.set({
      iterationKey: {
        'items': items,
        'audioUrl': audioUrl,
      }
    }, SetOptions(merge: true)); // Merge to keep other iterations
  }

  // Future<void> saveAnswer_word(
  //     String uploadedUrl, String userLanguage, String _currentWord) async {
  //   final user = _auth.currentUser;
  //   if (user == null) return;
  //   String userId = user.uid;

  //   await _firestore
  //       .collection("users")
  //       .doc(userId)
  //       .collection("3 Word")
  //       .doc(userLanguage) // Stores based on language
  //       .set({
  //     _currentWord: uploadedUrl, // ✅ Save URL under the word
  //   }, SetOptions(merge: true)); // ✅ Merge data instead of overwriting
  // }

  Future<void> saveAnswer_word(
      String uploadedUrl, String userLanguage, String currentWord) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String userId = user.uid;

    await _firestore
        .collection("users")
        .doc(userId)
        .collection("3 Word")
        .doc(userLanguage) // Grouped by language
        .set({
      currentWord: {
        'audioUrl': uploadedUrl,
      }
    }, SetOptions(merge: true)); // Merge to keep existing data
  }

  Future<void> saveAnswer_Listen(
      String uploadedUrl, String userLanguage, String _currentWord) async {
    final user = _auth.currentUser;
    if (user == null) return;
    String userId = user.uid;

    await _firestore
        .collection("users")
        .doc(userId)
        .collection("4 Listen")
        .doc(userLanguage) // Stores based on language
        .set({
      _currentWord: uploadedUrl, // ✅ Save URL under the word
    }, SetOptions(merge: true)); // ✅ Merge data instead of overwriting
  }

  Future<void> saveAnswer_Story(
    String language,
    String iterationKey,
    String storyText,
    String audioUrl,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;
    String userId = user.uid;

    final docRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("5 Story")
        .doc(language);

    await docRef.set({
      iterationKey: {
        'story': storyText,
        'audiourl': audioUrl,
      }
    }, SetOptions(merge: true));
  }

  Future<void> saveAnswer_Ph_deletion_final(
      String uploadedUrl, String userLanguage, String currentWord, String sound) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String userId = user.uid;

    await _firestore
        .collection("users")
        .doc(userId)
        .collection("7 Word Game 1")
        .doc(userLanguage) // Grouped by language
        .set({
      currentWord: {
        'audioUrl': uploadedUrl,
        'sound': sound,
      }
    }, SetOptions(merge: true)); // Merge to keep existing data
  }

  Future<void> saveAnswer_Ph_deletion_initial(
      String uploadedUrl, String userLanguage, String currentWord, String sound) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String userId = user.uid;

    await _firestore
        .collection("users")
        .doc(userId)
        .collection("8 Word Game 2")
        .doc(userLanguage) // Grouped by language
        .set({
      currentWord: {
        'audioUrl': uploadedUrl,
        'sound': sound,
      }
    }, SetOptions(merge: true)); // Merge to keep existing data
  }

  

  // Future<void> saveAnswer_Ph_deletion_initial(
  //     String uploadedUrl, String userLanguage, String _currentWord) async {
  //   final user = _auth.currentUser;
  //   if (user == null) return;
  //   String userId = user.uid;

  //   await _firestore
  //       .collection("users")
  //       .doc(userId)
  //       .collection("8 Word Game 2")
  //       .doc(userLanguage) // Stores based on language
  //       .set({
  //     _currentWord: uploadedUrl,
  //   }, SetOptions(merge: true)); // ✅ Merge data instead of overwriting
  // }

  Future<void> saveAnswer_Ph_substitution_final(
      String uploadedUrl, String userLanguage, String currentWord, String Sound1, String Sound2) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String userId = user.uid;

    await _firestore
        .collection("users")
        .doc(userId)
        .collection("9 Word Game 3")
        .doc(userLanguage) // Grouped by language
        .set({
      currentWord: {
        'audioUrl': uploadedUrl,
        'sound1': Sound1,
        'sound2': Sound2
      }
    }, SetOptions(merge: true)); // Merge to keep existing data
  }

  // Future<void> saveAnswer_Ph_substitution_final(
  //     String uploadedUrl, String userLanguage,String currentWord, String Sound1, String Sound2) async {
  //   final user = _auth.currentUser;
  //   if (user == null) return;
  //   String userId = user.uid;

  //   await _firestore
  //       .collection("users")
  //       .doc(userId)
  //       .collection("9 Word Game 3")
  //       .doc(userLanguage) // Stores based on language
  //       .set({
  //     Sound1: uploadedUrl,
  //   }, SetOptions(merge: true)); // ✅ Merge data instead of overwriting
  // }

  Future<void> saveAnswer_Ph_substitution_initial(
      String uploadedUrl, String userLanguage, String currentWord, String Sound1, String Sound2) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String userId = user.uid;

    await _firestore
        .collection("users")
        .doc(userId)
        .collection("10 Word Game 4")
        .doc(userLanguage) // Grouped by language
        .set({
      currentWord: {
        'audioUrl': uploadedUrl,
        'sound1': Sound1,
        'sound2': Sound2
      }
    }, SetOptions(merge: true)); // Merge to keep existing data
  }

//   Future<void> saveAnswer_Ph_substitution_initial(
//       String uploadedUrl, String userLanguage, String Sound2) async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//     String userId = user.uid;

//     await _firestore
//         .collection("users")
//         .doc(userId)
//         .collection("10 Word Game 4")
//         .doc(userLanguage) // Stores based on language
//         .set({
//       Sound2: uploadedUrl,
//     }, SetOptions(merge: true)); // ✅ Merge data instead of overwriting
//   }
}
