import 'dart:async';
import 'dart:io';

import 'package:brainu/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../aws/FileUploader.dart';
import '../firebase/firebase_save_answer.dart';
import '../firebase/firebase_services.dart';
import '../components/appbar.dart';
import '../components/audio_buttons.dart';
import '../components/question_container.dart';
import '../components/start_button.dart';
import '../components/popups/trophy.dart';
import '../components/popups/completion.dart';
import '../components/showcase/AudioShowcaseButtons.dart';
import '../generated/l10n.dart';
import 'package:brainu/managers/trophy_manager.dart';

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
  bool _loading = false;

  final GlobalKey _storyContainerKey = GlobalKey();
  final GlobalKey _recordButtonKey = GlobalKey();
  final GlobalKey _playButtonKey = GlobalKey();
  final GlobalKey _confirmButtonKey = GlobalKey();

  late FirebaseServices _firebaseServices;
  late FirebaseSave _firebaseSave;
  late String userLanguage = "english"; // Default language
  final FileUploader _fileUploader = FileUploader();

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  late StreamSubscription _connectivitySub;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _player.openPlayer();
    _initializeFirebase();
    loadTrophyCount();
    loadProgress();
    _loadShowcaseStatus();

    // Connectivity listener for offline sync
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await _syncUnsyncedRecordings();
      }
    });

    // Flush offline recordings immediately at startup
    _syncUnsyncedRecordings();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _connectivitySub.cancel();
    super.dispose();
  }

  Future<void> _initializeFirebase() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _firebaseServices = FirebaseServices(userId: uid);
    _firebaseSave = FirebaseSave(userId: uid);
    userLanguage = await _firebaseServices.getUserLanguage();
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

  Future<void> _loadShowcaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showShowcase = prefs.getBool('showShowcase_5') ?? true;
    });
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
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    trophyCount = trophyManager.trophyCount;
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

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final test1Dir = Directory('${directory.path}/test1');
    if (!test1Dir.existsSync()) {
      test1Dir.createSync(recursive: true);
    }
    return '${test1Dir.path}/audio_recording$currentStoryIndex.aac';
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

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _confirmStory() async {
    if (_recordingPath == null) return;

    setState(() => _loading = true);

    File audioFile = File(_recordingPath!);
    String? uploadedUrl;

    try {
      uploadedUrl = await _fileUploader.uploadFile(audioFile);
    } catch (e) {
      uploadedUrl = null;
    }

    if (uploadedUrl != null) {
      await _saveStoryAnswer(
        iterationKey: 'iteration${currentStoryIndex + 1}',
        currentStory: stories[currentStoryIndex],
        uploadedUrl: uploadedUrl,
      );
    } else {
      // Save offline
      final box = await Hive.openBox('story_unsynced');
      await box.put(DateTime.now().millisecondsSinceEpoch.toString(), {
        'filePath': _recordingPath!,
        'storyIndex': currentStoryIndex,
        'lang': userLanguage,
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _saveStoryAnswer({
    required String iterationKey,
    required String currentStory,
    required String uploadedUrl,
  }) async {
    await _firebaseSave.saveAnswer_Story(
      iterationKey: iterationKey,
      storyText: currentStory,
      audioUrl: uploadedUrl,
      userLanguage: userLanguage,
    );

    questionIndex++;
    await saveProgress();

    if (questionIndex % 5 == 0) {
      trophyCount++;
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
      showAllWordsDoneDialog();
    }
  }

  Future<void> _saveTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    trophyManager.increase();
    setState(() {
      trophyCount = trophyManager.trophyCount;
    });
    await trophyManager.saveToFirebase();
  }

  void showIterationCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => const TrophyDialog(),
    );
  }

  void showAllWordsDoneDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CompletionDialog(
        onReset: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('Story_questionIndex', 0);
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

  Future<void> _syncUnsyncedRecordings() async {
    final box = await Hive.openBox('story_unsynced');
    final keys = box.keys.toList();
    if (keys.isEmpty) return;

    setState(() => _loading = true);

    for (final key in keys) {
      final data = box.get(key);
      if (data == null) continue;

      File file = File(data['filePath']);
      String storyUrl = await _fileUploader.uploadFile(file) ?? '';
      if (storyUrl.isNotEmpty) {
        String currentStory = stories[data['storyIndex']];
        String iterationKey = 'iteration${data['storyIndex'] + 1}';

        await _firebaseSave.saveAnswer_Story(
          iterationKey: iterationKey,
          storyText: currentStory,
          audioUrl: storyUrl,
          userLanguage: data['lang'],
        );

        await box.delete(key);
      }
    }

    setState(() => _loading = false);
  }

  void _resetLevel() {
    setState(() {
      currentStoryIndex = 0;
      _recordingAvailable = false;
      _showGameElements = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    stories = getStories(context);
    currentStoryIndex = questionIndex.clamp(0, stories.length - 1);

    return Stack(
      children: [
        ShowCaseWidget(
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
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('showShowcase_5', false);
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
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('showShowcase_5', true);
                        setState(() => showShowcase = true);
                        ShowCaseWidget.of(context).startShowCase([
                          _storyContainerKey,
                          _recordButtonKey,
                          _playButtonKey,
                          _confirmButtonKey,
                        ]);
                      },
                    ),
                    body: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomContainer(
                              text: S.of(context).paragraph_reading_question),
                          if (_showGameElements &&
                              currentStoryIndex < stories.length)
                            Showcase(
                              key: _storyContainerKey,
                              description: S.of(context).Read_text_loudly,
                              child: GestureDetector(
                                onTap: () {
                                  ShowCaseWidget.of(context).dismiss();
                                },
                                child: Container(
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.height * 0.37,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                          'assets/img/Story_container.png'),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        70, 60, 70, 65),
                                    child: ScrollbarTheme(
                                      data: ScrollbarThemeData(
                                        thumbColor: MaterialStateProperty.all(
                                            Color.fromARGB(154, 141, 110, 99)),
                                        trackColor: MaterialStateProperty.all(
                                            Colors.brown[100]),
                                        thickness: MaterialStateProperty.all(5),
                                        radius: Radius.circular(10),
                                      ),
                                      child: Scrollbar(
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          child: Text(
                                            stories[currentStoryIndex],
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: Color.fromRGBO(
                                                  114, 64, 23, 1),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (!_showGameElements)
                            StartButton(
                              onPressed: () {
                                setState(() {
                                  _showGameElements = true;
                                });
                              },
                            ),
                          if (_showGameElements)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25.0),
                              child: AudioShowcaseButtons(
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
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_loading) const AppLoader(message: "Processing..."),
      ],
    );
  }
}
