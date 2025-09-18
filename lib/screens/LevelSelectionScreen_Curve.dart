import 'package:brainu/managers/trophy_manager.dart';
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
import 'package:vibration/vibration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../components/PathPainter.dart';
import 'dart:math';

class LevelSelectionScreen extends StatefulWidget {
  final User? user;

  const LevelSelectionScreen({Key? key, this.user}) : super(key: key);

  @override
  _LevelSelectionScreenState createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  final int numberOfLevels = 10;

  late List<bool> selectedLevels;
  int? _tappedButtonIndex;

  late Map<int, bool> _levelCompletionStatus;

  final _scrollController = ScrollController();

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
//   final List<Widget> levels = [
//   Letter(level: 1),
//   Identify(level: 2),
//   Word(level: 3),
//   Listen(level: 4),
//   Story(level: 5),
//   Swap(level: 6),
//   Ph_deletion_final(level: 7),
//   Ph_deletion_initial(level: 8),
//   Ph_substitution_final(level: 9),
//   Ph_substitution_initial(level: 10),
// ];


  @override
  void initState() {
    super.initState();
    selectedLevels = List.generate(numberOfLevels, (_) => true);
    _levelCompletionStatus = Map.fromIterable(
      List.generate(numberOfLevels, (i) => i),
      key: (i) => i,
      value: (i) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToHighestUnlocked();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // New method to calculate button positions dynamically based on screen size
  List<Offset> _calculateLevelPositions(
      BuildContext context, int numberOfVisibleLevels) {
    final size = MediaQuery.of(context).size;
    final double pathWidth = size.width * 0.7;
    final double pathStartFromEdge = size.width * 0.15;
    final double verticalStep = 120.0;

    List<Offset> positions = [];
    for (int i = 0; i < numberOfVisibleLevels; i++) {
      // Mirror the "S" shape by negating the sine function's result
      final double x = pathStartFromEdge +
          pathWidth / 2 -
          (pathWidth / 2 * sin(i * 1.0)); // Changed '+' to '-'
      final double y = verticalStep * i + 100.0;
      positions.add(Offset(x, y));
    }
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    final visibleIndices = selectedLevels
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final visibleLevelPositions =
        _calculateLevelPositions(context, visibleIndices.length);

    final double contentHeight = visibleLevelPositions.last.dy + 150.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.3),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Consumer<TrophyManager>(
              builder: (context, trophyManager, _) => Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber[700], size: 30),
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
                  icon: Icon(Icons.bug_report, color: Colors.blue),
                  onPressed: () {
                    // 🔑 Toggle all levels lock/unlock for testing
                    setState(() {
                      bool anyUnlocked =
                          _levelCompletionStatus.containsValue(true);
                      if (anyUnlocked) {
                        // Lock all
                        _levelCompletionStatus.updateAll((key, value) => false);
                      } else {
                        // Unlock all
                        _levelCompletionStatus.updateAll((key, value) => true);
                      }
                    });
                  },
                ),
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
      body: Stack(
        children: [
          // Fixed background image
          Positioned.fill(
            child: Image.asset(
              "assets/img/background.jpeg",
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // Scrollable content with the level path and buttons
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: contentHeight,
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: PathPainter(visibleLevelPositions),
                        child: Container(),
                      ),
                      ..._buildMapButtons(
                          context, visibleLevelPositions, visibleIndices),
                      _buildCharacter(visibleLevelPositions, visibleIndices),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Future<bool> isLevelUnlocked(int level) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('levelUnlocked_$level') ?? (level == 0); // level 0 always unlocked
}

  List<Widget> _buildMapButtons(BuildContext context,
      List<Offset> levelPositions, List<int> visibleIndices) {
    List<Widget> buttons = [];
    for (int i = 0; i < levelPositions.length; i++) {
      int actualLevelIndex = visibleIndices[i];
     buttons.add(
  FutureBuilder<bool>(
    future: isLevelUnlocked(actualLevelIndex),
    builder: (context, snapshot) {
      bool isLocked = !(snapshot.data ?? (actualLevelIndex == 0));
      return Positioned(
        left: levelPositions[i].dx,
        top: levelPositions[i].dy,
        child: Transform.translate(
          offset: Offset(-40, -40),
          child: _buildLevelButton(context, actualLevelIndex, i + 1, isLocked),
        ),
      );
    },
  ),
);

    }
    return buttons;
  }

  Widget _buildLevelButton(
      BuildContext context, int levelIndex, int number, bool isLocked) {
    Color buttonColor;
    IconData? icon;

    if (_levelCompletionStatus[levelIndex]!) {
      buttonColor = Colors.green;
      icon = Icons.check;
    } else if (isLocked) {
      buttonColor = Colors.grey[400]!;
      icon = Icons.lock;
    } else {
      buttonColor = Colors.orange;
      icon = null;
    }

    bool isTapped = _tappedButtonIndex == levelIndex;

    return GestureDetector(
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
      onTap: isLocked
          ? null
          : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
  // if (levels[levelIndex] is Letter) {
  //   return Letter(level: levelIndex); // ✅ pass level
  // }
  return levels[levelIndex];
}),

              );
              setState(() {
                _levelCompletionStatus[levelIndex] = true;
              });
            },
      child: AnimatedScale(
        scale: isTapped ? 0.9 : 1.0,
        duration: Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: buttonColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 40, color: Colors.white)
              : Text(
                  number.toString(),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCharacter(
      List<Offset> levelPositions, List<int> visibleIndices) {
    int lastUnlockedIndex = -1;
    for (int i = 0; i < _levelCompletionStatus.length; i++) {
      if (_levelCompletionStatus[i]!) {
        lastUnlockedIndex = i;
      } else {
        break;
      }
    }

    int visibleCharacterIndex;

    if (lastUnlockedIndex >= 0 && visibleIndices.contains(lastUnlockedIndex)) {
      visibleCharacterIndex = visibleIndices.indexOf(lastUnlockedIndex);
    } else if (visibleIndices.isNotEmpty) {
      visibleCharacterIndex = 0;
    } else {
      return const SizedBox.shrink();
    }

    final Offset levelPos = levelPositions[visibleCharacterIndex];

    // ✅ Dynamic scaling
    final size = MediaQuery.of(context).size;
    final double characterSize = size.width * 0.22; // responsive
    final double screenPadding = 20.0;

    // ✅ By default, place to the right of button
    double leftPos = levelPos.dx + 10; // button width ≈ 80
    if (leftPos + characterSize > size.width - screenPadding) {
      // Too close to right edge → shift to left of button
      leftPos = levelPos.dx - characterSize - 10;
    }

    // Align vertically with button center
    double topPos = levelPos.dy - characterSize * 0.6;

    return Positioned(
      top: topPos,
      left: leftPos,
      child: Image.asset(
        'assets/img/Brainu.png',
        width: characterSize,
        height: characterSize,
        fit: BoxFit.contain,
      ),
    );
  }

  void _scrollToHighestUnlocked() {
    int lastUnlockedIndex = -1;
    for (int i = 0; i < _levelCompletionStatus.length; i++) {
      if (_levelCompletionStatus[i]!) {
        lastUnlockedIndex = i;
      } else {
        break;
      }
    }

    int targetIndex = lastUnlockedIndex >= 0 ? lastUnlockedIndex : 0;

    final visibleIndices = selectedLevels
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (visibleIndices.isEmpty) return;

    final visibleLevelPositions =
        _calculateLevelPositions(context, visibleIndices.length);

    if (targetIndex < visibleIndices.length) {
      final targetPosition =
          visibleLevelPositions[visibleIndices.indexOf(targetIndex)];

      _scrollController.animateTo(
        targetPosition.dy - 200,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
}
