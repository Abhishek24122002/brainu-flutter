import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../aws/FileUploader.dart';
import '../firebase/firebase_services.dart';

import 'package:flutter_sound/flutter_sound.dart';
import '../components/StartRecordingButton.dart';
import '../components/PlayAudioButton.dart';
import '../components/ConfirmButton.dart';
import '../generated/l10n.dart';
import '../firebase/firebase_save_answer.dart';

class Ph_deletion_final extends StatefulWidget {
  @override
  _Ph_deletion_finalState createState() => _Ph_deletion_finalState();
}

class _Ph_deletion_finalState extends State<Ph_deletion_final> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final FirebaseSave _firebaseSave = FirebaseSave();
  final FileUploader _fileUploader = FileUploader();
  String _userLanguage = "english"; // Default language
  String word1 = '';
  String word2 = '';
  List<String> options = [];
  String? selectedOption;
  bool isSubmitEnabled = false;
  AudioPlayer audioPlayer = AudioPlayer();
  int questionCounter = 0;
  int iterationCounter = 0;
  int trophyCount = 0; // Track total trophies
  Map<String, int> clickCountMap = {};
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _recordingAvailable = false;
  String? _recordingPath;
  bool _showGameElements = false; // Initially hide the game elements

  Map<String, List<List<String>>> wordPairsByLanguage = {
    "english": [
      ['bank', 'bank_k'],
      ['bart', 'bart_t'],
      ['boom', 'boom_m'],
      ['brown', 'brown_n'],
      ['chilly', 'chilly_y'],
      ['down', 'down_n'],
      ['fort', 'fort_t'],
      ['ink', 'ink_k'],
      ['kino', 'kino_o'],
      ['news', 'news_s'],
      ['party', 'party_y'],
      ['peak', 'peak_k'],
      ['pink', 'pink_k'],
      ['seat', 'seat_t'],
      ['seed', 'seed_d'],
      ['sing', 'sing_g'],
      ['tact', 'tact_t'],
      ['teach', 'teach_ch'],
      ['tips', 'tips_s'],
      ['took', 'took_k'],
      ['want', 'want_t'],
      ['waster', 'waster_r'],
      ['weepy', 'weepy_y'],
      ['wind', 'wind_d'],
      ['woven', 'woven_n']
    ],
    "hindi": [
      ['aadmi', 'aadmi_mi'],
      ['bajar', 'bajar_ra'],
      ['bakri', 'bakri_ri'],
      ['dharti', 'dharti_ti'],
      ['jankari', 'jankari_ri']
    ]
  };

  List<List<String>> usedWordPairs = [];

  @override
  void initState() {
    super.initState();
    _loadTrophyCount();
    _fetchUserLanguage(); // Load the trophy count when the level is loaded
    _initializeRecorder();
    _player.openPlayer();
  }

  Future<void> _fetchUserLanguage() async {
    String language = await _firebaseServices.getUserLanguage();
    setState(() {
      _userLanguage = language;
      generateWords(); // Call generateWords() after setting language
    });
  }

  Future<void> _initializeRecorder() async {
    var micStatus = await Permission.microphone.request();
    if (micStatus.isGranted) {
      await _recorder.openRecorder();
    } else {
      print("Microphone permission denied");
    }
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final phonemeDir = Directory('${directory.path}/Phoneme_deletion_final');

    if (!phonemeDir.existsSync()) {
      phonemeDir.createSync(recursive: true);
    }

    // Ensure word2 is available before naming the file
    if (word2.isEmpty) {
      throw Exception("word2 is empty, cannot generate file name.");
    }

    return '${phonemeDir.path}/${word2}_rec.aac';
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    _recordingPath = await _getFilePath();
    await _recorder.startRecorder(toFile: _recordingPath);

    setState(() {
      _isRecording = true;
      _recordingAvailable =
          false; // Ensure recording isn't considered available until finished
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();

    // Ensure the file path is updated before checking if it exists
    String filePath = await _getFilePath();

    setState(() {
      _isRecording = false;
      _recordingPath = filePath;
      _recordingAvailable = File(filePath).existsSync(); // Check if file exists
      isSubmitEnabled =
          _recordingAvailable; // Enable confirm button if recording is available
    });

    print("Recording stopped. File exists: $_recordingAvailable");
  }

  Future<void> _playRecording() async {
    if (_recordingPath != null && File(_recordingPath!).existsSync()) {
      await _player.startPlayer(
        fromURI: _recordingPath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );
      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future<void> _loadTrophyCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      trophyCount = prefs.getInt('trophyCount') ??
          0; // Default to 0 if no trophy count is stored
    });
  }

  Future<void> _saveTrophyCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trophyCount', trophyCount); // Save the trophy count
  }

  void generateWords() {
    List<List<String>> availableWords =
        wordPairsByLanguage[_userLanguage] ?? [];

    if (availableWords.isEmpty) {
      setState(() {
        selectedOption = null;
        isSubmitEnabled = false;
        clickCountMap.clear();
      });
      showAllWordsDoneDialog();
      return;
    }

    Random random = Random();
    int index = random.nextInt(availableWords.length);
    List<String> selectedPair = availableWords.removeAt(index);
    usedWordPairs.add(selectedPair);

    word1 = selectedPair[0];
    word2 = selectedPair[1];

    setState(() {
      selectedOption = null;
      isSubmitEnabled = false;
      clickCountMap = {for (var option in options) option: 0};
    });
  }

  Future<void> playAudio(String option) async {
    try {
      String audioPath =
          'audio/$_userLanguage/phoneme_deletion/final/${option.toLowerCase()}.wav';
      print('Playing audio: $audioPath');
      await audioPlayer.play(AssetSource(audioPath));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> handleSubmit() async {
  if (_recordingPath != null && File(_recordingPath!).existsSync()) {
    File file = File(_recordingPath!);
    String? uploadedUrl = await _fileUploader.uploadFile(file);

    if (uploadedUrl != null) {
      print("File uploaded successfully: $uploadedUrl");

      // Call the function to save the uploaded URL
      await _firebaseSave.saveAnswer_Ph_deletion_final(uploadedUrl, _userLanguage, word2);

      setState(() {
        questionCounter++;
        _showGameElements = false;
        _recordingAvailable = false;
        isSubmitEnabled = false; // Disable confirm button until a new recording is made
      });

      if (questionCounter == 5) {
        iterationCounter++;
        trophyCount++;
        _saveTrophyCount();
        questionCounter = 0;
        showIterationCompleteDialog();
      }

      if (wordPairsByLanguage[_userLanguage]!.isNotEmpty) {
        generateWords();
      } else {
        showAllWordsDoneDialog();
      }
    } else {
      print("File upload failed.");
    }
  } else {
    print("No recording available for upload.");
  }
}


// Check if a new recording file exists
  Future<bool> _checkForNewRecording() async {
    if (_recordingPath == null) return false;
    return File(_recordingPath!).existsSync();
  }

  void resetLevel() {
    setState(() {
      wordPairsByLanguage[_userLanguage]!.addAll(usedWordPairs);
      usedWordPairs.clear();
      questionCounter = 0;
      iterationCounter = 0;
    });
    generateWords();
  }

  void showIterationCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You Won!!!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 69, 20, 153),
                ),
              ),
              SizedBox(height: 20),
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 80,
              ),
              SizedBox(height: 20),
              Text(
                '$trophyCount', // Display the number of trophies
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                generateWords();
              },
              child: Text(
                'Continue',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        );
      },
    );
  }

  void showAllWordsDoneDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('All Words Done!'),
          content: Text(
              'You have completed all words in this level. Reset to play again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetLevel();
              },
              child: Text('Reset Level'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
        title: Text(
          S.of(context).game_word_game1,
          style: TextStyle(color: Colors.white),
        ),
       backgroundColor: Theme.of(context).primaryColorDark,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Column(children: [
          // Question Container with shadow
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              S.of(context).phoneme_deletion_question,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          if (!_showGameElements)
            Container(
              margin: EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showGameElements = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColorDark,
                  padding: EdgeInsets.symmetric(vertical: 20), // Button height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity, // Full width button
                  child: Center(
                    child: Text(
                      S.of(context).click_here_to_start,
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),

          // These elements are only shown after clicking the start button
          if (_showGameElements) ...[
            // Main game content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Display dynamic text with clickable buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          children: _userLanguage == "hindi"
                              ? [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () => playAudio(
                                          word1), // Swap order for Hindi
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.orangeAccent,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10)),
                                        ),
                                        child: Text(
                                          S.of(context).Word,
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextSpan(text: "  "),
                                  TextSpan(text: S.of(context).from_the),
                                  TextSpan(text: "  "),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () => playAudio(
                                          word2), // Swap order for Hindi
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.lightBlueAccent,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10)),
                                        ),
                                        child: Text(
                                          S.of(context).sound,
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextSpan(text: "  "),
                                  TextSpan(text: S.of(context).Remove),
                                ]
                              : [
                                  TextSpan(text: S.of(context).Remove),
                                  TextSpan(text: "  "),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () => playAudio(word2),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.lightBlueAccent,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10)),
                                        ),
                                        child: Text(
                                          S.of(context).sound,
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextSpan(text: "  "),
                                  TextSpan(text: S.of(context).from_the),
                                  TextSpan(text: "  "),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () => playAudio(word1),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.orangeAccent,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10)),
                                        ),
                                        child: Text(
                                          S.of(context).Word,
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                        ),
                      ),
                    ),

                    SizedBox(height: 40),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          children: [
                            StartRecordingButton(
                              onPressed: _toggleRecording,
                              isRecording: _isRecording,
                            ),
                            SizedBox(height: 15),
                            PlayAudioButton(
                              isEnabled: _recordingAvailable,
                              onPressed: _isPlaying ? null : _playRecording,
                              isPlaying: _isPlaying,
                            ),
                            SizedBox(height: 15),
                            ConfirmButton(
                              isEnabled:
                                  _recordingAvailable, // Only enable when a new recording exists
                              onPressed:
                                  _recordingAvailable ? handleSubmit : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
