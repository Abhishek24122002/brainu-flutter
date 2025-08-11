import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../aws/FileUploader.dart';
import '../components/WoodenButton.dart';
import '../components/appbar.dart';
import '../components/question_container.dart';
import '../components/start_button.dart';
import '../firebase/firebase_services.dart';

import 'package:flutter_sound/flutter_sound.dart';
import '../components/audio_buttons.dart';
import '../generated/l10n.dart';
import '../firebase/firebase_save_answer.dart';

import 'package:vibration/vibration.dart';

import 'package:brainu/managers/trophy_manager.dart';
import 'package:provider/provider.dart';

import '../components/popups/trophy.dart';
import '../components/popups/completion.dart';
import '../components/showcase/AudioShowcaseButtons.dart';

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
  bool _showGameElements = false;
  int questionIndex = 0;
  bool showShowcase = false;
  int currentIndex = 0;

  final GlobalKey _recordButtonKey = GlobalKey();
  final GlobalKey _playButtonKey = GlobalKey();
  final GlobalKey _confirmButtonKey = GlobalKey();

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
    loadTrophyCount();
    _fetchUserLanguage(); // Load the trophy count when the level is loaded
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

  Future<void> _loadShowcaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showShowcase = prefs.getBool('showShowcase_7') ?? true;
    });
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentIndex = prefs.getInt('7_currentIndex') ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('7_currentIndex', currentIndex);
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

  Future<void> generateWords() async {
    // List<List<String>> availableWords =
    //     wordPairsByLanguage[_userLanguage] ?? [];

    // if (availableWords.isEmpty) {
    //   setState(() {
    //     selectedOption = null;
    //     isSubmitEnabled = false;
    //     clickCountMap.clear();
    //   });
    //   showAllWordsDoneDialog();
    //   return;
    // }

    // Random random = Random();
    // int index = random.nextInt(availableWords.length);
    // List<String> selectedPair = availableWords.removeAt(index);
    // usedWordPairs.add(selectedPair);

    // word1 = selectedPair[0];
    // word2 = selectedPair[1];

    // setState(() {
    //   selectedOption = null;
    //   isSubmitEnabled = false;
    //   clickCountMap = {for (var option in options) option: 0};
    // });

    List<List<String>> availableWords =
        wordPairsByLanguage[_userLanguage] ?? [];

    if (currentIndex >= availableWords.length) {
      setState(() {
        selectedOption = null;
        isSubmitEnabled = false;
        clickCountMap.clear();
      });
      showAllWordsDoneDialog();
      return;
    }

    List<String> selectedPair = availableWords[currentIndex];
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

        await _firebaseSave.saveAnswer_Ph_deletion_final(
          uploadedUrl,
          _userLanguage,
          word1,
          word2,
        );

        setState(() {
          questionCounter++;
          _showGameElements = false;
          _recordingAvailable = false;
          isSubmitEnabled = false;
        });

        currentIndex++; // Move to next index for next call
    await _saveProgress();

        final bool allWordsDone = wordPairsByLanguage[_userLanguage]!.isEmpty;
        final bool shouldShowTrophy = questionCounter == 5;

        if (shouldShowTrophy) {
          iterationCounter++;
          trophyCount++;
          await _saveTrophyCount();
          questionCounter = 0;

          // 🏆 Show the trophy dialog and wait for it to close
          await showDialog(
            context: context,
            builder: (context) => const TrophyDialog(),
          );

          // 🎯 If all words are done, show the completion dialog after trophy
          if (allWordsDone) {
            await Future.delayed(
                Duration(milliseconds: 300)); // optional smooth delay
            showAllWordsDoneDialog();
          } else {
            generateWords();
          }

          return; // exit early to avoid duplicate calls
        }

        // If it's not time for trophy yet
        if (allWordsDone) {
          showAllWordsDoneDialog();
        } else {
          generateWords();
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

  Future<void> resetLevel() async {
    setState(() {
      wordPairsByLanguage[_userLanguage]!.addAll(usedWordPairs);
      usedWordPairs.clear();
      questionCounter = 0;
      iterationCounter = 0;
      currentIndex = 0;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('7_currentIndex');
    generateWords();
  }

  void showIterationCompleteDialog() {
    showDialog(
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
              await prefs.setBool('showShowcase_7', false);
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
                appBar: CustomAppBar(
                  titleKey: 'wordgame1',
                  onLearnPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('showShowcase_7', true);
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

                    // These elements are only shown after clicking the start button
                    if (_showGameElements) ...[
                      // Main game content
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              S.of(context).from_the,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white),
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
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              S.of(context).Remove,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white),
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              S.of(context).Remove,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white),
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
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              S.of(context).from_the,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white),
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          AnimatedWoodenButton(
                                            label: S.of(context).Word,
                                            onPressed: () => playAudio(word1),
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
