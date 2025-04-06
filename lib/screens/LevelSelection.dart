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
import 'Word.dart';
import 'Listen.dart';
import 'Story.dart';
import 'swap.dart';

class LevelSelection extends StatefulWidget {
  @override
  _LevelSelectionState createState() => _LevelSelectionState();
}

class _LevelSelectionState extends State<LevelSelection> {
  List<bool> selectedLevels = List.generate(10, (_) => true); // Default: all selected

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
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(S.of(context).games, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('uid');
              Navigator.pushReplacement(
                context,
                Navigation.generateRoute(RouteSettings(name: '/login')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () async {
              final result = await showDialog<List<bool>>(
                context: context,
                builder: (context) {
                  return SelectGameDialog(initialSelectedLevels: selectedLevels);
                },
              );

              if (result != null) {
                setState(() {
                  selectedLevels = result;
                });
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/img/background.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildRow(context, [0, 1, 2]),
              _buildRow(context, [3, 4, 5]),
              _buildRow(context, [6, 7, 8]),
              _buildRow(context, [null, 9, null]),
              SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<int?> indices) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: indices.map((index) {
        if (index == null || !selectedLevels[index]) return SizedBox(width: 80);
        return _buildButton(context, index);
      }).toList(),
    );
  }

  Widget _buildButton(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => levels[index]),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/img/button.png',
              width: 80,
              height: 80,
            ),
            Text(
              (index + 1).toString(),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B2F00),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
