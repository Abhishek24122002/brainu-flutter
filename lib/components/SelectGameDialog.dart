import 'package:flutter/material.dart';

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
    // Initialize with the passed-in selected levels
    selectedLevels = List.from(widget.initialSelectedLevels);
  }

  List<String> levelNames = [
    'Letter',
    'Identify',
    'Word',
    'Listen',
    'Story',
    'Swapping',
    'Word Game 1',
    'Word Game 2',
    'Word Game 3',
    'Word Game 4'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Levels'),
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
            Navigator.pop(context, selectedLevels); // Pass selected levels back
          },
          child: Text('Done'),
        ),
      ],
    );
  }
}
