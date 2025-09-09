import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../aws/FileUploader.dart';
import '../components/appbar.dart';
import '../components/question_container.dart';
import '../components/start_button.dart';
import '../firebase/firebase_save_answer.dart';
import '../firebase/firebase_services.dart';
import '../generated/l10n.dart';

import 'package:brainu/managers/trophy_manager.dart';
import 'package:provider/provider.dart';

import 'package:brainu/components/popups/trophy.dart';
import 'package:brainu/components/popups/completion.dart';
import '../components/showcase/AudioShowcaseButtons.dart';
import 'package:showcaseview/showcaseview.dart';


class Identify extends StatefulWidget {
  @override
  _IdentifyState createState() => _IdentifyState();
}

class _IdentifyState extends State<Identify> {
  int _iteration = 0;
  bool _showGameElements = false; // Control visibility

  bool showShowcase = false;

  final GlobalKey _recordButtonKey = GlobalKey();
  final GlobalKey _playButtonKey = GlobalKey();
  final GlobalKey _confirmButtonKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();

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
  int trophyCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _player.openPlayer();
    _loadShowcaseStatus();
    // Convert list to string for Firebase
    _imageNamesString = _imageNames.join(', ');
    _loadIteration().then((_) {
      _fetchUserLanguage();
      _loadTrophyCount(); // Only after iteration is loaded
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

  Future<void> _loadShowcaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showShowcase = prefs.getBool('showShowcase_2') ?? true;
    });
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

  Future<void> _loadTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    trophyCount = trophyManager.trophyCount;
  }

  Future<void> _saveTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    trophyManager.increase(); // update Provider
    setState(() {
      trophyCount = trophyManager.trophyCount;
    });
    await trophyManager.saveToFirebase();
  }

  void _showTrophyDialog() {
    showDialog(
      context: context,
      builder: (context) => const TrophyDialog(),
    );
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
    if (_iteration % 2 == 0) {
      await _saveTrophyCount();
      _showTrophyDialog();
    }
    // 👈 Save after updating

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
          userLanguage, iterationKey, imageNamesForKey, uploadedUrl);

      // Determine max iterations based on language
      int maxIterations = (userLanguage == "hindi") ? iterations.length : 2;

      if (_iteration < maxIterations) {
        _randomizeImages();
      } else {
        showDialog(
          context: context,
          builder: (context) => CompletionDialog(
            onReset: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('identify_iteration', 0);
              setState(() {
                _iteration = 0;
              });
              _randomizeImages(); // Restart with fresh images
            },
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
    return ShowCaseWidget(
      builder: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (showShowcase && _iteration == 0) {
              ShowCaseWidget.of(context).startShowCase([
                _boardKey,
                _recordButtonKey,
                _playButtonKey,
                _confirmButtonKey,
              ]);
              // Save it so next time it's skipped
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showShowcase_2', false);
              setState(() {
                showShowcase = false;
              });
            }
          });
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
                // appBar: CustomAppBar(titleKey: 'ldentify'),
                appBar: CustomAppBar(
                  titleKey: 'ldentify',
                  onLearnPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('showShowcase_2', true);
                    setState(() {
                      showShowcase = true;
                    });
                    ShowCaseWidget.of(context).startShowCase([
                      _boardKey, 
                      _recordButtonKey,
                      _playButtonKey,
                      _confirmButtonKey,
                    ]);
                  },
                ),
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
                    if (_showGameElements)
                      Expanded(
                        // Expanded added here
                        child: Column(
                          children: [
                            Expanded(
  child: Showcase(
    key: _boardKey,
    description: S.of(context).Identify_and_speak, // 👈 localized message
    child: Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF00AAB3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFBA4C24),
          width: 6,
        ),
      ),
                                child: GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                    childAspectRatio: 1.3,
                                  ),
                                  itemCount: _images.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color.fromARGB(
                                                20, 0, 0, 0),
                                            blurRadius: 3,
                                            spreadRadius: 0.5,
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                      child: Image.asset(
                                        _images[index],
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            ),
                            SizedBox(
                                height: 5), // spacing between board and buttons

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25.0, vertical: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AudioShowcaseButtons(
                                    isRecording: _isRecording,
                                    isPlaying: _isPlaying,
                                    isEnabled: _recordingAvailable,
                                    onRecordPressed: _toggleRecording,
                                    onPlayPressed: _playRecording,
                                    onConfirmPressed: _uploadAudioAndNavigate,
                                    keys: {
                                      'record': _recordButtonKey,
                                      'play': _playButtonKey,
                                      'confirm': _confirmButtonKey,
                                    },
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
            ],
          );
        },
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
