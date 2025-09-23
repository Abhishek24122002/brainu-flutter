import 'package:brainu/managers/language_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class FirebaseSave {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseSave({required this.userId});

  /// Save User Answer for Letter
  Future<void> saveAnswer_Letter({
    required String letter,
    required bool isCorrect,
    required String selectedOption,
    required String userLanguage, // pass from LanguageManager
  }) async {
    if (userId.isEmpty) return;

    String result = isCorrect ? "Correct" : "Wrong";
    String letter_option = "${letter}_selected_option";

    // Save locally in Hive
    final box = await Hive.openBox('answers');
    await box.put('${userId}_letter_$letter',
        {'result': result, 'option': selectedOption});

    // Save to Firestore
    await _firestore
        .collection("users")
        .doc(userId)
        .collection("1 Letter")
        .doc(userLanguage)
        .set({letter: result, letter_option: selectedOption},
            SetOptions(merge: true));
  }

  Future<void> saveAnswer_Identify({
    required String iterationKey,
    required List<String> items,
    required String audioUrl,
    required String userLanguage,
  }) async {
    if (userId.isEmpty) return;

    // Optional: Hive caching
    final box = await Hive.openBox('answers');
    await box.put('${userId}_identify_$iterationKey',
        {'items': items, 'audioUrl': audioUrl});

    final docRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("2 Identify")
        .doc(userLanguage);

    await docRef.set({
      iterationKey: {'items': items, 'audioUrl': audioUrl}
    }, SetOptions(merge: true));
  }

  Future<void> saveAnswer_Word({
    required String uploadedUrl,
    required String currentWord,
    required String userLanguage,
  }) async {
    if (userId.isEmpty) return;

    final box = await Hive.openBox('answers');
    await box.put('${userId}_word_$currentWord', {'audioUrl': uploadedUrl});

    final docRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("3 Word")
        .doc(userLanguage);

    await docRef.set({
      currentWord: {'audioUrl': uploadedUrl}
    }, SetOptions(merge: true));
  }

  Future<void> saveAnswer_Listen({
    required String uploadedUrl,
    required String currentWord,
    required String userLanguage,
  }) async {
    if (userId.isEmpty) return;

    final box = await Hive.openBox('answers');
    await box.put('${userId}_listen_$currentWord', {'imageUrl': uploadedUrl});

    final docRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("4 Listen")
        .doc(userLanguage);

    await docRef.set({
      currentWord: {'imageUrl': uploadedUrl}
    }, SetOptions(merge: true));
  }

  Future<void> saveAnswer_Story({
    required String iterationKey,
    required String storyText,
    required String audioUrl,
    required String userLanguage,
  }) async {
    if (userId.isEmpty) return;

    final box = await Hive.openBox('answers');
    await box.put('${userId}_story_$iterationKey',
        {'story': storyText, 'audioUrl': audioUrl});

    final docRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("5 Story")
        .doc(userLanguage);

    await docRef.set({
      iterationKey: {'story': storyText, 'audiourl': audioUrl}
    }, SetOptions(merge: true));
  }

  // Ph Deletion Final
  Future<void> saveAnswer_PhDeletionFinal({
    required String uploadedUrl,
    required String currentWord,
    required String sound,
    required String userLanguage,
  }) async {
    if (userId.isEmpty) return;

    final box = await Hive.openBox('answers');
    await box.put('${userId}_phDelFinal_$currentWord',
        {'audioUrl': uploadedUrl, 'sound': sound});

    final docRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("7 Word Game 1")
        .doc(userLanguage);

    await docRef.set({
      currentWord: {'audioUrl': uploadedUrl, 'sound': sound}
    }, SetOptions(merge: true));
  }

  // Ph Deletion Initial
  Future<void> saveAnswer_PhDeletionInitial({
    required String uploadedUrl,
    required String currentWord,
    required String sound,
    required String userLanguage,
  }) async {
    if (userId.isEmpty) return;

    final box = await Hive.openBox('answers');
    await box.put('${userId}_phDelInit_$currentWord',
        {'audioUrl': uploadedUrl, 'sound': sound});

    final docRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("8 Word Game 2")
        .doc(userLanguage);

    await docRef.set({
      currentWord: {'audioUrl': uploadedUrl, 'sound': sound}
    }, SetOptions(merge: true));
  }

  // Ph Substitution Final
  Future<void> saveAnswer_PhSubstitutionFinal({
    required String uploadedUrl,
    required String currentWord,
    required String sound1,
    required String sound2,
    required String userLanguage,
  }) async {
    if (userId.isEmpty) return;

    final box = await Hive.openBox('answers');
    await box.put('${userId}_phSubFinal_$currentWord',
        {'audioUrl': uploadedUrl, 'sound1': sound1, 'sound2': sound2});

    final docRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("9 Word Game 3")
        .doc(userLanguage);

    await docRef.set({
      currentWord: {'audioUrl': uploadedUrl, 'sound1': sound1, 'sound2': sound2}
    }, SetOptions(merge: true));
  }

  // Ph Substitution Initial
  Future<void> saveAnswer_PhSubstitutionInitial({
    required String uploadedUrl,
    required String currentWord,
    required String sound1,
    required String sound2,
    required String userLanguage,
  }) async {
    if (userId.isEmpty) return;

    final box = await Hive.openBox('answers');
    await box.put('${userId}_phSubInit_$currentWord',
        {'audioUrl': uploadedUrl, 'sound1': sound1, 'sound2': sound2});

    final docRef = _firestore
        .collection("users")
        .doc(userId)
        .collection("10 Word Game 4")
        .doc(userLanguage);

    await docRef.set({
      currentWord: {'audioUrl': uploadedUrl, 'sound1': sound1, 'sound2': sound2}
    }, SetOptions(merge: true));
  }
}
