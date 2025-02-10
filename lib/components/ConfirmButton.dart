import 'package:flutter/material.dart';

import '../generated/l10n.dart';

class ConfirmButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;

  ConfirmButton({
    required this.onPressed,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(Icons.send, color: Colors.white),
      label: Text(S.of(context).confirm,
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: isEnabled ? Colors.green : Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
