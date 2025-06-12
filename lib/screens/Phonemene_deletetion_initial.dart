import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sound/flutter_sound.dart';
import '../aws/FileUploader.dart';
import '../components/WoodenButton.dart';
import '../components/audio_buttons.dart';
import '../firebase/firebase_services.dart';
import '../generated/l10n.dart';
import '../firebase/firebase_save_answer.dart';

import '../components/question_container.dart';
import '../components/start_button.dart';
import '../components/appbar.dart';

class Ph_deletion_initial extends StatefulWidget {
  @override
  _Ph_deletion_initialState createState() => _Ph_deletion_initialState();
}

class _Ph_deletion_initialState extends State<Ph_deletion_initial> {
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
  bool _showGameElements = false;

  Map<String, List<List<String>>> wordPairsByLanguage = {
    "english": [
      ['across', 'across_a'],
      ['aware', 'aware_a'],
      ['bland', 'bland_b'],
      ['bridge', 'bridge_b'],
      ['bring', 'bring_b'],
      ['chair', 'chair_ch'],
      ['cloud', 'cloud_c'],
      ['cold', 'cold_c'],
      ['factual', 'factual_f'],
      ['fall', 'fall_f'],
      ['land', 'land_l'],
      ['learn', 'learn_l'],
      ['learning', 'learning_l'],
      ['part', 'part_p'],
      ['place', 'place_p'],
      ['plate', 'plate_p'],
      ['prime', 'prime_p'],
      ['proof', 'proof_p'],
      ['select', 'select_s'],
      ['space', 'space_s'],
      ['spoke', 'spoke_s'],
      ['start', 'start_s'],
      ['table', 'table_t'],
      ['tact', 'tact_t'],
      ['teach', 'teach_t']
    ],
    "hindi": [
      ['sapna', 'sapna_sa'],
      ['magar', 'magar_ma'],
      ['kidhar', 'kidhar_ki'],
      ['achal', 'achal_a'],
      ['bahar', 'bahar_b']
    ]
  };

  List<List<String>> usedWordPairs = [];

  @override
  void initState() {
    super.initState();
    _loadTrophyCount();
    _fetchUserLanguage(); // Load the trophy count when the level is loaded
    generateWords();
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
    final phonemeDir = Directory('${directory.path}/Phoneme_deletion_initial');

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
      // All words used; show level completed
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
      String audioPath;
      audioPath =
          'audio/$_userLanguage/phoneme_deletion/initial/${option.toLowerCase()}.wav';

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
        await _firebaseSave.saveAnswer_Ph_deletion_initial(
            uploadedUrl, _userLanguage, word1,word2);

        setState(() {
          questionCounter++;
          _showGameElements = false;
          _recordingAvailable = false;
          isSubmitEnabled =
              false; // Disable confirm button until a new recording is made
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
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/img/Deletion_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(titleKey: 'wordgame2'),
          body: Container(
            // color: Colors.white,
            child: Column(children: [
              CustomContainer(
                text: S.of(context).phoneme_deletion_question,
              ),
              if (!_showGameElements)
                StartButton(
                  onPressed: () {
                    setState(() {
                      _showGameElements = true;
                    });
                  },
                ),
              // Main game content
              if (_showGameElements) ...[
                // Main game content
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: _userLanguage == "hindi"
                                ? [
                                    // Hindi order: Word → From → Sound → Remove
                                    AnimatedWoodenButton(
                                      label: S.of(context).Word,
                                      onPressed: () => playAudio(word1),
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        S.of(context).from_the,
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    AnimatedWoodenButton(
                                      label: S.of(context).sound,
                                      onPressed: () => playAudio(word2),
                                    ),
                                    SizedBox(height: 10),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        S.of(context).Remove,
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.white),
                                      ),
                                    ),
                                  ]
                                : [
                                    // Default order: Remove → Sound → From → Word
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        S.of(context).Remove,
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    AnimatedWoodenButton(
                                      label: S.of(context).sound,
                                      onPressed: () => playAudio(word2),
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        S.of(context).from_the,
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    AnimatedWoodenButton(
                                      label: S.of(context).Word,
                                      onPressed: () => playAudio(word1),
                                    ),
                                  ],
                          ),
                        ),
                       
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25.0, vertical: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                StartRecordingButton(
                                  onPressed: _toggleRecording,
                                  isRecording: _isRecording,
                                ),
                               
                                PlayAudioButton(
                                  isEnabled: _recordingAvailable,
                                  onPressed: _isPlaying ? null : _playRecording,
                                  isPlaying: _isPlaying,
                                ),
                                
                                ConfirmButton(
                                  isEnabled:
                                      _recordingAvailable, // Only enable when a new recording exists
                                  onPressed:
                                      _recordingAvailable ? handleSubmit : null,
                                ),
                              ],
                            ))
                      ],
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}
