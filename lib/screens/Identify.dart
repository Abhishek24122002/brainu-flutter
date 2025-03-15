import 'package:brainu/screens/LevelSelectionScreen.dart';
import 'package:brainu/screens/Listen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';

import '../aws/FileUploader.dart';
import '../generated/l10n.dart';

class Identify extends StatefulWidget {
  @override
  _IdentifyState createState() => _IdentifyState();
}

class _IdentifyState extends State<Identify> {
  final List<String> _imageNames = [
    'ic_r_fish.png',
    'ic_r_color_star.png',
    'ic_r_table.png',
    'ic_r_ship.png',
    'ic_r_key.png'
  ];

  List<String> _images = [];

  final FileUploader _fileUploader =
      FileUploader(); // Add this inside `_IdentifyState`
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
    _randomizeImages();
  }

  void _randomizeImages() {
    Random random = Random();
    _images = List.generate(15, (index) {
      return 'assets/img/${_imageNames[random.nextInt(_imageNames.length)]}';
    });

    setState(() {});
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

  Future<void> _uploadAudioAndNavigate() async {
    if (_recordingPath == null || !File(_recordingPath!).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No recording found!")),
      );
      return;
    }

    File audioFile = File(_recordingPath!);
    String? uploadedUrl = await _fileUploader.uploadFile(audioFile);

    if (uploadedUrl != null) {
      print("Audio uploaded: $uploadedUrl");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload successful!")),
      );

      // Navigate to next screen after successful upload
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LevelSelectionScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed! Please try again.")),
      );
    }
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

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown, // **Board-Like Background**
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
        title: Text(
          S.of(context).game_identify,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.all(20),
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
                  S.of(context).ran_question,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              // **Board-Like Grid Container**
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.brown[300], // Light brown board color
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.brown[200]!, width: 10), // Thick border
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        _images[index],
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Column(
                children: [
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
                    onPressed:
                        _recordingAvailable ? _uploadAudioAndNavigate : null,
                    label: S.of(context).confirm,
                    icon: Icons.send,
                    color: _recordingAvailable ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(fontSize: 18, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
