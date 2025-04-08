import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class DoneButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const DoneButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF8B3E00), // Brown fill
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
          gradient: const LinearGradient(
            colors: [Color(0xFFA04A00), Color(0xFF6B2A00)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.fredokaOne(
              fontSize: 18,
              color: Colors.white,
              shadows: [
                const Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
