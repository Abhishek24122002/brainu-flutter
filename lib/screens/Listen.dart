import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:brainu/aws/FileUploader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/appbar.dart';
import '../components/question_container.dart';
import '../components/start_button.dart';
import '../components/submit_button.dart';
import '../generated/l10n.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../firebase/firebase_save_answer.dart';
import '../firebase/firebase_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brainu/managers/trophy_manager.dart';
import 'package:provider/provider.dart';

import '../components/popups/trophy.dart';
import '../components/popups/completion.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class Listen extends StatefulWidget {
  @override
  _ListenState createState() => _ListenState();
}

class _ListenState extends State<Listen> {
  final GlobalKey _canvasKey = GlobalKey();
  final FirebaseServices _firebaseServices = FirebaseServices(userId: '');
  final FirebaseSave _firebaseSave = FirebaseSave(userId: '');
  late String userLanguage = "english";
  final FileUploader _fileUploader = FileUploader(); // Default to English
  late AudioPlayer _audioPlayer;
  bool _isDrawingDone = false;

  List<String> _remainingWords = [];
  String _currentWord = "";
  List<Offset> _points = [];
  bool _showGameElements = false;
  int questionIndex = 0;
  int trophyCount = 0;
  int iterationCounter = 0;

  String currentLocale = "en"; // Default language

    // Hive boxes
late Box _progressBox;    // to store question index
late Box<List> _pendingBox; // to store pending answers (recordings)

// Connectivity
final Connectivity _connectivity = Connectivity();
StreamSubscription<ConnectivityResult>? _connectivitySub;

  bool showShowcase = false;

  final GlobalKey _boardKey = GlobalKey();
  FileUploader fileUploader =
      FileUploader(); // Create an instance of FileUploader
  @override
  void initState() {
    _fetchUserLanguage();
    _initLocalBoxesAndListeners();
    loadTrophyCount();
    _loadShowcaseStatus();
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detectLocaleAndLoadWords();
  }

  Future<void> _detectLocaleAndLoadWords() async {
    Locale locale = Localizations.localeOf(context);
    String newLocale = locale.languageCode;

    if (currentLocale != newLocale) {
      currentLocale = newLocale;
    }
    _loadWords();
  }

  void _loadWords() async {
    final prefs = await SharedPreferences.getInstance();
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

    questionIndex = prefs.getInt('Listen_questionIndex') ?? 0;
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
    super.dispose();
  }

  Future<void> _initLocalBoxesAndListeners() async {
    _progressBox = await Hive.openBox('listen_progress');
    _pendingBox = await Hive.openBox<List>('listen_pending');

    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _processPendingAnswers();
      }
    });

    var current = await _connectivity.checkConnectivity();
    if (current != ConnectivityResult.none) {
      _processPendingAnswers();
    }
  }

  Future<void> _fetchUserLanguage() async {
    userLanguage = await _firebaseServices.getUserLanguage();
  }

  Future<void> _loadShowcaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      showShowcase = prefs.getBool('showShowcase_4') ?? true;
    });
  }

  // Future<void> saveProgress() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setInt('Listen_questionIndex', questionIndex);
  // }
   Future<void> _saveProgress() async {
  await _progressBox.put('Listen_questionIndex', questionIndex);
}

  // Future<void> loadProgress() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   questionIndex = prefs.getInt('Listen_questionIndex') ?? 0;
  // }
  Future<void> _loadProgress() async {
    questionIndex = _progressBox.get('Listen_questionIndex', defaultValue: 0);
  }

  Future<void> loadTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    int trophyC = trophyManager.trophyCount;
    trophyCount = trophyC;
  }

  Future<void> _saveCanvasAsImage() async {
    try {
      RenderRepaintBoundary boundary = _canvasKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image originalImage = await boundary.toImage();

      int width = originalImage.width;
      int height = originalImage.height;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
          recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

      // Fill background with white
      Paint whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), whitePaint);

      // Draw the original image on top
      final paint = Paint();
      canvas.drawImage(originalImage, Offset.zero, paint);

      ui.Image finalImage =
          await recorder.endRecording().toImage(width, height);
      ByteData? byteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // ✅ Upload the PNG bytes directly using FileUploader
      String fileName = "drawing_${DateTime.now().millisecondsSinceEpoch}.png";
      String? uploadedUrl = await fileUploader.uploadBytes(pngBytes, fileName);

      if (uploadedUrl != null) {
        print("Uploaded File URL: $uploadedUrl");

        // ✅ Save file URL to Firebase
        // await saveAnswer_Listen(uploadedUrl);
        await _firebaseSave.saveAnswer_Listen(
          uploadedUrl: uploadedUrl,
          currentWord: _currentWord,
          userLanguage: userLanguage,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green),
        );
      } else {
        print("Upload failed!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to upload image'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("Error saving image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to upload image'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _playNextWordAudio() async {
    if (_remainingWords.isEmpty) {
      print("All words played, staying on level.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All words played!"),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    setState(() {
      _currentWord = _remainingWords.removeAt(0);
    });

    print("Playing word: $_currentWord");
    _playAudio(_currentWord);
  }

  void _playAudio(String word) async {
    if (word.isEmpty) {
      print("Error: Word is empty, cannot play audio.");
      return;
    }

    String audioPath = currentLocale == "hi"
        ? "audio/hindi/dictation_consonent/$word.wav"
        : "audio/english/dictation_consonent/$word.wav";

    print("Trying to play audio: $audioPath"); // Debugging

    try {
      await _audioPlayer.play(AssetSource(audioPath));
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Future<void> _onSubmit() async {
    if (_points.isEmpty || _points.every((point) => point == Offset.zero)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Write the word you heard"),
          backgroundColor: Colors.red,
        ),
      );
      _playAudio(_currentWord);
      return;
    }

    _saveCanvasAsImage();

    setState(() {
      _points.clear();
      _isDrawingDone = false;
      _showGameElements = false; // 👈 Show Start button again
    });

    questionIndex++;
    await _saveProgress();

    if (_remainingWords.isEmpty) {
      showCompletionDialog();
      return;
    }

    // 🏆 Check for trophy every 5 words
    if (questionIndex % 5 == 0) {
      trophyCount++;
      await _saveTrophyCount();
      showIterationCompleteDialog();
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

      // Upload to AWS
      String? uploadedUrl = await _fileUploader.uploadFile(audioFile);

      if (uploadedUrl != null) {
        await _firebaseSave.saveAnswer_Word(
          uploadedUrl: uploadedUrl,
          currentWord: item['word'],
          userLanguage: item['userLanguage'],
        );

        pending.remove(item);
        anyUploaded = true;
      }
    } catch (e) {
      debugPrint('Failed to upload word answer: $e');
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

  void showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CompletionDialog(
        onReset: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('Listen_questionIndex', 0);
          setState(() {
            questionIndex = 0;
            _detectLocaleAndLoadWords(); // Reset word list
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
          ShowCaseWidget.of(context).startShowCase([
            _boardKey,
          ]);
          // Save it so next time it's skipped
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('showShowcase_4', false);
          setState(() {
            showShowcase = false;
          });
        }
      });
      return Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'assets/img/Listen_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent, // Important!
          // appBar: CustomAppBar(titleKey: 'listen'),
          appBar: CustomAppBar(
            titleKey: 'listen',
            onLearnPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showShowcase_4', true);
              setState(() {
                showShowcase = true;
              });
              ShowCaseWidget.of(context).startShowCase([
                _boardKey,
              ]);
            },
          ),
          body: Container(
            child: Column(
              children: [
                CustomContainer(text: S.of(context).dictation_consonent),
                SizedBox(height: 5),
                if (!_showGameElements)
                  StartButton(
                    onPressed: () {
                      setState(() {
                        _showGameElements = true;
                      });
                      _playNextWordAudio();
                    },
                  ),
                if (_showGameElements)
                  Flexible(
                    flex: 6, // Adjust proportion
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double boardHeight =
                            constraints.maxHeight * 0.7; // Limit height
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
                                      // Stop showcase immediately on first touch
                                      if (showShowcase) {
                                        ShowCaseWidget.of(context)
                                            .dismiss(); // Close showcase popup
                                        setState(() => showShowcase = false);
                                        SharedPreferences.getInstance().then(
                                            (prefs) => prefs.setBool(
                                                'showShowcase_4', false));
                                      }
                                      // Begin drawing as before
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
                                          Image.asset(
                                            'assets/img/board.png',
                                            fit: BoxFit.fill,
                                          ),
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
