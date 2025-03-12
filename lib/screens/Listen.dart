import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../generated/l10n.dart';
import 'LevelSelectionScreen.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'dart:convert';

class Listen extends StatefulWidget {
  @override
  _ListenState createState() => _ListenState();
}

class _ListenState extends State<Listen> {
  final GlobalKey _canvasKey = GlobalKey();
  late AudioPlayer _audioPlayer;
  List<String> _remainingWords = [];
  String _currentWord = "";
  List<Offset> _points = [];
  String currentLocale = "en"; // Default language

  @override
  void initState() {
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

  void _loadWords() {
    final Map<String, List<String>> wordLists = {
      "en": [
        "amaze", "avoid", "book", "cage", "cake", "cooky", "credit",
        "cycle", "dinner", "fear", "fruit"
      ],
      "hi": [
        "dosti","kandhe","tasvir","pathar","prasad","sundar","baccha","basti",
        "dhyan","kulla","kutta","machar","parantu","pyasa","sant","takhti"
      ]
    };

    _remainingWords = List.from(wordLists[currentLocale] ?? wordLists["en"]!);
    _playNextWordAudio();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  
  Future<void> _uploadImageToS3(File file) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://localhost:5000/upload'),
  );

  request.files.add(
    await http.MultipartFile.fromPath('image', file.path),
  );

  var response = await request.send();
  if (response.statusCode == 200) {
    var responseData = await response.stream.bytesToString();
    var jsonData = jsonDecode(responseData);
    print('Uploaded Image URL: ${jsonData["imageUrl"]}');
  } else {
    print('Upload failed with status: ${response.statusCode}');
  }
}

Future<void> _saveCanvasAsImage() async {
  try {
    RenderRepaintBoundary boundary =
        _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png';
    File file = File(filePath);
    await file.writeAsBytes(pngBytes);

    print('Image saved at: $filePath');
    
    // Upload the image to AWS S3
    await _uploadImageToS3(file);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: Colors.green),
    );
  } catch (e) {
    print("Error saving image: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to upload image'), backgroundColor: Colors.red),
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

  void _onSubmit() {
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

  _saveCanvasAsImage(); // Save image before clearing

  setState(() {
    _points.clear();
  });
  _playNextWordAudio();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          S.of(context).game_listen,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        S.of(context).dictation_consonent,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      RenderBox renderBox =
                          _canvasKey.currentContext!.findRenderObject() as RenderBox;
                      _points.add(renderBox.globalToLocal(details.globalPosition));
                    });
                  },
                  onPanEnd: (_) => _points.add(Offset.zero),
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: CustomPaint(
                      painter: CanvasPainter(_points),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blueAccent, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _onSubmit,
                icon: Icon(Icons.check, color: Colors.white),
                label: Text(
                  S.of(context).submit,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) => true;
}
