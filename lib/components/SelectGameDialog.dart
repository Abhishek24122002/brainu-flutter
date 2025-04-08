import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../generated/l10n.dart';
import 'done_button.dart';

class SelectGameDialog extends StatefulWidget {
  final List<bool> initialSelectedLevels;

  SelectGameDialog({required this.initialSelectedLevels});

  @override
  _SelectGameDialogState createState() => _SelectGameDialogState();
}

class _SelectGameDialogState extends State<SelectGameDialog> {
  late List<bool> selectedLevels;

  @override
  void initState() {
    super.initState();
    selectedLevels = List.from(widget.initialSelectedLevels);
  }

  @override
  Widget build(BuildContext context) {
    List<String> levelNames = [
      S.of(context).game_letter,
      S.of(context).game_identify,
      S.of(context).game_word,
      S.of(context).game_listen,
      S.of(context).game_story,
      S.of(context).game_swapping,
      S.of(context).game_word_game1,
      S.of(context).game_word_game2,
      S.of(context).game_word_game3,
      S.of(context).game_word_game4,
    ];

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Center(
        child: Stack(
          children: [
            // Stroke
            Text(
              S.of(context).select_your_games,
              style: GoogleFonts.fredokaOne(
                textStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = Color(0xFF71420E), // 🟤 Stroke color
                ),
              ),
            ),
            // Fill
            Text(
              S.of(context).select_your_games,
              style: GoogleFonts.fredokaOne(
                textStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFDA748), // 🟠 Fill color
                ),
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(levelNames.length, (index) {
            return CheckboxListTile(
              title: Text(
                levelNames[index],
                style: TextStyle(color: Color(0xFF71420E)), // 🟤 Text color
              ),
              value: selectedLevels[index],
              activeColor: Color(0xFF954305), // 🟠 Checkbox fill color
              checkColor: Colors.white,
              onChanged: (value) {
                setState(() {
                  selectedLevels[index] = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.trailing,
            );
          }),
        ),
      ),
      actions: [
        DoneButton(
          text: S.of(context).done,
          onPressed: () {
            Navigator.pop(context, selectedLevels);
          },
        ),
      ],
    );
  }
}
