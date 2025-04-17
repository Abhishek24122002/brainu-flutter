import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sound/flutter_sound.dart';
import '../components/audio_buttons.dart';
import '../firebase/firebase_services.dart';
import '../generated/l10n.dart';
import '../firebase/firebase_save_answer.dart';
import '../aws/FileUploader.dart';

import '../components/appbar.dart';
import '../components/question_container.dart';
import '../components/start_button.dart';

class Ph_substitution_final extends StatefulWidget {
  @override
  _Ph_substitution_finalState createState() => _Ph_substitution_finalState();
}

class _Ph_substitution_finalState extends State<Ph_substitution_final> {
  String sound1 = '';
  String sound2 = '';
  String word = '';
  final FirebaseServices _firebaseServices = FirebaseServices();
  final FirebaseSave _firebaseSave = FirebaseSave();
  final FileUploader _fileUploader = FileUploader();
  String _userLanguage = "english"; // Default language
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
      ["t", "x", "box"],
      ["t", "r", "car"],
      ["n", "r", "chair"],
      ["p", "t", "cheat"],
      ["t", "l", "coal"],
      ["g", "m", "drum"],
      ["t", "g", "flag"],
      ["l", "d", "food"],
      ["g", "m", "from"],
      ["d", "n", "main"],
      ["d", "p", "map"],
      ["l", "n", "mean"],
      ["s", "t", "mist"],
      ["n", "d", "mood"],
      ["d", "g", "mug"],
      ["r", "l", "peel"],
      ["t", "n", "plan"],
      ["m", "s", "plus"],
      ["r", "l", "pool"],
      ["l", "n", "rain"],
      ["t", "d", "red"],
      ["t", "m", "room"],
      ["p", "t", "shot"],
      ["t", "m", "slim"],
      ["r", "l", "towel"]
    ],
    "hindi": [
      ["kaam_dha", "kaam_k", "kaam"],
      ["naal_da", "naal_n", "naal"],
      ["naam_k", "naam_n", "naam"],
      ["raja_a", "raja_r", "raja"],
      ["shaam_k", "shaam_sha", "shaam"],
    ]
  };

  List<List<String>> usedWordPairs = [];

  @override
  void initState() {
    super.initState();
    _loadTrophyCount(); // Load the trophy count when the level is loaded
    _fetchUserLanguage();
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
    final phonemeDir =
        Directory('${directory.path}/Phoneme_substitution_final');

    if (!phonemeDir.existsSync()) {
      phonemeDir.createSync(recursive: true);
    }

    // Ensure word2 is available before naming the file
    if (word.isEmpty) {
      throw Exception("word is empty, cannot generate file name.");
    }

    return '${phonemeDir.path}/${word}_rec.aac';
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
      trophyCount = prefs.getInt('ph_subs_fin_trophyCount') ??
          0; // Default to 0 if no trophy count is stored
    });
  }

  Future<void> _saveTrophyCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'ph_subs_fin_trophyCount', trophyCount); // Save the trophy count
  }

  // void generateWords() {
  //   if (wordPairs.isEmpty) {
  //     // All words used; show level completed
  //     setState(() {
  //       selectedOption = null;
  //       isSubmitEnabled = false;
  //       clickCountMap.clear();
  //     });
  //     showAllWordsDoneDialog();
  //     return;
  //   }

  //   Random random = Random();
  //   int index = random.nextInt(wordPairs.length);
  //   List<String> selectedPair = wordPairs.removeAt(index);
  //   usedWordPairs.add(selectedPair);

  //   sound1 = selectedPair[0];
  //   sound2 = selectedPair[1];
  //   word = selectedPair[2];

  //   setState(() {
  //     selectedOption = null;
  //     isSubmitEnabled = false;
  //     clickCountMap = {for (var option in options) option: 0};
  //   });
  // }
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

    sound1 = selectedPair[0];
    sound2 = selectedPair[1];
    word = selectedPair[2];

    setState(() {
      selectedOption = null;
      isSubmitEnabled = false;
      clickCountMap = {for (var option in options) option: 0};
    });
  }

  // Future<void> playAudio(String option, [bool isOption = false]) async {
  //   try {
  //     String audioPath;

  //     if (option.length == 1) {
  //       // For single-character sounds
  //       audioPath = 'audio/english/v_and_c/${option.toLowerCase()}.wav';
  //     } else {
  //       // For words
  //       audioPath =
  //           'audio/english/phoneme_substitution/final/${option.toLowerCase()}.wav';
  //     }

  //     print('Playing audio: $audioPath');
  //     await audioPlayer.play(AssetSource(audioPath));
  //   } catch (e) {
  //     print('Error playing audio: $e');
  //   }
  // }
  Future<void> playAudio(String option) async {
    try {
      String audioPath =
          'audio/$_userLanguage/phoneme_substitution/final/${option.toLowerCase()}.wav';
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
        await _firebaseSave.saveAnswer_Ph_substitution_final(
            uploadedUrl, _userLanguage, sound1);

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
        Positioned(
          child: Image.asset(
            'assets/img/Deletion_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(titleKey: 'wordgame3'),
          body: Container(
            child: Column(children: [
              // Question Container with shadow
              CustomContainer(
                text: S.of(context).phoneme_substitution_question,
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
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            if (_userLanguage !=
                                "hindi") // Show "Substitute" at the top for English
                              Column(
                                children: [
                                  Text(
                                    S.of(context).substitute,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                ],
                              ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  children: _userLanguage == "hindi"
                                      ? [
                                          // Word Button (First in Hindi)
                                          WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.middle,
                                            child: GestureDetector(
                                              onTap: () => playAudio(word),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.orangeAccent,
                                                  borderRadius:
                                                      BorderRadius.all(
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
                                          TextSpan(text: S.of(context).In),
                                          TextSpan(text: "  "),
                                          // Sound1 Button
                                          WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.middle,
                                            child: GestureDetector(
                                              onTap: () => playAudio(sound2),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.lightBlueAccent,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(10)),
                                                ),
                                                child: Text(
                                                  S.of(context).sound2,
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                          TextSpan(text: "  "),
                                          TextSpan(text: S.of(context).With),
                                          TextSpan(text: "  "),
                                          // Sound2 Button
                                          WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.middle,
                                            child: GestureDetector(
                                              onTap: () => playAudio(sound1),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.lightBlueAccent,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(10)),
                                                ),
                                                child: Text(
                                                  S.of(context).sound1,
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                          TextSpan(text: "\n\n"),
                                          // "Substitute" at the bottom for Hindi
                                          WidgetSpan(
                                            child: Text(
                                              S.of(context).substitute,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ]
                                      : [
                                          // Sound1 Button (English order)
                                          WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.middle,
                                            child: GestureDetector(
                                              onTap: () => playAudio(sound1),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.lightBlueAccent,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(10)),
                                                ),
                                                child: Text(
                                                  S.of(context).sound1,
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                          TextSpan(text: "  "),
                                          TextSpan(text: S.of(context).With),
                                          TextSpan(text: "  "),
                                          // Sound2 Button
                                          WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.middle,
                                            child: GestureDetector(
                                              onTap: () => playAudio(sound2),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.lightBlueAccent,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(10)),
                                                ),
                                                child: Text(
                                                  S.of(context).sound2,
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                          TextSpan(text: "  "),
                                          TextSpan(text: S.of(context).In),
                                          TextSpan(text: "  "),
                                          // Word Button (Last in English)
                                          WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.middle,
                                            child: GestureDetector(
                                              onTap: () => playAudio(word),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.orangeAccent,
                                                  borderRadius:
                                                      BorderRadius.all(
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
                          ],
                        ),
                        SizedBox(height: 20),
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25.0, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
