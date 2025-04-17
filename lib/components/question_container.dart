import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../generated/l10n.dart'; // Import localization file

class CustomContainer extends StatelessWidget {
  final String text;

  const CustomContainer({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.fredokaOne(
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 138, 58, 9),
          ),
        ),
      ),
    );
  }
}
