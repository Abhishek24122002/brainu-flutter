// components/popups/completion.dart
import 'package:flutter/material.dart';
import 'package:brainu/screens/LevelSelectionScreen.dart';

class CompletionDialog extends StatelessWidget {
  final VoidCallback onReset;

  const CompletionDialog({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Congratulations!'),
      content: Text('You have completed all words.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onReset();
          },
          child: Text('Reset Words'),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LevelSelectionScreen()),
            );
          },
          child: Text('Next Level'),
        ),
      ],
    );
  }
}
