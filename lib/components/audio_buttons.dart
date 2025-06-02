import 'package:flutter/material.dart';
import '../generated/l10n.dart';

class StartRecordingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isRecording;

  const StartRecordingButton({
    required this.onPressed,
    required this.isRecording,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String image = isRecording ? 'assets/img/red_btn.png' : 'assets/img/green_btn.png';
    final String label = isRecording ? S.of(context).stop_recording : S.of(context).start_recording;
    final IconData icon = isRecording ? Icons.stop : Icons.mic;

    return CustomImageButton(
      imagePath: image,
      label: label,
      icon: icon,
      onPressed: onPressed,
    );
  }
}

class PlayAudioButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isPlaying;
  final bool isEnabled;

  const PlayAudioButton({
    required this.onPressed,
    required this.isPlaying,
    required this.isEnabled,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String image = isEnabled ? 'assets/img/default_btn.png' : 'assets/img/default_btn.png'; // you can add a greyed-out version too
    return CustomImageButton(
      imagePath: image,
      label: S.of(context).play_audio,
      icon: Icons.play_arrow,
      onPressed: isEnabled ? onPressed : null,
    );
  }
}

class ConfirmButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;

  const ConfirmButton({
    required this.onPressed,
    required this.isEnabled,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String image = isEnabled ? 'assets/img/brown_btn.png' : 'assets/img/brown_btn.png'; // consider adding a disabled version
    return CustomImageButton(
      imagePath: image,
      label: S.of(context).confirm,
      icon: Icons.check,
      onPressed: isEnabled ? onPressed : null,
    );
  }
}

class CustomImageButton extends StatelessWidget {
  final String imagePath;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const CustomImageButton({
    required this.imagePath,
    required this.label,
    required this.icon,
    this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    

    final horizontalMargin = screenWidth * 0.03;
    final isSmallScreen = screenWidth < 370;
    final buttonHeight = isSmallScreen ? 40.0 : 60.0;
    final fontSize = isSmallScreen ? 16.0 : 22.0;
    final iconSize = isSmallScreen ? 20.0 : 28.0;
    final verticalSpacing = isSmallScreen ? 3.0 : 8.0;

    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed != null ? 1.0 : 0.5,
        child: Container(
          width: screenWidth - 2 * horizontalMargin,
          height: buttonHeight,
          margin: EdgeInsets.symmetric(
            vertical: verticalSpacing,
            horizontal: horizontalMargin,
          ),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.fill,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: iconSize),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
