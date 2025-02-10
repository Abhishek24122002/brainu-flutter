import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../generated/l10n.dart';

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
        _showGameElements = false;
      });
    } else {
      showAllWordsDoneDialog();
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).game_story,
            style: TextStyle(color: Colors.white)),
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
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Question Section
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    S.of(context).paragraph_reading_question,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Story Section with Scrollbar and Dynamic Height
              if (_showGameElements && currentStoryIndex < stories.length)
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.28, // 30% of screen height
                      child: Scrollbar(
                        thumbVisibility: true, // Always show the scrollbar
                        child: SingleChildScrollView(
                          child: Text(
                            stories[currentStoryIndex],
                            style:
                                TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 20),

              // Start Button
              if (!_showGameElements)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showGameElements = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        S.of(context).click_here_to_start,
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),

              // Recording & Confirm Buttons
              if (_showGameElements) ...[
                SizedBox(height: 15),
                _buildStyledButton(
                  onPressed: _toggleRecording,
                  label: _isRecording
                      ? S.of(context).stop_recording
                      : S.of(context).start_recording,
                  icon: _isRecording ? Icons.stop : Icons.mic,
                  color: _isRecording ? Colors.red : Colors.blue,
                ),
                SizedBox(height: 15),
                _buildStyledButton(
                  onPressed: _isPlaying ? null : _playRecording,
                  label: S.of(context).play_audio,
                  icon: Icons.play_arrow,
                  color: Colors.amberAccent,
                ),
                SizedBox(height: 15),
                _buildStyledButton(
                  onPressed: _recordingAvailable ? _confirmStory : null,
                  label: S.of(context).confirm,
                  icon: Icons.send,
                  color: _recordingAvailable ? Colors.green : Colors.grey,
                ),
              ],
            ],
          ),
        ),
      ),)
    );
  }

  Widget _buildStyledButton(
      {required VoidCallback? onPressed,
      required String label,
      required IconData icon,
      required Color color}) {
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
