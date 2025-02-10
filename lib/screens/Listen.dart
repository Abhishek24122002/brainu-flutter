import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../generated/l10n.dart';
import 'LevelSelectionScreen.dart';

class Listen extends StatefulWidget {
  @override
  _ListenState createState() => _ListenState();
}

class _ListenState extends State<Listen> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<String> words = [
    "amaze",
    "avoid",
    "book",
    "cage",
    "cake",
    "cooky",
    "credit",
    "cycle",
    "dinner",
    "fear",
    "fruit"
  ];
  late AudioPlayer _audioPlayer;
  List<String> _remainingWords = [];
  String _currentWord = "";
  List<Offset> _points = [];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _remainingWords = List.from(words); // Clone the words list
    _playNextWordAudio();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playNextWordAudio() async {
    if (_remainingWords.isEmpty) {
      _navigateToLevelSelection();
      return;
    }

    setState(() {
      _currentWord =
          _remainingWords.removeAt(Random().nextInt(_remainingWords.length));
    });

    String audioPath = "audio/english/dictation_consonent/$_currentWord.wav";
    await _audioPlayer.play(AssetSource(audioPath));
  }

  void _navigateToLevelSelection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LevelSelectionScreen()),
    );
  }

  void _onSubmit() {
    // Clear canvas and play next word
    setState(() {
      _points.clear();
    });
    _playNextWordAudio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(iconTheme: IconThemeData( color: const Color.fromARGB(255, 255, 255, 255),),
        title: Text(S.of(context).game_listen,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        
      ),
      body: Container(
        color: Colors.white, // Plain white background
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
                      Text(S.of(context).dictation_consonent,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          
                        ),
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
                      RenderBox renderBox = _canvasKey.currentContext!
                          .findRenderObject() as RenderBox;
                      _points
                          .add(renderBox.globalToLocal(details.globalPosition));
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
                label: Text(S.of(context).submit,
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
      ..color = Colors.black // Pen color remains black
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
