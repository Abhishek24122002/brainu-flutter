import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../components/StartRecordingButton.dart';
import '../components/PlayAudioButton.dart';
import '../components/ConfirmButton.dart';

class PhonemeDeletionFinal extends StatefulWidget {
  @override
  _PhonemeDeletionFinalState createState() => _PhonemeDeletionFinalState();
}

class _PhonemeDeletionFinalState extends State<PhonemeDeletionFinal> {
  int _currentIndex = 0;
  final List<String> audioStrings = [
    "bank",
    "bart",
    "boom",
    "brown",
    "chilly",
    "down",
    "fort",
    "ink",
    "kino",
    "news",
    "party",
    "peak",
    "pink",
    "seat",
    "seed",
    "sing",
    "tact",
    "teach",
    "tips",
    "took",
    "want",
    "waster",
    "weepy",
    "wind",
    "woven"
  ];
  final List<String> audioInitialsStrings = [
    "bank_k",
    "bart_t",
    "boom_m",
    "brown_n",
    "chilly_y",
    "down_n",
    "fort_t",
    "ink_k",
    "kino_o",
    "news_s",
    "party_y",
    "peak_k",
    "pink_k",
    "seat_t",
    "seed_d",
    "sing_g",
    "tact_t",
    "teach_ch",
    "tips_s",
    "took_k",
    "want_t",
    "waster_r",
    "weepy_y",
    "wind_d",
    "woven_n"
  ];

  String currentWord = "bank";
  String currentSound = "bank_k";

  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _recordingAvailable = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _initializeSound();
  }

  Future<void> _initializeSound() async {
    await _player.openPlayer();
    await _recorder.openRecorder();
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final testDir = Directory('${directory.path}/phoneme_deletion');
    if (!testDir.existsSync()) {
      testDir.createSync(recursive: true);
    }
    return '${testDir.path}/recorded_audio.aac';
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

  Future<void> _playAudio(String audio) async {
    final path = 'assets/audio/english/phoneme_deletion/final/$audio.wav';
    try {
      await _player.startPlayer(
        fromURI: path,
        codec: Codec.pcm16WAV,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  @override
  void dispose() {
    _player.closePlayer();
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Phoneme Deletion',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade100, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Remove the',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _playAudio(currentSound),
                    child: Text("Sound"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'from the',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _playAudio(currentWord),
                    child: Text("Word"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              StartRecordingButton(
                onPressed: _toggleRecording,
                isRecording: _isRecording,
              ),
              SizedBox(height: 15),
              PlayAudioButton(
                onPressed: _isPlaying ? null : _playRecording,
                isPlaying: _isPlaying,
              ),
              SizedBox(height: 15),
              ConfirmButton(
                onPressed: _recordingAvailable
                    ? () {
                        if (_currentIndex < audioStrings.length - 1) {
                          setState(() {
                            _currentIndex++;
                            currentWord = audioStrings[_currentIndex];
                            currentSound = audioInitialsStrings[_currentIndex];
                          });
                        } else {
                          print("All words completed!");
                        }
                        print(
                            'Audio confirmed for word: $currentWord, sound: $currentSound');
                      }
                    : null,
                isEnabled: _recordingAvailable,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
