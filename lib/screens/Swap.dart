import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/option_button.dart';
import '../components/submit_button.dart';

class Swap extends StatefulWidget {
  @override
  _SwapState createState() => _SwapState();
}

class _SwapState extends State<Swap> {
  String word1 = '';
  String word2 = '';
  List<String> options = [];
  String? selectedOption;
  bool isSubmitEnabled = false;
  AudioPlayer audioPlayer = AudioPlayer();
  int questionCounter = 0;
  int iterationCounter = 0;
  int trophyCount = 0; // Track total trophies
  Map<String, int> clickCountMap = {};

  List<List<String>> wordPairs = [
    ['Belly', 'Jeans'],
    ['Bean', 'Dust'],
    ['Bedding', 'Wells'],
    ['Town', 'Drain'],
    ['Waste', 'Hood'],
    ['Pew', 'Nose'],
    ['Nosy', 'Cook'],
    ['Mold', 'Food'],
    ['Most', 'Cold'],
    ['Fold', 'Trap'],
    ['Tick', 'Par'],
    ['Wish', 'Deep'],
    ['Care', 'Bar'],
    ['Sound', 'Ride'],
    ['Look', 'Take'],
    ['Kind', 'Male'],
    ['Came', 'Nap'],
    ['Save', 'Cage'],
    ['Lack', 'Band'],
    ['Feast', 'Ban'],
    ['Head', 'Dear'],
    ['Doggy', 'Fay'],
    ['Tot', 'Here'],
    ['Take', 'Fall'],
    ['Warm', 'Fire']
  ];

  List<List<String>> usedWordPairs = [];

  @override
  void initState() {
    super.initState();
    _loadTrophyCount(); // Load the trophy count when the level is loaded
    generateWords();
  }

  Future<void> _loadTrophyCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      trophyCount = prefs.getInt('trophyCount') ??
          0; // Default to 0 if no trophy count is stored
    });
  }

  Future<void> _saveTrophyCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trophyCount', trophyCount); // Save the trophy count
  }

  void generateWords() {
    if (wordPairs.isEmpty) {
      // All words used; show level completed
      setState(() {
        selectedOption = null;
        isSubmitEnabled = false;
        clickCountMap.clear();
      });
      showAllWordsDoneDialog();
      return;
    }

    Random random = Random();
    int index = random.nextInt(wordPairs.length);
    List<String> selectedPair = wordPairs.removeAt(index);
    usedWordPairs.add(selectedPair);

    word1 = selectedPair[0];
    word2 = selectedPair[1];

    generateOptions(word1, word2);

    setState(() {
      selectedOption = null;
      isSubmitEnabled = false;
      clickCountMap = {for (var option in options) option: 0};
    });
  }

  void generateOptions(String word1, String word2) {
    // Correct Answer
    String correctAnswer =
        '${word2[0]}${word1.substring(1)}_${word1[0]}${word2.substring(1)}_c.wav';

    // Distractors
    String distractor1 =
        '${word1[0]}${word1.substring(1)}_${word1[0]}${word2.substring(1)}.wav';
    String distractor2 =
        '${word2[0]}${word1.substring(1)}_${word2[0]}${word2.substring(1)}.wav';

    // Collect options and shuffle to randomize positions
    List<String> optionsList = [correctAnswer, distractor1, distractor2];
    optionsList.shuffle(Random()); // Randomly shuffle options

    setState(() {
      options = optionsList;
    });

    print('Generated options (shuffled): $options');
  }

  Future<void> playAudio(String option, [bool isOption = false]) async {
    try {
      String audioPath;

      if (isOption) {
        // The option already contains the correct filename, so use it as is.
        audioPath = 'audio/english/spoonerism/${option.toLowerCase()}';
      } else {
        // Construct path for individual words
        audioPath = 'audio/english/spoonerism/${option.toLowerCase()}.wav';
      }

      print('Playing audio: $audioPath');
      await audioPlayer.play(AssetSource(audioPath));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  void handleClick(String option) {
    setState(() {
      // Resetting previous option click count if it's a new selection
      if (selectedOption != null && selectedOption != option) {
        int previousCount = clickCountMap[selectedOption!] ?? 0;
        if (previousCount == 1 || previousCount == 2) {
          clickCountMap[selectedOption!] = 0;
        }
      }

      int currentCount = clickCountMap[option] ?? 0;
      if (currentCount == 0) {
        clickCountMap[option] = 1;
        // Play the correct option audio based on the selected option
        playAudio(option, true); // Pass the selected option for audio
      } else if (currentCount == 1) {
        clickCountMap[option] = 2;
        playAudio(option, true); // Play the option audio again on second click
      } else if (currentCount == 2) {
        clickCountMap[option] = 0; // Reset count after 2 clicks
      }

      selectedOption = (clickCountMap[option] == 0) ? null : option;
      isSubmitEnabled = clickCountMap.values.any((count) =>
          count >= 2); // Enable submit button if an option is selected
    });
  }

  void handleSubmit() {
    String correctAnswer =
        '${word2[0]}${word1.substring(1)}_${word1[0]}${word2.substring(1)}_c.wav';

    if (selectedOption == correctAnswer) {
      print('Correct Answer!');
    } else {
      print('Incorrect Answer.');
    }

    setState(() {
      questionCounter++;
      if (questionCounter == 5) {
        iterationCounter++;
        trophyCount++; // Increment trophy count
        _saveTrophyCount();
        questionCounter = 0;
        showIterationCompleteDialog();
      } else {
        generateWords();
      }
    });
  }

  void resetLevel() {
    setState(() {
      wordPairs.addAll(usedWordPairs);
      usedWordPairs.clear();
      questionCounter = 0;
      iterationCounter = 0;
    });
    generateWords();
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
                generateWords();
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

  void showAllWordsDoneDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('All Words Done!'),
          content: Text(
              'You have completed all words in this level. Reset to play again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetLevel();
              },
              child: Text('Reset Level'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Swap the Words'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Question Container with shadow
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
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
                'To help Brainu perform the Spoonerism Step, exchange the first letters of the pair of words and tell Brainu what the new pair is! Tap on the words to listen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Main game content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              playAudio(word1), // For playing individual words

                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
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
                              '${word1.substring(0, 1)}${word1.substring(1)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 30),
                        GestureDetector(
                          onTap: () =>
                              playAudio(word2), // For playing individual words
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
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
                              '${word2.substring(0, 1)}${word2.substring(1)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Wrap(
                      spacing: 20,
                      children: options.map((option) {
                        return OptionButton(
                          index: options.indexOf(option) + 1,
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
          ],
        ),
      ),
    );
  }
}
