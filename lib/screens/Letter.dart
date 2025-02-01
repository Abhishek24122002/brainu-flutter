import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/option_button.dart';
import '../components/submit_button.dart';

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
  int iterationCounter = 0;
  bool _showGameElements = false; 
  int questionIndex = 0; // Track position in the list
  int trophyCount = 0; // Track total trophies

  List<List<String>> wordPairs = [
  ['A', 'a'],
  ['B', 'b'],
  ['C', 'c'],
  ['D', 'd'],
  ['E', 'e'],
  ['F', 'f'],
  ['G', 'g'],
  ['H', 'h'],
  ['I', 'i'],
  ['J', 'j'],
  ['K', 'k'],
  ['L', 'l'],
  ['M', 'm'],
  ['N', 'n'],
  ['O', 'o'],
  ['P', 'p'],
  ['Q', 'q'],
  ['R', 'r'],
  ['S', 's'],
  ['T', 't'],
  ['U', 'u'],
  ['V', 'v'],
  ['W', 'w'],
  ['X', 'x'],
  ['Y', 'y'],
  ['Z', 'z']
];

  @override
  void initState() {
    super.initState();
    generateQuestionAndOptions();

    audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          isAudioPlaying = false;

          // Reset only if button was red (not green)
          if (selectedOption != null &&
              (clickCountMap[selectedOption!] ?? 0) < 2) {
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
  if (questionIndex >= wordPairs.length) {
    questionIndex = 0; // Reset to start after reaching end
  }

  question = wordPairs[questionIndex][0]; // Display uppercase letter
  String correctAnswer = wordPairs[questionIndex][1]; // Corresponding lowercase letter

  Set<String> randomOptions = {correctAnswer};
  while (randomOptions.length < 3) {
    int randomOptionIndex = Random().nextInt(wordPairs.length);
    randomOptions.add(wordPairs[randomOptionIndex][1]); // Pick random lowercase letters
  }

  options = randomOptions.toList();
  options.shuffle();

  selectedOption = null;
  isSubmitEnabled = false;

  clickCountMap = {for (var option in options) option: 0};
  clickTimers = {for (var option in options) option: null};

  questionIndex++; // Move to the next letter for the next round
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
  Future<void> _loadTrophyCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      trophyCount = prefs.getInt('V_C_trophyCount') ??
          0; // Default to 0 if no trophy count is stored
    });
  }

  Future<void> _saveTrophyCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('V_C_trophyCount', trophyCount); // Save the trophy count
  }
void showIterationCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You Won!!!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 69, 20, 153),
                ),
              ),
              SizedBox(height: 20),
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 80,
              ),
              SizedBox(height: 20),
              Text(
                '$trophyCount', // Display the number of trophies
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // generateWords();
              },
              child: Text(
                'Continue',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        );
      },
    );
  }
  void handleSubmit() {
    setState(() {
      questionCounter++;
      _showGameElements = false;
      if (questionCounter == 5) {
        iterationCounter++;
        trophyCount++;
        _saveTrophyCount();
    questionCounter = 0;
        showIterationCompleteDialog();
        
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
      appBar: AppBar(iconTheme: IconThemeData( color: const Color.fromARGB(255, 255, 255, 255),),
        title: Text('Letter',style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Brainu is in a dense forest to identify different varieties of leaves and flowers. \n \n Help Brainu Identify the different consonants too. Listen to the options given and choose the correct one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            if (!_showGameElements)
            Container(
              margin: EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showGameElements = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color
                  padding: EdgeInsets.symmetric(vertical: 20), // Button height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity, // Full width button
                  child: Center(
                    child: Text(
                      "Click Here to Start",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 20),

            if (_showGameElements) ...[
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
        ]),
      ),
    );
  }
}
