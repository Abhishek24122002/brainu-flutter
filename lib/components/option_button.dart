import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class OptionButton extends StatelessWidget {
  final int index;
  final bool isSelected;
  final int clickCount;
  final VoidCallback onPressed;

  OptionButton({
    required this.index,
    required this.isSelected,
    required this.clickCount,
    required this.onPressed,
  });

  String getImageAsset()   {
    if (clickCount >= 2) {
      return 'assets/img/green_btn_round.png';
    } else if (clickCount == 1) {
      return 'assets/img/red_btn_round.png';
    }
    return 'assets/img/default_btn_round.png';
  }

  Color getTextColor() {
    if (clickCount >= 2) return Colors.white;
    if (clickCount == 1) return Colors.white;
    return Colors.brown.shade700;
  }

  Future<void> _handleTap() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 30); // quick vibrational feedback
    }
    onPressed();
  }

  @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  // Adjust button size relative to screen width (and optionally height)
  double buttonSize = screenWidth * 0.2; // 20% of screen width
  buttonSize = buttonSize.clamp(60.0, 100.0); // Clamp to a reasonable range

  return GestureDetector(
    onTap: _handleTap,
    child: Container(
      width: buttonSize,
      height: buttonSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            getImageAsset(),
            width: buttonSize,
            height: buttonSize,
            fit: BoxFit.contain,
          ),
          Text(
            '$index',
            style: TextStyle(
              fontSize: buttonSize * 0.35, // Scales text size
              fontWeight: FontWeight.bold,
              color: getTextColor(),
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}