import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // For audio playback
import '../components/option_button.dart';
import '../components/submit_button.dart';

class SwappingLevel extends StatefulWidget {
  @override
  _SwappingLevelState createState() => _SwappingLevelState();
}

class _SwappingLevelState extends State<SwappingLevel> {
  final String word1 = 'Mold';
  final String word2 = 'Food';
  final List<String> options = ['Mold_Mood', 'Fold_Food', 'Fold_Mood'];
  String? selectedOption;
  bool isSubmitEnabled = false;

  final AudioPlayer audioPlayer = AudioPlayer(); // Initialize audio player

  @override
  void initState() {
    super.initState();
    options.shuffle(); // Randomize the order of options
  }

  void playAudio(String fileName) async {
    try {
      await audioPlayer.play(AssetSource('$fileName.mp3')); // Play audio file
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  void handleClick(String option) {
    setState(() {
      selectedOption = option;
      isSubmitEnabled = true;
    });
    playAudio(option); // Play the corresponding audio
  }

  void handleSubmit() {
    if (selectedOption == 'Fold_Mood') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Correct!'),
          content: Text('You chose the correct answer: Fold_Mood'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  selectedOption = null;
                  isSubmitEnabled = false;
                });
              },
              child: Text('Next'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Wrong!'),
          content: Text('Try again!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Swapping Level'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Words with cloud-like decorations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCloud(word1),
                _buildCloud(word2),
              ],
            ),
            SizedBox(height: 40),
            // Option buttons
            // Wrap(
            //   spacing: 20,
            //   children: options.map((option) {
            //     int index = options.indexOf(option) + 1; // Button number
            //     return OptionButton(
            //       index: index,
            //       isSelected: selectedOption == option,
            //       color: selectedOption == option ? Colors.green : Colors.blue,
            //       onPressed: () => handleClick(option),
            //     );
            //   }).toList(),
            // ),
            SizedBox(height: 40),
            // Submit button
            SubmitButton(
              isEnabled: isSubmitEnabled,
              onPressed: handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  // Widget for a cloud-like structure around a word
  Widget _buildCloud(String word) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.lightBlue[100],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.normal,
            color: Colors.blue[900],
          ),
          children: [
            TextSpan(
              text: word[0], // First letter
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: word.substring(1), // Remaining letters
            ),
          ],
        ),
      ),
    );
  }
}
