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
import 'Word.dart';
import 'Listen.dart';
import 'Story.dart';
import 'swap.dart';

class LevelSelectionScreen extends StatefulWidget {
  @override
  _LevelSelectionScreenState createState() => _LevelSelectionScreenState();
  final User? user;

  const LevelSelectionScreen({Key? key, this.user}) : super(key: key);
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  List<bool> selectedLevels = List.generate(10, (_) => true); // Default all levels enabled
  final List<Color> numberColors = [
    Colors.red, Colors.orange, Colors.green, Colors.blue, Colors.purple,
    Colors.pink, Colors.teal, Colors.amber, Colors.deepPurple, Colors.lime
  ];

  @override
  Widget build(BuildContext context) {
    final filteredIndices = selectedLevels
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          S.of(context).games,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('uid'); // Clear stored UID
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
          /// **🔹 Navy Blue Gradient Background**
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade700, Color.fromARGB(255, 100, 25, 176)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          /// **🔸 Random Star Decorations**
          for (int i = 0; i < 15; i++)
            Positioned(
              left: Random().nextDouble() * MediaQuery.of(context).size.width,
              top: Random().nextDouble() * MediaQuery.of(context).size.height,
              child: Icon(
                Icons.star,
                color: Colors.yellow.shade600,
                size: Random().nextDouble() * 20 + 10, // Varying sizes
              ),
            ),

          /// **🧠 Brainu Icon at Bottom Right**
          Positioned(
            bottom: 10,
            right: 10,
            child: Image.asset(
              "assets/img/Brainu_icon.png",
              width: 110,
              height: 110,
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.5,
              ),
              itemCount: filteredIndices.length,
              itemBuilder: (context, index) {
                final levelIndex = filteredIndices[index]; // Original level index
                final displayedNumber = index + 1; // Sequential numbering (1, 2, 3...)

                return GestureDetector(
                  onTap: () {
                    Widget page;
                    switch (levelIndex) {
                      case 0:
                        page = Letter();
                        break;
                      case 1:
                        page = Identify();
                        break;
                      case 2:
                        page = Word();
                        break;
                      case 3:
                        page = Listen();
                        break;
                      case 4:
                        page = Story();
                        break;
                      case 5:
                        page = Swap();
                        break;
                      case 6:
                        page = Ph_deletion_final();
                        break;
                      case 7:
                        page = Ph_deletion_initial();
                        break;
                      case 8:
                        page = Ph_substitution_final();
                        break;
                      case 9:
                        page = Ph_substitution_initial();
                        break;
                      default:
                        return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
                  },
                  
                  /// **🎨 Circular Buttons with White Center Gradient**
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.white, Colors.lightBlueAccent.shade100, Colors.blue],
                        stops: [0.2, 0.6, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$displayedNumber', // Shows sequential number
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: numberColors[index % numberColors.length], // Uses index for color
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// **✨ Helper Method for Star Icons**
  Widget _starIcon({double size = 20}) {
    return Icon(
      Icons.star,
      color: Colors.yellow.shade600,
      size: size,
    );
  }
}
