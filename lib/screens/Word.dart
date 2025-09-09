import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'dart:io';
import '../components/question_container.dart';
import '../components/start_button.dart';
import '../firebase/firebase_save_answer.dart';
import '../firebase/firebase_services.dart';
import '../aws/FileUploader.dart';
import '../generated/l10n.dart';
import '../components/appbar.dart';

import 'package:brainu/managers/trophy_manager.dart';
import 'package:provider/provider.dart';

import '../components/popups/trophy.dart';
import '../components/popups/completion.dart';
import '../components/showcase/AudioShowcaseButtons.dart';

class Word extends StatefulWidget {
  @override
  _WordState createState() => _WordState();
}

class _WordState extends State<Word> {
  List<String> remainingWords = [];
  late SharedPreferences prefs;
  String currentWord = "";
  bool _showGameElements = false;
  bool _isUploading = false; // Prevent multiple confirm presses

  final FirebaseServices _firebaseServices = FirebaseServices();
  final FirebaseSave _firebaseSave = FirebaseSave();
  late String userLanguage = "english"; // Default to English
  final FileUploader _fileUploader = FileUploader();

  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _recordingAvailable = false;
  String? _recordingPath;
  int questionIndex = 0;
  int trophyCount = 0;
  bool showShowcase = false;

  final GlobalKey _wordKey = GlobalKey();
  final GlobalKey _recordButtonKey = GlobalKey();
  final GlobalKey _playButtonKey = GlobalKey();
  final GlobalKey _confirmButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _player.openPlayer();
    _fetchUserLanguage();
    loadTrophyCount();
    _loadShowcaseStatus();
  }

  Future<void> _fetchUserLanguage() async {
    userLanguage = await _firebaseServices.getUserLanguage();
    await _loadWords(); // Load words after fetching user language
  }

  Future<void> _loadShowcaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showShowcase = prefs.getBool('showShowcase_3') ?? true;
    });
  }

  Future<void> _loadWords() async {
    prefs = await SharedPreferences.getInstance();

    final Map<String, List<String>> wordLists = {
      "english": [
        "Wonder",
        "Huge",
        "Alarm",
        "Cabin",
        "Daily",
        "Blush",
        "Promise",
        "Divide",
        "Expect",
        "Opinion",
        "Avoid",
        "Famous",
        "Proof",
        "Reflect",
        "Board",
        "Excess",
        "Search",
        "Lizard",
        "Notice",
        "Ocean",
        "Career",
        "Brain",
        "Rumor",
        "Flood",
        "Idea"
      ],
      "hindi": [
        "बकरी",
        "सफाई",
        "तरीका",
        "जंगल",
        "अपनी",
        "जामुन",
        "रसोई",
        "कढ़ाई",
        "गर्मी",
        "तेंदुआ",
        "टीचर",
        "मटोल",
        "पक्षी",
        "जमीन",
        "कंबल",
        "दीवार",
        "बिजली",
        "अम्बर",
        "बाहर",
        "आवाज",
        "सुझाव",
        "गौशाला",
        "बछिया",
        "सपना",
        "रोशनी",
        "दीपक",
        "हिसया",
        "घुमाओ",
        "जहाज",
        "दातून",
        "बिलख",
        "पर्वत",
        "पापड़",
        "खटिया",
        "आंगन",
        "मैदान",
        "करेला",
        "अधिक",
        "स्कूल",
        "चाहिए",
        "समुद",
        "फसल",
        "पकौड़ी",
        "मेमना",
        "सर्कस",
        "ईश्वर",
        "जल्दी",
        "पृथ्वी",
        "केचुआ",
        "बरखा",
        "समझ",
        "अमर",
        "खबर",
        "गमला",
        "मंजीर",
        "औरत",
        "पालक",
        "मचान",
        "परदा",
        "गुलाब",
        "बालक",
        "लगन",
        "लड़की",
        "अमीर",
        "काजल",
        "उधार",
        "कितना",
        "भलाई",
        "कोशिश",
        "गाजर",
        "आदमी",
        "गरीब",
        "आराम",
        "कागज",
        "दानव",
        "सूरत",
        "महल",
        "इमली",
        "गरम",
        "बदन",
        "चमन",
        "अपना",
        "बहुत",
        "कपड़ा",
        "तितली",
        "झलक",
        "मलाई",
        "सफ़ेद",
        "कछुआ",
        "जगह",
        "कमल",
        "सुराही",
        "दहाड़",
        "गठरी",
        "योजना"
      ]
    };

    // Ensure userLanguage is valid
    userLanguage = userLanguage.toLowerCase();
    print("Selected Language for Words: $userLanguage"); // Debugging output
    if (!wordLists.containsKey(userLanguage)) {
      userLanguage =
          "english"; // Default to English if an invalid language is set
    }

    List<String> selectedWords = wordLists[userLanguage]!;
    print("Selected Words List: $selectedWords");
    // ✅ **Update remainingWords and currentWord**

    // 👇 Load saved progress
    questionIndex = prefs.getInt('Word_questionIndex') ?? 0;

    // 👇 Skip words based on progress
    if (questionIndex < selectedWords.length) {
      remainingWords = selectedWords.sublist(questionIndex);
    } else {
      remainingWords = [];
    }
    setState(() {
      currentWord = remainingWords.isNotEmpty ? remainingWords.first : "";
    });

    print("Remaining Words: $remainingWords");
    print("Current Word: $currentWord");
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('Word_questionIndex', questionIndex);
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    questionIndex = prefs.getInt('Word_questionIndex') ?? 0;
  }

  Future<void> loadTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    int trophyC = trophyManager.trophyCount;
    trophyCount = trophyC;
  }

  Future<void> _saveWords() async {
    await prefs.setStringList('remainingWords_$userLanguage', remainingWords);
  }

  Future<void> _resetWords(List<String> selectedWords) async {
    await prefs.remove('remainingWords_$userLanguage'); // Clear stored words

    setState(() {
      remainingWords = List.from(selectedWords);
      currentWord = remainingWords.first;
    });

    await _saveWords();
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    await _recorder.openRecorder();
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final test1Dir = Directory('${directory.path}/test1');
    if (!test1Dir.existsSync()) {
      test1Dir.createSync(recursive: true);
    }
    return '${test1Dir.path}/audio_recording.aac';
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
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
      _recordingAvailable = true;
    });
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

  void _onConfirm() async {
    if (_isUploading) {
      print("Upload already in progress. Please wait.");
      return;
    }

    if (_recordingPath == null || !File(_recordingPath!).existsSync()) {
      print("No recording available to upload.");
      return;
    }

    setState(() {
      _isUploading = true;
    });

    File audioFile = File(_recordingPath!);
    String? uploadedUrl = await _fileUploader.uploadFile(audioFile);

    if (uploadedUrl != null) {
      await _firebaseSave.saveAnswer_word(
          uploadedUrl, userLanguage, currentWord);

      if (remainingWords.isNotEmpty) {
        setState(() {
          remainingWords.removeAt(0);
          currentWord = remainingWords.isNotEmpty ? remainingWords.first : "";
        });
        await _saveWords();
      }

      setState(() {
        _showGameElements = false;
        _recordingAvailable = false;
        _recordingPath = null;
      });

      questionIndex++;
      await saveProgress();

      // 🏆 Check for trophy every 5 words
      if (questionIndex % 5 == 0) {
        trophyCount++;
        await _saveTrophyCount();
        showIterationCompleteDialog();
      }

      if (remainingWords.isEmpty) {
        _showCompletionDialog();
      }
    } else {
      print("File upload failed.");
    }

    setState(() {
      _isUploading = false;
    });
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

  void showIterationCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => const TrophyDialog(),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CompletionDialog(
        onReset: _loadWords,
      ),
    );
  }

  @override
  void dispose() {
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
            if (showShowcase && questionIndex == 0) {
              ShowCaseWidget.of(context).startShowCase([
                _wordKey,
                _recordButtonKey,
                _playButtonKey,
                _confirmButtonKey,
              ]);
              // Save it so next time it's skipped
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showShowcase_3', false);
              setState(() {
                showShowcase = false;
              });
            }
          });
          return Stack(
            children: [
              // 🖼 Background image covering the entire screen
              Positioned.fill(
                child: Image.asset(
                  'assets/img/Word_bg.png',
                  fit: BoxFit.cover,
                ),
              ),

              // 🧠 Main UI with transparent background
              Scaffold(
                backgroundColor: Colors.transparent, // Important!
                // appBar: CustomAppBar(titleKey: 'word'),
                appBar: CustomAppBar(
                  titleKey: 'word',
                  onLearnPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('showShowcase_3', true);
                    setState(() {
                      showShowcase = true;
                    });
                    ShowCaseWidget.of(context).startShowCase([
                      _wordKey,
                      _recordButtonKey,
                      _playButtonKey,
                      _confirmButtonKey,
                    ]);
                  },
                ),

                body: Column(
                  children: [
                    CustomContainer(text: S.of(context).word_reading_question),
                    if (!_showGameElements)
                      StartButton(
                        onPressed: () {
                          setState(() {
                            _showGameElements = true;
                          });
                        },
                      ),
                    if (_showGameElements)
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            Expanded(
                              child: Center(
                                child: Transform.translate(
                                  offset: Offset(
                                      0, -20), // Move word 40 pixels upward
                                  child: Showcase(
                                    key: _wordKey,
                                    description:
                                        S.of(context).Read_text_loudly,
                                    child: GestureDetector(
                                      onTap: () {
                                        // 👇 Stop showcase when user touches the word
                                        ShowCaseWidget.of(context).dismiss();
                                      },
                                      child: Text(
                                        currentWord,
                                        style: const TextStyle(
                                          fontSize: 50,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7B2F00),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ✅ Buttons aligned to bottom
                            // Padding(
                            //   padding: const EdgeInsets.symmetric(
                            //       horizontal: 25.0, vertical: 20),
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.stretch,
                            //     children: [
                            //       StartRecordingButton(
                            //         onPressed: _toggleRecording,
                            //         isRecording: _isRecording,
                            //       ),
                            //       const SizedBox(height: 10),
                            //       PlayAudioButton(
                            //         onPressed: _isPlaying ? null : _playRecording,
                            //         isPlaying: _isPlaying,
                            //         isEnabled: _recordingAvailable,
                            //       ),
                            //       const SizedBox(height: 10),
                            //       ConfirmButton(
                            //         onPressed: (_recordingAvailable && !_isUploading)
                            //             ? _onConfirm
                            //             : null,
                            //         isEnabled: _recordingAvailable && !_isUploading,
                            //       ),
                            //     ],
                            //   ),
                            // ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25.0, vertical: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AudioShowcaseButtons(
                                    isRecording: _isRecording,
                                    isPlaying: _isPlaying,
                                    isEnabled: _recordingAvailable,
                                    onRecordPressed: _toggleRecording,
                                    onPlayPressed: _playRecording,
                                    onConfirmPressed: _onConfirm,
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
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
