import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:brainu/aws/FileUploader.dart';
import 'package:brainu/firebase/firebase_save_answer.dart';
import 'package:brainu/firebase/firebase_services.dart';
import 'package:brainu/managers/trophy_manager.dart';
import 'package:brainu/components/appbar.dart';
import 'package:brainu/components/question_container.dart';
import 'package:brainu/components/start_button.dart';
import 'package:brainu/components/submit_button.dart';
import 'package:brainu/components/popups/trophy.dart';
import 'package:brainu/components/popups/completion.dart';
import 'package:brainu/generated/l10n.dart';
import 'package:brainu/widgets/app_loader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

class Listen extends StatefulWidget {
  @override
  _ListenState createState() => _ListenState();
}

class _ListenState extends State<Listen> {
  final GlobalKey _canvasKey = GlobalKey();
  late FirebaseServices _firebaseServices;
  late FirebaseSave _firebaseSave;
  late String userLanguage = "english";
  late AudioPlayer _audioPlayer;

  late StreamSubscription _connectivitySub;

  bool _isDrawingDone = false;
  List<String> _remainingWords = [];
  String _currentWord = "";
  List<Offset> _points = [];
  bool _showGameElements = false;
  int questionIndex = 0;
  int trophyCount = 0;
  int iterationCounter = 0;
  String currentLocale = "en";

  bool showShowcase = false;
  final GlobalKey _boardKey = GlobalKey();
  FileUploader fileUploader = FileUploader();

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _firebaseServices = FirebaseServices(userId: uid);
    _firebaseSave = FirebaseSave(userId: uid);

    _fetchUserLanguage();
    loadTrophyCount();
    _loadShowcaseStatus();
    _audioPlayer = AudioPlayer();

    _initConnectivityListener();
    loadProgress();

    _syncUnsyncedDrawings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detectLocaleAndLoadWords();
  }

  Future<void> _initConnectivityListener() async {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _syncUnsyncedDrawings();
      }
    });
  }

  Future<void> _syncUnsyncedDrawings() async {
    final box = await Hive.openBox('listen_unsynced');
    final keys = box.keys.toList();

    for (final key in keys) {
      final data = box.get(key);
      if (data == null) continue;

      final Uint8List bytes = data['bytes'];
      final String word = data['word'];
      final String lang = data['lang'];

      String fileName = "drawing_${DateTime.now().millisecondsSinceEpoch}.png";
      String? uploadedUrl = await fileUploader.uploadBytes(bytes, fileName);

      if (uploadedUrl != null) {
        await _firebaseSave.saveAnswer_Listen(
          uploadedUrl,
          currentWord: word,
          userLanguage: lang,
        );
        await box.delete(key);
      }
    }
  }

  Future<void> _detectLocaleAndLoadWords() async {
    Locale locale = Localizations.localeOf(context);
    String newLocale = locale.languageCode;
    if (currentLocale != newLocale) currentLocale = newLocale;
    _loadWords();
  }

  void _loadWords() async {
    final box = await Hive.openBox('listen_progress');
    questionIndex = box.get('Listen_questionIndex', defaultValue: 0);

    final Map<String, List<String>> wordLists = {
      "en": [
        "amaze",
        "avoid",
        "book",
        "cage",
        "cake",
        "cooky",
        "credit",
        "cycle",
        "dinner",
        "edit",
        "fear",
        "fruit",
        "head",
        "invite",
        "kind",
        "mood",
        "note",
        "phone",
        "plan",
        "plate",
        "play",
        "select",
        "soft",
        "vanish",
        "yellow"
      ],
      "hi": [
        "dosti",
        "kandhe",
        "tasvir",
        "pathar",
        "prasad",
        "sundar",
        "baccha",
        "basti",
        "dhyan",
        "kulla",
        "kutta",
        "machar",
        "parantu",
        "pyasa",
        "sant",
        "takhti"
      ]
    };

    List<String> fullList = wordLists[currentLocale] ?? wordLists["en"]!;
    if (questionIndex < fullList.length) {
      _remainingWords = fullList.sublist(questionIndex);
    } else {
      _remainingWords = [];
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _connectivitySub.cancel();
    super.dispose();
  }

  Future<void> _fetchUserLanguage() async {
    userLanguage = await _firebaseServices.getUserLanguage();
  }

  Future<void> _loadShowcaseStatus() async {
    final box = await Hive.openBox('listen_flags');
    setState(() {
      showShowcase = box.get('showShowcase_4', defaultValue: true);
    });
  }

  Future<void> saveProgress() async {
    final box = await Hive.openBox('listen_progress');
    await box.put('Listen_questionIndex', questionIndex);
  }

  Future<void> loadProgress() async {
    final box = await Hive.openBox('listen_progress');
    questionIndex = box.get('Listen_questionIndex', defaultValue: 0);
  }

  Future<void> loadTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    trophyCount = trophyManager.trophyCount;
  }

  Future<void> _saveCanvasAsImage() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AppLoader(message: 'Saving drawing...'),
      );

      RenderRepaintBoundary boundary = _canvasKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image originalImage = await boundary.toImage();

      ByteData? byteData =
          await originalImage.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      String fileName = "drawing_${DateTime.now().millisecondsSinceEpoch}.png";
      String? uploadedUrl = await fileUploader.uploadBytes(pngBytes, fileName);

      if (uploadedUrl != null) {
        await _firebaseSave.saveAnswer_Listen(
          uploadedUrl,
          currentWord: _currentWord,
          userLanguage: userLanguage,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded successfully!')),
        );
      } else {
        // offline → save locally
        final box = await Hive.openBox('listen_unsynced');
        await box.put(DateTime.now().millisecondsSinceEpoch.toString(), {
          'bytes': pngBytes,
          'word': _currentWord,
          'lang': userLanguage,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved offline, will sync later')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Hide loader in case of error
      print("Error saving image: $e");
    }
  }

  void _playNextWordAudio() async {
    if (_remainingWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All words played!")),
      );
      return;
    }

    setState(() {
      _currentWord = _remainingWords.removeAt(0);
    });

    _playAudio(_currentWord);
  }

  void _playAudio(String word) async {
    String audioPath = currentLocale == "hi"
        ? "audio/hindi/dictation_consonent/$word.wav"
        : "audio/english/dictation_consonent/$word.wav";

    try {
      await _audioPlayer.play(AssetSource(audioPath));
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Future<void> _onSubmit() async {
    if (_points.isEmpty || _points.every((point) => point == Offset.zero)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Write the word you heard")),
      );
      _playAudio(_currentWord);
      return;
    }

    await _saveCanvasAsImage();

    setState(() {
      _points.clear();
      _isDrawingDone = false;
      _showGameElements = false;
    });

    questionIndex++;
    await saveProgress();

    if (_remainingWords.isEmpty) {
      showCompletionDialog();
      return;
    }

    if (questionIndex % 5 == 0) {
      trophyCount++;
      await _saveTrophyCount();
      showIterationCompleteDialog();
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
    showDialog(context: context, builder: (context) => const TrophyDialog());
  }

  void showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CompletionDialog(
        onReset: () async {
          final box = await Hive.openBox('listen_progress');
          await box.put('Listen_questionIndex', 0);
          setState(() {
            questionIndex = 0;
            _detectLocaleAndLoadWords();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(builder: Builder(builder: (context) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (showShowcase && iterationCounter == 0) {
          ShowCaseWidget.of(context).startShowCase([_boardKey]);
          final box = await Hive.openBox('listen_flags');
          await box.put('showShowcase_4', false);
          setState(() => showShowcase = false);
        }
      });
      return Stack(children: [
        Positioned.fill(
          child: Image.asset('assets/img/Listen_bg.png', fit: BoxFit.cover),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(
            titleKey: 'listen',
            onLearnPressed: () async {
              final box = await Hive.openBox('listen_flags');
              await box.put('showShowcase_4', true);
              setState(() => showShowcase = true);
              ShowCaseWidget.of(context).startShowCase([_boardKey]);
            },
          ),
          body: Column(
            children: [
              CustomContainer(text: S.of(context).dictation_consonent),
              SizedBox(height: 5),
              if (!_showGameElements)
                StartButton(
                  onPressed: () {
                    setState(() => _showGameElements = true);
                    _playNextWordAudio();
                  },
                ),
              if (_showGameElements)
                Flexible(
                  flex: 6,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double boardHeight = constraints.maxHeight * 0.7;
                      return Column(
                        children: [
                          Showcase(
                            key: _boardKey,
                            description: S.of(context).write_here,
                            child: Container(
                              height: boardHeight,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 25.w, vertical: 8.h),
                              child: AspectRatio(
                                aspectRatio: 4 / 3,
                                child: GestureDetector(
                                  onPanStart: (details) {
                                    if (showShowcase) {
                                      ShowCaseWidget.of(context).dismiss();
                                      setState(() => showShowcase = false);
                                      Hive.openBox('listen_flags').then((box) =>
                                          box.put('showShowcase_4', false));
                                    }
                                    setState(() {
                                      RenderBox renderBox = _canvasKey
                                          .currentContext!
                                          .findRenderObject() as RenderBox;
                                      _points.add(renderBox.globalToLocal(
                                          details.globalPosition));
                                    });
                                  },
                                  onPanUpdate: (details) {
                                    setState(() {
                                      RenderBox renderBox = _canvasKey
                                          .currentContext!
                                          .findRenderObject() as RenderBox;
                                      _points.add(renderBox.globalToLocal(
                                          details.globalPosition));
                                    });
                                  },
                                  onPanEnd: (_) {
                                    _points.add(Offset.zero);
                                    bool hasMeaningfulDrawing = _points
                                            .where((p) => p != Offset.zero)
                                            .length >
                                        2;
                                    setState(() {
                                      _isDrawingDone = hasMeaningfulDrawing;
                                    });
                                  },
                                  child: RepaintBoundary(
                                    key: _canvasKey,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.asset('assets/img/board.png',
                                            fit: BoxFit.fill),
                                        CustomPaint(
                                          painter: CanvasPainter(_points),
                                          child: Container(
                                              color: Colors.transparent),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _points.clear();
                                    _isDrawingDone = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFE40808),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  S.of(context).Clear,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                              ),
                              SubmitButton(
                                isEnabled: _isDrawingDone,
                                onPressed: _onSubmit,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ]);
    }));
  }
}

class CanvasPainter extends CustomPainter {
  final List<Offset> points;
  CanvasPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) => true;
}
