import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/appbar.dart';
import '../components/question_container.dart';
import '../components/start_button.dart';
import '../firebase/firebase_services.dart'; // Import your FirebaseServices file

import '../components/option_button.dart';
import '../components/submit_button.dart';
import '../generated/l10n.dart';
import 'package:google_fonts/google_fonts.dart';

class Swap extends StatefulWidget {
  @override
  _SwapState createState() => _SwapState();
}

class _SwapState extends State<Swap> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  String _userLanguage = "english"; // Default language

  String word1 = '';
  String word2 = '';
  String word3 = '';
  String word4 = '';
  String correct = '';
  String opt1 = '';
  String opt2 = '';
  List<String> options = [];
  String? selectedOption;
  bool isSubmitEnabled = false;
  AudioPlayer audioPlayer = AudioPlayer();
  int questionCounter = 0;
  int iterationCounter = 0;
  int trophyCount = 0; // Track total trophies
  bool _showGameElements = false;
  Map<String, int> clickCountMap = {};

  Map<String, List<List<String>>> wordPairsByLanguage = {
    "english": [
      [
        'Belly',
        'Jeans',
        'belly',
        'jeans',
        'jelly_beans_c',
        'jelly_jeans',
        'belly_beans'
      ],
      ['Bean', 'Dust', 'bean', 'dust', 'dean_bust_c', 'dean_dust', 'bean_bust'],
      [
        'Bedding',
        'Wells',
        'bedding',
        'wells',
        'wedding_bells_c',
        'bedding_bells',
        'wedding_wells'
      ],
      [
        'Town',
        'Drain',
        'town',
        'drain',
        'down_train_c',
        'down_drain',
        'town_train'
      ],
      [
        'Waste',
        'Hood',
        'waste',
        'hood',
        'haste_wood_c',
        'haste_hood',
        'waste_wood'
      ],
      ['Pew', 'Nose', 'pew', 'nose', 'new_pose_c', 'new_nose', 'pew_pose'],
      ['Nosy', 'Cook', 'nosy', 'cook', 'cosy_nook_c', 'nosy_nook', 'cosy_cook'],
      ['Mold', 'Food', 'mold', 'food', 'fold_mood_c', 'fold_food', 'mold_mood'],
      ['Most', 'Cold', 'most', 'cold', 'cost_mold_c', 'cost_cold', 'most_mold'],
      ['Fold', 'Trap', 'fold', 'trap', 'told_frap_c', 'told_trap', 'fold_frap'],
      ['Tick', 'Par', 'tick', 'par', 'pick_tar_c', 'pick_par', 'tick_tar'],
      ['Wish', 'Deep', 'wish', 'deep', 'dish_weep_c', 'dish_deep', 'wish_weep'],
      ['Care', 'Bar', 'care', 'bar', 'bare_car_c', 'bare_bar', 'care_car'],
      [
        'Sound',
        'Ride',
        'sound',
        'ride',
        'round_side_c',
        'round_ride',
        'sound_side'
      ],
      ['Look', 'Take', 'look', 'take', 'took_lake_c', 'took_take', 'look_lake'],
      ['Kind', 'Male', 'kind', 'male', 'mind_kale_c', 'mind_male', 'kind_kale'],
      ['Came', 'Nap', 'came', 'nap', 'name_cap_c', 'came_cap', 'name_nap'],
      ['Save', 'Cage', 'save', 'cage', 'cave_sage_c', 'cave_cage', 'save_sage'],
      ['Lack', 'Band', 'lack', 'band', 'back_land_c', 'back_band', 'lack_land'],
      ['Feast', 'Ban', 'feast', 'ban', 'beast_fan_c', 'beast_ban', 'feast_fan'],
      ['Head', 'Dear', 'head', 'dear', 'dead_hear_c', 'dead_dear', 'head_hear'],
      ['Doggy', 'Fay', 'doggy', 'fay', 'foggy_day_c', 'foggy_fay', 'doggy_day'],
      ['Tot', 'Here', 'tot', 'here', 'hot_tere_c', 'hot_here', 'tot_tere'],
      ['Take', 'Fall', 'take', 'fall', 'fake_tall_c', 'fake_fall', 'take_tall'],
      ['Warm', 'Fire', 'warm', 'fire', 'farm_wire_c', 'farm_fire', 'warm_wire']
    ],
    "hindi": [
      [
        'कच्ची',
        'सड़क',
        'kachhi',
        'sadak',
        'sachhi_kadak',
        'kachhi_kadak',
        'sachii_sadak'
      ],
      ['दाग', 'नाल', 'daag', 'naal', 'naag_daal', 'naag_naal', 'daag_daal'],
      ['आम', 'राजा', 'aam', 'raja', 'raam_aaja', 'raam_raja', 'aam_aaja'],
      [
        'अदला',
        'बदली',
        'adla',
        'badli',
        'badla_adli',
        'badla_badli',
        'adla_adli'
      ],
      ['काल', 'ताज', 'kaal', 'taaj', 'taal_kaaj', 'taal_taaj', 'kaal_kaaj'],
      ['काला', 'नाम', 'kaala', 'naam', 'nala_kaam', 'nala_naam', 'kala_kaam'],
      ['शाम', 'कान', 'shaam', 'kaan', 'kaam_shaan', 'kaam_kaan', 'shaam_shaan'],
      ['काम', 'धान', 'kaam', 'dhaan', 'dhaam_kaan', 'kaam_kaan', 'dhaam_dhaan'],
      [
        'जली',
        'गोभी',
        'jali',
        'gobhi',
        'goli_jabhi',
        'goli_gabhi',
        'jali_jabhi'
      ],
    ]
  };
  Widget _buildWordContainer(String word) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/img/Spoonerism_btn.png',
          height: 100,
          fit: BoxFit.contain,
        ),
        // Stroke
        Text(
          word,
          style: GoogleFonts.fredokaOne(
            fontSize: 32,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..color = Color(0xFF4C1C07), // Stroke color
          ),
        ),
        // Fill
        Text(
          word,
          style: GoogleFonts.fredokaOne(
            fontSize: 32,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 227, 122, 42), // Fill color
          ),
        ),
      ],
    );
  }

  List<List<String>> usedWordPairs = [];

  @override
  void initState() {
    super.initState();
    _loadTrophyCount(); // Load the trophy count when the level is loaded
    _fetchUserLanguage();
  }

  Future<void> _fetchUserLanguage() async {
    String language = await _firebaseServices.getUserLanguage();
    setState(() {
      _userLanguage = language;
      generateWords(); // Call generateWords() after setting language
    });
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
    if (wordPairsByLanguage[_userLanguage] == null ||
        wordPairsByLanguage[_userLanguage]!.isEmpty) {
      showAllWordsDoneDialog();
      return;
    }

    Random random = Random();
    int index = random.nextInt(wordPairsByLanguage[_userLanguage]!.length);
    List<String> selectedPair =
        List.from(wordPairsByLanguage[_userLanguage]![index]);
    usedWordPairs.add(selectedPair);

    word1 = selectedPair[0];
    word2 = selectedPair[1];
    word3 = selectedPair[2];
    word4 = selectedPair[3];
    correct = selectedPair[4];
    opt1 = selectedPair[5];
    opt2 = selectedPair[6];

    generateOptions(correct);
    setState(() {
      selectedOption = null;
      isSubmitEnabled = false;
      clickCountMap.clear();
    });
  }

  void generateOptions(correct) {
    // Correct Answer
    String correctAnswer = '$correct.wav';

    // Distractors
    String distractor1 = '$opt1.wav';
    String distractor2 = '$opt2.wav';

    // Collect options and shuffle to randomize positions
    List<String> optionsList = [correctAnswer, distractor1, distractor2];
    optionsList.shuffle(Random()); // Randomly shuffle options

    setState(() {
      options = optionsList;
    });

    print('Generated options (shuffled): $options');
  }

//using language variable
  Future<void> playAudio(String option, [bool isOption = false]) async {
    try {
      String audioPath;

      audioPath =
          'audio/$_userLanguage/spoonerism/${option.toLowerCase()}${isOption ? '' : '.wav'}';

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

  Future<void> _storeAnswer(String correctAnswer, bool isCorrect) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userId = user.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("6 Swapping")
        .doc(_userLanguage) // Store answer under the correct language
        .set({correctAnswer: isCorrect}, SetOptions(merge: true));
  }

  void handleSubmit() async {
    String correctAnswer = '$correct.wav';
    bool isCorrect = selectedOption == correctAnswer;

    // Increase trophy count for correct answers
    if (isCorrect) {
      trophyCount++;
      _saveTrophyCount();
    }

    // Store answer in Firebase
    await _storeAnswer(correctAnswer, isCorrect);

    setState(() {
      questionCounter++;
      _showGameElements = false; // Hide elements after submitting

      if (questionCounter == 5) {
        iterationCounter++;
        questionCounter = 0;
        showIterationCompleteDialog();
      } else {
        generateWords();
      }
    });
  }

  void resetLevel() {
    setState(() {
      if (usedWordPairs.isNotEmpty) {
        wordPairsByLanguage[_userLanguage]?.addAll(usedWordPairs);
        usedWordPairs.clear();
      }
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
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/img/Spoonerism_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(titleKey: 'spoonerism'),
          body: Column(
            children: [
              CustomContainer(text: S.of(context).spoonerism_question),
              if (!_showGameElements)
                StartButton(
                  onPressed: () {
                    setState(() {
                      _showGameElements = true;
                      generateWords(); // Generate words when the game starts
                    });
                  },
                ),
              // Main game content
              if (_showGameElements)
                Expanded(
                  child: Stack(
                    children: [
                      // Positioning the two boards slightly upward and aligned to left/right
                      // Left board (shift word slightly right and down)
                      Positioned(
                        top: MediaQuery.of(context).size.height * 0.15,
                        left: 0,
                        child: GestureDetector(
                          onTap: () => playAudio(word3),
                          child: _buildWordContainer(word1),
                        ),
                      ),

// Right board (shift word slightly left and down)
                      Positioned(
                        top: MediaQuery.of(context).size.height * 0.15,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => playAudio(word4),
                          child: _buildWordContainer(word2),
                        ),
                      ),

                      // Center options below boards
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.25),
                            Wrap(
                              spacing: 20,
                              alignment: WrapAlignment.center,
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
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
