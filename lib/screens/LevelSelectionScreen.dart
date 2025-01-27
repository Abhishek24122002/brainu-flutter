
import 'package:brainu/screens/Identify.dart';
import 'package:brainu/screens/Phonemene_deletetion_final.dart';

import 'package:flutter/material.dart';

import 'Letter.dart';
import 'Phonemene_deletetion_initial.dart';
import 'Phonemene_substitution_final.dart';
import 'Phonemene_substitution_initial.dart';
import 'Word.dart';
import 'Listen.dart';
import 'Story.dart';
import 'swap.dart';

class LevelSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Level'),
        backgroundColor: Colors.blueAccent,
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          bool isActive = index < 10; // Only first 10 levels are active
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.blue : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            ),
            onPressed: isActive
                ? () {
                    if (index == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Letter()),
                      );
                    } else if (index == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Identify()),
                      );
                    } else if (index == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Word()),
                      );
                    }
                    else if (index == 3) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Listen()),
                      );
                    }
                    else if (index == 4) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Story()),
                      );
                    }
                    else if (index == 5) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Swap()),
                      );
                    }
                    else if (index == 6) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Ph_deletion_final()),
                      );
                    }
                    else if (index == 7) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Ph_deletion_initial()),
                      );
                    }

                    else if (index == 8) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Ph_substitution_final()),
                      );
                    }

                    else if (index == 9) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Ph_substitution_initial()),
                      );
                    }
                  }
                : null,
            child: Text(
              'Level ${index + 1}',
              style: TextStyle(fontSize: 18),
            ),
          );
        },
      ),
    );
  }
}
