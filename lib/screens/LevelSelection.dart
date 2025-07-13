// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Required for HapticFeedback
// import 'package:shared_preferences/shared_preferences.dart';
// import '../Authentication/navigation.dart';
// import '../components/SelectGameDialog.dart';
// import '../generated/l10n.dart';
// import 'Letter.dart';
// import 'Identify.dart';
// import 'Phonemene_deletetion_final.dart';
// import 'Phonemene_deletetion_initial.dart';
// import 'Phonemene_substitution_final.dart';
// import 'Phonemene_substitution_initial.dart';
// import 'Word.dart';
// import 'Listen.dart';
// import 'Story.dart';
// import 'swap.dart';
// import 'package:vibration/vibration.dart';
// import 'dart:ui';
// import 'package:google_fonts/google_fonts.dart';

// class LevelSelection extends StatefulWidget {
//   @override
//   _LevelSelectionState createState() => _LevelSelectionState();
// }

// class _LevelSelectionState extends State<LevelSelection> {
//   List<bool> selectedLevels = List.generate(10, (_) => true);

//   final List<Widget> levels = [
//     Letter(),
//     Identify(),
//     Word(),
//     Listen(),
//     Story(),
//     Swap(),
//     Ph_deletion_final(),
//     Ph_deletion_initial(),
//     Ph_substitution_final(),
//     Ph_substitution_initial(),
//   ];

//   int? _tappedButtonIndex;

//   @override
//   Widget build(BuildContext context) {
//     // Filter visible levels
//     List<int> visibleIndices = [];
//     for (int i = 0; i < selectedLevels.length; i++) {
//       if (selectedLevels[i]) visibleIndices.add(i);
//     }

//     return Stack(
//       children: [
//         // 🌄 Background Image (covers full screen including AppBar)
//         Positioned.fill(
//           child: Image.asset(
//             'assets/img/background.jpeg',
//             fit: BoxFit.cover,
//           ),
//         ),

//         // Main Scaffold on top
//         Scaffold(
//           backgroundColor: Colors.transparent, // ⬅️ Transparent to see image
//           appBar: PreferredSize(
//             preferredSize: Size.fromHeight(kToolbarHeight),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.3),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     offset: Offset(0, 4),
//                     blurRadius: 6,
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 child: BackdropFilter(
//                   filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                   child: AppBar(
//                     automaticallyImplyLeading: false, // ❌ Remove back arrow
//                     backgroundColor: Colors.transparent,
//                     elevation: 0,
//                     iconTheme: IconThemeData(color: Colors.black),
//                     title: Stack(
//                       children: [
//                         // Stroke
//                         Text(
//                           S.of(context).games,
//                           style: GoogleFonts.fredokaOne(
//                             textStyle: TextStyle(
//                               fontSize: 28,
//                               fontWeight: FontWeight.bold,
//                               foreground: Paint()
//                                 ..style = PaintingStyle.stroke
//                                 ..strokeWidth = 3
//                                 ..color = Color(0xFF954305), // 🟠 Stroke color
//                             ),
//                           ),
//                         ),
//                         // Fill
//                         Text(
//                           S.of(context).games,
//                           style: GoogleFonts.fredokaOne(
//                             textStyle: TextStyle(
//                               fontSize: 28,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFFFDA748), // 🟡 Fill color
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     centerTitle: true,
//                     actions: [
//                       IconButton(
//                         icon: Icon(Icons.logout,
//                             color: Color(0xFFEE5B03)), // 🔥 New color
//                         onPressed: () async {
//                           await FirebaseAuth.instance.signOut();
//                           SharedPreferences prefs =
//                               await SharedPreferences.getInstance();
//                           await prefs.remove('uid');
//                           Navigator.pushReplacement(
//                             context,
//                             Navigation.generateRoute(
//                                 RouteSettings(name: '/login')),
//                           );
//                         },
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.menu,
//                             color: Color(0xFFEE5B03)), // 🔥 New color
//                         onPressed: () async {
//                           final result = await showDialog<List<bool>>(
//                             context: context,
//                             builder: (context) {
//                               return SelectGameDialog(
//                                   initialSelectedLevels: selectedLevels);
//                             },
//                           );

//                           if (result != null) {
//                             setState(() {
//                               selectedLevels = result;
//                             });
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           body: Padding(
//             padding: const EdgeInsets.only(bottom: 40),
//             child: Align(
//               alignment: Alignment.bottomCenter,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: _buildButtonRows(context, visibleIndices),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   List<Widget> _buildButtonRows(
//       BuildContext context, List<int> visibleIndices) {
//     List<Widget> rows = [];
//     int totalButtons = visibleIndices.length;
//     int buttonNumber = 1;

//     List<int> rowConfig;
//     switch (totalButtons) {
//       case 1:
//         rowConfig = [0, 1];
//         break;
//       case 2:
//         rowConfig = [0, 2];
//         break;
//       case 3:
//         rowConfig = [0, 3];
//         break;
//       case 4:
//         rowConfig = [0, 2, 2];
//         break;
//       case 5:
//         rowConfig = [0, 3, 2];
//         break;
//       case 6:
//         rowConfig = [0, 3, 3];
//         break;
//       case 7:
//         rowConfig = [3, 2, 2];
//         break;
//       case 8:
//         rowConfig = [3, 3, 2];
//         break;
//       case 9:
//         rowConfig = [3, 3, 3];
//         break;
//       case 10:
//       default:
//         rowConfig = [3, 3, 3, 1];
//         break;
//     }

//     int currentIndex = 0;
//     for (int rowButtons in rowConfig) {
//       if (rowButtons == 0) continue;

//       List<Widget> row = [];
//       for (int i = 0; i < rowButtons; i++) {
//         if (currentIndex >= totalButtons) break;
//         int index = visibleIndices[currentIndex];
//         row.add(_buildNumberedButton(context, index, buttonNumber));
//         currentIndex++;
//         buttonNumber++;
//       }

//       rows.add(Row(
//         mainAxisAlignment: rowButtons < 3
//             ? MainAxisAlignment.center
//             : MainAxisAlignment.spaceEvenly,
//         children: row,
//       ));
//       rows.add(SizedBox(height: 16));
//     }

//     return rows;
//   }

//   Widget _buildNumberedButton(
//       BuildContext context, int levelIndex, int buttonNumber) {
//     bool isTapped = _tappedButtonIndex == levelIndex;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0),
//       child: GestureDetector(
//         onTapDown: (_) async {
//           if (await Vibration.hasVibrator() ?? false) {
//             Vibration.vibrate(duration: 50); // Vibrational feedback
//           }
//           setState(() {
//             _tappedButtonIndex = levelIndex;
//           });
//         },
//         onTapUp: (_) async {
//           await Future.delayed(Duration(milliseconds: 100));
//           setState(() {
//             _tappedButtonIndex = null;
//           });
//         },
//         onTapCancel: () {
//           setState(() {
//             _tappedButtonIndex = null;
//           });
//         },
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => levels[levelIndex]),
//           );
//         },
//         child: AnimatedScale(
//           scale: isTapped ? 0.9 : 1.0,
//           duration: Duration(milliseconds: 100),
//           curve: Curves.easeOut,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               Image.asset(
//                 'assets/img/button.png',
//                 width: 80,
//                 height: 80,
//               ),
//               Text(
//                 buttonNumber.toString(),
//                 style: TextStyle(
//                   fontSize: 40,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF7B2F00),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
