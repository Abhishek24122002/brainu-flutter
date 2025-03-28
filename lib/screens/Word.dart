import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../components/StartRecordingButton.dart';
import '../components/PlayAudioButton.dart';
import '../components/ConfirmButton.dart';
import '../firebase/firebase_save_answer.dart';
import '../firebase/firebase_services.dart';
import '../aws/FileUploader.dart';
import '../generated/l10n.dart';
import 'LevelSelectionScreen.dart';

class Word extends StatefulWidget {
  @override
  _WordState createState() => _WordState();
}

class _WordState extends State<Word> {
  List<String> remainingWords = [];
  late SharedPreferences prefs;
  String currentWord = "";

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

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _player.openPlayer();
    _fetchUserLanguage();
  }

  Future<void> _fetchUserLanguage() async {
    userLanguage = await _firebaseServices.getUserLanguage();
    await _loadWords(); // Load words after fetching user language
  }

  Future<void> _loadWords() async {
    prefs = await SharedPreferences.getInstance();

    // Define word lists for both languages
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
        "बकरी","सफाई","तरीका","जंगल","अपनी","जामुन","रसोई","कढ़ाई","गर्मी","तेंदुआ","टीचर","मटोल","पक्षी","जमीन","कंबल","दीवार","बिजली","अम्बर", "बाहर", "आवाज","सुझाव","गौशाला","बछिया","सपना","रोशनी","दीपक","हिसया","घुमाओ","जहाज","दातून","बिलख","पर्वत","पापड़","खटिया","आंगन","मैदान","करेला","अधिक","स्कूल","चाहिए","समुद","फसल","पकौड़ी","मेमना","सर्कस","ईश्वर","जल्दी","पृथ्वी","केचुआ","बरखा","समझ","अमर","खबर","गमला","मंजीर","औरत","पालक","मचान","परदा","गुलाब","बालक","लगन","लड़की","अमीर","काजल","उधार","कितना","भलाई","कोशिश","गाजर","आदमी","गरीब","आराम","कागज","दानव","सूरत","महल","इमली","गरम","बदन","चमन","अपना","बहुत","कपड़ा","तितली","झलक","मलाई","सफ़ेद","कछुआ","जगह","कमल","सुराही","दहाड़","गठरी","योजना"
      ]
    };

    // Select words based on the fetched user language
    List<String> selectedWords =
        wordLists[userLanguage.toLowerCase()] ?? wordLists["english"]!;

    // Load stored words or reset
    List<String>? savedWords =
        prefs.getStringList('remainingWords_$userLanguage');

    if (savedWords == null || savedWords.isEmpty) {
      await _resetWords(selectedWords);
    } else {
      setState(() {
        remainingWords = savedWords;
        currentWord = remainingWords.first;
      });
    }
  }

  Future<void> _saveWords() async {
    await prefs.setStringList('remainingWords_$userLanguage', remainingWords);
  }

  Future<void> _resetWords(List<String> selectedWords) async {
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
    if (_recordingPath == null || !File(_recordingPath!).existsSync()) {
      print("No recording available to upload.");
      return;
    }

    File audioFile = File(_recordingPath!);
    String? uploadedUrl = await _fileUploader.uploadFile(audioFile);

    if (uploadedUrl != null) {
      print("File uploaded successfully: $uploadedUrl");

      // ✅ Save the word answer
      await _firebaseSave.saveAnswer_word(
          uploadedUrl, userLanguage, currentWord);

      // Update words
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
    } else {
      print("File upload failed.");
    }
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
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          S.of(context).game_word,
          style: TextStyle(color: Colors.white),
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
            children: [
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
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
                  S.of(context).word_reading_question,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              SizedBox(height: 20),
              if (currentWord.isNotEmpty)
                Text(
                  currentWord,
                  style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              SizedBox(height: 40),
              StartRecordingButton(
                  onPressed: _toggleRecording, isRecording: _isRecording),
              SizedBox(height: 15),
              PlayAudioButton(
                  onPressed: _isPlaying ? null : _playRecording,
                  isPlaying: _isPlaying,
                  isEnabled: _recordingAvailable),
              SizedBox(height: 15),
              ConfirmButton(
                  onPressed: _recordingAvailable ? _onConfirm : null,
                  isEnabled: _recordingAvailable),
            ],
          ),
        ),
      ),
    );
  }
}
