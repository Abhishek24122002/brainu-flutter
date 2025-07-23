import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../generated/l10n.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleKey;
  final VoidCallback? onLearnPressed; // ✅ NEW

  const CustomAppBar({
    Key? key,
    required this.titleKey,
    this.onLearnPressed, // ✅ NEW
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.3),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(
        color: Color(0xFF7B2F00),
        size: 28,
      ),
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
      actions: [
        if (onLearnPressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: onLearnPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school, // 🎓 degree cap
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 4),
                  Text(
                    S.of(context).Learn,
                    style: GoogleFonts.fredokaOne(
                      textStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _localizedTitle(BuildContext context) {
    final s = S.of(context);
    switch (titleKey) {
      case 'letter':
        return s.letter;
      case 'word':
        return s.Word;
      case 'listen':
        return s.game_listen;
      case 'ldentify':
        return s.game_identify;
      case 'story':
        return s.game_story;
      case 'spoonerism':
        return s.game_swapping;
      case 'wordgame1':
        return s.game_word_game1;
      case 'wordgame2':
        return s.game_word_game2;
      case 'wordgame3':
        return s.game_word_game3;
      case 'wordgame4':
        return s.game_word_game4;
      default:
        return titleKey;
    }
  }
}
