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

  String getImageAsset() {
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
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: 90,
        height: 90,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              getImageAsset(),
              width: 90,
              height: 90,
              fit: BoxFit.contain,
            ),
            Text(
              '$index',
              style: TextStyle(
                fontSize: 32,
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
