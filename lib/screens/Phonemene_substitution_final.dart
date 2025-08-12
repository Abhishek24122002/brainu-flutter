import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:showcaseview/showcaseview.dart';
import '../components/WoodenButton.dart';
import '../components/audio_buttons.dart';
import '../components/showcase/AudioShowcaseButtons.dart';
import '../firebase/firebase_services.dart';
import '../generated/l10n.dart';
import '../firebase/firebase_save_answer.dart';
import '../aws/FileUploader.dart';

import '../components/appbar.dart';
import '../components/question_container.dart';
import '../components/start_button.dart';

import 'package:brainu/managers/trophy_manager.dart';
import 'package:provider/provider.dart';

import '../components/popups/trophy.dart';
import '../components/popups/completion.dart';

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
  bool showShowcase = false;
  int currentIndex = 0;

  final GlobalKey _recordButtonKey = GlobalKey();
  final GlobalKey _playButtonKey = GlobalKey();
  final GlobalKey _confirmButtonKey = GlobalKey();

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
    loadTrophyCount(); // Load the trophy count when the level is loaded
    _fetchUserLanguage();
    _initializeRecorder();
    _player.openPlayer();
    _loadShowcaseStatus();
    _loadProgress();
  }

  Future<void> _fetchUserLanguage() async {
    String language = await _firebaseServices.getUserLanguage();
    setState(() {
      _userLanguage = language;
      generateWords(); // Call generateWords() after setting language
    });
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentIndex = prefs.getInt('9_currentIndex') ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('9_currentIndex', currentIndex);
  }

  Future<void> _loadShowcaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showShowcase = prefs.getBool('showShowcase_9') ?? true;
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

  Future<void> loadTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    int trophyC = trophyManager.trophyCount;
    trophyCount = trophyC;
  }

  Future<void> _saveTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    trophyManager.increase(); // this updates the provider

    // Now refresh local trophyCount from provider
    setState(() {
      trophyCount = trophyManager.trophyCount;
    });

    // Optionally also save to Firebase if needed:
    await trophyManager.saveToFirebase();
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

    // if (availableWords.isEmpty) {
    //   setState(() {
    //     selectedOption = null;
    //     isSubmitEnabled = false;
    //     clickCountMap.clear();
    //   });
    //   showAllWordsDoneDialog();
    //   return;
    // }

    if (currentIndex >= availableWords.length) {
      setState(() {
        selectedOption = null;
        isSubmitEnabled = false;
        clickCountMap.clear();
      });
      showAllWordsDoneDialog();
      return;
    }

    // Random random = Random();
    // int index = random.nextInt(availableWords.length);
    // List<String> selectedPair = availableWords.removeAt(index);

    List<String> selectedPair = availableWords[currentIndex];
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
            uploadedUrl, _userLanguage, word, sound1, sound2);

        setState(() {
          questionCounter++;
          _showGameElements = false;
          _recordingAvailable = false;
          isSubmitEnabled =
              false; // Disable confirm button until a new recording is made
        });

        currentIndex++; // Move to next index for next call
    await _saveProgress();

        if (questionCounter == 5) {
          iterationCounter++;
          trophyCount++;
          await _saveTrophyCount();
          questionCounter = 0;

          // Show TrophyDialog first
          await showIterationCompleteDialog();

          // After TrophyDialog is closed, check if any words remain
          if (wordPairsByLanguage[_userLanguage]!.isNotEmpty) {
            generateWords();
          } else {
            // Show CompletionDialog after TrophyDialog is dismissed
            showAllWordsDoneDialog();
          }
        } else {
          // If it's not the 5th question, proceed normally
          if (wordPairsByLanguage[_userLanguage]!.isNotEmpty) {
            generateWords();
          } else {
            showAllWordsDoneDialog();
          }
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

  Future<void> resetLevel() async {
    setState(() {
      wordPairsByLanguage[_userLanguage]!.addAll(usedWordPairs);
      usedWordPairs.clear();
      questionCounter = 0;
      iterationCounter = 0;
      currentIndex = 0;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('9_currentIndex');
    generateWords();
  }

  Future<void> showIterationCompleteDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const TrophyDialog(),
    );
  }

  void showAllWordsDoneDialog() {
    showDialog(
      context: context,
      builder: (context) => CompletionDialog(
        onReset: () {
          Navigator.of(context).pop();
          resetLevel();
        },
      ),
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
    return ShowCaseWidget(
      builder: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (showShowcase && iterationCounter == 0) {
              ShowCaseWidget.of(context).startShowCase([
                _recordButtonKey,
                _playButtonKey,
                _confirmButtonKey,
              ]);
              // Save it so next time it's skipped
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showShowcase_9', false);
              setState(() {
                showShowcase = false;
              });
            }
          });
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
                // appBar: CustomAppBar(titleKey: 'wordgame3'),
                appBar: CustomAppBar(
                  titleKey: 'wordgame3',
                  onLearnPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('showShowcase_9', true);
                    setState(() {
                      showShowcase = true;
                    });
                    ShowCaseWidget.of(context).startShowCase([
                      _recordButtonKey,
                      _playButtonKey,
                      _confirmButtonKey,
                    ]);
                  },
                ),
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
                      // Main game content
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: _userLanguage == "hindi"
                                      ? [
                                          AnimatedWoodenButton(
                                            label: S.of(context).Word,
                                            onPressed: () => playAudio(word),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              S.of(context).In,
                                              style: TextStyle(
                                                  fontSize: 60.sp,
                                                  color: Colors.white),
                                            ),
                                          ),
                                          AnimatedWoodenButton(
                                            label: S.of(context).sound2,
                                            onPressed: () => playAudio(sound2),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              S.of(context).With,
                                              style: TextStyle(
                                                  fontSize: 60.sp,
                                                  color: Colors.white),
                                            ),
                                          ),
                                          AnimatedWoodenButton(
                                            label: S.of(context).sound1,
                                            onPressed: () => playAudio(sound1),
                                          ),
                                          SizedBox(height: 10),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              S.of(context).substitute,
                                              style: TextStyle(
                                                  fontSize: 60.sp,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ]
                                      : [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              S.of(context).substitute,
                                              style: TextStyle(
                                                  fontSize: 60.sp,
                                                  color: Colors.white),
                                            ),
                                          ),
                                          AnimatedWoodenButton(
                                            label: S.of(context).sound2,
                                            onPressed: () => playAudio(sound2),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              S.of(context).With,
                                              style: TextStyle(
                                                  fontSize: 60.sp,
                                                  color: Colors.white),
                                            ),
                                          ),
                                          AnimatedWoodenButton(
                                            label: S.of(context).sound1,
                                            onPressed: () => playAudio(sound1),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 15, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              S.of(context).In,
                                              // style: TextStyle(
                                              //     fontSize: 18, color: Colors.white),
                                              style: TextStyle(
                                                  fontSize: 60.sp,
                                                  color: Colors.white),
                                            ),
                                          ),
                                          AnimatedWoodenButton(
                                            label: S.of(context).Word,
                                            onPressed: () => playAudio(word),
                                          ),
                                        ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25.0, vertical: 0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AudioShowcaseButtons(
                                      isRecording: _isRecording,
                                      isPlaying: _isPlaying,
                                      isEnabled: _recordingAvailable,
                                      onRecordPressed: _toggleRecording,
                                      onPlayPressed: _playRecording,
                                      onConfirmPressed: handleSubmit,
                                      keys: {
                                        'record': _recordButtonKey,
                                        'play': _playButtonKey,
                                        'confirm': _confirmButtonKey,
                                      },
                                    ),
                                  ],
                                ),
                              ),
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
        },
      ),
    );
  }
}
