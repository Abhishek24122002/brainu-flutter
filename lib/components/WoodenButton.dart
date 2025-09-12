import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vibration/vibration.dart';

class AnimatedWoodenButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const AnimatedWoodenButton({required this.label, required this.onPressed});

  @override
  _AnimatedWoodenButtonState createState() => _AnimatedWoodenButtonState();
}

class _AnimatedWoodenButtonState extends State<AnimatedWoodenButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) async {
    setState(() {
      _scale = 0.9;
    });

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 40);
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Adaptive sizes
    double buttonHeight = screenWidth < 500 ? 70.h : 60.h; // bigger on phones
    double buttonWidth  = screenWidth < 500 ? 630.w : 560.w;
    double fontSize     = screenWidth < 500 ? 80.sp : 45.sp;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/img/Wooden_btn.png',
              height: buttonHeight,
              width: buttonWidth,
              fit: BoxFit.contain,
            ),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
