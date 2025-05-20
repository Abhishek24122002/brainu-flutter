import 'package:flutter/material.dart';
import '../generated/l10n.dart';

class SubmitButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const SubmitButton({
    required this.isEnabled,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? const Color(0xFF8B3A00) : Colors.grey,
        foregroundColor: Colors.white,
        shadowColor: Colors.black.withOpacity(0.4),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(80), // pill shape
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 120),
      ),
      child: Text(
        S.of(context).submit,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
