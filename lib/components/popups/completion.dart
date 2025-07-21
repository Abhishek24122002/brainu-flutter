import 'package:flutter/material.dart';
import 'package:brainu/screens/LevelSelectionScreen.dart';
import 'package:brainu/generated/l10n.dart';

class CompletionDialog extends StatelessWidget {
  final VoidCallback onReset;

  const CompletionDialog({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevents back button dismissal
      child: AlertDialog(
        title: Text(S.of(context).Congratulation),
        content: Text(S.of(context).you_did_it),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onReset();
            },
            child: Text(S.of(context).restart),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LevelSelectionScreen()),
              );
            },
            child: Text(S.of(context).done),
          ),
        ],
      ),
    );
  }
}
