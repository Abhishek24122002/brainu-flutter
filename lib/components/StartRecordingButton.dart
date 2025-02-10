import 'package:flutter/material.dart';

import '../generated/l10n.dart';

class StartRecordingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isRecording;

  StartRecordingButton({
    required this.onPressed,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        isRecording ? Icons.stop : Icons.mic,
        color: Colors.white,
      ),
      label: Text(
        isRecording ? S.of(context).stop_recording :  S.of(context).start_recording,
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: isRecording ? Colors.red : Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
