import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../components/audio_buttons.dart';

import '../components/question_container.dart';
import '../components/start_button.dart';
import '../firebase/firebase_save_answer.dart';
import '../firebase/firebase_services.dart';
import '../aws/FileUploader.dart';
import '../generated/l10n.dart';
import '../screens/LevelSelectionScreen.dart';

import '../components/appbar.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _player.openPlayer();
    _fetchUserLanguage();
    loadTrophyCount();

  }

  Future<void> _fetchUserLanguage() async {
    userLanguage = await _firebaseServices.getUserLanguage();
    await _loadWords(); // Load words after fetching user language
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
  final prefs = await SharedPreferences.getInstance();
  trophyCount = prefs.getInt('Word_trophyCount') ?? 0;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('Word_trophyCount', trophyCount); // Save the trophy count
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
              onPressed: () async {
                Navigator.of(context).pop();
                // generateWords();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('Word_questionIndex', 0);

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

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Congratulations!'),
          content: Text('You have completed all words.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadWords();
              },
              child: Text('Reset Words'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LevelSelectionScreen()),
                );
              },
              child: Text('Next Level'),
            ),
          ],
        );
      },
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
    return Stack(children: [
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
        appBar: CustomAppBar(titleKey: 'word'),

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
                          offset: Offset(0, -20), // Move word 40 pixels upward
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

                    // ✅ Buttons aligned to bottom
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
                          const SizedBox(height: 10),
                          PlayAudioButton(
                            onPressed: _isPlaying ? null : _playRecording,
                            isPlaying: _isPlaying,
                            isEnabled: _recordingAvailable,
                          ),
                          const SizedBox(height: 10),
                          ConfirmButton(
                            onPressed: (_recordingAvailable && !_isUploading)
                                ? _onConfirm
                                : null,
                            isEnabled: _recordingAvailable && !_isUploading,
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
    ]);
  }
}
