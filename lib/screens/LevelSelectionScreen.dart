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
import 'Swap2.dart';
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
  List<bool> selectedLevels =
      List.generate(10, (_) => true); // Default all levels enabled

  @override
  Widget build(BuildContext context) {
    final filteredIndices = selectedLevels
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    int itemCount = filteredIndices.length;
    int crossAxisCount = 2; // Fixed to 2 columns for 2xN layout

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
        title: Text(S.of(context).games,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
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
            icon: Icon(
              Icons.menu,
              color: Colors.white,
            ),
            onPressed: () async {
              final result = await showDialog<List<bool>>(
                context: context,
                builder: (context) {
                  return SelectGameDialog(
                      initialSelectedLevels: selectedLevels);
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
      body: Padding(
        padding: EdgeInsets.all(10),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount, // Fixed to 2 columns
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5, // Adjust aspect ratio for better spacing
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final levelIndex = filteredIndices[index];

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
                    page = Swap2();
                    break;
                    case 6:
                    page = Swap();
                    break;
                  // case 6: temp chnaged for testing
                  //   page = Ph_deletion_final();
                  //   break;
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
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => page));
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
