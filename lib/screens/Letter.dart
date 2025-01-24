import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../components/option_button.dart';
import '../components/submit_button.dart';
import 'LevelSelectionScreen.dart';

class Letter extends StatefulWidget {
  @override
  _LetterState createState() => _LetterState();
}

class _LetterState extends State<Letter> {
  String question = '';
  List<String> options = [];
  bool isSubmitEnabled = false;
  String? selectedOption;
  Map<String, int> clickCountMap = {};
  Map<String, Timer?> clickTimers = {};
  AudioPlayer audioPlayer = AudioPlayer();
  bool isAudioPlaying = false;
  int questionCounter = 0;

  @override
  void initState() {
    super.initState();
    generateQuestionAndOptions();

    audioPlayer.onPlayerComplete.listen((_) {
  if (mounted) {
    setState(() {
      isAudioPlaying = false;
      
      // Reset only if button was red (not green)
      if (selectedOption != null && (clickCountMap[selectedOption!] ?? 0) < 2) {
        clickCountMap[selectedOption!] = 0; // Reset color to blue
        selectedOption = null; // Deselect button
      }

      // Ensure submit button stays active if any button is green
      isSubmitEnabled = clickCountMap.values.any((count) => count >= 2);
    });
  }
});

  }

  void generateQuestionAndOptions() {
    Random random = Random();
    question = String.fromCharCode(97 + random.nextInt(26));

    Set<String> randomOptions = {question};
    while (randomOptions.length < 3) {
      String randomAlphabet = String.fromCharCode(97 + random.nextInt(26));
      randomOptions.add(randomAlphabet);
    }

    options = randomOptions.toList();
    options.shuffle();

    selectedOption = null;
    isSubmitEnabled = false;

    clickCountMap = {for (var option in options) option: 0};
    clickTimers = {for (var option in options) option: null};
  }

  Future<void> playAudio(String alphabet) async {
    try {
      final audioPath = 'audio/english/v_and_c/$alphabet.wav';
      await audioPlayer.play(AssetSource(audioPath));
      setState(() {
        isAudioPlaying = true;
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void handleClick(String option) {
  setState(() {
    // Reset the previous red or green option to blue if a new option is clicked
    if (selectedOption != null && selectedOption != option) {
      int previousCount = clickCountMap[selectedOption!] ?? 0;
      if (previousCount == 1 || previousCount == 2) {
        clickCountMap[selectedOption!] = 0; // Reset previous option to blue
      }
    }

    // Update the click count for the current option
    int currentCount = clickCountMap[option] ?? 0;

    if (currentCount == 0) {
      // First click: make it red
      clickCountMap[option] = 1;
      playAudio(option); // Play audio on the first click
    } else if (currentCount == 1) {
      // Second click: make it green
      clickCountMap[option] = 2;
      playAudio(option); // Play audio on the second click
    } else if (currentCount == 2) {
      // Third click: reset to blue
      clickCountMap[option] = 0;
    }

    // Update the selected option
    selectedOption = (clickCountMap[option] == 0) ? null : option;

    // Enable the submit button if any button is green
    isSubmitEnabled = clickCountMap.values.any((count) => count >= 2);
  });
}





  void handleSubmit() {
    setState(() {
      questionCounter++;
      if (questionCounter == 5) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LevelSelectionScreen()),
        );
      } else {
        generateQuestionAndOptions();
      }
    });
  }

  @override
  void dispose() {
    clickTimers.values.forEach((timer) => timer?.cancel());
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Identify the Alphabet'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Question: What is this alphabet?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                question.toUpperCase(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 40),
              Wrap(
                spacing: 20,
                children: options.asMap().entries.map((entry) {
                  int index = entry.key + 1;
                  String option = entry.value;

                  return OptionButton(
                    index: index,
                    isSelected: selectedOption == option,
                    clickCount: clickCountMap[option] ?? 0,
                    onPressed: () => handleClick(option),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              SubmitButton(
                isEnabled: isSubmitEnabled,
                onPressed: handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
