import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../generated/l10n.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleKey;

  const CustomAppBar({Key? key, required this.titleKey}) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.3),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF7B2F00)),
      title: Stack(
        children: [
          Text(
            _localizedTitle(context),
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
            _localizedTitle(context),
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
    );
  }

  String _localizedTitle(BuildContext context) {
    final s = S.of(context);
    switch (titleKey) {
      case 'letter':
        return s.letter;

      case 'word':
        return s.Word;
      // Add more keys and localizations as needed
      default:
        return titleKey;
    }
  }
}
