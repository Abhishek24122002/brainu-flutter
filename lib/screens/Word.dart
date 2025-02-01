import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../components/StartRecordingButton.dart';
import '../components/PlayAudioButton.dart';
import '../components/ConfirmButton.dart';
import 'LevelSelectionScreen.dart';

class Word extends StatefulWidget {
  @override
  _WordState createState() => _WordState();
}

class _WordState extends State<Word> {
  final List<String> words = [
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
  ];
  List<String> remainingWords = [];
  late SharedPreferences prefs;
  String currentWord = "";

  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _recordingAvailable = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _player.openPlayer();
    _loadWords();
  }

  Future<void> _loadWords() async {
    prefs = await SharedPreferences.getInstance();
    remainingWords = prefs.getStringList('remainingWords') ?? words;
    if (remainingWords.isEmpty) {
      _resetWords();
    } else {
      setState(() {
        currentWord = remainingWords.first;
      });
    }
  }

  Future<void> _saveWords() async {
    await prefs.setStringList('remainingWords', remainingWords);
  }

  Future<void> _resetWords() async {
    setState(() {
      remainingWords = List.from(words);
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
    if (remainingWords.isNotEmpty) {
      setState(() {
        remainingWords.removeAt(0);
        if (remainingWords.isEmpty) {
          _showCompletionDialog();
        } else {
          currentWord = remainingWords.first;
        }
      });
      await _saveWords();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Congratulations!'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('You have completed all words.'),
                SizedBox(height: 20),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetWords();
                  },
                  child: Text('Reset Words'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LevelSelectionScreen(),
                      ),
                    );
                  },
                  child: Text('Next Level'),
                ),
              ],
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
    return Scaffold(
      appBar: AppBar(iconTheme: IconThemeData( color: const Color.fromARGB(255, 255, 255, 255),),
        title: Text(
          'Word',style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade100, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                  'Brainu is at the beach. He is holding a board that will show a few words. Help him read them out by recording your answer. The word will appear only when you tap.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (currentWord.isNotEmpty)
                Column(
                  children: [
                    Text(
                      currentWord,
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 40),
              StartRecordingButton(
                onPressed: _toggleRecording,
                isRecording: _isRecording,
              ),
              SizedBox(height: 15),
              PlayAudioButton(
                onPressed: _isPlaying ? null : _playRecording,
                isPlaying: _isPlaying, isEnabled:  _recordingAvailable,
              ),
              SizedBox(height: 15),
              ConfirmButton(
                onPressed: _recordingAvailable ? _onConfirm : null,
                isEnabled: _recordingAvailable,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
