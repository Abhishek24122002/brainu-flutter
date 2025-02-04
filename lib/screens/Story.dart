import 'package:brainu/screens/LevelSelectionScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class Story extends StatefulWidget {
  @override
  _StoryState createState() => _StoryState();
}

class _StoryState extends State<Story> {
  final List<String> stories = [
    "Ants are found everywhere in the world. They make their home in buildings, gardens, etc. They live in anthills. Ants are very hardworking insects. Throughout the summers, they collect food for the winter season.",
    "The lion is known as the king of the jungle. It is a strong and powerful animal. Lions live in groups called prides. They hunt animals for food and are often seen resting under trees during the daytime.",
    "The sun rises in the east and sets in the west. It provides light and heat to the Earth. Plants use sunlight to prepare food in a process called photosynthesis. Without the sun, life on Earth would not be possible."
  ];

  int currentStoryIndex = 0;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _recordingAvailable = false;
  bool _showGameElements = false;
  String? _recordingPath;

  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _player = FlutterSoundPlayer();

  @override
  void initState() {
    super.initState();
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
    return '${test1Dir.path}/audio_recording$currentStoryIndex.aac';
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

  void _confirmStory() {
  if (currentStoryIndex < stories.length - 1) {
    setState(() {
      _recordingAvailable = false;
      currentStoryIndex++;
      _recordingPath = null;
    });
  } else {
    showAllWordsDoneDialog();
  }
}


  void _resetLevel() {
    setState(() {
      currentStoryIndex = 0;
      _recordingAvailable = false;
      _showGameElements = false;
    });
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
                _resetLevel();
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
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Story Reading', style: TextStyle(color: Colors.white)),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Question Section (Always Visible)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "Brainu wants to listen to a story but he is not able to read. Can you help him by reading a story?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Story Section (Initially Hidden)
              if (_showGameElements)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      stories[currentStoryIndex],
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                ),

              SizedBox(height: 20),

              // Click Here to Start Button (Initially Visible)
              if (!_showGameElements)
            Container(
              margin: EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showGameElements = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color
                  padding: EdgeInsets.symmetric(vertical: 20), // Button height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity, // Full width button
                  child: Center(
                    child: Text(
                      "Click Here to Start",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
              // Recording and Confirm Buttons (Initially Hidden)
              if (_showGameElements) ...[
                SizedBox(height: 15),
                _buildStyledButton(
                  onPressed: _toggleRecording,
                  label: _isRecording ? 'Stop Recording' : 'Start Recording',
                  icon: _isRecording ? Icons.stop : Icons.mic,
                  color: _isRecording ? Colors.red : Colors.blue,
                ),
                SizedBox(height: 15),
                _buildStyledButton(
                  onPressed: _isPlaying ? null : _playRecording,
                  label: 'Play Audio',
                  icon: Icons.play_arrow,
                  color: Colors.amberAccent,
                ),
                SizedBox(height: 15),
                _buildStyledButton(
                  onPressed: _recordingAvailable ? _confirmStory : null,
                  label: 'Confirm',
                  icon: Icons.send,
                  color: _recordingAvailable ? Colors.green : Colors.grey,
                ),
              ],

              SizedBox(height: 20),

              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledButton({required VoidCallback? onPressed, required String label, required IconData icon, required Color color}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(fontSize: 18, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
