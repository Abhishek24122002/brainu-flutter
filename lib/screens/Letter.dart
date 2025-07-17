import 'dart:async';
import 'dart:math';
import 'package:brainu/firebase/firebase_save_answer.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/appbar.dart';
import '../components/option_button.dart';
import '../components/question_container.dart';
import '../components/start_button.dart';
import '../components/submit_button.dart';
import '../firebase/firebase_services.dart';
import '../generated/l10n.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:brainu/managers/trophy_manager.dart';
import 'package:provider/provider.dart';

class Letter extends StatefulWidget {
  @override
  _LetterState createState() => _LetterState();
}

class _LetterState extends State<Letter> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final FirebaseSave _firebaseSave = FirebaseSave();
  late String userLanguage = "english"; // Default to English
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
  int questionIndex = 0;
  int trophyCount = 0;

  final GlobalKey _startButtonKey = GlobalKey();
  bool _hasShownShowcase = false;

  List<List<String>> englishWordPairs = [
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

  List<List<String>> hindiWordPairs = [
    ['आ', 'aa'],
    ['च', 'ch'],
    ['छ', 'chh'],
    ['ई', 'ee'],
    ['ग', 'g'],
    ['घ', 'gh'],
    ['ज', 'j'],
    ['झ', 'jh'],
    ['क', 'k'],
    ['ख', 'kh'],
    ['ओ', 'o'],
    ['ऊ', 'oo'],
    ['ट', 'ta'],
    ['ठ', 'tha'],
    ['औ', 'aou'],
    ['क्ष', 'sha'],
    ['ढ', 'dha'],
    ['त', 't'],
    ['ड', 'da'],
    ['थ', 'th'],
    ['न', 'n'],
    ['फ', 'ph'],
    ['ल', 'l'],
    ['र', 'r'],
    ['इ', 'ee'],
    ['द', 'd'],
    ['प', 'p'],
    ['म', 'm'],
    ['स', 's'],
    ['ह', 'h'],
    ['य', 'y'],
    ['ब', 'b'],
    ['ण', 'n_n'],
    ['ष', 'sh_s'],
    ['भ', 'bh'],
    ['श', 'sh_sh'],
    ['त्र', 'tra'],
    ['ऐ', 'a'],
    ['ऋ', 'ri'],
    ['ज्ञ', 'gya'],
    ['अं', 'am'],
    ['ए', 'ae'],
    ['री', 'ree'],
    ['सि', 'si'],
    ['कु', 'ku'],
    ['मू', 'mu'],
    ['उ', 'u'],
    ['खी', 'khi'],
    ['चू', 'chu'],
    ['मि', 'mi'],
    ['हु', 'hu'],
    ['बी', 'bi'],
    ['ले', 'le'],
    ['म्रे', 'mre'],
    ['चि', 'chi'],
    ['ने', 'ne'],
    ['जा', 'jaa'],
    ['टी', 'ti'],
    ['डा', 'da'],
    ['थे', 'the'],
    ['से', 'se'],
    ['बा', 'baa'],
    ['गु', 'gu'],
    ['फै', 'fai'],
    ['ती', 'tii'],
    ['रा', 'ra'],
    ['पु', 'pu'],
    ['सो', 'so'],
    ['वी', 'vi'],
    ['शू', 'shu'],
    ['र्म', 'mre'],
    ['प्र', 'pr'],
    ['कृ', 'kre']
  ];
  Future<void> _checkAndShowShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool('seen_vc_start_showcase') ?? false;

    if (!seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context).startShowCase([_startButtonKey]);
      });
      await prefs.setBool('seen_vc_start_showcase', true);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserLanguage();
    _checkAndShowShowcase();

    audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          isAudioPlaying = false;
          if (selectedOption != null &&
              (clickCountMap[selectedOption!] ?? 0) < 2) {
            clickCountMap[selectedOption!] = 0;
            selectedOption = null;
          }
          isSubmitEnabled = clickCountMap.values.any((count) => count >= 2);
        });
      }
    });
    loadProgress().then((_) {
      loadTrophyCount().then((_) {
        generateQuestionAndOptions();
      });
    });
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('V_C_questionIndex', questionIndex);
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    questionIndex = prefs.getInt('V_C_questionIndex') ?? 0;
  }

  Future<void> loadTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    int trophyC = trophyManager.trophyCount;
    trophyCount = trophyC;
  }

  Future<void> playAudio(String alphabet) async {
    try {
      final audioPath = 'audio/$userLanguage/v_and_c/$alphabet.wav';
      await audioPlayer.play(AssetSource(audioPath));
      setState(() {
        isAudioPlaying = true;
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> _saveTrophyCount() async {
    final trophyManager = Provider.of<TrophyManager>(context, listen: false);
    trophyManager.increase(); // this updates the provider

    // Now refresh local trophyCount from provider
    setState(() {
      trophyCount = trophyManager.trophyCount;
    });

    // Optionally also save to Firebase if needed:
    await trophyManager.saveToFirebase();
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
                '${Provider.of<TrophyManager>(context).trophyCount}', // Display the number of trophies
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
              onPressed: () async {
                Navigator.of(context).pop();
                // generateWords();
                final prefs = await SharedPreferences.getInstance();
                if (questionIndex >= wordPairs.length) {
                  await prefs.setInt('V_C_questionIndex', 0);
                }
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

  void generateQuestionAndOptions() {
    if (questionIndex >= wordPairs.length) {
      questionIndex = 0;
    }

    question = wordPairs[questionIndex][0];
    String correctAnswer = wordPairs[questionIndex][1];

    Set<String> randomOptions = {correctAnswer};
    while (randomOptions.length < 3) {
      int randomIndex = Random().nextInt(wordPairs.length);
      randomOptions.add(wordPairs[randomIndex][1]);
    }

    options = randomOptions.toList();
    options.shuffle();

    selectedOption = null;
    isSubmitEnabled = false;

    clickCountMap = {for (var option in options) option: 0};
    clickTimers = {for (var option in options) option: null};
  }

  String getHindiCharacterFromOption(String option) {
    for (var pair in hindiWordPairs) {
      if (pair[1] == option) {
        return pair[0]; // Return the Hindi character
      }
    }
    return option; // fallback
  }

  late List<List<String>> wordPairs = englishWordPairs; // Default is English

  Future<void> _fetchUserLanguage() async {
    userLanguage = await _firebaseServices.getUserLanguage();
    setState(() {
      wordPairs = userLanguage == "hindi" ? hindiWordPairs : englishWordPairs;
      generateQuestionAndOptions(); // Regenerate based on the new list
    });
  }

  Future<void> saveAnswer_Letter(bool isCorrect, String? selectedOption) async {
    String optionToSend = selectedOption!;
    if (userLanguage == "hindi") {
      optionToSend = getHindiCharacterFromOption(selectedOption);
    }
    await _firebaseSave.saveAnswer_Letter(
        question, isCorrect, optionToSend, userLanguage);
  }

  void handleClick(String option) {
    setState(() {
      if (selectedOption != null && selectedOption != option) {
        int previousCount = clickCountMap[selectedOption!] ?? 0;
        if (previousCount == 1 || previousCount == 2) {
          clickCountMap[selectedOption!] = 0;
        }
      }

      int currentCount = clickCountMap[option] ?? 0;

      if (currentCount == 0) {
        clickCountMap[option] = 1;
        playAudio(option);
      } else if (currentCount == 1) {
        clickCountMap[option] = 2;
        playAudio(option);
      } else if (currentCount == 2) {
        clickCountMap[option] = 0;
      }

      selectedOption = (clickCountMap[option] == 0) ? null : option;
      isSubmitEnabled = clickCountMap.values.any((count) => count >= 2);
    });
  }

  void handleSubmit() {
    bool isCorrect = selectedOption == wordPairs[questionIndex][1];
    saveAnswer_Letter(isCorrect, selectedOption);

    setState(() {
      questionCounter++;
      _showGameElements = false;
      questionIndex++;
      saveProgress();

      if (questionCounter == 5) {
        iterationCounter++;

        _saveTrophyCount();
        questionCounter = 0;

        showIterationCompleteDialog();

        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              generateQuestionAndOptions();
            });
          }
        });
      } else {
        setState(() {
          generateQuestionAndOptions();
        });
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
    return ShowCaseWidget(
        builder: Builder(
            builder: (context) => Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset('assets/img/Letter_bg.png',
                          fit: BoxFit.cover),
                    ),
                    Scaffold(
                      backgroundColor: Colors.transparent, // Important!
                      appBar: CustomAppBar(titleKey: 'letter'),

                      body: Column(
                        children: [
                          CustomContainer(
                              text: S.of(context).vc_starting_question),
                          if (!_showGameElements)
                            StartButton(
                              onPressed: () {
                                setState(() {
                                  _showGameElements = true;
                                });
                              },
                            ),
                          if (_showGameElements)
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  double screenWidth = constraints.maxWidth;
                                  double imageSize =
                                      screenWidth * 0.55; // Scales for tablet
                                  double fontSize = screenWidth *
                                      0.15; // Responsive font size
                                  double spacing = screenWidth *
                                      0.04; // Spacing between options

                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/img/Letter_brainu.png',
                                              width: imageSize,
                                              height: imageSize,
                                              fit: BoxFit.contain,
                                            ),
                                            Positioned(
                                              bottom: 20,
                                              child: Text(
                                                question.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF7B2F00),
                                                  backgroundColor: Colors.white
                                                      .withOpacity(1),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: spacing),
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: spacing,
                                          runSpacing: spacing / 2,
                                          children: options
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            int index = entry.key + 1;
                                            String option = entry.value;

                                            return OptionButton(
                                              index: index,
                                              isSelected:
                                                  selectedOption == option,
                                              clickCount:
                                                  clickCountMap[option] ?? 0,
                                              onPressed: () =>
                                                  handleClick(option),
                                            );
                                          }).toList(),
                                        ),
                                        SizedBox(height: spacing),
                                        SubmitButton(
                                          isEnabled: isSubmitEnabled,
                                          onPressed: handleSubmit,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                )));
  }
}
