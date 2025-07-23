import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../generated/l10n.dart';
import '../audio_buttons.dart';

class AudioShowcaseButtons extends StatelessWidget {
  final bool isRecording;
  final bool isPlaying;
  final bool isEnabled;

  final VoidCallback? onRecordPressed;
  final VoidCallback? onPlayPressed;
  final VoidCallback? onConfirmPressed;

  final Map<String, GlobalKey<State<StatefulWidget>>> keys;

  const AudioShowcaseButtons({
    super.key,
    required this.isRecording,
    required this.isPlaying,
    required this.isEnabled,
    required this.onRecordPressed,
    required this.onPlayPressed,
    required this.onConfirmPressed,
    required this.keys,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Showcase(
          key: keys['record']!,
          description: S.of(context).Click_here_to_record,
          child: StartRecordingButton(
            onPressed: onRecordPressed,
            isRecording: isRecording,
          ),
        ),
        Showcase(
          key: keys['play']!,
          description: S.of(context).Click_here_to_listen,
          child: PlayAudioButton(
            isEnabled: isEnabled,
            onPressed: isPlaying ? null : onPlayPressed,
            isPlaying: isPlaying,
          ),
        ),
        Showcase(
          key: keys['confirm']!,
          description: S.of(context).Click_here_to_submit,
          child: ConfirmButton(
            isEnabled: isEnabled,
            onPressed: isEnabled ? onConfirmPressed : null,
          ),
        ),
      ],
    );
  }
}
