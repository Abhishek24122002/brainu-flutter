import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:brainu/components/popups/completion.dart';
import 'package:brainu/components/popups/trophy.dart';
import 'package:brainu/managers/trophy_manager.dart';
import 'package:brainu/widgets/app_loader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../aws/FileUploader.dart';
import '../components/appbar.dart';
import '../components/question_container.dart';
import '../components/showcase/AudioShowcaseButtons.dart';
import '../components/start_button.dart';
import '../firebase/firebase_save_answer.dart';
import '../firebase/firebase_services.dart';
import '../generated/l10n.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Identify extends StatefulWidget {
  @override
  _IdentifyState createState() => _IdentifyState();
}

class _IdentifyState extends State<Identify> {
  int _iteration = 0;
  bool _showGameElements = false;
  bool showShowcase = false;

  final GlobalKey _recordButtonKey = GlobalKey();
  final GlobalKey _playButtonKey = GlobalKey();
  final GlobalKey _confirmButtonKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();

  List<List<String>> iterations = [
    ['star', 'triangle', 'circle', 'rectangle'],
    ['ship', 'color_star', 'fish', 'table', 'key'],
    ['g', 'f', 'v', 'j', 'k'],
    ['p', 'k', 'v']
  ];

  final List<String> _imageNames = [
    'fish',
    'color_star',
    'table',
    'ship',
    'key'
  ];

  late FirebaseServices _firebaseServices;
  late FirebaseSave _firebaseSave;

  late String userLanguage = "english";
  List<String> _images = [];

  final FileUploader _fileUploader = FileUploader();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _recordingAvailable = false;
  String? _recordingPath;

  int trophyCount = 0;

  late Box _identifyBox;
  late Box<List> _pendingUploadsBox;

  late final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _initAll();
  }

  Future<void> _initAll() async {
    _identifyBox = await Hive.openBox('identify_box');
    _pendingUploadsBox = await Hive.openBox<List>('identify_pending_uploads');

    await _initializeRecorder();
    await _player.openPlayer();

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _firebaseServices = FirebaseServices(userId: uid);
    _firebaseSave = FirebaseSave(userId: uid);

    _loadIterationFromHive();
    _loadShowcaseFromHive();
    await _fetchUserLanguage();
    _randomizeImages();
    _loadTrophyCount();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) _processPendingUploads();
    });

    var currentConn = await _connectivity.checkConnectivity();
    if (currentConn != ConnectivityResult.none) _processPendingUploads();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (showShowcase && _iteration == 0) {
        ShowCaseWidget.of(context)?.startShowCase([
          _boardKey,
          _recordButtonKey,
          _playButtonKey,
          _confirmButtonKey,
        ]);
        _saveShowcaseToHive(false);
      }
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
    if (!test1Dir.existsSync()) test1Dir.createSync(recursive: true);
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${test1Dir.path}/audio_recording_${ts}.aac';
  }

  void _randomizeImages() {
    Random random = Random();
    List<List<String>> allowedIterations =
        (userLanguage.toLowerCase() == "hindi")
            ? iterations
            : iterations.sublist(0, 2);

    int currentIteration = _iteration % allowedIterations.length;
    List<String> availableImages = allowedIterations[currentIteration];

    _images = List.generate(15, (index) {
      return 'assets/img/ic_r_${availableImages[random.nextInt(availableImages.length)]}.png';
    });

    setState(() {});
  }

  Future<void> _fetchUserLanguage() async {
    try {
      String langCode = await _firebaseServices.getUserLanguage();
      userLanguage = langCode.toLowerCase();
    } catch (e) {
      userLanguage = 'english';
    }
    _randomizeImages();
  }

  Future<void> _saveIterationToHive() async {
    await _identifyBox.put('identify_iteration', _iteration);
  }

  void _loadIterationFromHive() {
    final stored = _identifyBox.get('identify_iteration');
    _iteration = stored != null && stored is int ? stored : 0;
  }

  Future<void> _saveShowcaseToHive(bool val) async {
    await _identifyBox.put('showShowcase_2', val);
  }

  void _loadShowcaseFromHive() {
    final stored = _identifyBox.get('showShowcase_2');
    showShowcase = stored != null && stored is bool ? stored : true;
  }

  Future<void> _loadTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    trophyCount = trophyManager.trophyCount;
  }

  Future<void> _saveTrophyCountAndShowDialogIfNeeded() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    trophyManager.increase();
    await trophyManager.saveToHive();
    var conn = await _connectivity.checkConnectivity();
    if (conn != ConnectivityResult.none) await trophyManager.saveToFirebase();

    setState(() {
      trophyCount = trophyManager.trophyCount;
    });
    _showTrophyDialog();
  }

  void _showTrophyDialog() {
    showDialog(
      context: context,
      builder: (context) => const TrophyDialog(),
    );
  }

  Future<void> _uploadAudioAndNavigate() async {
    if (_player.isPlaying) await _player.stopPlayer();

    setState(() {
      _iteration++;
      _showGameElements = false;
    });
    await _saveIterationToHive();

    if (_iteration % 2 == 0) await _saveTrophyCountAndShowDialogIfNeeded();

    if (_recordingPath == null || !File(_recordingPath!).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No recording found!")),
      );
      return;
    }

    List<String> imageNamesForKey = _images.map((path) {
      return path.split('_r_').last.replaceAll('.png', '');
    }).toList();

    final uploadItem = {
      'filePath': _recordingPath!,
      'iteration': _iteration,
      'imageNames': imageNamesForKey,
      'userLanguage': userLanguage,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const AppLoader(message: "Uploading...", style: LoaderStyle.wave),
    );

    var connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      List<Map<String, dynamic>> pending = List<Map<String, dynamic>>.from(
          _pendingUploadsBox.get('pending', defaultValue: [])!);
      pending.add(uploadItem);
      await _pendingUploadsBox.put('pending', pending);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Saved offline. Will upload when network is available.")),
      );
      _afterUploadSuccessFlow();
      return;
    }

    final File audioFile = File(_recordingPath!);
    String? uploadedUrl;
    try {
      uploadedUrl = await _fileUploader.uploadFile(audioFile);
    } catch (e) {
      uploadedUrl = null;
    }

    if (uploadedUrl == null) {
      List<Map<String, dynamic>> pending = List<Map<String, dynamic>>.from(
          _pendingUploadsBox.get('pending', defaultValue: [])!);
      pending.add(uploadItem);
      await _pendingUploadsBox.put('pending', pending);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Upload failed — saved offline and will retry.")),
      );
      _afterUploadSuccessFlow();
      return;
    }

    try {
      await _firebaseSave.saveAnswer_Identify(
        iterationKey: "iteration$_iteration",
        items: imageNamesForKey,
        audioUrl: uploadedUrl,
        userLanguage: userLanguage,
      );
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload successful!")),
      );
      _afterUploadSuccessFlow();
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saving result failed. Saved offline.")),
      );
      List<Map<String, dynamic>> pending = List<Map<String, dynamic>>.from(
          _pendingUploadsBox.get('pending', defaultValue: [])!);
      pending.add(uploadItem);
      await _pendingUploadsBox.put('pending', pending);
      _afterUploadSuccessFlow();
    }
  }

  void _afterUploadSuccessFlow() {
    int maxIterations =
        (userLanguage.toLowerCase() == "hindi") ? iterations.length : 2;
    if (_iteration < maxIterations) {
      _randomizeImages();
    } else {
      showDialog(
        context: context,
        builder: (context) => CompletionDialog(
          onReset: () async {
            _iteration = 0;
            await _saveIterationToHive();
            _randomizeImages();
            setState(() {});
          },
        ),
      );
    }
  }

  Future<void> _processPendingUploads() async {
    List<Map<String, dynamic>> pending = List<Map<String, dynamic>>.from(
        _pendingUploadsBox.get('pending', defaultValue: [])!);
    if (pending.isEmpty) return;

    final List<Map<String, dynamic>> items = List.from(pending);
    bool anyUploaded = false;

    for (var item in items) {
      try {
        final filePath = item['filePath'] as String;
        final imageNames = (item['imageNames'] as List).cast<String>();
        final userLang = item['userLanguage'] as String;
        final iterationVal = item['iteration'] as int;
        final f = File(filePath);
        if (!f.existsSync()) {
          pending.remove(item);
          continue;
        }

        final url = await _fileUploader.uploadFile(f);
        if (url != null) {
          await _firebaseSave.saveAnswer_Identify(
            iterationKey: "iteration$iterationVal",
            items: imageNames,
            audioUrl: url,
            userLanguage: userLang,
          );
          anyUploaded = true;
          pending.remove(item);
        }
      } catch (e) {}
    }

    if (anyUploaded) await _pendingUploadsBox.put('pending', pending);
  }

  Future<void> _toggleRecording() async {
    if (_isRecording)
      await _stopRecording();
    else
      await _startRecording();
  }

  Future<void> _startRecording() async {
    if (_player.isPlaying) await _player.stopPlayer();
    _recordingPath = await _getFilePath();
    await _recorder.startRecorder(toFile: _recordingPath);
    setState(() {
      _isRecording = true;
      _recordingAvailable = false;
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
          });
      setState(() {
        _isPlaying = true;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    try {
      _recorder.closeRecorder();
      _player.closePlayer();
    } catch (_) {}
    _identifyBox.close();
    _pendingUploadsBox.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: Builder(
        builder: (context) {
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
                appBar: CustomAppBar(
                  titleKey: 'ldentify',
                  onLearnPressed: () async {
                    await _saveShowcaseToHive(true);
                    setState(() {
                      showShowcase = true;
                    });
                    ShowCaseWidget.of(context)?.startShowCase([
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
                            _recordingPath = null;
                            _recordingAvailable = false;
                          });
                        },
                      ),
                    if (_showGameElements)
                      Expanded(
                        child: Column(
                          children: [
                            Showcase(
                              key: _boardKey,
                              description: S.of(context).Identify_and_speak,
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
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
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
                            SizedBox(height: 5),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25.0, vertical: 20),
                                child: AudioShowcaseButtons(
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
