import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../aws/FileUploader.dart';
import '../firebase/firebase_save_answer.dart';
import '../firebase/firebase_services.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../generated/l10n.dart';

import '../components/appbar.dart';

import '../components/audio_buttons.dart';

import '../components/question_container.dart';
import '../components/start_button.dart';

class Story extends StatefulWidget {
  @override
  _StoryState createState() => _StoryState();
}

class _StoryState extends State<Story> {
  late List<String> stories;
  int currentStoryIndex = 0;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _recordingAvailable = false;
  bool _showGameElements = false;
  String? _recordingPath;
  int questionIndex = 0;
  int trophyCount = 0;

  final FirebaseServices _firebaseServices = FirebaseServices();
  final FirebaseSave _firebaseSave = FirebaseSave();
  late String userLanguage = "english"; // Default to English
  final FileUploader _fileUploader = FileUploader();

  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _player = FlutterSoundPlayer();

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _player.openPlayer();
    _fetchUserLanguage();
    loadTrophyCount();
    loadProgress();
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    await _recorder.openRecorder();
  }

  /// Function to get stories dynamically from ARB files
  List<String> getStories(BuildContext context) {
    return [
      S.of(context).paragraph_reading_0,
      S.of(context).paragraph_reading_1,
      S.of(context).paragraph_reading_2,
      S.of(context).paragraph_reading_3,
      S.of(context).paragraph_reading_4,
    ].where((story) => story.isNotEmpty).toList(); // Filter out empty stories
  }

  Future<void> _fetchUserLanguage() async {
    userLanguage = await _firebaseServices.getUserLanguage();
  }
  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('Story_questionIndex', questionIndex);
  }

  Future<void> loadProgress() async {
  final prefs = await SharedPreferences.getInstance();
  questionIndex = prefs.getInt('Story_questionIndex') ?? 0;
}

  Future<void> loadTrophyCount() async {
  final prefs = await SharedPreferences.getInstance();
  trophyCount = prefs.getInt('Story_trophyCount') ?? 0;
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
  
  void _confirmStory() async {
  if (_recordingPath == null) {
    print("No recording found.");
    return;
  }

  File recordedFile = File(_recordingPath!);
  if (!recordedFile.existsSync()) {
    print("Recorded file does not exist.");
    return;
  }

  File audioFile = File(_recordingPath!);
  String? uploadedUrl = await _fileUploader.uploadFile(audioFile);

  if (uploadedUrl != null) {
    print("File uploaded successfully: $uploadedUrl");

    String currentStory = stories[currentStoryIndex];
    String iterationKey = 'iteration${currentStoryIndex + 1}';

    await _firebaseSave.saveAnswer_Story(
      userLanguage,
      iterationKey,
      currentStory,
      uploadedUrl,
    );

    // ✅ INCREMENT first
    questionIndex++;
    await saveProgress();

    // ✅ Trophy only after every 5 stories (5, 10, 15, ...)
    if (questionIndex % 5 == 0) {
      trophyCount++;
      await _saveTrophyCount();
      showIterationCompleteDialog();
      return; // Stop here to avoid advancing to next story before dialog
    }

    // ✅ Proceed to next story if not the end
    if (currentStoryIndex < stories.length - 1) {
      setState(() {
        _recordingAvailable = false;
        currentStoryIndex++;
        _recordingPath = null;
        _showGameElements = false;
      });
    } else {
      showAllWordsDoneDialog();
    }
  } else {
    print("File upload failed.");
  }
}

  Future<void> _saveTrophyCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('Story_trophyCount', trophyCount); // Save the trophy count
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
          title: Text('All Story Done'),
          content: Text(
              'You have completed all Stories in this Game. Reset to play again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetLevel();
              },
              child: Text('Reset Level'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final test1Dir = Directory('${directory.path}/test1');
    if (!test1Dir.existsSync()) {
      test1Dir.createSync(recursive: true);
    }
    return '${test1Dir.path}/audio_recording$currentStoryIndex.aac';
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
      _recordingAvailable = true;
    });
  }

  Future<void> _startRecording() async {
    _recordingPath = await _getFilePath();
    await _recorder.startRecorder(toFile: _recordingPath);
    setState(() {
      _isRecording = true;
    });
  }

  void _resetLevel() {
    setState(() {
      currentStoryIndex = 0;
      _recordingAvailable = false;
      _showGameElements = false;
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    stories = getStories(context); // Fetch localized stories
    // ✅ Set the currentStoryIndex based on saved progress
  currentStoryIndex = questionIndex.clamp(0, stories.length - 1);


    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/img/Listen_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(titleKey: 'story'),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align to start instead of center
              children: [
                // Question Section
                CustomContainer(text: S.of(context).paragraph_reading_question),

                // Story Section with Scroll only for text
                if (_showGameElements && currentStoryIndex < stories.length)
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.40,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/img/Story_container.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(50, 60, 50, 60),
                      child: ScrollbarTheme(
                        data: ScrollbarThemeData(
                          thumbColor: MaterialStateProperty.all(
                              Color.fromARGB(154, 141, 110, 99)),
                          trackColor:
                              MaterialStateProperty.all(Colors.brown[100]),
                          thickness: MaterialStateProperty.all(5),
                          radius: Radius.circular(10),
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: Text(
                              
                              stories[currentStoryIndex],
                              style: TextStyle(
                                fontSize: 16,
                                color: Color.fromRGBO(114, 64, 23, 1),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // const SizedBox(height: 10),

                // Start Button
                if (!_showGameElements)
                  StartButton(
                    onPressed: () {
                      setState(() {
                        _showGameElements = true;
                      });
                    },
                  ),

                // Recording & Confirm Buttons
                if (_showGameElements) ...[
                  StartRecordingButton(
                    onPressed: _toggleRecording,
                    isRecording: _isRecording,
                  ),
                  const SizedBox(height: 3),
                  PlayAudioButton(
                    onPressed: _isPlaying ? null : _playRecording,
                    isPlaying: _isPlaying,
                    isEnabled: _recordingPath != null,
                  ),
                  const SizedBox(height: 3),
                  ConfirmButton(
                    onPressed: _recordingAvailable ? _confirmStory : null,
                    isEnabled: _recordingAvailable,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
