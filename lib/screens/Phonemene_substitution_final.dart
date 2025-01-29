import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sound/flutter_sound.dart';
import '../components/StartRecordingButton.dart';
import '../components/PlayAudioButton.dart';
import '../components/ConfirmButton.dart';
import 'LevelSelectionScreen.dart';

class Ph_substitution_final extends StatefulWidget {
  @override
  _Ph_substitution_finalState createState() => _Ph_substitution_finalState();
}

class _Ph_substitution_finalState extends State<Ph_substitution_final> {
  String sound1 = '';
  String sound2 = '';
  String word = '';
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

  List<List<String>> wordPairs = [
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
  ];

  List<List<String>> usedWordPairs = [];

  @override
  void initState() {
    super.initState();
    _loadTrophyCount(); // Load the trophy count when the level is loaded
    generateWords();
    _initializeRecorder();
    _player.openPlayer();
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
    if (wordPairs.isEmpty) {
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
    int index = random.nextInt(wordPairs.length);
    List<String> selectedPair = wordPairs.removeAt(index);
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

  Future<void> playAudio(String option, [bool isOption = false]) async {
    try {
      String audioPath;

      if (option.length == 1) {
        // For single-character sounds
        audioPath = 'audio/english/v_and_c/${option.toLowerCase()}.wav';
      } else {
        // For words
        audioPath =
            'audio/english/phoneme_substitution/final/${option.toLowerCase()}.wav';
      }

      print('Playing audio: $audioPath');
      await audioPlayer.play(AssetSource(audioPath));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void handleSubmit() {
    String correctAnswer =
        '${sound2[0]}${sound1.substring(1)}_${sound1[0]}${sound2.substring(1)}.wav';

    if (selectedOption == correctAnswer) {
      print('Correct Answer!');
    } else {
      print('Incorrect Answer.');
    }

    setState(() {
      questionCounter++;
      if (questionCounter == 5) {
        iterationCounter++;
        trophyCount++; // Increment trophy count
        _saveTrophyCount();
        questionCounter = 0;
        showIterationCompleteDialog();
      } else {
        generateWords();
      }
    });
  }

  void resetLevel() {
    setState(() {
      wordPairs.addAll(usedWordPairs);
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
        title: Text('Phoneme Substitution Final'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
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
                'Help Brainu by telling him what new word will be formed when sound 1 is substituted with sound 2 in the given word. \nTap on sound 1, sound 2, and word icons on the board for audio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Main game content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Center-aligned text for "Substitute"
                    Text(
                      'Substitute',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(
                        height:
                            10), // Add spacing between "Substitute" and the next section
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: RichText(
                        textAlign: TextAlign.center, // Center-align the text
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          children: [
                            // Sound1 Button
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () => playAudio(sound1),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlueAccent,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: Text(
                                    "Sound1",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(text: ' with '),
                            // Sound2 Button
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () => playAudio(sound2),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlueAccent,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: Text(
                                    "Sound2",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                        height:
                            20), // Add spacing between "with" section and Word button
                    // Word Button
                    GestureDetector(
                      onTap: () => playAudio(word),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Text(
                          "Word",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
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
                              onPressed: _isPlaying ? null : _playRecording,
                              isPlaying: _isPlaying,
                            ),
                            SizedBox(height: 15),
                            ConfirmButton(
                              onPressed: _recordingAvailable
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              LevelSelectionScreen(),
                                        ),
                                      );
                                    }
                                  : null,
                              isEnabled: _recordingAvailable,
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
        ),
      ),
    );
  }
}
