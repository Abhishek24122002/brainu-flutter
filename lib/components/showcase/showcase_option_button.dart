import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:vibration/vibration.dart';

class ShowcaseOptionButton extends StatelessWidget {
  final int index;
  final bool isSelected;
  final int clickCount;
  final VoidCallback onPressed;

  final GlobalKey<State<StatefulWidget>> showcaseKey;
  final String description;

  const ShowcaseOptionButton({
    super.key,
    required this.index,
    required this.isSelected,
    required this.clickCount,
    required this.onPressed,
    required this.showcaseKey,
    required this.description,
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
    if (clickCount >= 2 || clickCount == 1) {
      return Colors.white;
    }
    return Colors.brown.shade700;
  }

  Future<void> _handleTap() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 30);
    }
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double buttonSize = screenWidth * 0.2;
    buttonSize = buttonSize.clamp(60.0, 100.0);

    return Showcase(
      key: showcaseKey,
      description: description,
      disposeOnTap: false, // Prevents tapping outside from proceeding
       disableBarrierInteraction: true, // ✅ Prevent tapping outside
  onTargetClick: () async {
  await _handleTap(); // 👉 perform the button action
  ShowCaseWidget.of(context).next(); // 👉 then move to next showcase
},
      child: GestureDetector(
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
                  fontSize: buttonSize * 0.35,
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
      ),
    );
  }
}
