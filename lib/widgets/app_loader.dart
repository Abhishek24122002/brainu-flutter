import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

enum LoaderStyle {
  circle,
  bounce,
  wave,
  fadingCube,
  chasingDots,
  pulse,
  dualRing,
}

class AppLoader extends StatelessWidget {
  final String? message;
  final LoaderStyle style;
  final Color color;

  const AppLoader({
    super.key,
    this.message,
    this.style = LoaderStyle.circle,
    this.color = Colors.white,
  });

  Widget _buildLoader() {
    switch (style) {
      case LoaderStyle.bounce:
        return SpinKitThreeBounce(color: color, size: 40);
      case LoaderStyle.wave:
        return SpinKitWave(color: color, size: 40);
      case LoaderStyle.fadingCube:
        return SpinKitFadingCube(color: color, size: 40);
      case LoaderStyle.chasingDots:
        return SpinKitChasingDots(color: color, size: 40);
      case LoaderStyle.pulse:
        return SpinKitPulse(color: color, size: 40);
      case LoaderStyle.dualRing:
        return SpinKitDualRing(color: color, size: 40);
      case LoaderStyle.circle:
      default:
        return SpinKitFadingCircle(color: color, size: 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.5),
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.transparent),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLoader(),
                if (message != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    message!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
