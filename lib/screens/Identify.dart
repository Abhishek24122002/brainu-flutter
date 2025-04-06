import 'package:brainu/screens/LevelSelectionScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';

import '../aws/FileUploader.dart';
import '../components/question_container.dart';
import '../firebase/firebase_save_answer.dart';
import '../firebase/firebase_services.dart';
import '../generated/l10n.dart';

class Identify extends StatefulWidget {
  @override
  _IdentifyState createState() => _IdentifyState();
}

class _IdentifyState extends State<Identify> {
  int _iteration = 0;
  bool _showGameElements = false; // Control visibility
  List<List<String>> iterations = [
    // Iteration 1 (Common)
    ['star', 'triangle', 'circle', 'rectangle'],

    // Iteration 2 (Common)
    ['ship', 'color_star', 'fish', 'table', 'key'],

    // Iteration 3 (Hindi Only)
    ['g', 'f', 'v', 'j', 'k'],

    // Iteration 4 (Hindi Only)
    ['p', 'k', 'v']
  ];

  final List<String> _imageNames = [
    'fish',
    'color_star',
    'table',
    'ship',
    'key'
  ];

  late String _imageNamesString; // Single string of names
  final FirebaseServices _firebaseServices = FirebaseServices();
  final FirebaseSave _firebaseSave = FirebaseSave();
  late String userLanguage = "english"; // Default to English

  List<String> _images = [];

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
    _fetchUserLanguage();
    _player.openPlayer();
    // Convert list to string for Firebase
    _imageNamesString = _imageNames.join(', ');
  }

  void _randomizeImages() {
    Random random = Random();

    // Determine the correct iteration list
    List<List<String>> allowedIterations =
        (userLanguage == "hindi") ? iterations : iterations.sublist(0, 2);

    int currentIteration =
        _iteration % allowedIterations.length; // Ensure it loops back

    List<String> availableImages = allowedIterations[currentIteration];

    _images = List.generate(15, (index) {
      return 'assets/img/ic_r_${availableImages[random.nextInt(availableImages.length)]}.png';
    });

    setState(() {});
  }

  Future<void> _fetchUserLanguage() async {
    userLanguage = await _firebaseServices.getUserLanguage();

    _randomizeImages();
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
    setState(() {
        _iteration++;
        _showGameElements = false;
      });
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

      await _firebaseSave.saveAnswer_Identify(
          uploadedUrl, userLanguage, _imageNamesString);

      // Determine the max number of iterations allowed based on the language
      int maxIterations = (userLanguage == "hindi") ? iterations.length : 2;

      

      if (_iteration < maxIterations) {
        _randomizeImages(); // Refresh with new iteration images
      } else {
        // Navigate to Level Selection Screen after all iterations
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LevelSelectionScreen(),
          ),
        );
      }
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
      // backgroundColor: Colors.brown,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(S.of(context).game_identify,
            style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColorDark,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CustomContainer(text: S.of(context).ran_question),
            // Show this button only if game elements are hidden
            if (!_showGameElements)
              Container(
                margin: EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showGameElements = true;
                      _recordingPath = null; // Clear the last recording
                      _recordingAvailable = false;
                    });
                    

                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColorDark,
                    padding: EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Text(S.of(context).click_here_to_start,
                          style: TextStyle(fontSize: 20, color: Colors.white)),
                    ),
                  ),
                ),
              ),

            // Game elements become visible after clicking the button
            Visibility(
              visible: _showGameElements,
              child: Column(
                children: [
                  

                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.brown,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black!, width: 10),
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

                  // Buttons for recording and submitting answers
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
                        onPressed: _recordingAvailable
                            ? _uploadAudioAndNavigate
                            : null,
                        label: S.of(context).confirm,
                        icon: Icons.send,
                        color: _recordingAvailable ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
