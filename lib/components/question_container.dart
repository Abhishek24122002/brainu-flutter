import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../generated/l10n.dart'; // Import localization file

class CustomContainer extends StatelessWidget {
  final String text;

  const CustomContainer({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dynamicFontSize = screenWidth * 0.004; 

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.fredokaOne(
          textStyle: TextStyle(
            fontSize: dynamicFontSize.clamp(14.0, 24.0), // min 16, max 28
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 138, 58, 9),
          ),
        ),
      ),
    );
  }
}
