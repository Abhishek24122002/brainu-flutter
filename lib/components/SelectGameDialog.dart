import 'package:flutter/material.dart';
import '../generated/l10n.dart';

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
      title: Text(S.of(context).select_your_games),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(levelNames.length, (index) {
            return CheckboxListTile(
              title: Text(levelNames[index]),
              value: selectedLevels[index],
              onChanged: (value) {
                setState(() {
                  selectedLevels[index] = value ?? false;
                });
              },
            );
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, selectedLevels);
          },
          child: Text(S.of(context).done),
        ),
      ],
    );
  }
}
