import 'package:flutter/material.dart';

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

  Color getButtonColor() {
    if (clickCount >= 2) {
      return Colors.green; // Second click → Green
    } else if (clickCount == 1) {
      return Colors.red; // First click → Red
    }
    return Colors.blueAccent; // Default state → Blue
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
        shape: BoxShape.circle,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: getButtonColor(),
          foregroundColor: Colors.white,
          shape: CircleBorder(),
          padding: EdgeInsets.all(20),
        ),
        onPressed: onPressed,
        child: Text(
          '$index',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
