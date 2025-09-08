import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:brainu/generated/l10n.dart';

class ClickHereToListenShowcase extends StatelessWidget {
  final GlobalKey showcaseKey;
  final Widget child;
  final VoidCallback? onTargetClick;

  const ClickHereToListenShowcase({
    Key? key,
    required this.showcaseKey,
    required this.child,
    this.onTargetClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: showcaseKey,
      description: S.of(context).Click_here_to_listen,
      onTargetClick: onTargetClick,
      disposeOnTap: false, // keep highlight until clicked
      child: child,
    );
  }
}
