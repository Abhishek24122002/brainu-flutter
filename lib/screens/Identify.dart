import 'package:brainu/screens/LevelSelectionScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../aws/FileUploader.dart';
import '../components/appbar.dart';
import '../components/audio_buttons.dart';
import '../components/question_container.dart';
import '../components/start_button.dart';
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
    _player.openPlayer();
    // Convert list to string for Firebase
    _imageNamesString = _imageNames.join(', ');
    _loadIteration().then((_) {
    _fetchUserLanguage(); // Only after iteration is loaded
  });
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
  Future<void> _saveIteration() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('identify_iteration', _iteration);
}
Future<void> _loadIteration() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _iteration = prefs.getInt('identify_iteration') ?? 0;
  });
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
  await _saveIteration(); // 👈 Save after updating

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

    

    // Extract just the names from the asset paths
List<String> imageNamesForKey = _images.map((path) {
  String name = path.split('_r_').last.replaceAll('.png', '');
  return name;
}).toList();

String iterationKey = "iteration${_iteration}"; 

// Save to Firebase as a proper JSON object
await _firebaseSave.saveAnswer_Identify(
  userLanguage,
  iterationKey,
  imageNamesForKey,
  uploadedUrl
);



    // Determine max iterations based on language
    int maxIterations = (userLanguage == "hindi") ? iterations.length : 2;

   if (_iteration < maxIterations) {
  _randomizeImages();
} else {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('identify_iteration', 0); // ✅ Reset iteration
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LevelSelectionScreen()),
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
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/img/Identify_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(titleKey: 'ldentify'),
          body: Column(
            children: [
              CustomContainer(text: S.of(context).ran_question),

              if (!_showGameElements)
                StartButton(
                  onPressed: () {
                    setState(() {
                      _showGameElements = true;
                      _recordingPath = null; // Clear the last recording
                      _recordingAvailable = false;
                    });
                  },
                ),
              // Game elements become visible after clicking the button
              if (_showGameElements)
                Column(
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFF00AAB3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Color(0xFFBA4C24),
                            width: 10), // updated border color
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(30, 0, 0, 0),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                  offset: Offset(3, 3),
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
                    SizedBox(height: 5),

                    // Buttons for recording and submitting answers
                    
                      // padding: const EdgeInsets.symmetric(
                      //     horizontal: 25.0, vertical: 20),
                       Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          StartRecordingButton(
                            onPressed: _toggleRecording,
                            isRecording: _isRecording,
                          ),
                          PlayAudioButton(
                            onPressed: _playRecording,
                            isPlaying: _isPlaying,
                            isEnabled: _recordingAvailable && !_isPlaying,
                          ),
                          ConfirmButton(
                            onPressed: _uploadAudioAndNavigate,
                            isEnabled: _recordingAvailable,
                          ),
                        ],
                      ),
                    
                  ],
                ),
            ],
          ),
        ),
      ],
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
