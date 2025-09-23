import 'package:brainu/managers/trophy_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:vibration/vibration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  late Box<List> completedLevelsBox;
  late Box<List> assignedLevelsBox;
  Map<int, bool> _levelCompletionStatus = {};
  Map<int, bool> _levelUnlockedStatus = {};

  Stream<DocumentSnapshot>? _assignedListener; // 🔹 Firestore stream
  List<int> _currentAssigned = [];

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  @override
  void dispose() {
    super.dispose();
    // Cancel Firestore listener when screen is disposed
    _assignedListener = null;
  }

  Future<void> _initHive() async {
    completedLevelsBox = await Hive.openBox<List>('completedLevels');
    assignedLevelsBox = await Hive.openBox<List>('assignedLevels');

    List<int> completed =
        (completedLevelsBox.get('completed', defaultValue: []) ?? [])
            .cast<int>();
    List<int> assigned =
        (assignedLevelsBox.get('assigned', defaultValue: []) ?? []).cast<int>();

    _currentAssigned = assigned;

    for (int i = 0; i < levels.length; i++) {
      _levelCompletionStatus[i] = completed.contains(i);
      _levelUnlockedStatus[i] =
          i == 0 || _levelCompletionStatus[i - 1]! || assigned.contains(i);
    }

    _syncWithFirestore(completed, assigned);
    _listenForAssignedLevels(); // 🔹 Start real-time sync

    setState(() {});
  }

  Future<void> _syncWithFirestore(
      List<int> localCompleted, List<int> localAssigned) async {
    var connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none && widget.user != null) {
      var userDoc =
          FirebaseFirestore.instance.collection('users').doc(widget.user!.uid);

      DocumentSnapshot snapshot = await userDoc.get();

      List<dynamic> firestoreCompleted =
          (snapshot.data() as Map<String, dynamic>)['completedLevels'] ?? [];

      // 🔹 Delta sync for completed levels
      List<int> toUpdate = localCompleted
          .where((level) => !firestoreCompleted.contains(level))
          .toList();

      if (toUpdate.isNotEmpty) {
        await userDoc.update({
          'completedLevels': FieldValue.arrayUnion(toUpdate),
        });
      }
    }
  }

  void _listenForAssignedLevels() {
    if (widget.user == null) return;

    _assignedListener = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user!.uid)
        .snapshots();

    _assignedListener!.listen((snapshot) async {
      if (!snapshot.exists) return;

      List<dynamic> firestoreAssigned =
          (snapshot.data() as Map<String, dynamic>)['assignedLevels'] ?? [];

      List<int> newAssigned = firestoreAssigned.cast<int>();

      // 🔹 Only update if data changed
      if (newAssigned.toSet().difference(_currentAssigned.toSet()).isNotEmpty) {
        _currentAssigned = newAssigned;

        // Save to Hive
        await assignedLevelsBox.put('assigned', newAssigned);

        // Recalculate unlocks
        for (int i = 0; i < levels.length; i++) {
          _levelUnlockedStatus[i] = i == 0 ||
              _levelCompletionStatus[i - 1]! ||
              newAssigned.contains(i);
        }

        if (mounted) setState(() {});
      }
    });
  }

  void _markLevelCompleted(int index) async {
    _levelCompletionStatus[index] = true;

    if (index + 1 < levels.length) {
      _levelUnlockedStatus[index + 1] = true;
    }

    List<int> completed = _levelCompletionStatus.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    await completedLevelsBox.put('completed', completed);

    _syncWithFirestore(completed, _currentAssigned);

    setState(() {});
  }

  bool _isLocked(int index) {
    return !(_levelUnlockedStatus[index] ?? (index == 0));
  }

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
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/img/background.jpeg"),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.white.withOpacity(0.3),
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<TrophyManager>(
                  builder: (context, trophyManager, _) => Row(
                    children: [
                      Icon(Icons.emoji_events,
                          color: Colors.amber[700], size: 30),
                      const SizedBox(width: 4),
                      Text(
                        trophyManager.trophyCount.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
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
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.logout, color: Color(0xFFEE5B03)),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        await completedLevelsBox.clear();
                        await assignedLevelsBox.clear();
                        Navigator.pushReplacement(
                          context,
                          Navigation.generateRoute(
                              RouteSettings(name: '/login')),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.menu, color: Color(0xFFEE5B03)),
                      onPressed: () async {
                        final result = await showDialog<List<bool>>(
                          context: context,
                          builder: (context) => SelectGameDialog(
                              initialSelectedLevels: selectedLevels),
                        );
                        if (result != null) {
                          setState(() => selectedLevels = result);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            centerTitle: true,
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
    bool isLocked = _isLocked(levelIndex);

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
        onTap: () async {
          if (isLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Complete previous level or wait for admin assignment",
                ),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => levels[levelIndex]),
          );
          _markLevelCompleted(levelIndex);
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
              if (isLocked)
                Icon(Icons.lock, color: Colors.white, size: 40)
              else if (_levelCompletionStatus[levelIndex]!)
                Icon(Icons.check, color: Colors.white, size: 40)
              else
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
