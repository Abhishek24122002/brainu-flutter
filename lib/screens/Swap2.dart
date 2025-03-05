import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../generated/l10n.dart';

class Swap2 extends StatefulWidget {
  @override
  _Swap2State createState() => _Swap2State();
}

class _Swap2State extends State<Swap2> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String userLanguage = 'english'; // Default language

  // Word pairs for both languages
  final List<List<String>> wordPairsEnglish = [
    ['Belly', 'Jeans', 'belly', 'jeans', 'jelly_beans_c', 'jelly_jeans', 'belly_beans'],
    ['Bean', 'Dust', 'bean', 'dust', 'dean_bust_c', 'dean_dust', 'bean_bust'],
    ['Bedding', 'Wells', 'bedding', 'wells', 'wedding_bells_c', 'bedding_bells', 'wedding_wells'],
    ['Town', 'Drain', 'town', 'drain', 'down_train_c', 'down_drain', 'town_train'],
    ['Waste', 'Hood', 'waste', 'hood', 'haste_wood_c', 'haste_hood', 'waste_wood'],
  ];

  final List<List<String>> wordPairsHindi = [
    ['कच्ची', 'सड़क', 'kachhi', 'sadak', 'sachhi_kadak', 'kachhi_kadak', 'sachii_sadak'],
    ['दाग', 'नाल', 'daag', 'naal', 'naag_daal', 'naag_naal', 'daag_daal'],
    ['आम', 'राजा', 'aam', 'raja', 'raam_aaja', 'raam_raja', 'aam_aaja'],
    ['अदला', 'बदली', 'adla', 'badli', 'badla_adli', 'badla_badli', 'adla_adli'],
    ['काल', 'ताज', 'kaal', 'taaj', 'taal_kaaj', 'taal_taaj', 'kaal_kaaj'],
    ['काला', 'नाम', 'kaala', 'naam', 'nala_kaam', 'nala_naam', 'kala_kaam'],
    ['शाम', 'कान', 'shaam', 'kaan', 'kaam_shaan', 'kaam_kaan', 'shaam_shaan'],
    ['काम', 'धान', 'kaam', 'dhaan', 'dhaam_kaan', 'kaam_kaan', 'dhaam_dhaan'],
    ['जली', 'गोभी', 'jali', 'gobhi', 'goli_jabhi', 'goli_gabhi', 'jali_jabhi'],
  ];

  int currentIndex = 0;

  Future<void> _getUserLanguage() async {
    setState(() {
      userLanguage = 'hindi'; // Change this to 'english' if needed
    });
  }

  Future<void> playAudio(String option, [bool isOption = false]) async {
    try {
      String audioPath = 'audio/$userLanguage/spoonerism/${option.toLowerCase()}.wav';
      print('Playing audio: $audioPath');
      await _audioPlayer.play(AssetSource(audioPath));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserLanguage(); // Fetch the user's language preference on startup
  }

  @override
  Widget build(BuildContext context) {
    List<List<String>> wordPairs = userLanguage == 'hindi' ? wordPairsHindi : wordPairsEnglish;
    List<String> currentPair = wordPairs[currentIndex];

    List<String> options = [currentPair[4], currentPair[5], currentPair[6]];
    options.shuffle(); // Shuffle options

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          S.of(context).game_swapping,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Question Container
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(15),
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
                S.of(context).spoonerism_question,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Display Word 1
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Word 1 Container
                GestureDetector(
                  onTap: () => playAudio(currentPair[2]),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                      currentPair[0],
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Word 2 Container
                GestureDetector(
                  onTap: () => playAudio(currentPair[3]),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                      currentPair[1],
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Answer options
            for (int i = 0; i < 3; i++)
              ElevatedButton(
                onPressed: () {
                  playAudio(options[i], true);
                  bool isCorrect = options[i] == currentPair[4];
                  print(isCorrect ? "Correct Answer" : "Wrong Answer");
                },
                child: Text(userLanguage == 'hindi' ? "विकल्प ${i + 1}" : "Option ${i + 1}"),
              ),
            SizedBox(height: 40),

            // Next button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentIndex = (currentIndex + 1) % wordPairs.length;
                });
              },
              child: Text(userLanguage == 'hindi' ? "अगला" : "Next"),
            ),
          ],
        ),
      ),
    );
  }
}
