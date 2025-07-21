// components/popups/trophy.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brainu/managers/trophy_manager.dart';
import 'package:brainu/generated/l10n.dart';

class TrophyDialog extends StatelessWidget {
  const TrophyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final trophyCount = Provider.of<TrophyManager>(context).trophyCount;

    return AlertDialog(
      contentPadding: EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.of(context).you_won,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 69, 20, 153),
            ),
          ),
          SizedBox(height: 20),
          Icon(Icons.emoji_events, color: Colors.amber, size: 80),
          SizedBox(height: 20),
          Text(
            '$trophyCount',
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).done, style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
