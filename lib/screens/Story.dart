import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'dart:io';
import '../aws/FileUploader.dart';
import '../firebase/firebase_save_answer.dart';
import '../firebase/firebase_services.dart';

import '../generated/l10n.dart';

import '../components/appbar.dart';
import '../components/question_container.dart';
import '../components/start_button.dart';
import '../components/popups/trophy.dart';
import '../components/popups/completion.dart';
import '../components/showcase/AudioShowcaseButtons.dart';

import 'package:brainu/managers/trophy_manager.dart';
import 'package:provider/provider.dart';

import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

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
  bool showShowcase = false;

  final GlobalKey _storyContainerKey = GlobalKey();
  final GlobalKey _recordButtonKey = GlobalKey();
  final GlobalKey _playButtonKey = GlobalKey();
  final GlobalKey _confirmButtonKey = GlobalKey();

  final FirebaseServices _firebaseServices = FirebaseServices(userId: '');
  final FirebaseSave _firebaseSave = FirebaseSave(userId: '');
  late String userLanguage = "english";
  final FileUploader _fileUploader = FileUploader();

  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  FlutterSoundPlayer _player = FlutterSoundPlayer();

  // Hive boxes
  late Box _progressBox;
  late Box<List> _pendingBox;

  // Connectivity
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _player.openPlayer();
    _initLocalBoxesAndListeners();
    _fetchUserLanguage();
    loadTrophyCount();
    _loadShowcaseStatus();
  }

  Future<void> _initLocalBoxesAndListeners() async {
    _progressBox = await Hive.openBox('story_progress');
    _pendingBox = await Hive.openBox<List>('story_pending');

    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _processPendingAnswers();
      }
    });

    var current = await _connectivity.checkConnectivity();
    if (current != ConnectivityResult.none) {
      _processPendingAnswers();
    }

    _loadProgress();
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    await _recorder.openRecorder();
  }

  List<String> getStories(BuildContext context) {
    return [
      S.of(context).paragraph_reading_0,
      S.of(context).paragraph_reading_1,
      S.of(context).paragraph_reading_2,
      S.of(context).paragraph_reading_3,
      S.of(context).paragraph_reading_4,
    ].where((story) => story.isNotEmpty).toList();
  }

  Future<void> _fetchUserLanguage() async {
    userLanguage = await _firebaseServices.getUserLanguage();
  }

  Future<void> _loadShowcaseStatus() async {
    final box = await Hive.openBox('showcase_flags');
    setState(() {
      showShowcase = box.get('showShowcase_5', defaultValue: true);
    });
  }

  Future<void> _saveShowcaseStatus(bool value) async {
    final box = await Hive.openBox('showcase_flags');
    await box.put('showShowcase_5', value);
  }

  Future<void> _saveProgress() async {
    await _progressBox.put('Story_questionIndex', questionIndex);
  }

  Future<void> _loadProgress() async {
    questionIndex = _progressBox.get('Story_questionIndex', defaultValue: 0);
  }

  Future<void> loadTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    trophyCount = trophyManager.trophyCount;
  }

  Future<void> _playRecording() async {
    if (_recordingPath != null && File(_recordingPath!).existsSync()) {
      await _player.startPlayer(
        fromURI: _recordingPath,
        whenFinished: () {
          setState(() => _isPlaying = false);
        },
      );
      setState(() => _isPlaying = true);
    }
  }

  void _confirmStory() async {
    if (_recordingPath == null) return;

    File recordedFile = File(_recordingPath!);
    if (!recordedFile.existsSync()) return;

    final pendingItem = {
      'filePath': _recordingPath,
      'storyIndex': currentStoryIndex,
      'storyText': stories[currentStoryIndex],
      'userLanguage': userLanguage,
      'timestamp': DateTime.now().toIso8601String(),
    };

    List pending = _pendingBox.get('pending', defaultValue: [])!.toList();
    pending.add(pendingItem);
    await _pendingBox.put('pending', pending.cast());

    var conn = await _connectivity.checkConnectivity();
    if (conn != ConnectivityResult.none) {
      await _processPendingAnswers();
    }

    questionIndex++;
    await _saveProgress();

    if (questionIndex % 5 == 0) {
      await _saveTrophyCount();
      showIterationCompleteDialog();
      return;
    }

    if (currentStoryIndex < stories.length - 1) {
      setState(() {
        _recordingAvailable = false;
        currentStoryIndex++;
        _recordingPath = null;
        _showGameElements = false;
      });
    } else {
      showAllStoriesDoneDialog();
    }
  }

  Future<void> _processPendingAnswers() async {
  final pending = _pendingBox.get('pending', defaultValue: [])!.toList();
  if (pending.isEmpty) return;

  final List items = List.from(pending);
  bool anyUploaded = false;

  for (var item in items) {
    try {
      File audioFile = File(item['filePath']);
      if (!audioFile.existsSync()) continue;

      String? uploadedUrl = await _fileUploader.uploadFile(audioFile);
      if (uploadedUrl != null) {
        await _firebaseSave.saveAnswer_Story(
          iterationKey: 'iteration${item['storyIndex'] + 1}',
          storyText: item['storyText'],
          audioUrl: uploadedUrl,
          userLanguage: item['userLanguage'],
        );
        pending.remove(item);
        anyUploaded = true;
      }
    } catch (e) {
      debugPrint('Failed to upload story answer: $e');
    }
  }

  if (anyUploaded) {
    await _pendingBox.put('pending', pending);
  }
}


  Future<void> _saveTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    trophyManager.increase();
    setState(() => trophyCount = trophyManager.trophyCount);
    await trophyManager.saveToFirebase();
    await trophyManager.saveToHive();
  }

  void showIterationCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => const TrophyDialog(),
    );
  }

  void showAllStoriesDoneDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CompletionDialog(
        onReset: () async {
          await _progressBox.put('Story_questionIndex', 0);
          setState(() {
            questionIndex = 0;
            currentStoryIndex = 0;
            _recordingAvailable = false;
            _showGameElements = false;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _progressBox.close();
    _pendingBox.close();
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final test1Dir = Directory('${directory.path}/test1');
    if (!test1Dir.existsSync()) {
      test1Dir.createSync(recursive: true);
    }
    return '${test1Dir.path}/audio_story$currentStoryIndex.aac';
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
    setState(() => _isRecording = true);
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
    stories = getStories(context);
    currentStoryIndex = questionIndex.clamp(0, stories.length - 1);

    return ShowCaseWidget(
      builder: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (showShowcase && currentStoryIndex == 0) {
              ShowCaseWidget.of(context).startShowCase([
                _storyContainerKey,
                _recordButtonKey,
                _playButtonKey,
                _confirmButtonKey,
              ]);
              await _saveShowcaseStatus(false);
              setState(() => showShowcase = false);
            }
          });

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
                appBar: CustomAppBar(
                  titleKey: 'story',
                  onLearnPressed: () async {
                    await _saveShowcaseStatus(true);
                    setState(() => showShowcase = true);
                    ShowCaseWidget.of(context).startShowCase([
                      _storyContainerKey,
                      _recordButtonKey,
                      _playButtonKey,
                      _confirmButtonKey,
                    ]);
                  },
                ),
                body: Column(
                  children: [
                    CustomContainer(
                        text: S.of(context).paragraph_reading_question),
                    if (!_showGameElements)
                      StartButton(
                        onPressed: () {
                          setState(() => _showGameElements = true);
                        },
                      ),
                    if (_showGameElements && currentStoryIndex < stories.length)
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: Showcase(
                                  key: _storyContainerKey,
                                  description: S.of(context).Read_text_loudly,
                                  child: SingleChildScrollView(
                                    child: Text(
                                      stories[currentStoryIndex],
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 25.0, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AudioShowcaseButtons(
                                    isRecording: _isRecording,
                                    isPlaying: _isPlaying,
                                    isEnabled: _recordingAvailable,
                                    onRecordPressed: _toggleRecording,
                                    onPlayPressed: _playRecording,
                                    onConfirmPressed: _confirmStory,
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
