import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Authentication/navigation.dart';
import '../components/SelectGameDialog.dart';
import '../generated/l10n.dart';
import 'Letter.dart';
import 'Identify.dart';
import 'Phonemene_deletetion_final.dart';
import 'Phonemene_deletetion_initial.dart';
import 'Phonemene_substitution_final.dart';
import 'Phonemene_substitution_initial.dart';
import 'LevelSelection.dart';
import 'Word.dart';
import 'Listen.dart';
import 'Story.dart';
import 'swap.dart';

import 'package:vibration/vibration.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class LevelSelectionScreen extends StatefulWidget {
  final User? user;

  const LevelSelectionScreen({Key? key, this.user}) : super(key: key);

  @override
  _LevelSelectionScreenState createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  List<bool> selectedLevels = List.generate(10, (_) => true);
  int? _tappedButtonIndex;

  final List<Widget> levels = [
    Letter(),
    Identify(),
    Word(),
    Listen(),
    Story(),
    Swap(),
    Ph_deletion_final(),
    Ph_deletion_initial(),
    Ph_substitution_final(),
    Ph_substitution_initial(),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleIndices = selectedLevels
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    return Stack(
      children: [
        // 🖼 Background image
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/img/background.jpeg"),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // 🧠 Main UI
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.white.withOpacity(0.3),
            elevation: 0,
            title: Stack(
              children: [
                Text(
                  S.of(context).games,
                  style: GoogleFonts.fredokaOne(
                    textStyle: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3
                        ..color = Color(0xFF954305),
                    ),
                  ),
                ),
                Text(
                  S.of(context).games,
                  style: GoogleFonts.fredokaOne(
                    textStyle: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFDA748),
                    ),
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Color(0xFFEE5B03)),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove('uid');
                  Navigator.pushReplacement(
                    context,
                    Navigation.generateRoute(RouteSettings(name: '/login')),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.menu, color: Color(0xFFEE5B03)),
                onPressed: () async {
                  final result = await showDialog<List<bool>>(
                    context: context,
                    builder: (context) =>
                        SelectGameDialog(initialSelectedLevels: selectedLevels),
                  );
                  if (result != null) {
                    setState(() => selectedLevels = result);
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildButtonRows(context, visibleIndices),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildButtonRows(
      BuildContext context, List<int> visibleIndices) {
    List<Widget> rows = [];
    int total = visibleIndices.length;
    int number = 1;
    List<int> config;

    switch (total) {
      case 1:
        config = [0, 1];
        break;
      case 2:
        config = [0, 2];
        break;
      case 3:
        config = [0, 3];
        break;
      case 4:
        config = [0, 2, 2];
        break;
      case 5:
        config = [0, 3, 2];
        break;
      case 6:
        config = [0, 3, 3];
        break;
      case 7:
        config = [3, 2, 2];
        break;
      case 8:
        config = [3, 3, 2];
        break;
      case 9:
        config = [3, 3, 3];
        break;
      default:
        config = [3, 3, 3, 1];
    }

    int current = 0;
    for (int rowCount in config) {
      if (rowCount == 0) continue;
      List<Widget> row = [];
      for (int i = 0; i < rowCount; i++) {
        if (current >= total) break;
        int index = visibleIndices[current];
        row.add(_buildNumberedButton(context, index, number));
        current++;
        number++;
      }
      rows.add(Row(
        mainAxisAlignment: rowCount < 3
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceEvenly,
        children: row,
      ));
      rows.add(SizedBox(height: 16));
    }
    return rows;
  }

  Widget _buildNumberedButton(
      BuildContext context, int levelIndex, int number) {
    bool isTapped = _tappedButtonIndex == levelIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTapDown: (_) async {
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(duration: 50);
          }
          setState(() => _tappedButtonIndex = levelIndex);
        },
        onTapUp: (_) async {
          await Future.delayed(Duration(milliseconds: 100));
          setState(() => _tappedButtonIndex = null);
        },
        onTapCancel: () {
          setState(() => _tappedButtonIndex = null);
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => levels[levelIndex]),
          );
        },
        child: AnimatedScale(
          scale: isTapped ? 0.9 : 1.0,
          duration: Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/img/button.png',
                width: 80,
                height: 80,
              ),
              Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B2F00),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
