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

    // Vibrate on press
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
              height: 60.h,   // Responsive height
              width: 560.w,   // Responsive width
              fit: BoxFit.contain,
            ),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 84.sp,              // Responsive font
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
