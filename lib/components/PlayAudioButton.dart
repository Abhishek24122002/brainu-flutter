import 'package:flutter/material.dart';

class PlayAudioButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isPlaying;

  PlayAudioButton({
    required this.onPressed,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.play_arrow, color: Colors.white),
      label: Text(
        'Play Audio',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.amberAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
